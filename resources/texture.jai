TextureFormat :: enum
{
    RGBA;
}

Texture :: struct
{
    width, height: u32;
    format: TextureFormat;

    handle: TextureHandle;
}

texture_load :: (texture: *Texture, path: string) -> bool
{
    assert(texture != null);

    texture_data: = read_and_decode_texture(path, *temporary_allocator);
    if texture_data.data == null
    {
        log_error("unable to load texture \"%\".", path);
        return false;
    }

    texture.format = .RGBA;
    texture.width = texture_data.width;
    texture.height = texture_data.height;
    texture.handle = renderer_create_texture(texture_data.width, texture_data.height, texture_data.data);
    assert(texture.handle != RENDERER_INVALID_HANDLE);
    return true;
}

texture_unload :: (texture: *Texture)
{
    assert(texture != null);
    assert(texture.handle != RENDERER_INVALID_HANDLE);

    renderer_destroy_texture(texture.handle);
    <<texture = .{};
}