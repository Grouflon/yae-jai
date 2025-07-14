AnimationPlayer :: struct
{
    current_animation: *Animation;
    current_time_s: float = 0.0;
    current_frame: s32 = -1;
    current_repeat_count: s32;
    is_playing: bool;
}

animation_player_set_animation :: (using player: *AnimationPlayer, animation: *Animation)
{
    assert(player != null);
    assert(animation != null);

    if current_animation == animation return;

    animation_player_stop(player);

    current_animation = animation;
    current_time_s = 0.0;
    current_frame = 0;
    current_repeat_count = 0;
}

animation_player_play :: (using player: *AnimationPlayer, animation: *Animation)
{
    assert(player != null);

    if current_animation == animation return;
    
    animation_player_stop(player);
    animation_player_set_animation(player, animation);
    animation_player_play(player);
}

animation_player_play :: (using player: *AnimationPlayer)
{
    if is_playing return;

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

animation_player_set_frame :: (using player: *AnimationPlayer, frame: s32)
{
    assert(player != null);
    if current_animation == null { return; }

    current_frame = positive_mod(frame, xx current_animation.frame_count);
    current_time_s = cast(float)(current_frame) / current_animation.frames_per_second;

    animation_player_update(player, 0);
}

animation_player_update :: (using player: *AnimationPlayer, dt: float)
{
    assert(player != null);

    if !is_playing { return; }
    if current_animation == null { return; }

    current_time_s += dt;

    // Update loops
    frame_time: = 1.0 / current_animation.frames_per_second;
    animation_duration: = cast(float) current_animation.frame_count * frame_time;
    while animation_duration > 0 && current_time_s > animation_duration
    {
        current_time_s -= animation_duration;
        current_repeat_count += 1;
    }

    // Update frame
    current_frame = floor_to_s32(current_time_s / frame_time);
}

animation_player_draw :: (using player: *AnimationPlayer, position: Vector2, flip_x: bool = false, flip_y: bool = false, tint: Color = WHITE)
{
    assert(player != null);

    if current_animation == null { return; }
    if (current_frame < 0 || current_frame >= current_animation.frame_count) { return; }

    for event: current_animation.sprite_events
    {
        if !is_frame_within_event(current_frame, *event) continue;

        draw_sprite(position + event.offset, event.sprite, event.flip_x ^ flip_x, event.flip_y ^ flip_y, tint);
    }

    for event: current_animation.box_events
    {
        if !is_frame_within_event(current_frame, *event) continue;

        draw_outlined_rect(position + event.rect);
    }
}
