create_window :: (width: int, height: int, window_name: string, background_color: Color) -> *void
{
    rgb: [3]float = .[ cast(float)background_color.r / 255.0, cast(float)background_color.g / 255.0, cast(float)background_color.b / 255.0 ];
    return create_window(width, height, window_name, background_color_rgb = rgb);
}

get_console_window_handle :: () -> *void
{
    return GetConsoleWindow();
}

get_window_position :: (window_handle: *void) -> width: int, height: int
{
    rect: Windows.RECT;
    Windows.GetWindowRect(window_handle, *rect);
    return rect.left, rect.top;
}

get_window_size :: (window_handle: *void) -> width: int, height: int
{
    rect: Windows.RECT;
    Windows.GetWindowRect(window_handle, *rect);
    return rect.right - rect.left, rect.bottom - rect.top;
}

get_viewport_size :: (window_handle: *void) -> width: int, height: int
{
    rect: Windows.RECT;
    Windows.GetClientRect(window_handle, *rect);
    return rect.right - rect.left, rect.bottom - rect.top;
}

update_input_events :: ()
{
    update_window_events();
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

read_and_decode_texture :: (filename: string, allocator: *Allocator) -> TextureData
{
    push_allocator(allocator);

    width, height, channels: s32;
    data: = stbi_load(temp_c_string(filename), *width, *height, *channels, 4);
    if data == null { return .{}; }

    texture_data: TextureData;
    texture_data.data = data;
    texture_data.width = xx width;
    texture_data.height = xx height;
    texture_data.channels = xx channels;
    return texture_data;
}

preload :: (filename: string, file_type: PreloadFileType) {}

#scope_file

GetConsoleWindow :: () -> Windows.HWND #foreign kernel32;
GetWindowTextA :: (window: Windows.HWND, out_str: *u8, max_string_length: s32) -> s32 #foreign user32;
EnumWindows :: (f: #type (window: Windows.HWND, data: *void) -> bool #c_call, data: *void) -> bool #foreign user32;

Windows :: #import "Windows";
kernel32 :: #system_library "kernel32";
user32 :: #system_library "user32";

#import "Input";
#import "Window_Creation";
#import "GL"(DUMP_GL_ERRORS = true);
#import "File";
#import "stb_image";