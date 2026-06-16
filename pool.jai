// Collection
PoolCollection :: struct
{
    pools: Table(*Type_Info, PoolBase);
}
pool_collection: PoolCollection;

pool_add :: ($T: Type) -> *T, ID(T)
{
    pool: = get_or_add_pool(type_info(T));
    assert(pool != null);

    data, id: = pool_add(pool);

    return data, .{index = id.index, generation = id.generation};
}

pool_remove :: (ptr: *$T)
{
    pool: = get_or_add_pool(type_info(T));
    assert(pool != null);

    item: *PoolBase.Item = (ptr.(*void) - POOL_ITEM_HEADER_SIZE);
    pool_remove(pool, item);
}

pool_remove :: (id: ID($T))
{
    pool: = get_or_add_pool(type_info(T));
    assert(pool != null);

    item: = pool_index_to_item_ptr(pool, id.index);
    assert(item.generation == id.generation); // removing already released item

    pool_remove(pool, item);
}

get_or_add_pool :: (ti: *Type_Info) -> *PoolBase
{
    assert(ti != null);

    pool, newly_added: = find_or_add(*pool_collection.pools, ti);
    if newly_added
    {
        pool_init(pool, ti);
    }
    assert(pool != null);
    return pool;
}

// Pool
PoolBase :: struct
{
    Item :: struct
    {
        generation: u32;
        previous: u32;
        next: u32;
        data: *void;
    }

    pages: [..]*void;
    type: *Type_Info;
    items_per_page: s64;

    first_used: u32;
    last_used: u32;
    first_unused: u32;

    used_count: u32;
}

POOL_ITEM_HEADER_SIZE :: size_of(PoolBase.Item) - size_of(*void);

ID :: struct($T: Type)
{
    #as using id: IDBase;
}

IDBase :: struct
{
    index: u32;
    generation: u32;
}

operator == :: inline (a: IDBase, b: IDBase) -> bool
{
    return a.index == b.index && a.generation == b.generation;
}

pool_init :: (using pool: *PoolBase, ti: *Type_Info, page_size: u32 = 32 * 1024)
{
    assert(pool != null);
    assert(pool.type == null);

    type = ti;
    item_size: = get_item_size(pool);
    assert(page_size >= item_size);
    items_per_page = floor_to_s64(cast(float)page_size / cast(float)item_size);

    first_used = 0;
    last_used = 0;
    first_unused = 0;

    pool_add_page(pool); // we allocate a page already to make the null item valid immediately
}

pool_shutdown :: (using pool: *PoolBase)
{
    assert(pool != null);

    for page: pages
    {
        free(page);
    }
    array_reset(*pages);

    first_used = 0;
    last_used = 0;
    first_unused = 0;
    type = null;
}

pool_add :: (using pool: *PoolBase, $initialize:=true) -> *void, IDBase
{
    assert(pool != null);

    if first_unused == 0
    {
        pool_add_page(pool);
        assert(first_unused > 0);
    }

    new_item_index: = first_unused;
    item: = pool_index_to_item_ptr(pool, first_unused);

    first_unused = item.next;
    if first_unused > 0 { pool_index_to_item_ptr(pool, first_unused).previous = 0; }
    item.previous = last_used;
    item.next = 0;

    id: = IDBase.{ index = new_item_index, generation = item.generation};

    if first_used == 0
    {
        assert(last_used == 0);
        first_used = new_item_index;
        last_used = new_item_index;
    }
    else
    {
        pool_index_to_item_ptr(pool, last_used).next = new_item_index;
        last_used = new_item_index;
    }

    #if initialize
    {
        if type.type == .STRUCT && type.(*Type_Info_Struct).initializer != null
        {
            type.(*Type_Info_Struct).initializer(*item.data);
        }
        else
        {
            memset(*item.data, 0, type.runtime_size);
        }
    }

    // log("add % (% % %)", id.index, first_used, last_used, first_unused);
    // for *item, i: items
    // {
    //     log("% % %", i, item.previous, item.next);
    // }

    used_count += 1;

    return *item.data, id;
}

