Renderer :: OpenGLRenderer;

RENDERER_INVALID_HANDLE :: 0;
TextureHandle :: GLuint;
ShaderProgramHandle :: GLuint;

OpenGLRenderer :: struct
{
    vao: GLuint;
    vbo: GLuint;
    ibo: GLuint;

    // Maybe all this could go to a renderer agnostic command buffer thingy
    is_drawing: bool;
    vertex_buffer: [..]Vertex;
    index_buffer: [..]u16;
    command_buffer: [..]DrawCommand;

    shader_stack: [..]ShaderProgram;
    camera_stack: [..]Camera;
    transform_stack: [..]Matrix4;

    texture_1px_white: Texture;
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

    texture_data: u32 = 0xffffffff;
    image_data: = ImageData.{ cast(*u8)*texture_data, 1, 1, 4 };
    texture_1px_white = load_texture(image_data);

    array_add(*transform_stack, Matrix4_Identity);

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

    array_reset(*vertex_buffer);
    array_reset(*index_buffer);
    array_reset(*command_buffer);
    array_reset(*shader_stack);
    array_reset(*camera_stack);

    unload_texture(texture_1px_white);
    texture_1px_white = .{};

    // no need to destroy context apparently
}

load_texture :: (image_data: ImageData, parameters: TextureParameters = .{}) -> Texture
{
    if image_data.data == null return .{};
    if image_data.channels != 4
    {
        log_error("only rgba8 images is supported for now");
        return .{};
    }

    texture: Texture;
    texture.width = image_data.width;
    texture.height = image_data.height;

    // OpenGL stores textures from bottom row to top row, therefore we have to reverse y data before loading.
    reversed_data: *u8;
    {
        row_size: = image_data.width * image_data.channels;
        push_allocator(temporary_allocator);
        reversed_data = alloc(row_size * image_data.height);
        for i: 0..image_data.height-1
        {
            memcpy(reversed_data + row_size * i, image_data.data + (image_data.height-1-i) * row_size, row_size);
        }
    }

    GL_VERIFY(glActiveTexture(GL_TEXTURE0));
    GL_VERIFY(glGenTextures(1, *texture.handle));
    GL_VERIFY(glBindTexture(GL_TEXTURE_2D, texture.handle));

    GL_VERIFY(glTexImage2D(
        GL_TEXTURE_2D,    // target
        0,                // level
        GL_RGBA8,         // internal format
        image_data.width,           // width
        image_data.height,          // height
        0,                // border, must be 0
        GL_RGBA,          // format
        GL_UNSIGNED_BYTE, // type
        reversed_data
    ));
    set_texture_parameters(texture, parameters);

    return texture;
}

set_texture_parameters :: (texture: Texture, parameters: TextureParameters)
{
    if texture.handle == RENDERER_INVALID_HANDLE return;

    GL_VERIFY(glActiveTexture(GL_TEXTURE0));
    GL_VERIFY(glBindTexture(GL_TEXTURE_2D, texture.handle));

    to_gl :: (filter: TextureFilter) -> GLint
    {
        if #complete filter ==
        {
            case .LINEAR; return GL_LINEAR;
            case .NEAREST; return GL_NEAREST;
        }    
    }

    to_gl :: (wrap: TextureWrap) -> GLint
    {
        if #complete wrap ==
        {
            case .REPEAT; return GL_REPEAT;
            case .MIRRORED_REPEAT; return GL_MIRRORED_REPEAT;
            case .CLAMP_TO_BORDER; return GL_CLAMP_TO_BORDER;
            case .CLAMP_TO_EDGE; return GL_CLAMP_TO_EDGE;
            case .MIRROR_CLAMP_TO_EDGE; return GL_MIRROR_CLAMP_TO_EDGE;
        }    
    }

    GL_VERIFY(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, to_gl(parameters.min_filter)));
    GL_VERIFY(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, to_gl(parameters.mag_filter)));
    GL_VERIFY(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, to_gl(parameters.wrap_s)));
    GL_VERIFY(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, to_gl(parameters.wrap_t)));
}

unload_texture :: (texture: Texture)
{
    if texture.handle == RENDERER_INVALID_HANDLE return;
    GL_VERIFY(glDeleteTextures(1, *texture.handle));
}

load_shader_program :: (vs_text: string, fs_text: string) -> ShaderProgram, bool
{
    // Generic shader
    result: bool;
    vertex_shader:, result = create_shader(GL_VERTEX_SHADER, .[vs_text]);
    if !result return .{}, false;
    defer GL_VERIFY(glDeleteShader(vertex_shader));
    fragment_shader:, result = create_shader(GL_FRAGMENT_SHADER, .[fs_text]);
    if !result return .{}, false;
    defer GL_VERIFY(glDeleteShader(fragment_shader));

    program:, result = create_shader_program(.[vertex_shader, fragment_shader]);
    if !result return .{}, false;
    
    return ShaderProgram.{
        handle = program,
        mvp_uniform_location = glGetUniformLocation(program, "uMvp"),
        texture_uniform_location = glGetUniformLocation(program, "uTexture"),
    }, true;
}

