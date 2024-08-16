Animation :: struct
{
    texture: Texture2D;
    data: *AsepriteData;
    index: s32 = -1;
}

operator == :: (a: Animation, b: Animation) -> bool
{
    if a.texture.id != b.texture.id { return false; }
    if a.data != b.data { return false; }
    if a.index != b.index { return false; }
    return true;
}

AnimationPlayer :: struct
{
    play_rate : float = 1.0;

    current_animation: Animation;
    current_frame: s32 = -1;
    current_time_ms: float;
    current_repeat_count: s32;
    is_playing: bool;
}

is_animation_valid :: (using animation: Animation) -> bool
{
    if texture.id == 0 { return false; }
    if data == null { return false; }
    if index < 0 { return false; }

    return true;
}

animation_get_duration :: (using animation: Animation) -> s32
{
    if !is_animation_valid(animation) { return -1; }

    return data.frame_tags[index].duration_in_ms;
}

animation_player_play :: (using player: *AnimationPlayer, animation: Animation)
{
    assert(player != null);
    if !is_animation_valid(animation) { return; }
    if current_animation == animation { return;}

    animation_player_stop(player);

    play_rate = 1.0;
    current_animation = animation;
    current_time_ms = 0.0;
    current_frame = -1;
    current_repeat_count = 0;
    is_playing = true;

    animation_player_update(player, 0.0);
}

animation_player_stop :: (using player: *AnimationPlayer)
{
    if is_playing
    {
        animation_player_update(player, 0.0); // Note: maybe we need a stop requested flag instead of that
        is_playing = false;
    }
}

animation_player_update :: (using player: *AnimationPlayer, dt: float)
{
    assert(player != null);

    if !is_playing { return; }
    if !is_animation_valid(current_animation) { return; }

    animation_data: = current_animation.data.frame_tags[current_animation.index];
    animation_duration: = cast(float) animation_data.duration_in_ms;

    // Update loops
    while current_time_ms > animation_duration
    {
        current_time_ms -= animation_duration;
        current_repeat_count += 1;
        if animation_data.repeat_count > 0 && current_repeat_count >= animation_data.repeat_count
        {
            current_time_ms = animation_duration;
            is_playing = false;
        }
    }

    // Update frame
    duration: s32 = 0;
    time_in_ms: s32 = floor_to_s32(current_time_ms);
    for i: animation_data.start_frame..animation_data.end_frame
    {
        frame: = current_animation.data.frames[i];
        if time_in_ms <= duration + frame.duration_in_ms
        {
            current_frame = i;
            break;
        }
        duration += frame.duration_in_ms;
    }

    // Update time
    if is_playing
    {
        current_time_ms += dt * 1000 * play_rate;
    }
}

animation_player_draw :: (using player: *AnimationPlayer, position: Vector2, flip_x: bool = false, flip_y: bool = false, tint: Color = WHITE)
{
    assert(player != null);

    if !is_animation_valid(current_animation) { return; }
    if (current_frame < 0 || current_frame >= current_animation.data.frames.count) { return; }

    draw_sprite(position, current_animation.texture, current_animation.data, current_frame, flip_x, flip_y, tint);
}