pool_remove :: (using pool: *PoolBase, item: *PoolBase.Item)
{
    assert(pool != null);
    assert(item != null);

    page_index: s64 = -1;
    for p, i: pages
    {
        if item >= p && item < (p+items_per_page)
        {
            page_index = i;
            break;
        }
    }
    assert(page_index >= 0);
    index: u32 = xx (page_index * items_per_page + (item - pages[page_index].(*PoolBase.Item)));

    // Patch used list
    if index == first_used
    {
        first_used = item.next;
    }
    if index == last_used
    {
        last_used = item.previous;
    }
    if item.previous > 0 { pool_index_to_item_ptr(pool, item.previous).next = item.next; }
    if item.next > 0 { pool_index_to_item_ptr(pool, item.next).previous = item.previous; }

    // Patch unused list (keep unused list ordered to avoid memory fragmentation)
    if first_unused == 0
    {
        // Empty unused list
        first_unused = index;
        item.previous = 0;
        item.next = 0;
    }
    else if index < first_unused
    {
        // removed index is before first unused
        item.previous = 0;
        item.next = first_unused;
        pool_index_to_item_ptr(pool, first_unused).previous = index;
        first_unused = index;
    }
    else
    {
        // removed index is after first unused
        append_index: = first_unused;
        append_item: = pool_index_to_item_ptr(pool, append_index);
        while append_item.next < index && append_item.next > 0
        {
            append_index = append_item.next;
            append_item = pool_index_to_item_ptr(pool, append_index);
        }

        if append_item.next > 0 { pool_index_to_item_ptr(pool, append_item.next).previous = index; }
        item.next = append_item.next;
        item.previous = append_index;
        append_item.next = index;
    }

    used_count -= 1;

    item.generation += 1;
}

get :: (id: ID($T), $do_checks: = true) -> *T
{
    return get(T, id, do_checks);
}

get :: ($T: Type, id: IDBase, $do_checks: = true) -> *T
{
    pool: *PoolBase(T) = xx id.pool;
    #if do_checks
    {
        if pool == null return null;
        item: = pool_index_to_item_ptr(pool, id.index);
        return ifx id.generation == item.generation then *item.data else null;
    }
    else
    {
        return *pool_index_to_item_ptr(id.index).data;
    }
}

for_expansion :: (pool: PoolBase, body: Code, flags: For_Flags) #expand
{
    i: = 0;

    #if flags & .REVERSE
        index: = pool.last_used;
    else
        index: = pool.first_used;

    while index > 0
    {
        item: = pool_index_to_item_ptr(*pool, index);

        `it_index: = i;     // The backtick will export it_index to the caller.
        `it: = *item.data;  // Same.

        // Preparation for next iteration should be done before inserting body, otherwise continue will break the loop
        #if flags & .REVERSE
            index = item.previous;
        else
            index = item.next;
        i += 1;

        #insert (remove=#assert(false)) body;
    }
}

get_item_size :: (pool: *PoolBase) -> s64
{
    return POOL_ITEM_HEADER_SIZE + pool.type.runtime_size;
}

#scope_file

pool_index_to_item_ptr :: (using pool: *PoolBase, index: u32) -> *PoolBase.Item
{
    assert(index >= 0);
    page_index: = index / items_per_page;
    assert(page_index < pages.count);
    item_index: = index % items_per_page;
    return pages[page_index] + item_index;
}

pool_add_page :: (using pool: *PoolBase)
{
    assert(pool != null);
    assert(first_unused == 0);

    item_size: = get_item_size(pool);
    page: = alloc(items_per_page * item_size);
    array_add(*pages, page);
    page_index: = pages.count - 1;
    first_item_index: = 0;
    if page_index == 0
    {
        first_item_index = 1; // 0 is reserved as the null item
        memset(page, 0, item_size); // 0 initialize null index
    }
    start_index: = page_index * items_per_page;
    first_unused = xx (start_index + first_item_index);

    for i: first_item_index..items_per_page-1
    {
        item: *Item = xx (page + (i * item_size));
        item.generation = 0;
        item.previous = xx(start_index + i-1);
        item.next = xx(start_index + i+1);
    }

    get_page_item :: (page: *void, index: s64, item_size: s64) -> *PoolBase.Item
    {
        return xx (page + (index * item_size));
    }

    first_item: = get_page_item(page, first_item_index, item_size);
    last_item: = get_page_item(page, items_per_page-1, item_size);
    first_item.previous = 0; // first item is first unused item so previous is null
    last_item.next = 0; // last item is last unused item so next is null
}
