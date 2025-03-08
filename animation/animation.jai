AnimationPlayer :: struct
{
    current_animation: *Animation;
    current_time_s: float = 0.0;
    current_frame: s32 = -1;
    current_repeat_count: s32;
    is_playing: bool;
}

animation_player_play :: (using player: *AnimationPlayer, animation: *Animation)
{
    assert(player != null);
    assert(animation != null);

    if current_animation == animation return;

    animation_player_stop(player);

    current_animation = animation;
    current_time_s = 0.0;
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

animation_player_advance_frame :: (using player: *AnimationPlayer)
{
    assert(player != null);
    if current_animation == null { return; }

    animation_player_update(player, 1.0 / current_animation.frames_per_second);
}

animation_player_update :: (using player: *AnimationPlayer, dt: float)
{
    assert(player != null);

    if !is_playing { return; }
    if current_animation == null { return; }

    current_time_s += dt;

    // Update loops
    frame_time: = 1.0 / current_animation.frames_per_second;
    animation_duration: = cast(float) current_animation.frames.count * frame_time;
    while current_time_s > animation_duration
    {
        current_time_s -= animation_duration;
        current_repeat_count += 1;
        // if animation_data.repeat_count > 0 && current_repeat_count >= animation_data.repeat_count
        // {
        //     current_time_ms = animation_duration;
        //     is_playing = false;
        // }
    }


    // Update frame
    current_frame = floor_to_s32(current_time_s / frame_time);
}

animation_player_draw :: (using player: *AnimationPlayer, position: Vector2, flip_x: bool = false, flip_y: bool = false, tint: Color = WHITE)
{
    assert(player != null);

    if current_animation == null { return; }
    if (current_frame < 0 || current_frame >= current_animation.frames.count) { return; }

    draw_sprite(position, current_animation.frames[current_frame].sprite, flip_x, flip_y, tint);
}
