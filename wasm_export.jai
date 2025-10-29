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

#scope_file
#import "yae";