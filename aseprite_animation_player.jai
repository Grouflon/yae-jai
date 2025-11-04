AsepriteAnimationPlayer :: struct
{
    play_rate: float = 1.0;
    frames_per_second: float = 10.0;
    current_time: float = 0.0;

    aseprite: *AsepriteFile;
    animation: StringHash;
}

animation_player_update :: (using player: *AsepriteAnimationPlayer, dt: float)
{
    assert(player != null);
    if aseprite == null || !aseprite.is_loaded_without_errors return;

    tag: = aseprite_get_tag(*aseprite.data, animation);
    if tag == null return;

    frame_count: = (tag.end_frame+1) - tag.start_frame;
    current_time += dt * play_rate;
    current_time = positive_mod(current_time, (cast(float)frame_count) / frames_per_second);
}

animation_player_play :: (using player: *AsepriteAnimationPlayer, aseprite_file: *AsepriteFile, animation_name: string, loop: bool = true) -> bool
{
    assert(player != null);
    assert(aseprite_file != null);

    hash: = string_hash(animation_name);
    tag: = aseprite_get_tag(*aseprite_file.data, hash);
    if tag == null return false;

    current_time = 0;
    aseprite = aseprite_file;
    animation = hash;
    return true;
}

animation_player_draw :: (using player: *AsepriteAnimationPlayer, position: Vector3, flip_x: bool = false, flip_y: bool = false, tint: Color = WHITE)
{
    assert(player != null);
    if aseprite == null || !aseprite.is_loaded_without_errors return;
    if aseprite.texture == null || !aseprite.texture.is_loaded_without_errors return;

    tag: = aseprite_get_tag(*aseprite.data, animation);
    if tag == null return;

    current_frame: = floor_to_s32(current_time * frames_per_second);
    aseprite_frame: = aseprite.data.frames[tag.start_frame + current_frame];

    draw_sprite(
        position,
        aseprite.texture.texture,
        to_rect(aseprite_frame.frame),
        to_rect(aseprite_frame.sprite_source_size),
        flip_x,
        flip_y,
        tint
    );
}