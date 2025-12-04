AsepriteAnimationPlayer :: struct
{
    play_rate: float = 1.0;
    current_time: float = 0.0;
    current_frame: s32 = -1;
    current_aseprite_frame: s32 = -1;
    is_playing: bool;
    is_looping: bool;
    flip_x: bool;
    flip_y: bool;
    tint: Color = WHITE;

    aseprite: *AsepriteFile;
    animation: StringHash;
}

AsepriteAnimation :: struct
{
    aseprite_name: string;
    animation_name: string;
}

AsepriteAnimationHandle :: struct
{
    aseprite: *AsepriteFile;
    animation: StringHash;
}

get_animation_handle :: (animation: AsepriteAnimation) -> bool, AsepriteAnimationHandle
{
    result: AsepriteAnimationHandle;
    result.aseprite = xx get_resource_by_name(animation.aseprite_name);
    if result.aseprite == null return false, .{};

    result.animation = string_hash(animation.animation_name);
    tag: = aseprite_get_tag(*result.aseprite.data, result.animation);
    if tag == null return false, .{};

    return true, result;
}

animation_player_update :: (using player: *AsepriteAnimationPlayer, dt: float)
{
    assert(player != null);
    if aseprite == null || !aseprite.is_loaded_without_errors return;

    tag: = aseprite_get_tag(*aseprite.data, animation);
    if tag == null return;

    fps: = get_frames_per_second(player);
    frame_count: = (tag.end_frame+1) - tag.start_frame;
    animation_duration: = (frame_count.(float)) / fps;

    current_time += dt * play_rate;
    if is_looping
    {
        current_time = positive_mod(current_time, animation_duration);
    }
    current_frame = floor_to_s32(current_time * fps);
    current_aseprite_frame = tag.start_frame + current_frame;

    if current_time > animation_duration
    {
        animation_player_stop(player);
    } 
}

animation_player_play :: (using player: *AsepriteAnimationPlayer, _animation: AsepriteAnimation, loop: bool = true)
{
    found, handle: = get_animation_handle(_animation);
    if !found
    {
        animation_player_stop(player);
        return;
    }

    animation_player_play(player, handle, loop);
}

animation_player_play :: (using player: *AsepriteAnimationPlayer, animation_handle: AsepriteAnimationHandle, loop: bool = true)
{
    animation_player_play(player, animation_handle.aseprite, animation_handle.animation, loop);
}

animation_player_play :: (using player: *AsepriteAnimationPlayer, aseprite_file: *AsepriteFile, animation_name: string, loop: bool = true)
{
    animation_player_play(player, aseprite_file, string_hash(animation_name), loop);
}

animation_player_play :: (using player: *AsepriteAnimationPlayer, aseprite_file: *AsepriteFile, animation_hash: StringHash, loop: bool = true)
{
    assert(player != null);

    if aseprite_file == aseprite && animation == animation_hash return;

    current_time = 0;
    aseprite = aseprite_file;
    animation = animation_hash;
    is_looping = loop;
    is_playing = true;

    animation_player_update(player, 0);
}

animation_player_stop :: (using player: *AsepriteAnimationPlayer)
{
    assert(player != null);

    current_time = 0;
    current_frame = -1;
    current_aseprite_frame = -1;
    aseprite = null;
    animation = .{};
    is_playing = false;
}


animation_player_draw :: (using player: *AsepriteAnimationPlayer, position: Vector3)
{
    assert(player != null);
    if aseprite == null || !aseprite.is_loaded_without_errors return;
    if aseprite.texture == null || !aseprite.texture.is_loaded_without_errors return;

    aseprite_frame: = aseprite.data.frames[current_aseprite_frame];

    draw_sprite(
        position,
        aseprite.texture.texture,
        to_bounds(aseprite_frame.frame),
        to_bounds(aseprite_frame.sprite_source_size),
        flip_x,
        flip_y,
        tint
    );
}

animation_get_current_slice :: (using player: *AsepriteAnimationPlayer, slice_name: string) -> bool, Bounds
{
    found, bounds: = aseprite_get_slice(*aseprite.data, slice_name, current_aseprite_frame, true);
    if !found return false, .{};

    if flip_x
    {
        w: float = xx aseprite.data.frames[current_aseprite_frame].frame.w;
        bounds = make_bounds(Vector2.{w - bounds.min.x, bounds.min.y}, Vector2.{w - bounds.max.x, bounds.max.y});
    }
    if flip_y
    {
        h: float = xx aseprite.data.frames[current_aseprite_frame].frame.h;
        bounds = make_bounds(Vector2.{bounds.min.x, h - bounds.min.y}, Vector2.{bounds.max.x, h - bounds.max.y});
    }
    return found, bounds;
}

#scope_file

get_frames_per_second :: (using player: *AsepriteAnimationPlayer) -> float
{
    if aseprite == null || aseprite.data.frames.count == 0 return 10.0;

    // @NOTE(remi): We assume that all frames have the same duration
    return 1000 / aseprite.data.frames[0].duration_in_ms.(float);
}