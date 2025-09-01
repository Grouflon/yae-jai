AnimationPlayer :: struct
{
    current_animation: *Animation;
    current_movement: Vector2;
    current_time_s: float = 0.0;
    current_frame: s32 = -1; // @NOTE(remi): this is a proxy, I should remove it
    current_loop_count: s32;
    is_playing: bool;
}

animation_player_set_animation :: (using player: *AnimationPlayer, animation: *Animation)
{
    assert(player != null);
    assert(animation != null);

    if current_animation == animation return;

    animation_player_stop(player);

    current_animation = animation;
    current_movement = .{};
    current_time_s = 0.0;
    current_frame = 0;
    current_loop_count = 0;
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
    current_loop_count = 0;

    animation_player_update(player, 0);
}

animation_player_update :: (using player: *AnimationPlayer, dt: float)
{
    assert(player != null);

    if !is_playing { return; }
    if current_animation == null { return; }

    previous_time_s: = current_time_s;
    current_time_s += dt;

    // Update loops
    animation_duration: = cast(float) current_animation.frame_count / current_animation.frames_per_second;
    while animation_duration > 0 && current_time_s > animation_duration
    {
        current_time_s -= animation_duration;
        current_loop_count += 1;
    }

    // Update frame
    current_frame_float: = current_time_s * current_animation.frames_per_second;
    current_frame = floor_to_s32(current_frame_float);

    // Accumulate movement
    current_movement = animation_evaluate_movement(current_animation, previous_time_s, current_time_s);
}

animation_player_get_current_box_events :: (using player: *AnimationPlayer) -> []BoxAnimationEvent
{
    result: [..]BoxAnimationEvent;
    result.allocator = temporary_allocator;

    for event: current_animation.events
    {
        if event.type != .BOX continue;
        if !is_frame_within_event(current_frame, *event) continue;
        array_add(*result, event.box);
    }
    return result;
}

animation_player_draw :: (using player: *AnimationPlayer, position: Vector2, flip_x: bool = false, flip_y: bool = false, tint: Color = WHITE)
{
    assert(player != null);

    if current_animation == null { return; }
    if (current_frame < 0 || current_frame >= current_animation.frame_count) { return; }

    for event: current_animation.events
    {
        if event.type != .SPRITE continue;
        if !is_frame_within_event(current_frame, *event) continue;

        draw_sprite(position + event.sprite.offset, event.sprite.sprite, event.sprite.flip_x ^ flip_x, event.sprite.flip_y ^ flip_y, tint);
    }
}
