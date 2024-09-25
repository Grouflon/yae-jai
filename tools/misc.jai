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

verify :: (result: bool) #expand
{
    if !result { assert(false); }
}

rgba :: (color: Color, a: float) -> Color
{
    return Color.{color.r, color.g, color.b, xx (a * 255) };
}