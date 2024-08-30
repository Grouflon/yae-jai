Spritesheet :: struct
{
    #as using base: Resource;
    type = Spritesheet;

    load_function = spritesheet_load;
    unload_function = spritesheet_unload;

    data: AsepriteData;
}

#scope_file

spritesheet_load :: (resource: *Resource)
{
    using spritesheet: = cast(*Spritesheet) resource;

    aseprite_load_data(*data, name);
    resource_add_file_watch(resource, name);
}

spritesheet_unload :: (resource: *Resource)
{
    using spritesheet: = cast(*Spritesheet) resource;

    aseprite_release_data(*data);
    resource_remove_file_watch(resource, name);
}
