Renderer :: OpenGLRenderer;

RENDERER_INVALID_HANDLE :: 0;
TextureHandle :: GLuint;

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
    command_buffer: [..]DrawCommand;
}

renderer_init :: ()
{
    using yae.renderer;

    assert(yae.window_handle != null);
    init_opengl_context(yae.window_handle);
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
    using yae.renderer;

    GL_VERIFY(glDeleteProgram(generic_shader_program));
    array_reset(*vertex_buffer);
    array_reset(*index_buffer);
    array_reset(*command_buffer);

    // no need to destroy context apparently
}

load_texture :: (file_path: string) -> bool, Texture
{
    return false, .{};
}

unload_texture :: (texture: Texture)
{
    
}

begin_camera :: (camera: Camera)
{
    using yae.renderer;

    location: = glGetUniformLocation(generic_shader_program, "uMvp");
    mvp: = camera_to_vp_matrix(camera);
    GL_VERIFY(glUniformMatrix4fv(location, 1, GL_TRUE, cast(*GLfloat)*mvp));
}

end_camera :: ()
{

}

begin_draw :: ()
{
    using yae.renderer;
    assert(!is_drawing);

    width, height: = get_window_size(yae.window_handle);
    GL_VERIFY(glViewport(0, 0, xx width, xx height));
    GL_VERIFY(glScissor(0, 0, xx width, xx height));

    is_drawing = true;
}

end_draw :: ()
{
    using yae.renderer;
    assert(is_drawing);

    GL_VERIFY(glBufferData(GL_ARRAY_BUFFER, vertex_buffer.count * size_of(Vertex), vertex_buffer.data, GL_STREAM_DRAW));
    GL_VERIFY(glBufferData(GL_ELEMENT_ARRAY_BUFFER, index_buffer.count * size_of(u16), index_buffer.data, GL_STREAM_DRAW));

    for command: command_buffer
    {
        GL_VERIFY(glActiveTexture(GL_TEXTURE0));
        GL_VERIFY(glBindTexture(GL_TEXTURE_2D, command.texture));

        texture_location: = glGetUniformLocation(generic_shader_program, "uTexture");
        GL_VERIFY(glUniform1i(texture_location, 0));

        GL_VERIFY(glDrawElements(GL_TRIANGLES, xx command.size, GL_UNSIGNED_SHORT, xx (command.start_index * size_of(u16))));
    }

    command_buffer.count = 0;
    vertex_buffer.count = 0;
    index_buffer.count = 0;
    is_drawing = false;
}

clear_background :: (color: Color)
{
    using yae.renderer;
    assert(is_drawing);

    GL_VERIFY(glClearColor(cast(float)(color.r) / 255, cast(float)(color.g) / 255, cast(float)(color.b) / 255, cast(float)(color.a) / 255));
    GL_VERIFY(glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT));
}

draw_command :: (vertices: []Vertex, indices: []u32, texture: TextureHandle)
{
    using yae.renderer;

    index_base: = vertex_buffer.count;
    array_add(*vertex_buffer, ..vertices);
    for i: indices
    {
        array_add(*index_buffer, xx (index_base + i));
    }

    array_add(*command_buffer, DrawCommand.{
        start_index = xx index_base,
        size = xx indices.count,
        texture = texture
    });
}

draw_sprite :: (texture: Texture, position: Vector2)
{

}

renderer_create_texture :: (width: u32, height: u32, data: *u8) -> TextureHandle
{
    assert(data != null);

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
        width,           // width
        height,          // height
        0,                // border, must be 0
        GL_RGBA,          // format
        GL_UNSIGNED_BYTE, // type
        data
    ));
    return texture;
}

renderer_destroy_texture :: (handle: TextureHandle)
{
    assert(handle != 0);

    GL_VERIFY(glDeleteTextures(1, *handle));
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
    fragTexCoord = vec2(inTexCoord.x, -inTexCoord.y); // Textures are stored upside-down in opengl
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
