TextureFile :: struct
{
    #as using _resource: Resource;
    type = type_info(TextureFile);
    load_function = texture_load;
    unload_function = texture_unload;

    Sprite :: struct
    {
        name: StringHash; @serialize
        bounds: Bounds; @serialize
        origin: Vector2; @serialize @step(1)
    }
    sprites: [..]Sprite; @serialize
    parameters: TextureParameters; @serialize

    texture: Texture;
    name_to_sprite_index: Table(StringHash, s64);
}

texture_add_or_set_sprite :: (using texture_file: *TextureFile, sprite_name: string, bounds: Bounds, origin: Vector2 = .{}) -> *TextureFile.Sprite, s64
{
    sprite_name_hash: = string_hash(sprite_name);
    sprite, index: = texture_get_sprite(texture_file, sprite_name_hash);
    if sprite == null
    {
        array_add(*sprites, .{ sprite_name_hash, bounds, origin });
        sprite = array_back(sprites);
        index = sprites.count-1;
    }
    else
    {
        sprite.bounds = bounds;
    }
    table_set(*name_to_sprite_index, sprite_name_hash, index);
    return sprite, index;
}

texture_remove_sprite :: (using texture: *TextureFile, name: string) -> bool
{
    name_hash: = string_hash(name);
    found, index: = table_remove(*name_to_sprite_index, name_hash);
    if !found return false;

    array_ordered_remove_by_index(*sprites, index);

    for i: index..sprites.count-1
    {
        table_set(*name_to_sprite_index, sprites[i].name, i);
    }
    return true;
}

texture_remove_sprite :: (using texture: *TextureFile, index: s64) -> bool
{
    if index < 0 || index >= sprites.count return false;
    return texture_remove_sprite(texture, sprites[index].name.str);
}

texture_get_sprite :: (texture: *TextureFile, name: string) -> *TextureFile.Sprite, s64
{
    sprite, index: = texture_get_sprite(texture, string_hash(name));
    return sprite, index;
}

texture_get_sprite :: (texture: *TextureFile, name_hash: StringHash) -> *TextureFile.Sprite, s64
{
    if texture == null return null, -1;
    found, index: = table_find_new(*texture.name_to_sprite_index, name_hash);
    if !found return null, -1;
    return *texture.sprites[index], index;
}

// 13.08.2025: This SpriteHandle thing is a bit shit, its confusing and not very convenient
SpriteHandle :: struct
{
    texture: *TextureFile; @serialize
    name: StringHash; @serialize
}

get_sprite :: (handle: SpriteHandle) -> *TextureFile.Sprite, *TextureFile
{
    if handle.texture == null return null, null;
    return texture_get_sprite(handle.texture, handle.name), handle.texture;
}

#scope_file

texture_load :: (resource: *Resource) -> bool
{
    using t: = cast(*TextureFile) resource;

    image_data: = read_and_decode_image(yae_resolve_path(path), *temporary_allocator);
    if image_data.data == null return false;
    
    texture = load_texture(image_data, parameters);

    for sprite, i: sprites
    {
        table_add(*name_to_sprite_index, sprite.name, i);
    }

    return true;
}

texture_unload :: (resource: *Resource)
{
    using t: = cast(*TextureFile) resource;

    unload_texture(texture);

    array_reset(*sprites);
    table_reset_and_free(*name_to_sprite_index);
}

// rl :: #import "raylib";