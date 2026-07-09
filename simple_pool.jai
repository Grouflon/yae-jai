SimplePool :: struct($T: Type)
{
    Item :: struct
    {
        data: T;
        previous: s32;
        next: s32;
    }

    items: [..]Item;
    first_used: s32 = -1;
    last_used: s32 = -1;
    first_unused: s32 = -1;

    used_count: s32 = 0;
}

pool_reserve :: (using pool: *SimplePool($T), count: s32)
{
    if count <= items.count return;

    previous_count: s32 = xx items.count;
    array_resize(*items, count);
    for i: previous_count..count-1
    {
        items[i].previous = i-1;
        items[i].next = i+1;
    }
    items[count-1].next = -1;

    if first_unused < 0
    {
        first_unused = previous_count;
        items[previous_count].previous = -1;
    }
    else
    {
        last_unused: = first_unused;
        while (items[last_unused].next >= 0) { last_unused = items[last_unused].next; }
        items[last_unused].next = previous_count;
        items[previous_count].previous = last_unused;
    }
}

pool_add :: (using pool: *SimplePool($T)) -> *T, s32
{
    // Grow pool if no unused items left
    if first_unused < 0
    {
        pool_reserve(pool, items.count.(s32) * 2 + 8);
    }
    assert(first_unused >= 0);

    // We append new item at the end of used list
    new_index: = first_unused;
    if last_used >= 0
    {
        items[last_used].next = new_index;
    }
    else
    {
        assert(first_used < 0);
        first_used = new_index;
    }

    first_unused = items[new_index].next;
    if first_unused >= 0
    {
        items[first_unused].previous = -1;
    }

    items[new_index].previous = last_used;
    items[new_index].next = -1;

    last_used = new_index;

    used_count += 1;

    return *items[new_index].data, new_index;
}

pool_remove :: (using pool: *SimplePool($T), item: *T)
{
    raw_data: *void = xx items.data;
    raw_item: *void = xx item;
    ITEM_SIZE :: size_of(SimplePool(T).Item);
    assert(raw_item >= raw_data && raw_item < (raw_data + pool.items.count * ITEM_SIZE));
    index: s32 = xx ((raw_item - raw_data) / ITEM_SIZE);
    pool_remove(pool, index);
}

pool_remove :: (using pool: *SimplePool($T), index: s32)
{
    assert(index >= 0 && index < items.count);
    assert(is_index_used(pool, index));

    // Patch used list
    item: = items.data + index;
    if index == first_used
    {
        assert(item.previous < 0);
        first_used = item.next;
        if first_used >= 0
        {
            items[first_used].previous = -1;
        }
    }
    else
    {
        if item.previous >= 0 items[item.previous].next = item.next;
        if item.next >= 0 items[item.next].previous = item.previous;
    }

    if index == last_used
    {
        last_used = item.previous;
    }

    // Insert at unused list start
    item.previous = -1;
    item.next = first_unused;
    if first_unused >= 0
    {
        items[first_unused].previous = index;
    }
    first_unused = index;

    used_count -= 1;
}

pool_clear :: (using pool: *SimplePool($T))
{

}

pool_get :: (using pool: *SimplePool($T), index: s32) -> *T // never store this, pointer can be invalidated when the pool grows
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
        index: = last_used;
    else
        index: = first_used;

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
is_index_used :: (using pool: *SimplePool($T), index: s32) -> bool
{
    i: = first_used;
    while i >= 0
    {
        if i == index return true;
        i = items[i].next;
    }
    return false;
}