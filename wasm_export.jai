// WASM callbacks

wasm_on_update :: (dt: float32) #c_call
{
    push_context
    {
        yae_frame(dt);
    }
}

// wasm_on_preload_end :: () #c_call
// {
//     push_context
//     {
//         yae_init();
//     }
// }

wasm_on_keydown :: (key_code: u32) #c_call
{
    push_context
    {
        on_key_event(key_code, true);
    }
}

wasm_on_keyup :: (key_code: u32) #c_call
{
    push_context
    {
        on_key_event(key_code, false);
    }
}

wasm_on_mousedown :: (button: u32) #c_call
{
    push_context
    {
        on_mousebutton_event(button, true);
    }
}

wasm_on_mouseup :: (button: u32) #c_call
{
    push_context
    {
        on_mousebutton_event(button, false);
    }
}

wasm_on_mousewheel :: (x: float, y: float, z: float) #c_call
{
    push_context
    {
        on_mousewheel_event(x, y, z);
    }
}

wasm_alloc :: (size: s64, allocator: *Allocator) -> *void #c_call
{
    push_context
    {
        if (allocator)
        {
            push_allocator(allocator);
            return alloc(size);
        }
        else
        {
            return alloc(size);
        }
    }
}

wasm_temp_alloc :: (size: s64) -> *void #c_call
{
    return wasm_alloc(size, *temporary_allocator);
}

wasm_memcmp :: (a: *void, b: *void, size: s64) -> s16 #c_call
{
    for i: 0..(size-1)
    {
        a_value: s16 = xx (cast(*u8)a)[i];
        b_value: s16 = xx (cast(*u8)b)[i];
        diff: = a_value - b_value;
        if diff != 0
        {
            return diff;
        }
    }
    return 0;
}

#scope_file
#import "yae";