unload_shader_program :: (program: ShaderProgram)
{
    if program.handle == RENDERER_INVALID_HANDLE return;
    GL_VERIFY(glDeleteProgram(program.handle));
}

begin_camera :: (camera: Camera)
{
    using yae.renderer;
    assert(is_drawing);

    draw_all_commands();
    array_add(*camera_stack, camera);
}

end_camera :: ()
{
    using yae.renderer;
    assert(is_drawing);
    assert(camera_stack.count > 0);

    #if WITH_EDITOR
    {
        editor_draw();
    }

    draw_all_commands();
    pop(*camera_stack);
}

begin_shader :: (shader: ShaderProgram)
{
    using yae.renderer;
    assert(is_drawing);

    draw_all_commands();
    array_add(*shader_stack, shader);
}

end_shader :: ()
{
    using yae.renderer;
    assert(is_drawing);
    assert(shader_stack.count > 0);

    draw_all_commands();
    pop(*shader_stack);
}

begin_draw :: ()
{
    using yae.renderer;
    assert(!is_drawing);
    is_drawing = true;

    begin_shader(yae_resources.generic_shader.program);

    glEnable(GL_BLEND);
    glBlendEquation(GL_FUNC_ADD);
    glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_STENCIL_TEST);
    glEnable(GL_SCISSOR_TEST);

    width, height: = get_viewport_size(yae.window_handle);
    GL_VERIFY(glViewport(0, 0, xx width, xx height));
    GL_VERIFY(glScissor(0, 0, xx width, xx height));
}

end_draw :: ()
{
    using yae.renderer;
    assert(is_drawing);

    end_shader(); // This triggers a draw

    assert(shader_stack.count == 0);
    is_drawing = false;
}

begin_transform :: (m: Matrix4 = Matrix4_Identity)
{
    using yae.renderer;
    assert(is_drawing);

    array_add(*transform_stack, m);
}

end_transform :: ()
{
    using yae.renderer;
    assert(is_drawing);
    assert(transform_stack.count > 1);

    pop(*transform_stack);
}

transform_translate :: (t: Vector3)
{
    using yae.renderer;
    assert(is_drawing);
    translate(array_back(transform_stack), t);
}

transform_rotate :: (r: Quaternion)
{
    using yae.renderer;
    assert(is_drawing);
    <<array_back(transform_stack) = rotate(array_back(transform_stack), r);
}

transform_scale :: (s: Vector3)
{
    using yae.renderer;
    assert(is_drawing);
    scale(array_back(transform_stack), s);
}

clear_background :: (color: Color)
{
    using yae.renderer;
    assert(is_drawing);

    GL_VERIFY(glClearColor(cast(float)(color.r) / 255, cast(float)(color.g) / 255, cast(float)(color.b) / 255, cast(float)(color.a) / 255));
    GL_VERIFY(glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT));
}

