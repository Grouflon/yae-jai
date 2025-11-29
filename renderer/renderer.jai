// == Each renderer must define those
// RENDERER_INVALID_HANDLE :: 0;
// TextureHandle :: GLuint;
// ShaderProgramHandle :: GLuint;
// RenderTextureHandle :: GLuint;

Texture :: struct
{
    width: u32;
    height: u32;
    handle: TextureHandle;
}

RenderTexture :: struct
{
    handle: RenderTextureHandle;
    texture: Texture;
    depth: Texture;
}

ShaderProgram :: struct
{
    handle: ShaderProgramHandle;
    mvp_uniform_location: s32;
    texture_uniform_location: s32;
    time_uniform_location: s32;
}

ShaderInstance :: struct
{
    program: ShaderProgram;
    uniforms: [..]ShaderUniform;
}

ShaderUniformType :: enum
{
    INT;
    FLOAT;
    VECTOR2;
    VECTOR3;
    VECTOR4;
}

ShaderUniform :: struct
{
    name: *u8; // only accept string literals for now
    type: ShaderUniformType;
    union {
        int_: s32;
        float_: float;
        vector2_: Vector2;
        vector3_: Vector3;
        vector4_: Vector4;
    }
}

TextureFilter :: enum
{
    LINEAR;
    NEAREST;
}

TextureWrap :: enum
{
    REPEAT;
    MIRRORED_REPEAT;
    CLAMP_TO_BORDER;
    CLAMP_TO_EDGE;
    MIRROR_CLAMP_TO_EDGE;
}

TextureParameters :: struct
{
    min_filter: TextureFilter = .LINEAR; @serialize
    mag_filter: TextureFilter = .LINEAR; @serialize
    wrap_s: TextureWrap = .REPEAT; @serialize
    wrap_t: TextureWrap = .REPEAT; @serialize
}

Vertex :: struct
{
    position: Vector3;
    uv: Vector2;
    color: Vector4;
}

DrawCommandType :: enum
{
    TRIANGLES;
    LINES;
    LINE_STRIP;
    LINE_LOOP;
}

DrawCommand :: struct
{
    type: DrawCommandType;
    transform: Matrix4;
    texture: TextureHandle;
    start_index: u32;
    line_width: float;
    size: u32;
}

#load "renderer_opengl.jai";