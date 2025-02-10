// API

DEFAULT_WINDOW_CREATION_COLOR :: Vector4.{38,38,51,255};

TextureData :: struct
{
    data: *u8;
    width: u32;
    height: u32;
    channels: u32;
}

PreloadFileType :: enum
{
    UNKNOWN :: 0;
    IMAGE :: 1;
}

// create_window :: (width: int, height: int, window_name: string, background_color: Color = DEFAULT_WINDOW_CREATION_COLOR) -> *void;
// get_window_size :: (window_handle: *void) -> int, int;
// get_viewport_size :: (window_handle: *void) -> int, int;
// get_window_position :: (window_handle: *void) -> int, int;
// get_mouse_position :: (window_handle: *void) -> Vector2;
// update_input_events :: ();
// init_opengl_context :: (window: *void);
// swap_buffers :: (window: *void);
// load_texture_data :: (filename: string, allocator: *Allocator) -> TextureData;
// preload :: (filename: string, file_type: PreloadFileType);

get_window_width :: () -> int { w, h: = get_window_size(app.window); return w; }
get_window_height :: () -> int { w, h: = get_window_size(app.window); return h; }
get_window_size :: () -> int, int { w, h: = get_window_size(app.window); return w, h; }
get_viewport_size :: () -> int, int { w, h: = get_viewport_size(app.window); return w, h; }
get_mouse_position :: () -> Vector2 { return get_mouse_position(app.window); }

#if OS == .WINDOWS
{
    #load "platform/platform_windows.jai";
}
#if OS == .WASM
{
    #load "platform/platform_wasm.jai";
}