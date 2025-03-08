TextureFile :: struct
{
    #as using base: Resource;

    load_function = texture_load;
    unload_function = texture_unload;
    release_function = texture_release;

    sprites: [..]*Sprite; @embed @serialize

    texture: Texture2D;
}

#scope_file

texture_load :: (resource: *Resource) -> bool
{
    using t: = cast(*TextureFile) resource;
    resource_add_file_watch(resource, name);

    texture = rl.LoadTexture(temp_c_string(name));
    return true;
}

texture_unload :: (resource: *Resource)
{
    using t: = cast(*TextureFile) resource;

    rl.UnloadTexture(texture);

    resource_remove_file_watch(resource, name);
}

texture_release :: (resource: *Resource)
{
    using t: = cast(*TextureFile) resource;

    array_free(sprites);
}

rl :: #import "raylib";