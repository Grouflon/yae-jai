AsepriteFile :: struct
{
    #as using _resource: Resource;
    type = type_info(AsepriteFile);
    load_function = aseprite_file_load;
    unload_function = aseprite_file_unload;

    texture: *TextureFile; @serialize
    animations: Table(StringHash, *Animation); @serialize

    data: AsepriteData;
    bounds_to_frame_index: Table(Bounds, s64);
}

get_animation :: (aseprite_file: *AsepriteFile, name: string) -> *Animation
{
    success, animation: = table_find_new(*aseprite_file.animations, string_hash(name));
    if !success return null;
    return get(animation);
}

animation_import_from_aseprite_file :: (animation: *Animation, aseprite_file: *AsepriteFile, aseprite_animation_name: string)
{
    assert(aseprite_file != null);
    assert(animation != null);
    assert(animation.is_loaded_without_errors);

    texture: = aseprite_file.texture;
    if texture == null return;

    tag_found, tag_index: = table_find_new(*aseprite_file.data.name_to_tag, aseprite_animation_name);
    if !tag_found return;
    tag: = aseprite_file.data.frame_tags[tag_index];

    animation.frame_count = tag.end_frame - tag.start_frame + 1;
    array_clear(*animation.sprite_events);

    start_frame: s32 = -1;
    current_sprite: *TextureFile.Sprite = null;

    for i: tag.start_frame..tag.end_frame
    {
        sprite_found, sprite_index: = table_find_new(*aseprite_file.aseprite_frame_to_sprite_index, i);
        if !sprite_found continue;

        sprite: = *texture.sprites[sprite_index];
        if sprite != current_sprite
        {
            if current_sprite != null
            {
                array_add(*animation.sprite_events, .{
                    begin = start_frame - tag.start_frame,
                    end = (i-1) - tag.start_frame,
                    sprite = .{texture, current_sprite.name},
                });
            }
            current_sprite = sprite;
            start_frame = i;
        }
    }
    if current_sprite != null
    {
        array_add(*animation.sprite_events, .{
            begin = start_frame - tag.start_frame,
            end = tag.end_frame - tag.start_frame,
            sprite = .{texture, current_sprite.name},
        });
    }

    resource_save_to_disk(animation);
}

aseprite_file_build_index_table :: (using aseprite_file: *AsepriteFile) -> Table(s64, s64)
{
    frame_index_to_sprite_index: Table(s64, s64);
    frame_index_to_sprite_index.allocator = temporary_allocator;

    if texture == null return frame_index_to_sprite_index;

    for sprite, i: texture.sprites
    {
        found, frame_index: = table_find_new(*bounds_to_frame_index, sprite.bounds);
        if found
        {
            table_add(*frame_index_to_sprite_index, frame_index, i);
        }
    }

    return frame_index_to_sprite_index;
}

aseprite_file_sync_sprites :: (using aseprite_file: *AsepriteFile)
{
    if texture == null return;

    // @NOTE: we keep obsolete sprites, but maybe that's for the better as there's no risk it breaks any animation that way
    for frame, i: data.frames
    {
        bounds: = get_bounds(frame.frame);
        found, frame_index: = table_find_new(*bounds_to_frame_index, bounds);
        assert(found); // It has to be there otherwise something is wrong in the loading process
        if i != frame_index continue;
        texture_add_or_set_sprite(texture, frame.name, bounds);
    }
    aseprite_file_build_index_table(aseprite_file);

    resource_save_to_disk(texture);
}

#scope_file



aseprite_file_load :: (resource: *Resource) -> bool
{
    using t: = cast(*AsepriteFile) resource;

    modified: = false;
    defer if modified resource_save_to_disk(resource);

    // Load aseprite data
    if (!aseprite_load_data(*data, path))
    {
        log_error("failed to load aseprite data file \"%\"", path);
        return false;
    }

    for frame, i: data.frames
    {
        bounds: = get_bounds(frame.frame);
        if !table_find_new(*bounds_to_frame_index, bounds)
        {
            table_add(*bounds_to_frame_index, bounds, i);
        }
    }

    aseprite_file_build_index_table(t);

    // // Texture
    // if texture
    // {

    // }
    // success: = resource_load(texture);
    // if !success
    // {
    //     aseprite_release_data(*data);
    //     log_error("failed to load texture \"%\"", texture.name);
    //     return false;
    // }

    // aseprite_file_sync_sprites(t);

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
    }

    // Remove unknown animations
    for animation, name: animations
    {
        if !table_contains(*existing_tags, name)
        {
            table_remove(*animations, name);
            modified = true;
            continue;
        }
    }

    return true;
}

aseprite_file_unload :: (resource: *Resource)
{
    using t: = cast(*AsepriteFile) resource;

    // for animation, name: animations
    // {
    //     resource_unload(animation);
    // }
    table_reset_and_free(*animations);
    table_reset_and_free(*bounds_to_frame_index);

    // resource_unload(texture);
    texture = null;

    aseprite_release_data(*data);
}