// NOTE: this actually queue commands instead of drawing them instantly.
draw_command :: (type: DrawCommandType, vertices: []Vertex, indices: []u16, texture: TextureHandle = 0, line_width: float = 0)
{
    using yae.renderer;

    start_index: = index_buffer.count;
    for i: indices
    {
        array_add(*index_buffer, xx (vertex_buffer.count + i));
    }
    array_add(*vertex_buffer, ..vertices);

    array_add(*command_buffer, DrawCommand.{
        type = type,
        transform = last(transform_stack),
        start_index = xx start_index,
        size = xx indices.count,
        texture = ifx texture != 0 then texture else texture_1px_white.handle,
        line_width = line_width,
    });
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

draw_all_commands :: ()
{
    using yae.renderer;
    assert(is_drawing);

    if command_buffer.count == 0 return;

    GL_VERIFY(glBufferData(GL_ARRAY_BUFFER, vertex_buffer.count * size_of(Vertex), vertex_buffer.data, GL_STREAM_DRAW));
    GL_VERIFY(glBufferData(GL_ELEMENT_ARRAY_BUFFER, index_buffer.count * size_of(u16), index_buffer.data, GL_STREAM_DRAW));

    shader: = last(shader_stack);
    GL_VERIFY(glUseProgram(shader.handle));

    vp: = camera_to_vp_matrix(last(camera_stack));

    for command: command_buffer
    {
        GL_VERIFY(glActiveTexture(GL_TEXTURE0));
        GL_VERIFY(glBindTexture(GL_TEXTURE_2D, command.texture));

        mvp: = vp * command.transform;
        GL_VERIFY(glUniformMatrix4fv(shader.mvp_uniform_location, 1, GL_TRUE, cast(*GLfloat)*mvp));
        GL_VERIFY(glUniform1i(shader.texture_uniform_location, 0));

        GL_VERIFY(glLineWidth(command.line_width));
        GL_VERIFY(glDrawElements(draw_command_type_to_gl(command.type), xx command.size, GL_UNSIGNED_SHORT, xx (command.start_index * size_of(u16))));
    }

    command_buffer.count = 0;
    vertex_buffer.count = 0;
    index_buffer.count = 0;
}

set_depth_test_enabled :: (value: bool)
{
    if value
    {
        glEnable(GL_DEPTH_TEST);
    }
    else
    {
        glDisable(GL_DEPTH_TEST);
    }
}

is_depth_test_enabled :: () -> bool
{
    return glGet(GL_DEPTH_TEST);
}

#if IMGUI_SUPPORTED
{
draw_imgui_drawdata :: (draw_data: *ImGui.ImDrawData)
{
    using yae.renderer;
    assert(!is_drawing);

    fb_width := (draw_data.DisplaySize.x * draw_data.FramebufferScale.x);
    fb_height := (draw_data.DisplaySize.y * draw_data.FramebufferScale.y);
    if fb_width == 0 || fb_height == 0 return;

    glEnable(GL_BLEND);
    glBlendEquation(GL_FUNC_ADD);
    glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_STENCIL_TEST);
    glEnable(GL_SCISSOR_TEST);

    glViewport(0, 0, xx fb_width, xx fb_height);
    L: float = draw_data.DisplayPos.x;
    R: float = draw_data.DisplayPos.x + draw_data.DisplaySize.x;
    T: float = draw_data.DisplayPos.y;
    B: float = draw_data.DisplayPos.y + draw_data.DisplaySize.y;
    ortho_projection: [4][4]float =
    .[
        .[ 2.0/(R-L),     0.0,         0.0,   0.0 ],
        .[ 0.0,           2.0/(T-B),   0.0,   0.0 ],
        .[ 0.0,           0.0,        -1.0,   0.0 ],
        .[ (R+L)/(L-R),  (T+B)/(B-T),  0.0,   1.0 ],
    ];

    glUseProgram(yae_resources.generic_shader.program.handle);
    glUniform1i(yae_resources.generic_shader.program.texture_uniform_location, 0);
    glUniformMatrix4fv(yae_resources.generic_shader.program.mvp_uniform_location, 1, GL_FALSE, xx ortho_projection.data);

    clip_off: = draw_data.DisplayPos;         // (0,0) unless using multi-viewports
    clip_scale: = draw_data.FramebufferScale; // (1,1) unless using retina display which are often (2,2)

    for i: 0..draw_data.CmdListsCount-1
    {
        command_list: = << (draw_data.CmdLists.Data + i);

        vertices: [..]Vertex;
        vertices.allocator = temporary_allocator;
        array_reserve(*vertices, command_list.VtxBuffer.Size);

        for j: 0..(command_list.VtxBuffer.Size-1)
        {
            v: = command_list.VtxBuffer.Data[j];
            array_add(*vertices, Vertex.{
                .{v.pos.x, v.pos.y, 0},
                .{v.uv.x, 1 - v.uv.y},
                color_to_normalized_vector4(v.col)
            });
        }

        GL_VERIFY(glBufferData(GL_ARRAY_BUFFER, vertices.count * size_of(Vertex), vertices.data, GL_STREAM_DRAW));
        GL_VERIFY(glBufferData(GL_ELEMENT_ARRAY_BUFFER, command_list.IdxBuffer.Size * size_of(u16), command_list.IdxBuffer.Data, GL_STREAM_DRAW));

        for j: 0..command_list.CmdBuffer.Size-1
        {
            cmd: = command_list.CmdBuffer.Data[j];

            clip_min: = Vector2.{(cmd.ClipRect.x - clip_off.x) * clip_scale.x, (cmd.ClipRect.y - clip_off.y) * clip_scale.y};
            clip_max: = Vector2.{(cmd.ClipRect.z - clip_off.x) * clip_scale.x, (cmd.ClipRect.w - clip_off.y) * clip_scale.y};
            if clip_max.x <= clip_min.x || clip_max.y <= clip_min.y
                continue;

            glScissor(xx clip_min.x, xx (fb_height - clip_max.y), xx (clip_max.x - clip_min.x), xx (clip_max.y - clip_min.y));

            if cmd.UserCallback != null
            {
                cmd.UserCallback(command_list, *cmd);
                continue;
            }

            GL_VERIFY(glActiveTexture(GL_TEXTURE0));
            GL_VERIFY(glBindTexture(GL_TEXTURE_2D, xx cmd.TextureId));

            GL_VERIFY(glDrawElements(GL_TRIANGLES, cmd.ElemCount, GL_UNSIGNED_SHORT, xx (cmd.IdxOffset * size_of(u16))));
        }
    }
}
}

#scope_file

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
        return RENDERER_INVALID_HANDLE, false;
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
        return RENDERER_INVALID_HANDLE, false;
    }
    return shader_program, true;
}

draw_command_type_to_gl :: (type: DrawCommandType) -> GLenum #expand #no_debug
{
    if type ==
    {
        case .TRIANGLES; return GL_TRIANGLES;
        case .LINES; return GL_LINES;
        case .LINE_STRIP; return GL_LINE_STRIP;
    }
}

#import "GL"(DUMP_GL_ERRORS = true);
