// == Each renderer must define those
// RENDERER_INVALID_HANDLE :: 0;
// TextureHandle :: GLuint;
// ShaderProgramHandle :: GLuint;

Texture :: struct
{
    width: u32;
    height: u32;
    handle: TextureHandle;
}

ShaderProgram :: struct
{
    handle: ShaderProgramHandle;
    mvp_uniform_location: s32;
    texture_uniform_location: s32;
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
    min_filter: TextureFilter = .LINEAR;
    mag_filter: TextureFilter = .LINEAR;
    wrap_s: TextureWrap = .REPEAT;
    wrap_t: TextureWrap = .REPEAT;
}

Vertex :: struct
{
    position: Vector3;
    uv: Vector2;
    color: Vector4;
}

DrawCommand :: struct
{
    start_index: u32;
    size: u32;
    texture: TextureHandle;
}

#load "renderer_opengl.jai";