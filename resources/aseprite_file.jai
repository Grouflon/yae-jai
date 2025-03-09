AsepriteFile :: struct
{
    #as using base: Resource;

    load_function = aseprite_data_load;
    unload_function = aseprite_data_unload;
    release_function = aseprite_data_release;

    //Note: we still have the problem that data is non-existent until we load the resource, therefore if we just create the resource and save it, it will be empty and clear all the ids
    // That may be a shortcoming of embedding resources like this, but maybe that's okay
    texture: *TextureFile; @embed @serialize
    animations: Table(string, *Animation); // to embed at some point to be able to maintain id. Bur require table serialization
}

get_animation :: (aseprite_file: *AsepriteFile, name: string) -> *Animation
{
    animation, success: = table_find(*aseprite_file.animations, name);
    if !success return null;
    return animation;
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

    // Texture
    if texture == null
    {
        texture = resource_get_or_create(TextureFile, aseprite_data.image_path);
    }
    assert(texture != null);

    success: = resource_load(texture);
    if !success
    {
        log_error("failed to load aseprite texture \"%\"", texture.name);
        return false;
    }

    // Sprites
    array_clear(*texture.sprites);
    for frame: aseprite_data.frames
    {
        sprite: = resource_get_or_create(Sprite, frame.name);
        if sprite == null continue;

        sprite.texture = texture;
        sprite.bounds = .{ 
            Vector2.{xx frame.frame.x, xx frame.frame.y },
            Vector2.{xx (frame.frame.x + frame.frame.w), xx (frame.frame.y + frame.frame.h) }
        };
        array_add(*texture.sprites, sprite);
    }

    // Animations
    table_clear(*animations);
    for tag: aseprite_data.frame_tags
    {
        animation: = resource_get_or_create(Animation, tprint("%.%", name, tag.name));

        array_clear(*animation.frames);
        for i: tag.start_frame..tag.end_frame
        {
            array_add(*animation.frames, .{ sprite = texture.sprites[i] });
        }
        table_add(*animations, tag.name, animation);

        resource_load(animation);
    }

    return true;
}

aseprite_data_unload :: (resource: *Resource)
{
    using t: = cast(*AsepriteFile) resource;

    for animation: animations
    {
        resource_unload(animation);
    }
    table_clear(*animations);

    resource_unload(texture);
    texture = null;

    resource_remove_file_watch(resource, name);
}

aseprite_data_release :: (resource: *Resource)
{
    using t: = cast(*AsepriteFile) resource;
    
    table_free(*animations);
}
