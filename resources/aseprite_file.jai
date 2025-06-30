AsepriteFile :: struct
{
    #as using _resource: Resource;

    load_function = aseprite_file_load;
    unload_function = aseprite_file_unload;

    data: AsepriteData;

    texture: *TextureFile; @serialize
    animations: Table(StringHash, *Animation); @serialize

    aseprite_frame_to_sprite_index: Table(s64, s64);
}

get_animation :: (aseprite_file: *AsepriteFile, name: string) -> *Animation
{
    success, animation: = table_find_new(*aseprite_file.animations, string_hash(name));
    if !success return null;
    return animation;
}

aseprite_file_sync_sprites :: (using aseprite_file: *AsepriteFile)
{
    assert(aseprite_file != null);
    assert(aseprite_file.is_loaded_without_errors);

    // Sprites
    bounds_to_sprite_index: Table(Bounds, s64);
    bounds_to_sprite_index.allocator = temporary_allocator;

    // Build existing sprite table, remove duplicates (should never happen if the code is right, but we handle it anyway)
    for < sprite, i: texture.sprites
    {
        entry, added: = find_or_add(*bounds_to_sprite_index, sprite.bounds);
        if !added
        {
            array_ordered_remove_by_index(*texture.sprites, i);
            continue;
        }
        <<entry = xx i;
    }

    // Match aseprite sprites with engine sprites
    table_reset(*aseprite_frame_to_sprite_index);
    for frame, i: data.frames
    {
        bounds: = Bounds.{ 
            Vector2.{xx frame.frame.x, xx frame.frame.y },
            Vector2.{xx (frame.frame.x + frame.frame.w), xx (frame.frame.y + frame.frame.h) }
        };

        found, index: = table_find_new(*bounds_to_sprite_index, bounds);
        if !found
        {
            sprite: = object_create(Sprite);
            assert(sprite != null);

            object_rename(sprite, frame.name);
            sprite.texture = texture;
            sprite.bounds = bounds;

            array_add(*texture.sprites, sprite);
            index = texture.sprites.count - 1;
        }

        table_set(*aseprite_frame_to_sprite_index, i, index);
    }

    // @NOTE: this will keep obsolete sprites, but maybe that's for the better as there's no risk it breaks any animation that way
}

#scope_file

aseprite_file_load :: (resource: *Resource) -> bool
{
    using t: = cast(*AsepriteFile) resource;
    modified: = false;
    defer if modified resource_save_to_disk(resource);

    resource_add_file_watch(resource, name);

    if (!aseprite_load_data(*data, name))
    {
        log_error("failed to load aseprite data file \"%\"", name);
        return false;
    }

    // Texture
    if texture == null
    {
        texture=, created: = resource_get_or_create(TextureFile, data.image_path);
        modified = true;
    }
    assert(texture != null);

    success: = resource_load(texture);
    if !success
    {
        log_error("failed to load texture \"%\"", texture.name);
        return false;
    }

    // Add unknown animations
    existing_tags: Table(StringHash, bool);
    existing_tags.allocator = temporary_allocator;
    for tag: data.frame_tags
    {
        name_hash: = string_hash(tag.name);

        table_add(*existing_tags, name_hash, true);

        found: = table_find_new(*animations, name_hash);
        if !found
        {
            table_add(*animations, name_hash, null);
            modified = true;
        }

        // animation: = resource_get_or_create(Animation, tprint("%.%", name, tag.name));
        // resource_load(animation);

        // animation.frame_count = tag.end_frame - tag.start_frame;
        // layer_index: = animation_add_layer(animation, "Sprites");

        // for i: tag.start_frame..tag.end_frame
        // {
        //     animation_add_event(animation, .{
        //         type = .SPRITE,
        //         layer_index = layer_index,
        //         begin = i - tag.start_frame,
        //         sprite = .{ sprite = texture.sprites[i] },
        //     });
        // }
        // table_add(*animations, tag.name, animation);
    }

    // Remove unknown animations
    for animation, name: animations
    {
        if !table_contains(*existing_tags, name)
        {
            table_remove(*animations, name);
            continue;
        }

        if animation != null
        {
            resource_load(animation);
        }
    }

    return true;
}

aseprite_file_unload :: (resource: *Resource)
{
    using t: = cast(*AsepriteFile) resource;

    for animation, name: animations
    {
        resource_unload(animation);
    }
    table_reset_and_free(*animations);
    table_reset_and_free(*aseprite_frame_to_sprite_index);

    resource_unload(texture);
    texture = null;

    aseprite_release_data(*data);

    resource_remove_file_watch(resource, name);
}
