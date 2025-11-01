// API

DEFAULT_WINDOW_CREATION_COLOR :: Color.{38,38,51,255};

ImageData :: struct
{
    data: *u8;
    width: u32;
    height: u32;
    channels: u32;
}

// Window
// create_window :: (width: int, height: int, window_name: string, background_color: Color = DEFAULT_WINDOW_CREATION_COLOR) -> *void;
// destroy_window :: (window_handle: *void);
// get_window_size :: (window_handle: *void) -> int, int;
// get_viewport_size :: (window_handle: *void) -> int, int;
// get_window_position :: (window_handle: *void) -> int, int;
// get_mouse_position :: (window_handle: *void) -> Vector2;
// set_mouse_position :: (window_handle: *void, position: Vector2);
// update_input_events :: ();
// is_window_focused :: () -> bool;
get_window_size :: () -> int, int { w, h: = get_window_size(yae.window_handle); return w, h; }
get_viewport_size :: () -> int, int { w, h: = get_viewport_size(yae.window_handle); return w, h; }
get_mouse_position :: () -> Vector2 { return get_mouse_position(yae.window_handle); }
set_mouse_position :: (position: Vector2) { set_mouse_position(yae.window_handle, position); }
get_window_scale_dpi :: () -> Vector2 { return .{1,1}; } // TO IMPLEMENT

// Time
// get_time :: () -> float64;

// Rendering
// init_opengl_context :: (window: *void);
// swap_buffers :: (window: *void);
// read_and_decode_image :: (filename: string) -> bool, ImageData;

// Filesystem
// file_exists :: (path: string) -> bool;
// get_absolute_path :: (path: string) -> string, bool;
// make_directory_if_it_does_not_exist :: (name: string, recursive := false) -> directory_now_exists: bool;
// read_entire_file :: (path: string) -> string, bool;
// write_entire_file :: (path: string, data: *void, count: int) -> bool;
write_entire_file :: (path: string, data: string) -> bool { return write_entire_file(path, data.data, data.count); }

// FileWatch
//FileWatcher :: struct {}

#if OS == .WINDOWS
{
    #load "platform_windows.jai";
}
#if OS == .WASM
{
    #load "platform_wasm.jai";
}