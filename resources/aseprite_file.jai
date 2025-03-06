AsepriteFile :: struct
{
    #as using base: Resource;

    load_function = aseprite_data_load;
    unload_function = aseprite_data_unload;

    texture: *TextureFile;
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

    array_clear(*texture.sprites);
    for frame: aseprite_data.frames
    {
        sprite: = resource_get_or_create(Sprite, frame.name);
        if sprite == null continue;

        sprite.texture = get_id(texture);
        sprite.bounds = .{ 
            Vector2.{xx frame.frame.x, xx frame.frame.y },
            Vector2.{xx (frame.frame.x + frame.frame.w), xx (frame.frame.y + frame.frame.h) }
        };
        array_add(*texture.sprites, get_id(sprite));
    }

    return true;
}

aseprite_data_unload :: (resource: *Resource)
{
    using t: = cast(*AsepriteFile) resource;

    resource_unload(texture);
    texture = null;
}