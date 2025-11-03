#scope_export

// Window
create_window :: (width: int, height: int, window_name: string, background_color: Color = DEFAULT_WINDOW_CREATION_COLOR) -> *void #foreign;
destroy_window :: (window_handle: *void) #foreign;
get_canvas_width :: () -> s32 #foreign;
get_canvas_height :: () -> s32 #foreign;

get_console_window_handle :: () -> *void
{
    return null;
}

get_window_position :: (window_handle: *void) -> width: int, height: int
{
    return 0, 0;
}

get_window_size :: (window_handle: *void) -> width: int, height: int
{
    return get_canvas_width(), get_canvas_height();
}

get_viewport_size :: (window_handle: *void) -> int, int
{
    return get_canvas_width(), get_canvas_height();
}

update_input_events :: ()
{
    input_per_frame_event_and_flag_update();

    for event : pending_events
    {
        if event.type ==
        {
            case .KEYBOARD;
            {
                if event.key_pressed
                {
                    if (input_button_states[event.key_code] & .DOWN) == 0
                    {
                        input_button_states[event.key_code] = .DOWN | .START;
                    }
                }
                else
                {
                    if (input_button_states[event.key_code] & .DOWN) != 0
                    {
                        input_button_states[event.key_code] = .END;
                    }
                }
            }
        }
    }

    array_add(*events_this_frame, ..pending_events);
    pending_events.count = 0;
}

on_key_event :: (key_code: u32, pressed: bool)
{
    jai_key_code: = wasm_to_jai_key_code(key_code);
    array_add(*pending_events, .{
        shift_pressed = (input_button_states[Key_Code.SHIFT] & .DOWN) != 0,
        ctrl_pressed = (input_button_states[Key_Code.CTRL] & .DOWN) != 0,
        alt_pressed = (input_button_states[Key_Code.ALT] & .DOWN) != 0,
        type = Event_Type.KEYBOARD,
        key_pressed = xx pressed,
        key_code = jai_key_code,
        repeat = xx (input_button_states[jai_key_code] & .DOWN),
    });
}

on_mousebutton_event :: (button: u32, pressed: bool)
{
    on_key_event(xx wasm_to_jai_mousebutton(button), pressed);
}

#scope_file
wasm_to_jai_key_code :: (key_code: u32) -> Key_Code
{
    if key_code ==
    {
        case 16; return Key_Code.SHIFT;
        case 17; return Key_Code.CTRL;
        case 18; return Key_Code.ALT;
        case 19; return Key_Code.PAUSE;

        case 33; return Key_Code.PAGE_UP;
        case 34; return Key_Code.PAGE_DOWN;
        case 35; return Key_Code.END;
        case 36; return Key_Code.HOME;
        case 37; return Key_Code.ARROW_LEFT;
        case 38; return Key_Code.ARROW_UP;
        case 39; return Key_Code.ARROW_RIGHT;
        case 40; return Key_Code.ARROW_DOWN;

        case 45; return Key_Code.INSERT;
        case 46; return Key_Code.DELETE;

        case 112; return Key_Code.F1;
        case 113; return Key_Code.F2;
        case 114; return Key_Code.F3;
        case 115; return Key_Code.F4;
        case 116; return Key_Code.F5;
        case 117; return Key_Code.F6;
        case 118; return Key_Code.F7;
        case 119; return Key_Code.F8;
        case 120; return Key_Code.F9;
        case 121; return Key_Code.F10;
        case 122; return Key_Code.F11;
        case 123; return Key_Code.F12;

        case 145; return Key_Code.SCROLL_LOCK;

        case; return xx key_code;
    }
}

wasm_to_jai_mousebutton :: (button: u32) -> Key_Code
{
    if button == 
    {
        case 1; return Key_Code.MOUSE_BUTTON_LEFT;
        case 2; return Key_Code.MOUSE_BUTTON_RIGHT;
        case 3; return Key_Code.MOUSE_BUTTON_MIDDLE;
        case; return Key_Code.UNKNOWN; 
    }
}


