Texture :: struct
{
    #as using base: Resource;
    type = Texture;

    load_function = texture_load;
    unload_function = texture_unload;

    texture: Texture2D;
}

#scope_file

texture_load :: (resource: *Resource)
{
    using t: = cast(*Texture) resource;

    texture = rl.LoadTexture(temp_c_string(name));
    resource_add_file_watch(resource, name);
}

texture_unload :: (resource: *Resource)
{
    using t: = cast(*Texture) resource;

    resource_remove_file_watch(resource, name);
    rl.UnloadTexture(texture);
}

rl :: #import "raylib";