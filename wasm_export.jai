// WASM callbacks
wasm_on_update :: (dt: float32) #c_call
{
    push_context
    {
        application_update(dt);
    }
}

wasm_on_preload_end :: () #c_call
{
    push_context
    {
        application_init();
    }
}

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
#import "Basic";
#import "yae";