create_window :: (width: int, height: int, window_name: string, background_color: Color) -> *void
{
    rgb: [3]float = .[ cast(float)background_color.r / 255.0, cast(float)background_color.g / 255.0, cast(float)background_color.b / 255.0 ];
    return create_window(width, height, window_name, background_color_rgb = rgb);
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
    dc := GetDC(window);
    SwapBuffers(dc);
}

load_texture_data :: (filename: string, allocator: *Allocator) -> TextureData
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

#import "Input";
#import "Window_Creation";
#import "GL"(DUMP_GL_ERRORS = true);
#import "Windows";
#import "File";
#import "stb_image";