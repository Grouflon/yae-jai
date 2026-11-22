SimplePool :: struct($T: Type)
{
    Item :: struct
    {
        previous: s32;
        next: s32;
        data: T;
    }

    items: [..]Item;

    used_list: PoolList;
    unused_list: PoolList;
}

PoolList :: struct
{
    first: s32 = -1;
    last: s32 = -1;
    count: s32 = 0;
}

pool_item_size :: (_type: *Type_Info) -> s64 #expand
{
    return _type.runtime_size + 8;
}

pool_reset :: (using _pool: *SimplePool($T))
{
    array_reset(*items);
    used_list = .{};
    unused_list = .{};
}

pool_reserve :: (using _pool: *SimplePool($T), _count: s32)
{
    pool_reserve(_pool, type_info(T), _count);
}

pool_reserve :: (using _pool: *SimplePool, _type: *Type_Info, _count: s32)
{
    items_array: *Resizable_Array = xx *_pool.items;
    previous_count: s32 = xx items_array.count;

    if _count <= previous_count return;

    array_reserve(items_array, _count, pool_item_size(_type));
    items_array.count = _count;

    // Initialize new items as a valid list
    new_list: PoolList;
    new_list.first = previous_count;
    new_list.last = _count-1;
    new_list.count = _count - previous_count;

    for i: new_list.first..new_list.last
    {
        item: = pool_get_raw_item(_pool, _type, i);
        item.previous = i-1;
        item.next = i+1;
    }
    pool_get_raw_item(_pool, _type, new_list.first).previous = -1;
    pool_get_raw_item(_pool, _type, new_list.last).next = -1;

    // Concatenate with current unused list
    unused_list = concatenate_lists(_pool, _type, unused_list, new_list);
}


pool_add :: (using _pool: *SimplePool($T)) -> *T, s32
{
    item, index: = pool_add(_pool, *_pool.used_list);
    return item, index;
}

pool_add :: (using _pool: *SimplePool($T), _list: *PoolList) -> *T, s32
{
    // Grow pool if no unused items left
    if unused_list.first < 0
    {
        pool_reserve(_pool, items.count.(s32) * 2 + 8);
    }
    assert(unused_list.first >= 0);

    // Move item from unused list to wanted list
    new_index: = unused_list.first;
    pool_move_item_between_lists(_pool, *unused_list, _list, new_index);

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
    pool_move_item_between_lists(_pool, *used_list, *unused_list, _index);
}

pool_remove :: (using _pool: *SimplePool($T), _list: *PoolList, _item: *T)
{
    assert(_list.pool != null);
    index: = pointer_to_index(_list.pool, _item);
    pool_remove(_list, index);
}

pool_remove :: (using _pool: *SimplePool($T), _list: *PoolList, index: s32)
{
    assert(_list.pool != null);
    move_item_between_lists(index, _list, *_list.pool.unused_list);
}


pool_clear :: (using _pool: *SimplePool($T))
{
    // TODO
    assert(false);
}

pool_get :: (using _pool: *SimplePool($T), _index: s32) -> *T // never store this pointer. It can and will be invalidated when the pool grows
{
    assert(_index >= 0 && index < items.count);
    assert(is_index_used(_pool, _index));

    return *items[_index].data;
}

pool_get_raw_item :: (using _pool: *SimplePool, _type: *Type_Info, _index: s32) -> *SimplePool(*void).Item
{
    data: *void = xx items.data;
    return xx (data + _index * pool_item_size(_type));
}

pool_move_item_between_lists :: (using _pool: *SimplePool($T), _source_list: *PoolList, _target_list: *PoolList, _index: s32)
{
    pool_move_item_between_lists(_pool, type_info(T), _source_list, _target_list, _index);
}

pool_move_item_between_lists :: (using _pool: *SimplePool, _type: *Type_Info, _source_list: *PoolList, _target_list: *PoolList, _index: s32)
{
    assert(is_index_in_list(_pool, _type, _source_list, _index));
    assert(_source_list.count > 0);

    // Remove from source list
    item: = pool_get_raw_item(_pool, _type, _index);
    _source_list.count -= 1;
    if item.previous >= 0 pool_get_raw_item(_pool, _type, item.previous).next = item.next;
    if item.next >= 0 pool_get_raw_item(_pool, _type, item.next).previous = item.previous;
    if _source_list.first == _index _source_list.first = item.next;
    if _source_list.last == _index _source_list.last = item.previous;

    // Insert in target list while keeping indices in order (is it always needed, I'm not sure. I feel like not doing it leads to insane fragmentation 100% of the time)
    i: = _target_list.first;
    while i >= 0 && i < _index
    {
        i = pool_get_raw_item(_pool, _type, i).next;
    }

    // Found a greater index in the target list, insert before
    if i >= 0
    {
        item.previous = pool_get_raw_item(_pool, _type, i).previous;
        item.next = i;
        if item.previous >= 0 pool_get_raw_item(_pool, _type, item.previous).next = _index;
        if item.next >= 0 pool_get_raw_item(_pool, _type, item.next).previous = _index;
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
            pool_get_raw_item(_pool, _type, _target_list.last).next = _index;
            _target_list.last = _index;
        }
    }
    _target_list.count += 1;
}

operator[] :: (using _pool: SimplePool($T), index: int) -> SimplePool(T).Item
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

#scope_file

is_index_in_list :: (using _pool: *SimplePool($T), _list: PoolList, _index: s32) -> bool
{
    i: = _list.first;
    while i >= 0
    {
        if i == _index return true;
        i = _pool.items[i].next;
    }
    return false;
}

is_index_in_list :: (using _pool: *SimplePool, _type:*Type_Info, _list: PoolList, _index: s32) -> bool
{
    i: = _list.first;
    while i >= 0
    {
        if i == _index return true;
        i = pool_get_raw_item(_pool, _type, i).next;
    }
    return false;
}

concatenate_lists :: (using _pool: *SimplePool($T), _list_a: PoolList, _list_b: PoolList) -> PoolList
{
    return concatenate_lists(_pool, type_info(T), _list_a, _list_b);
}

concatenate_lists :: (using _pool: *SimplePool, _type: *Type_Info, _list_a: PoolList, _list_b: PoolList) -> PoolList
{
    if _list_a.count == 0 return _list_b;
    if _list_b.count == 0 return _list_a;

    assert(_list_a.first >= 0);
    assert(_list_a.last >= 0);
    assert(_list_b.first >= 0);
    assert(_list_b.last >= 0);

    result: PoolList;
    result.first = _list_a.first;
    result.last = _list_b.first;
    result.count = _list_a.count + _list_b.count;
    pool_get_raw_item(_pool, _type, _list_a.last).next = _list_b.first;
    pool_get_raw_item(_pool, _type, _list_b.first).previous = _list_a.last;
    return result;
}

pointer_to_index :: (using _pool: SimplePool($T), _item: *T) -> s32
{
    raw_data: *void = xx items.data;
    raw_item: *void = xx _item;
    ITEM_SIZE :: size_of(SimplePool(T).Item);
    assert(raw_item >= raw_data && raw_item < (raw_data + items.count * ITEM_SIZE));
    return xx ((raw_item - raw_data) / ITEM_SIZE);
}