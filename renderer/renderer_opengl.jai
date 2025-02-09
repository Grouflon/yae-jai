Vertex :: struct
{
    position: Vector3;
    uv: Vector2;
    color: Vector4;
}

OpenGLRenderer :: struct
{
    generic_shader_program: GLuint;
    vao: GLuint;
    vbo: GLuint;
    ibo: GLuint;

    // Maybe all this could go to a renderer agnostic command buffer thingy
    is_drawing: bool;
    vertex_buffer: [..]Vertex;
    index_buffer: [..]u16;
    camera_stack: [..]Camera;
}
renderer: OpenGLRenderer;

renderer_init :: (window_handle: *void)
{
    using renderer;

    init_opengl_context(app.window);
    #if OS != .WASM
    {
        gl_enable_debug_output(true);
    }
    gl_version: = glGetString(GL_VERSION);
    log(tprint("OpenGL Version: %", to_string(gl_version)));

    // Generic shader
    vertex_shader: = create_shader(GL_VERTEX_SHADER, .[GENERIC_VERTEX_SHADER_SRC]);
    fragment_shader: = create_shader(GL_FRAGMENT_SHADER, .[GENERIC_FRAGMENT_SHADER_SRC]);
    generic_shader_program = create_shader_program(.[vertex_shader, fragment_shader]);
    GL_VERIFY(glDeleteShader(vertex_shader));
    GL_VERIFY(glDeleteShader(fragment_shader));
    GL_VERIFY(glUseProgram(generic_shader_program));

    // Vertex Buffer
    GL_VERIFY(glGenBuffers(1, *vbo));
    GL_VERIFY(glBindBuffer(GL_ARRAY_BUFFER, vbo));

    // VAO 
    // this needs to be done with vertex buffer bound
    GL_VERIFY(glGenVertexArrays(1, *vao));
    GL_VERIFY(glBindVertexArray(vao));
    // Position
    GL_VERIFY(glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), xx 0));
    GL_VERIFY(glEnableVertexAttribArray(0));
    // UV
    GL_VERIFY(glVertexAttribPointer(1, 2, GL_FLOAT, GL_TRUE, size_of(Vertex), xx size_of(Vector3)));
    GL_VERIFY(glEnableVertexAttribArray(1));
    // Color
    GL_VERIFY(glVertexAttribPointer(2, 4, GL_FLOAT, GL_TRUE, size_of(Vertex), xx (size_of(Vector3) + size_of(Vector2))));
    GL_VERIFY(glEnableVertexAttribArray(2));

    // Index Buffer
    GL_VERIFY(glGenBuffers(1, *ibo));
    GL_VERIFY(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo));
}

renderer_shutdown :: ()
{
    using renderer;

    GL_VERIFY(glDeleteProgram(generic_shader_program));
    // no need to destroy context apparently
}

begin_draw :: ()
{
    using renderer;
    assert(!is_drawing);

    width, height: = get_window_size(app.window);
    GL_VERIFY(glViewport(0, 0, xx width, xx height));
    GL_VERIFY(glScissor(0, 0, xx width, xx height));

    is_drawing = true;
}

end_draw :: ()
{
    using renderer;
    assert(is_drawing);

    location: = glGetUniformLocation(generic_shader_program, "uMvp");
    camera: = peek(camera_stack);
    mvp: = camera_to_vp_matrix(camera);
    GL_VERIFY(glUniformMatrix4fv(location, 1, GL_TRUE, cast(*GLfloat)*mvp));

    GL_VERIFY(glBufferData(GL_ARRAY_BUFFER, vertex_buffer.count * size_of(Vertex), vertex_buffer.data, GL_STREAM_DRAW));
    GL_VERIFY(glBufferData(GL_ELEMENT_ARRAY_BUFFER, index_buffer.count * size_of(u16), index_buffer.data, GL_STREAM_DRAW));
    GL_VERIFY(glDrawElements(GL_TRIANGLES, xx index_buffer.count, GL_UNSIGNED_SHORT, null));
    vertex_buffer.count = 0;
    index_buffer.count = 0;

    is_drawing = false;
}

clear_color :: (color: Color)
{
    using renderer;
    assert(is_drawing);

    GL_VERIFY(glClearColor(color.x, color.y, color.z, color.w));
    GL_VERIFY(glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT));
}

draw_triangle :: (vertices: []Vertex)
{
    using renderer;
    assert(is_drawing);
    assert(vertices.count == 3);

    base_index: u16 = xx vertex_buffer.count;
    array_add(*vertex_buffer, vertices[0]);
    array_add(*vertex_buffer, vertices[1]);
    array_add(*vertex_buffer, vertices[2]);
    array_add(*index_buffer, base_index);
    array_add(*index_buffer, base_index+1);
    array_add(*index_buffer, base_index+2);
}

