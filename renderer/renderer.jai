// == Each renderer must define those
// RENDERER_INVALID_HANDLE :: 0;
// TextureHandle :: GLuint;

Texture :: struct
{
    width: u32;
    height: u32;
    handle: TextureHandle;
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