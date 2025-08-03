AnimationPlayer :: struct
{
    current_animation: *Animation;
    current_movement: Vector2;
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
    current_movement = .{};
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

    previous_time_s: = current_time_s;
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
    previous_frame_float: = previous_time_s / frame_time;
    current_frame_float: = current_time_s / frame_time;
    current_frame = floor_to_s32(current_frame_float);

    // Accumulate movement
    current_movement = .{};
    if dt != 0
    {
        for event: current_animation.movement_events
        {
            if !(is_frame_within_event(current_frame, *event) || is_frame_within_event(floor_to_s32(previous_frame_float), *event)) continue;

            begin_float: float = xx event.begin;
            end_float: float = xx event.end;
            range: = (end_float - begin_float) + 1;

            begin: float = 0;
            end: float = 1;
            movememt_begin_frame: = max(previous_frame_float, begin_float);
            movememt_end_frame: = min(current_frame_float, end_float + 1.0);
            begin = (movememt_begin_frame - begin_float) / range;
            end = (movememt_end_frame - begin_float) / range;

            x_movement: = 0.0;
            y_movement: = 0.0;
            if end < begin
            {
                x_movement += curve_evaluate(event.x_movement, 1) - curve_evaluate(event.x_movement, begin);
                y_movement += curve_evaluate(event.y_movement, 1) - curve_evaluate(event.y_movement, begin);
                x_movement += curve_evaluate(event.x_movement, end) - curve_evaluate(event.x_movement, 0);
                y_movement += curve_evaluate(event.y_movement, end) - curve_evaluate(event.y_movement, 0);
            }
            else
            {
                x_movement += curve_evaluate(event.x_movement, end) - curve_evaluate(event.x_movement, begin);
                y_movement += curve_evaluate(event.y_movement, end) - curve_evaluate(event.y_movement, begin);
            }

            current_movement += .{x_movement, y_movement};
        }
    }
}

animation_player_get_current_box_events :: (using player: *AnimationPlayer) -> []BoxAnimationEvent
{
    result: [..]BoxAnimationEvent;
    result.allocator = temporary_allocator;

    for event: current_animation.box_events
    {
        if !is_frame_within_event(current_frame, *event) continue;
        array_add(*result, event);
    }
    return result;
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
}
