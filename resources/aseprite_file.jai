AsepriteFile :: struct
{
    #as using base: Resource;
    type = AsepriteFile;

    load_function = aseprite_data_load;
    unload_function = aseprite_data_unload;

    texture: *TextureFile;
    sprites: [..]*Sprite;
}

#scope_file

aseprite_data_load :: (resource: *Resource) -> bool
{
    using t: = cast(*AsepriteFile) resource;

    resource_add_file_watch(resource, name);

    aseprite_data: AsepriteData;
    {
        push_allocator(temporary_allocator);
        if (!aseprite_load_data(*aseprite_data, name))
        {
            log_error("failed to load aseprite data file \"%\"", name);
            return false;
        }
    }

    image, success: = resource_load(TextureFile, aseprite_data.image_path);
    if !success
    {
        log_error("failed to load aseprite texture \"%\"", aseprite_data.image_path);
        return false;
    }
    texture = image;

    return true;
}

aseprite_data_unload :: (resource: *Resource)
{
    using t: = cast(*AsepriteFile) resource;

    resource_unload(texture);
    texture = null;
}