pending_events : [..]Event;

// Input module shenanigans
Window_Type :: *void;
INVALID_WINDOW : Window_Type : null;
#poke_name Input Window_Type;
#poke_name Input INVALID_WINDOW;
Input :: #import "Input";
using Input;

#scope_export

// Time
get_time :: () -> float64 #foreign;

// Rendering
create_opengl_context :: () #foreign;
read_and_decode_image :: (filename: string, allocator: *Allocator) -> ImageData
{
    data: ImageData;
    read_and_decode_image(filename, allocator, *data);
    return data;
}
read_and_decode_image :: (filename: string, allocator: *Allocator, out_image_data: *ImageData) #foreign;
get_mouse_position :: (window_handle: *void) -> Vector2 #foreign;

init_opengl_context :: (window: *void)
{
    create_opengl_context();
    gl_load_wasm(*gl);
}

swap_buffers :: (window: *void)
{

}

#scope_file
// GL bindings
gl_load_wasm :: (procs: *GL_Procedures)
{
    procs.glGetString = _glGetString;
    procs.glGetIntegeri_v = _glGetIntegeri_v;
    procs.glGenVertexArrays = _glGenVertexArrays;
    procs.glBindVertexArray = _glBindVertexArray;
    procs.glVertexAttribPointer = _glVertexAttribPointer;
    procs.glEnableVertexAttribArray = _glEnableVertexAttribArray;
    procs.glGenBuffers = _glGenBuffers;
    procs.glBindBuffer = _glBindBuffer;
    procs.glBufferData = _glBufferData;
    procs.glClearColor = _glClearColor;
    procs.glClear = _glClear;
    procs.glViewport = _glViewport;
    procs.glScissor = _glScissor;
    procs.glCreateShader = _glCreateShader;
    procs.glShaderSource = _glShaderSource;
    procs.glCompileShader = _glCompileShader;
    procs.glGetShaderiv = _glGetShaderiv;
    procs.glGetShaderInfoLog = _glGetShaderInfoLog;
    procs.glDeleteShader = _glDeleteShader;
    procs.glCreateProgram = _glCreateProgram;
    procs.glAttachShader = _glAttachShader;
    procs.glLinkProgram = _glLinkProgram;
    procs.glDeleteProgram = _glDeleteProgram;
    procs.glGetProgramiv = _glGetProgramiv;
    procs.glGetProgramInfoLog = _glGetProgramInfoLog;
    procs.glUseProgram = _glUseProgram;
    procs.glDrawArrays = _glDrawArrays;
    procs.glDrawElements = _glDrawElements;
    procs.glActiveTexture = _glActiveTexture;
    procs.glGenTextures = _glGenTextures;
    procs.glBindTexture = _glBindTexture;
    procs.glTexParameteri = _glTexParameteri;
    procs.glTexImage2D = _glTexImage2D;
    procs.glGetUniformLocation = _glGetUniformLocation;
    procs.glUniform1i = _glUniform1i;
    procs.glUniformMatrix4fv = _glUniformMatrix4fv;
    procs.glEnable = _glEnable;
    procs.glDisable = _glDisable;
    procs.glBlendEquation = _glBlendEquation;
    procs.glBlendFuncSeparate = _glBlendFuncSeparate;
}

