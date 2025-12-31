default_allocator :: Context_Base.default_allocator;

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
            sum1 += data.*;
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
first :: (array: []$T) -> T #expand #no_debug
{
    assert(array.count > 0);
    return array[0];
}

last :: (array: []$T) -> T #expand #no_debug
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
        for < i: (to+1)..from // This is really weird jai
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
    table_free(table);
    table.* = .{};
}

table_free :: (table: *Table)
{
    deinit(table);
}

fixed_array_insert_at :: (array: *[$COUNT]$T, item: T, index: s64)
{
    assert(array != null);
    if index >= COUNT return;

    memcpy(array.data + index + 1, array.data + index, (COUNT-index-1) * size_of(T));
    memcpy(array.data + index, *item, size_of(T));
}

fixed_array_remove_at :: (array: *[$COUNT]$T, index: s64)
{
    assert(array != null);
    if index >= COUNT return;

    memcpy(array.data + index, array.data + index + 1, (COUNT-index-1) * size_of(T));
    memset(array.data + COUNT-1, 0, size_of(T));
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

c_format_string :: (fmt: *u8, args: *void, $BUFFER_SIZE: = 1024) -> string
{
    buffer: [BUFFER_SIZE]u8;
    result: = vsnprintf(buffer.data, BUFFER_SIZE, fmt, args);
    if result < 0
    {
        result = BUFFER_SIZE-1;
    }
    s: = to_string(buffer.data, result);
    assert(s.count < BUFFER_SIZE);
    return copy_temporary_string(s);
}

replace_string :: (dest: *string, src: string)
{
    dest.data = realloc(dest.data, src.count, dest.count);
    memcpy(dest.data, src.data, src.count);
    dest.count = src.count;
}

mem_swap :: (a: *void, b: *void, size: s64)
{
    tmp: = talloc(size);
    memcpy(tmp, b, size);
    memcpy(b, a, size);
    memcpy(a, tmp, size);
}

swap :: (a: *$T, b: *T) #expand
{
    tmp: = a.*;
    a.* = b.*;
    b.* = tmp;
}

default_init :: (data: *void, info: *Type_Info)
{
    if info.type == .STRUCT
    {
        info_struct: = cast(*Type_Info_Struct)info;
        if info_struct.initializer != null
        {
            info_struct.initializer(data);
            return;
        }
    }
    memset(data, 0, info.runtime_size);
}

default_init_range :: (data: *void, begin: s64, end: s64, info: *Type_Info)
{
    if info.type == .STRUCT
    {
        info_struct: = cast(*Type_Info_Struct)info;
        if info_struct.initializer != null
        {
            for begin..end  info_struct.initializer(data + it * info.runtime_size);
            return;
        }
    }

    count := end - begin + 1;
    if count <= 0  return;
    memset(data + begin, 0, count * info.runtime_size);
}

compare :: (a: $T, b: T) -> s64 {
    delta := a - b;
    if delta < 0 return -1;
    if delta > 0 return  1;
    return 0;
}

random_get_array_item :: (seed: u64, array: []$T) -> bool, T
{
    state: Random_State;
    random_seed(*state, seed);
    found, item: = random_get_array_item(*state, array);
    return found, item;
}

random_get_array_item :: (state: *Random_State, array: []$T) -> bool, T
{
    result: T;
    if array.count <= 0 return false, result;
    index: s32 = clamp(floor_to_s32(random_get_within_range(0, xx array.count)), 0, xx (array.count-1));
    return true, array[index];
}

random_get_array_item :: (array: []$T) -> bool, T
{
    found, item: = random_get_array_item(*context.random_state, array);
    return found, item;
}

random_range :: (state: *Random_State, min: $T, max_inclusive: T) -> T
{
    return min + ((max_inclusive - min).(float) * random_get_zero_to_one(state)).(T);
}

random_range :: (min: $T, max_inclusive: T) -> T
{
    return random_range(*context.random_state, min, max_inclusive);
}

random_bool :: (state: *Random_State) -> bool
{
    return ifx random_get_zero_to_one(state) > 0.5 then true else false;
}

random_bool :: () -> bool
{
    return random_bool(*context.random_state);
}

// array procedures duplicate to deal with our custom types until we find a solution for poking several operator == in the same module
yae_array_unordered_remove_by_value :: inline (array: *[] $T, item: T, $stop_after_first := false) -> s64 {
    // Probably want to say something to debug memory trackers here.
    // Need to make sure it doesn't cost anything in Release.
    removed := 0;
    for array.*  if it == item {
        removed += 1;
        remove it;

        #if stop_after_first  break;   // Early-out optimization.
    }

    return removed;
}

yae_array_find :: (array: [] $T, item: T) -> bool, s64 {
    for array if it == item return true, it_index;
    return false, -1;  // Not found.
}

yae_array_add_if_unique :: (array: *[..] $T, item: T) -> bool, s64 {   // Return true if newly added; also return index.
    // @Compiler: We should not need explicit dereference here, but auto-dereference doesn't work in some cases.
    found, index := yae_array_find(array.*, item);   
    if found return false, index;

    array_add(array, item);
    return true, array.count-1;
}

// resize_render_texture :: (render_texture: *rl.RenderTexture2D, size: Vector2) -> bool
// {
//     assert(render_texture != null);

//     width: = ceil_to_s32(size.x);
//     height: = ceil_to_s32(size.y);

//     if render_texture.texture.width == width && render_texture.texture.height == height { return false; }

//     if render_texture.texture.id != 0
//     {
//         rl.UnloadRenderTexture(render_texture);
//     }
//     <<render_texture = rl.LoadRenderTexture(width, height);
//     return true;
// }

#scope_file
vsnprintf :: (buffer: *u8, bufsz: s64, fmt: *u8, args: *void) -> s32 #foreign;

#import "Random";
// rl :: #import "raylib";