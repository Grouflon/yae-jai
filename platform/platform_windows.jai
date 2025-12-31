// Window
create_window :: (width: s32, height: s32, window_name: string, background_color: Color) -> *void
{
    return create_window(width, height, window_name, background_color.rgb);
}

destroy_window :: (window_handle: *void)
{
    Windows.DestroyWindow(window_handle);
}

get_console_window_handle :: () -> *void
{
    return GetConsoleWindow();
}

get_window_position :: (window_handle: *void) -> width: s32, height: s32
{
    rect: Windows.RECT;
    Windows.GetWindowRect(window_handle, *rect);
    return rect.left, rect.top;
}

get_window_size :: (window_handle: *void) -> width: s32, height: s32
{
    rect: Windows.RECT;
    Windows.GetWindowRect(window_handle, *rect);
    return rect.right - rect.left, rect.bottom - rect.top;
}

get_viewport_size :: (window_handle: *void) -> width: s32, height: s32
{
    rect: Windows.RECT;
    Windows.GetClientRect(window_handle, *rect);
    return rect.right - rect.left, rect.bottom - rect.top;
}

is_window_focused :: () -> bool
{
    return input_application_has_focus;
}

mouse_position: Vector2;
get_mouse_position :: (window_handle: *void) -> Vector2
{
    x, y, success: = get_mouse_pointer_position(window_handle, false);
    if success { mouse_position = .{ xx x, xx y}; };
    return mouse_position;
}

set_mouse_position :: (window_handle: *void, position: Vector2)
{
    // Probably need to do something better, like relative to the window
    SetCursorPos(xx position.x, xx position.y);
}

update_input_events :: ()
{
    update_window_events();
}

// Clipboard
get_clipboard_text :: () -> string
{
    return os_clipboard_get_text();
}

set_clipboard_text :: (text: string)
{
    os_clipboard_set_text(text);
}

// Time
get_time_since_startup :: () -> float64
{
    return seconds_since_init();
}

get_current_appolo_time :: () -> Apollo_Time
{
    return current_time_consensus();
}

init_opengl_context :: (window: *void)
{
    MINIMUM_GL_MAJOR_VERSION :: 3;
    MINIMUM_GL_MINOR_VERSION :: 3;

    hglrc, hdc, chosen_msaa := wgl_create_context(window, null, MINIMUM_GL_MAJOR_VERSION, MINIMUM_GL_MINOR_VERSION);

    gl_load(*gl);
    gl_enable_debug_output(break_on_error = true);
}

swap_buffers :: (window: *void)
{
    dc := Windows.GetDC(window);
    Windows.SwapBuffers(dc);
}

read_and_decode_image :: (filename: string, allocator: *Allocator) -> ImageData
{
    push_allocator(ifx allocator != null then allocator.* else default_allocator);

    width, height, channels: s32;
    data: = stbi_load(temp_c_string(filename), *width, *height, *channels, 4);
    if data == null { return .{}; }

    texture_data: ImageData;
    texture_data.data = data;
    texture_data.width = xx width;
    texture_data.height = xx height;
    texture_data.channels = 4;
    return texture_data;
}

// FileSystem

file_exists :: (path: string) -> bool
{
    return File_Utilities.file_exists(path);
}

get_absolute_path :: (path: string) -> string, bool
{
    path, success: = File.get_absolute_path(path);
    return path, success;
}

make_directory_if_it_does_not_exist :: (name: string, recursive := false) -> directory_now_exists: bool
{
    return File.make_directory_if_it_does_not_exist(name, recursive);
}

read_entire_file :: (path: string) -> string, bool
{
    content, success: = File.read_entire_file(path);
    return content, success;
}

write_entire_file :: (path: string, data: *void, count: int) -> bool
{
    return File.write_entire_file(path, data, count);
}

// System
get_path_of_running_executable :: () -> string
{
    return System.get_path_of_running_executable();
}


#scope_file

GetConsoleWindow :: () -> Windows.HWND #foreign kernel32;
GetWindowTextA :: (window: Windows.HWND, out_str: *u8, max_string_length: s32) -> s32 #foreign user32;
EnumWindows :: (f: #type (window: Windows.HWND, data: *void) -> bool #c_call, data: *void) -> bool #foreign user32;
SetCursorPos :: (x : s32, y : s32) -> s32 #foreign user32;

Windows :: #import "Windows";
System :: #import "System";
kernel32 :: #system_library "kernel32";
user32 :: #system_library "user32";

#import "Input";
#import "Window_Creation";
// #import "GL"(DUMP_GL_ERRORS = true);
File :: #import "File";
File_Utilities :: #import "File_Utilities";
#import "stb_image";
#import "Clipboard";