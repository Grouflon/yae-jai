Spritesheet :: struct
{
    #as using base: Resource;
    type = Spritesheet;

    frame_duration: float = 0.015;

    load_function = spritesheet_load;
    unload_function = spritesheet_unload;

    data: AsepriteData;
    texture: *Texture;
}


get_aseprite_tag :: (spritesheet: *Spritesheet, animation_name: string) -> *AsepriteFrameTag
{
    if spritesheet == null { return null; }
    index, found: = table_find(*spritesheet.data.name_to_tag, animation_name);
    if ! found { return null; }
    return spritesheet.data.frame_tags.data + index;
}

#scope_file

spritesheet_load :: (resource: *Resource)
{
    using spritesheet: = cast(*Spritesheet) resource;

    aseprite_load_data(*data, name);
    resource_add_file_watch(resource, name);

    if data.image_path.count > 0
    {
        texture = resource_load(Texture, data.image_path);
    }
}

spritesheet_unload :: (resource: *Resource)
{
    using spritesheet: = cast(*Spritesheet) resource;

    if texture != null
    {
        resource_unload(texture);
        texture = null;
    }

    aseprite_release_data(*data);
    resource_remove_file_watch(resource, name);
}
