AnimationPlayer :: struct
{
    play_rate : float = 1.0;

    current_spritesheet: *Spritesheet;
    current_animation: string;
    current_frame: s32 = -1;
    current_time_ms: float;
    current_repeat_count: s32;
    is_playing: bool;
}

animation_player_play :: (using player: *AnimationPlayer, spritesheet: *Spritesheet, animation_name: string)
{
    assert(player != null);
    assert(spritesheet != null);

    tag: = get_aseprite_tag(spritesheet, animation_name);
    if tag == null { return; }
    if tag == get_aseprite_tag(current_spritesheet, current_animation) { return; }

    animation_player_stop(player);

    play_rate = 1.0;
    current_spritesheet = spritesheet;
    current_animation = animation_name;
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

animation_player_advance_frame :: (using player: *AnimationPlayer)
{
    assert(player != null);
    if current_spritesheet == null { return; }

    animation_player_update(player, current_spritesheet.frame_duration);
}

animation_player_update :: (using player: *AnimationPlayer, dt: float)
{
    assert(player != null);

    if !is_playing { return; }

    animation_data: = get_aseprite_tag(current_spritesheet, current_animation);
    if animation_data == null { return; }

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
        frame: = current_spritesheet.data.frames[i];
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

    if current_spritesheet == null { return; }
    if current_spritesheet.texture == null { return; }

    tag: = get_aseprite_tag(current_spritesheet, current_animation);
    if tag == null { return; }

    if (current_frame < 0 || current_frame >= current_spritesheet.data.frames.count) { return; }

    draw_sprite(position, current_spritesheet.texture.texture, *current_spritesheet.data, current_frame, flip_x, flip_y, tint);
}
