SimplePool :: struct($T: Type)
{
    Item :: struct
    {
        data: T;
        previous: s32;
        next: s32;
    }

    items: [..]Item;

    used_list: PoolList(T);
    unused_list: PoolList(T);
}

PoolList :: struct($T: Type)
{
    pool: *SimplePool(T);
    first: s32 = -1;
    last: s32 = -1;
    count: s32 = 0;
}

pool_initialize :: (using _pool: *SimplePool($T), _base_pool_size: s32 = 256)
{
    used_list.pool = _pool;
    unused_list.pool = _pool;

    pool_reserve(_pool, _base_pool_size);
}

pool_shutdown :: (using _pool: *SimplePool($T))
{
    array_reset(*items);
    used_list = .{};
    unused_list = .{};
}

pool_reserve :: (using _pool: *SimplePool($T), _count: s32)
{
    if _count <= items.count return;

    previous_count: s32 = xx items.count;
    array_resize(*items, _count);

    // Initialize new items as a valid list
    new_list: PoolList(T);
    new_list.pool = _pool;
    new_list.first = previous_count;
    new_list.last = _count-1;
    new_list.count = _count - previous_count;
    for i: new_list.first..new_list.last
    {
        items[i].previous = i-1;
        items[i].next = i+1;
    }
    items[new_list.first].previous = -1;
    items[new_list.last].next = -1;

    // Concatenate with current unused list
    unused_list = concatenate_lists(unused_list, new_list);
}

pool_add :: (using pool: *SimplePool($T)) -> *T, s32
{
    item, index: = pool_add(pool.used_list);
    return item, index;
}

pool_add :: (_list: *PoolList($T)) -> *T, s32
{
    assert(_list.pool != null);
    using _list.pool;

    // Grow pool if no unused items left
    if unused_list.first < 0
    {
        pool_reserve(_list.pool, items.count.(s32) * 2 + 8);
    }
    assert(unused_list.first >= 0);

    // Move item from unused list to wanted list
    new_index: = unused_list.first;
    move_item_between_lists(new_index, *unused_list, _list);

    // Initialize data
    items[new_index].data = .{};

    return *items[new_index].data, new_index;
}

pool_remove :: (using _pool: *SimplePool($T), _item: *T)
{
    index: = pointer_to_index(_pool, _item);
    pool_remove(pool, index);
}

pool_remove :: (using _pool: *SimplePool($T), _index: s32)
{
    move_item_between_lists(_index, *used_list, *unused_list);
}

pool_remove :: (_list: *PoolList($T), _item: *T)
{
    assert(_list.pool != null);
    index: = pointer_to_index(_list.pool, _item);
    pool_remove(_list, index);
}

pool_remove :: (_list: *PoolList($T), index: s32)
{
    assert(_list.pool != null);
    move_item_between_lists(index, _list, *_list.pool.unused_list);
}


pool_clear :: (using _pool: *SimplePool($T))
{
    // TODO
}

pool_get :: (using pool: *SimplePool($T), index: s32) -> *T // never store this pointer. It can and will be invalidated when the pool grows
{
    assert(index >= 0 && index < items.count);
    assert(is_index_used(pool, index));

    return *items[index].data;
}

operator[] :: (using pool: SimplePool($T), index: int) -> SimplePool(T).Item
{
    return items[index];
}

for_expansion :: (using pool: SimplePool, body: Code, flags: For_Flags) #expand
{
    i: = 0;

    #if flags & .REVERSE
        index: = used_list.last;
    else
        index: = used_list.first;

    while index >= 0
    {
        item: = items.data + index;

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

for_expansion :: (using list: PoolList, body: Code, flags: For_Flags) #expand
{
    i: = 0;

    #if flags & .REVERSE
        index: = list.last;
    else
        index: = list.first;

    while index >= 0
    {
        item: = list.pool.items.data + index;

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

#scope_file


is_index_in_list :: (_list: PoolList($T), _index: s32) -> bool
{
    i: = _list.first;
    while i >= 0
    {
        if i == _index return true;
        i = _list.pool.items[i].next;
    }
    return false;
}

concatenate_lists :: (_list_a: PoolList($T), _list_b: PoolList(T)) -> PoolList(T)
{
    assert(_list_a.pool != null);
    assert(_list_a.pool == _list_b.pool);
    if _list_a.count == 0 return _list_b;
    if _list_b.count == 0 return _list_a;

    assert(_list_a.first >= 0);
    assert(_list_a.last >= 0);
    assert(_list_b.first >= 0);
    assert(_list_b.last >= 0);

    result: PoolList(T);
    result.first = _list_a.first;
    result.last = _list_b.first;
    result.count = _list_a.count + _list_b.count;
    _list_a.pool.items[_list_a.last].next = _list_b.first;
    _list_a.pool.items[_list_b.first].previous = _list_a.last;
    return result;
}

move_item_between_lists :: (_index: s32, _source_list: *PoolList($T), _target_list: *PoolList(T))
{
    assert(_source_list.pool != null);
    assert(_source_list.pool == _target_list.pool);
    assert(is_index_in_list(_source_list, _index));
    assert(_source_list.count > 0);

    using _source_list.pool;

    // Remove from source list
    item: = items.data + _index;
    _source_list.count -= 1;
    if item.previous >= 0 items[item.previous].next = item.next;
    if item.next >= 0 items[item.next].previous = item.previous;
    if _source_list.first == _index _source_list.first = item.next;
    if _source_list.last == _index _source_list.last = item.previous;

    // Insert in target list while keeping indices in order (is it always needed, I'm not sure. I feel like not doing it leads to insane fragmentation 100% of the time)
    i: = _target_list.first;
    while i >= 0 && i < _index
    {
        i = items[i].next;
    }

    // Found a greater index in the target list, insert before
    if i >= 0
    {
        item.previous = items[i].previous;
        item.next = i;
        if item.previous >= 0 items[item.previous].next = _index;
        if item.next >= 0 items[item.next].previous = _index;
        if i == _target_list.first _target_list.first = _index;
    }
    // Is last or only index
    else
    {
        // Is only index
        if _target_list.last < 0
        {
            assert(_target_list.first < 0);
            assert(_target_list.count == 0);

            item.previous = -1;
            item.next = -1;
            _target_list.first = _index;
            _target_list.last = _index;
        }
        // Is last index
        else
        {
            item.previous = _target_list.last;
            item.next = -1;
            items[_target_list.last].next = _index;
            _target_list.last = _index;
        }
    }
    _target_list.count += 1;
}

pointer_to_index :: (using _pool: SimplePool($T), _item: *T) -> s32
{
    raw_data: *void = xx items.data;
    raw_item: *void = xx _item;
    ITEM_SIZE :: size_of(SimplePool(T).Item);
    assert(raw_item >= raw_data && raw_item < (raw_data + items.count * ITEM_SIZE));
    return xx ((raw_item - raw_data) / ITEM_SIZE);
}