create_texture :: (texture_path: string) -> u32, bool
{
    texture_data: = read_and_decode_texture(texture_path, *temporary_allocator);

    if texture_data.data != null
    {
        texture: GLuint;
        GL_VERIFY(glActiveTexture(GL_TEXTURE0));
        GL_VERIFY(glGenTextures(1, *texture));
        GL_VERIFY(glBindTexture(GL_TEXTURE_2D, texture));
        GL_VERIFY(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR));
        GL_VERIFY(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST));
        GL_VERIFY(glTexImage2D(
            GL_TEXTURE_2D,    // target
            0,                // level
            GL_RGBA8,         // internal format
            texture_data.width,           // width
            texture_data.height,          // height
            0,                // border, must be 0
            GL_RGBA,          // format
            GL_UNSIGNED_BYTE, // type
            texture_data.data
        ));
        return texture, true;
    }
    else
    {
        log("failed to load texture %", texture_path);
        return 0, false;
    }
}

bind_texture :: (texture: u32, slot: u32)
{
    GL_VERIFY(glActiveTexture(xx (GL_TEXTURE0 + xx slot)));
    GL_VERIFY(glBindTexture(GL_TEXTURE_2D, xx texture));
}

shader_uniform_texture :: (shader_program: u32, uniform_name: string, texture: u32)
{
    if shader_program == 0 { shader_program = renderer.generic_shader_program; }

    texture_location: = glGetUniformLocation(shader_program, temp_c_string(uniform_name));
    GL_VERIFY(glUniform1i(texture_location, 0));
}

push_camera :: (camera: Camera)
{
    using renderer;
    array_add(*camera_stack, camera);
}

pop_camera :: ()
{
    using renderer;
    pop(*camera_stack);
}

#scope_file

GENERIC_VERTEX_SHADER_SRC :: #string END
#version 300 es
precision mediump float;

layout (location = 0) in vec3 inPosition;
layout (location = 1) in vec2 inTexCoord;
layout (location = 2) in vec4 inColor;

out vec2 fragTexCoord;
out vec4 fragColor;

uniform mat4 uMvp;

void main()
{
    gl_Position = uMvp * vec4(inPosition.x, inPosition.y, inPosition.z, 1.0);
    fragTexCoord = inTexCoord;
    fragColor = inColor;
}
END

GENERIC_FRAGMENT_SHADER_SRC :: #string END
#version 300 es
precision mediump float;

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 outColor;

uniform sampler2D uTexture;

void main()
{
    vec4 pixel = texture(uTexture, fragTexCoord);
    outColor = pixel * fragColor;
}
END

GL_VERIFY :: (c: Code) #expand #no_debug
{
    #insert c;
    #if OS != .WASM
    {
        DumpGLErrors("renderer");
    }
}

create_shader :: (shader_type: GLuint, sources: []string) -> GLuint, bool
{
    shader: = glCreateShader(shader_type);
    assert(shader != 0);

    sizes: [..]GLint;
    data: [..]*GLchar;
    sizes.allocator = temporary_allocator;
    data.allocator = temporary_allocator;
    for source, i : sources
    {
        array_add(*sizes, xx sources[i].count);
        array_add(*data, xx sources[i].data);
    }

    GL_VERIFY(glShaderSource(shader, xx sources.count, data.data, sizes.data));
    GL_VERIFY(glCompileShader(shader));
    success: GLint;
    GL_VERIFY(glGetShaderiv(shader, GL_COMPILE_STATUS, *success));
    if (!success)
    {
        info_log: [512]u8;
        size: GLsizei;
        GL_VERIFY(glGetShaderInfoLog(shader, 512, *size, info_log.data));
        info: = string.{ size, info_log.data };
        log(tprint("Shader Compilation Failed: %", info));
        GL_VERIFY(glDeleteShader(shader));
        return 0, false;
    }
    return shader, true;
}

create_shader_program :: (shaders: []GLuint) -> GLuint, bool
{
    shader_program: = glCreateProgram();
    assert(shader_program != 0);
    for shader: shaders
    {
        GL_VERIFY(glAttachShader(shader_program, shader));
    }
    GL_VERIFY(glLinkProgram(shader_program));
    success: GLint;
    GL_VERIFY(glGetProgramiv(shader_program, GL_LINK_STATUS, *success));
    if (!success)
    {
        info_log: [512]u8;
        size: GLsizei;
        GL_VERIFY(glGetProgramInfoLog(shader_program, 512, *size, info_log.data));
        info: = string.{ size, info_log.data };
        log(tprint("Program Link Failed: %", info));
        GL_VERIFY(glDeleteProgram(shader_program));
        return 0, false;
    }
    return shader_program, true;
}

#import "GL"(DUMP_GL_ERRORS = true);
