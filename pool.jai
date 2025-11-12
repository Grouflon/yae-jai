Pool :: struct($T: Type)
{
    Item :: struct
    {
        data: T;
        generation: u32;
        previous: s32;
        next: s32;
    }

    pages: [..]*Item;
    items_per_page: s64;

    first_used: s32 = -1;
    last_used: s32 = -1;
    first_unused: s32 = -1;
}

ID :: struct($T: Type)
{
    #as using id: BaseID;
}

BaseID :: struct
{
    pool: *void;
    index: s32;
    generation: u32;
}

operator == :: inline (a: BaseID, b: BaseID) -> bool
{
    return a.pool == b.pool && a.index == b.index && a.generation == b.generation;
}

pool_init :: (pool: *Pool, page_size: s32 = 32 * 1024)
{
    assert(pool != null);

    item_size: = size_of(pool.Item);
    assert(page_size >= item_size);
    pool.items_per_page = floor_to_s32(cast(float)page_size / cast(float)item_size);

    pool.first_used = -1;
    pool.last_used = -1;
    pool.first_unused = -1;
}

pool_shutdown :: (using pool: *Pool)
{
    assert(pool != null);

    for page: pages
    {
        free(page);
    }
    array_reset(*pages);
}

pool_add :: (using pool: *Pool($T), $initialize:=true) -> *T, ID(T)
{
    assert(pool != null);

    if first_unused < 0
    {
        pool_add_page(pool);
        assert(first_unused >= 0);
    }

    new_item_index: = first_unused;
    item: = pool_index_to_ptr(pool, first_unused);

    first_unused = item.next;
    if first_unused >= 0 { pool_index_to_ptr(pool, first_unused).previous = -1; }
    item.previous = last_used;
    item.next = -1;

    id: = ID(T).{ pool = pool, index = new_item_index, generation = item.generation};

    if first_used < 0
    {
        assert(last_used < 0);
        first_used = new_item_index;
        last_used = new_item_index;
    }
    else
    {
        pool_index_to_ptr(pool, last_used).next = new_item_index;
        last_used = new_item_index;
    }

    #if initialize
    {
        ini :: initializer_of(T);
        #if ini {
            ini(*item.data);
        } else {
            memset(*item.data, 0, size_of(T));
        }
    }

    // log("add % (% % %)", id.index, first_used, last_used, first_unused);
    // for *item, i: items
    // {
    //     log("% % %", i, item.previous, item.next);
    // }

    return *item.data, id;
}

pool_remove :: (using pool: *Pool($T), data: *T)
{
    assert(pool != null);

    // log("rem % (% % %)", id.index, first_used, last_used, first_unused);
    // for *item, i: items
    // {
    //     log("% % %", i, item.previous, item.next);
    // }

    item: *Pool(T).Item = xx data;
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
    index: s32 = xx (page_index * items_per_page + (item - pages[page_index]));

    // Patch used list
    if index == first_used
    {
        first_used = item.next;
    }
    if index == last_used
    {
        last_used = item.previous;
    }
    if item.previous >= 0 { pool_index_to_ptr(pool, item.previous).next = item.next; }
    if item.next >= 0 { pool_index_to_ptr(pool, item.next).previous = item.previous; }

    // Patch unused list (keep unused list ordered to avoid memory fragmentation)
    if first_unused < 0
    {
        // Empty unused list
        first_unused = index;
        item.previous = -1;
        item.next = -1;
    }
    else if index < first_unused
    {
        // removed index is before first unused
        item.previous = -1;
        item.next = first_unused;
        pool_index_to_ptr(pool, first_unused).previous = index;
        first_unused = index;
    }
    else
    {
        // removed index is after first unused
        append_index: = first_unused;
        append_item: = pool_index_to_ptr(pool, append_index);
        while append_item.next < index && append_item.next >= 0
        {
            append_index = append_item.next;
            append_item = pool_index_to_ptr(pool, append_index);
        }

        if append_item.next >= 0 { pool_index_to_ptr(pool, append_item.next).previous = index; }
        item.next = append_item.next;
        item.previous = append_index;
        append_item.next = index;
    }

    item.generation += 1;
}

get :: (id: ID($T), $do_checks: = true) -> *T
{
    return get(T, id, do_checks);
}

get :: ($T: Type, id: BaseID, $do_checks: = true) -> *T
{
    pool: *Pool(T) = xx id.pool;
    #if do_checks
    {
        if pool == null return null;
        item: = pool_index_to_ptr(pool, id.index);
        return ifx id.generation == item.generation then *item.data else null;
    }
    else
    {
        return *pool_index_to_ptr(id.index).data;
    }
}

for_expansion :: (pool: Pool, body: Code, flags: For_Flags) #expand
{
    i: = 0;

    #if flags & .REVERSE
        index: = pool.last_used;
    else
        index: = pool.first_used;

    while index >= 0
    {
        item: = pool_index_to_ptr(*pool, index);

        `it_index: = i;     // The backtick will export it_index to the caller.

        #if flags & .POINTER
            `it: = *item.data;  // Same.
        else
            `it: = item.data;

        // Preparation for next iteration should be done before inserting body, otherwise continue will break the loop
        #if flags & .REVERSE
            index = item.previous;
        else
            index = item.next;
        i += 1;

        #insert (remove=#assert(false)) body;
    }
}

#scope_file

pool_index_to_ptr :: (using pool: *Pool($T), index: s32) -> *Pool(T).Item
{
    assert(index >= 0);
    page_index: = index / items_per_page;
    assert(page_index < pages.count);
    item_index: = index % items_per_page;
    return pages[page_index] + item_index;
}

pool_add_page :: (using pool: *Pool($T))
{
    assert(pool != null);
    assert(first_unused < 0);

    page: *Pool(T).Item = xx alloc(items_per_page * size_of(pool.Item));
    array_add(*pages, page);
    page_index: = pages.count - 1;
    first_unused = xx (page_index * items_per_page);
    start_index: = xx (page_index * items_per_page);

    for i: 0..items_per_page-1
    {
        page[i].generation = 1; // We start generation at 1, so that IDs zero initialized are always invalid
        page[i].previous = xx(start_index + i-1);
        page[i].next = xx(start_index + i+1);
    }

    page[0].previous = -1;
    page[items_per_page-1].next = -1;
}