_glGetString :: (pname: GLenum) -> *GLubyte #foreign;
_glGetIntegeri_v :: (target: GLenum, size: GLuint, data: *GLint) #foreign;
_glGenVertexArrays :: (n: GLsizei, arrays: *GLuint) #foreign;
_glBindVertexArray :: (array: GLuint) #foreign;
_glVertexAttribPointer :: (index: GLuint, size: GLint, type: GLenum, normalized: GLboolean, stride: GLsizei, pointer: *void) #foreign;
_glEnableVertexAttribArray :: (index: GLuint) #foreign;
_glGenBuffers :: (n: GLsizei, buffers: *GLuint) #foreign;
_glBindBuffer :: (target: GLenum, buffer: GLuint) #foreign;
_glBufferData :: (target: GLenum, size: GLsizeiptr, data: *void, usage: GLenum) #foreign;
_glClearColor :: (red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat) #foreign;
_glClear :: (mask: GLbitfield) #foreign;
_glViewport :: (x: GLint, y: GLint, width: GLsizei, height: GLsizei) #foreign;
_glScissor :: (x: GLint, y: GLint, width: GLsizei, height: GLsizei) #foreign;
_glCreateShader :: (type: GLenum) -> GLuint #foreign;
_glShaderSource :: (shader: GLuint, count: GLsizei, str_array: **GLchar, length_array: *GLint) #foreign;
_glCompileShader :: (shader: GLuint) #foreign;
_glGetShaderiv :: (shader: GLuint, pname: GLenum, params: *GLint) #foreign;
_glGetShaderInfoLog :: (shader: GLuint, bufSize: GLsizei, length: *GLsizei, infoLog: *GLchar) #foreign;
_glDeleteShader :: (shader: GLuint) #foreign;
_glCreateProgram :: () -> GLuint #foreign;
_glAttachShader :: (program: GLuint, shader: GLuint) #foreign;
_glLinkProgram :: (program: GLuint) #foreign;
_glDeleteProgram :: (shader: GLuint) #foreign;
_glGetProgramiv :: (program: GLuint, pname: GLenum, params: *GLint) #foreign;
_glGetProgramInfoLog :: (program: GLuint, bufSize: GLsizei, length: *GLsizei, infoLog: *GLchar) #foreign;
_glUseProgram :: (program: GLuint) #foreign;
_glDrawArrays :: (mode: GLenum, first: GLint, count: GLsizei) #foreign;
_glDrawElements :: (mode: GLenum, count: GLsizei, type: GLenum, offset: *void) #foreign;
_glActiveTexture :: (texture: GLenum) #foreign;
_glGenTextures :: (n: GLsizei, textures: *GLuint) #foreign;
_glBindTexture :: (target: GLenum, texture: GLuint) #foreign;
_glTexParameteri :: (target: GLenum, pname: GLenum, param: GLint) #foreign;
_glTexImage2D :: (target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, border: GLint, format: GLenum, type: GLenum, pixels: *void) #foreign;
_glGetUniformLocation :: (program: GLuint, name: *GLchar) -> GLint #foreign;
_glUniform1i :: (location: GLint, v0: GLint) #foreign;
_glUniformMatrix4fv :: (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #foreign;
_glEnable :: (cap: GLenum) -> void #foreign;
_glDisable :: (cap: GLenum) -> void #foreign;
_glBlendEquation :: (mode: GLenum) -> void #foreign;
_glBlendFuncSeparate :: (sfactorRGB: GLenum, dfactorRGB: GLenum, sfactorAlpha: GLenum, dfactorAlpha: GLenum) -> void #foreign;

#import "GL"(DUMP_GL_ERRORS = true);
#scope_export

// Filesystem
file_exists :: (path: string) -> bool #foreign;
get_absolute_path :: (path: string) -> string, bool
{
    absolute_path: string;
    success: = get_absolute_path(path, *absolute_path);
    return absolute_path, success;
}
get_absolute_path :: (path: string, out_path: *string) -> bool #foreign;
make_directory_if_it_does_not_exist :: (name: string, recursive := false) -> directory_now_exists: bool #foreign;
read_entire_file :: (path: string) -> string, bool
{
    content: string;
    size: u64;
    success: = read_entire_file(path, cast(**void)*content.data, *size);
    content.count = xx size;
    return content, success;
}
read_entire_file :: (path: string, out_data: **void, out_size: *u64) -> bool #foreign;
write_entire_file :: (path: string, data: *void, count: int) -> bool #foreign;

// WASM Module implementations.
// If any become too complex, we might just want to duplicate the module in yae and do proper implementation there.
// But for now this approach is simpler architecturally
// System
get_path_of_running_executable :: () -> string #foreign;
// Basic
get_working_directory :: () -> string #foreign;
set_working_directory :: (s: string) #foreign;

