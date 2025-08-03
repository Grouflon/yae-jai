/*
 * Simple checksum function stolen from wikipedia:
 *
 *   http://en.wikipedia.org/wiki/Fletcher%27s_checksum
 */

fletcher32_checksum :: (data: *u8, len: s32) -> s32
{
    sum1, sum2: s32 = 0xffff, 0xffff;

    while len > 0
    {
        tlen: = ifx len > 360 then 360 else len;
        len -= tlen;
        while true
        {
            sum1 += <<data;
            sum2 += sum1;

            data += 1;
            tlen -= 1;
            if tlen <= 0 { break; }
        }
        sum1 = (sum1 & 0xffff) + (sum1 >> 16);
        sum2 = (sum2 & 0xffff) + (sum2 >> 16);
    }

    /* Second reduction step to reduce sums to 16 bits */
    sum1 = (sum1 & 0xffff) + (sum1 >> 16);
    sum2 = (sum2 & 0xffff) + (sum2 >> 16);
    return sum2 << 16 | sum1;
}

// Array Helpers
first :: inline (array: []$T) -> T
{
    assert(array.count > 0);
    return array[0];
}

last :: inline (array: []$T) -> T
{
    assert(array.count > 0);
    return array[array.count - 1];
}

array_back :: (array: []$T) -> *T
{
    if array.count <= 0 { return null; }
    return array.data + (array.count-1);
}

array_clear :: (array: *[..]$T)
{
    array.count = 0;
}

array_find :: (array: []$T, compare_function: #type (item:T, user_data: *void) -> bool, user_data: *void = null) -> bool, s64
{
    if compare_function == null return false, -1;

    for item, i: array
    {
        if compare_function(item, user_data) return true, i;
    }
    return false, -1;
}

array_move_item :: (array: []$T, from: s64, to: s64)
{
    array_move_item(array.data, array.size, type_info(T), from, to);
}

array_move_item :: (data:*void, size: s64, element_type: *Type_Info, from: s64, to: s64)
{
    if from == to return;
    assert(data != null);
    assert(element_type != null);
    assert(from >= 0 && from < size);
    assert(to >= 0 && to < size);

    element_size: = element_type.runtime_size;

    if to < from
    {
        for #v2 < i: (to+1)..from // This is really weird jai
        {
            mem_swap(data + i * element_size, data + (i-1) * element_size, element_size);
        }
    }
    else
    {
        for i: from..(to-1)
        {
            mem_swap(data + i * element_size, data + (i+1) * element_size, element_size);
        }
    }
}

table_clear :: (table: *Table)
{
    table_reset(table);
}

table_reset_and_free :: (table: *Table)
{
    table_reset(table);
    table_free(table);
}

table_free :: (table: *Table)
{
    deinit(table);
}

verify :: (result: bool)
{
    if !result { assert(false); }
}

rgba :: (color: Color, a: float) -> Color
{
    return Color.{color.r, color.g, color.b, xx (a * 255) };
}

cprint :: (format_string: string, args: .. Any) -> *u8
{
    return temp_c_string(tprint(format_string, ..args));
}

c_format_string :: (fmt: *u8, args: *void) -> string
{
    BUFFER_SIZE :: 1024;
    buffer: [BUFFER_SIZE]u8;
    result: = vsnprintf(buffer.data, BUFFER_SIZE, fmt, args);
    return copy_temporary_string(to_string(buffer.data, result));
}

mem_swap :: (a: *void, b: *void, size: s64)
{
    tmp: = talloc(size);
    memcpy(tmp, b, size);
    memcpy(b, a, size);
    memcpy(a, tmp, size);
}

#scope_file
vsnprintf :: (buffer: *u8, bufsz: s64, fmt: *u8, args: *void) -> s64 #foreign;