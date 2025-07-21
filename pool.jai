POOL_CHECK_ERRORS :: true;

Pool :: struct($T: Type)
{
    Item :: struct
    {
        data: T;
        generation: u32;
        previous: s32;
        next: s32;
    }

    items: [..]Item;
    first_used: s32 = -1;
    last_used: s32 = -1;
    first_unused: s32 = -1;
    auto_expand: bool = false;
}

PoolID :: struct($T: Type)
{
    pool: *Pool(T);
    index: s32;
    generation: u32;
}

pool_init :: (pool: *Pool, base_size: s32 = 8, auto_expand: bool = true)
{
    assert(pool != null);

    array_reset_keeping_memory(*pool.items);

    pool.first_used = -1;
    pool.last_used = -1;
    pool.first_unused = -1;
    pool.auto_expand = auto_expand;

    pool_grow(pool, base_size);
}

pool_shutdown :: (using pool: *Pool)
{
    assert(pool != null);

    array_reset(*items);
}

pool_add :: (using pool: *Pool($T)) -> PoolID(T), *T
{
    assert(pool != null);

    if first_unused < 0
    {
        if !auto_expand return .{}, null;

        pool_grow(pool, items.count * 2 + 8);
    }

    new_item_index: = first_unused;
    item: = *items[new_item_index];

    first_unused = item.next;
    if first_unused >= 0 { items[first_unused].previous = -1; }
    item.previous = last_used;
    item.next = -1;

    id: = PoolID(T).{pool, new_item_index, item.generation};

    if first_used < 0
    {
        assert(last_used < 0);
        first_used = new_item_index;
        last_used = new_item_index;
    }
    else
    {
        items[last_used].next = new_item_index;
        last_used = new_item_index;
    }

    ini :: initializer_of(T);
    #if ini {
        ini(*item.data);
    } else {
        memset(*item.data, 0, size_of(T));
    }

    return id, *item.data;
}

pool_remove :: (using pool: *Pool($T), id: PoolID(T))
{
    assert(pool != null);
    assert(id.pool == pool);
    
    #if POOL_CHECK_ERRORS
    {
        index: = first_used;
        found: = false;
        while index >= 0
        {
            if index == id.index && items[index].generation == id.generation
            {
                found = true;
                break;
            }
            index = items[index].next;
        }
        assert(found);
    }

    item: = items[id.index];
    assert(item.generation == id.generation);
    if item.previous >= 0 { items[item.previous].next = item.next; }
    item.next = first_unused;
    item.generation += 1;
    first_unused = id.index;
}

get :: (id: PoolID($T)) -> *T
{
    if id.pool == null return null;

    item: = id.pool.items[id.index];
    return ifx id.generation == item.generation then *item.data else null;
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
        item: = *pool.items[index];

        `it_index: = i;     // The backtick will export it_index to the caller.

        #if flags & .POINTER
            `it: = *item.data;  // Same.
        else
            `it: = item.data;

        #insert body;       // The user's code goes here.

        #if flags & .REVERSE
            index = item.previous;
        else
            index = item.next;

        i += 1;
    }
}

#scope_file

pool_grow :: (using pool: *Pool($T), new_size: s64)
{
    assert(pool != null);
    assert(first_unused < 0);

    prev_size: = items.count;
    array_resize(*items, new_size, false);
    first_unused = xx prev_size;

    for i: prev_size..items.count-1
    {
        items[i].generation = 1; // We start generation at 1, so that IDs zero initialized are always invalid
        items[i].previous = xx(i-1);
        items[i].next = xx(i+1);
    }
    items[items.count-1].next = -1;
}
