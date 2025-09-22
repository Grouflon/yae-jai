Animation :: struct
{
    #as using _resource: Resource;
    type = type_info(Animation);
    load_function = animation_load;
    unload_function = animation_unload;

    frames_per_second: float = 10.0; @serialize
    frame_count: s32 = 0; @serialize

    events: [..]AnimationEvent; @serialize
    layers: [..]AnimationLayer; @serialize

    // Editor
    preview_loop_count: u32 = 1; @serialize
}

AnimationLayer :: struct
{
    name: string; @serialize
}

AnimationEvent :: struct
    @serialize_filter(animation_event_serialize_filter) // deals with union. Fuck those commies
{
    type: AnimationEventType; @serialize
    begin: s32;  @serialize
    end: s32; @serialize // inclusive
    layer: u32; @serialize
    disabled: bool; @serialize

    union
    {
        sprite: SpriteAnimationEvent; @serialize
        box: BoxAnimationEvent; @serialize
        movement: MovementAnimationEvent; @serialize
    } 
}

animation_event_serialize_filter :: (parent_data: *void, parent_info: *Type_Info_Struct, member_info: *Type_Info_Struct_Member) -> bool
{
    assert(parent_info == type_info(AnimationEvent));
    event: *AnimationEvent = xx parent_data;

    if member_info.name ==
    {
        case "sprite"; return event.type == .SPRITE;
        case "box"; return event.type == .BOX;
        case "movement"; return event.type == .MOVEMENT;
    }
    return true;
}

AnimationEventType :: enum
{
    NONE :: 0;
    SPRITE;
    BOX;
    MOVEMENT;
}

SpriteAnimationEvent :: struct
{
    sprite: SpriteHandle; @serialize
    offset: Vector2; @serialize
    flip_x: bool; @serialize
    flip_y: bool; @serialize
}

BoxAnimationEvent :: struct
{
    rect: Rect; @serialize
    physics_layer: u8; @serialize
}

MovementAnimationEvent :: struct
{
    x_movement: float; @serialize
    x_easing: EasingType; @serialize
    x_custom_curve: Curve; @serialize

    y_movement: float; @serialize
    y_easing: EasingType; @serialize
    y_custom_curve: Curve; @serialize
}

is_frame_within_event :: (frame: s32, event: *AnimationEvent) -> bool
{
    assert(event != null);
    if event.end >= event.begin
    {
        return frame >= event.begin && frame <= event.end;
    }
    return frame == event.begin;
}

animation_frame_bounds :: (using animation: *Animation, frame: s32) -> Bounds
{
    bounds: Bounds;
    initialized: = false;
    for event: animation.events
    {
        if event.type != .SPRITE continue;
        if event.disabled continue;
        if !is_frame_within_event(frame, *event) continue;

        sprite: = get_sprite(event.sprite.sprite);
        if sprite == null continue;

        sprite_bounds: = sprite.bounds - sprite.bounds.min - sprite.origin + event.sprite.offset;

        if !initialized
        {
            bounds = sprite_bounds;
            initialized = true;
        }
        else
        {
            bounds = combine(bounds, sprite_bounds);
        }
    }

    return bounds;
}

animation_add_layer :: (using animation: *Animation, layer_name: string, index: s64 = -1) -> s64
{
    assert(animation != null);
    if !is_loaded_without_errors
    {
        log_warning("%: Can't add layer to unloaded Animation", name);
        return -1;
    }

    layer: = AnimationLayer.{ name = copy_string(layer_name)};
    if index < 0
    {
        array_add(*layers, layer);
        return layers.count-1;
    }
    else
    {
        array_insert_at(*layers, layer, index);
        return index;
    }
}

animation_remove_layer :: (using animation: *Animation, index: s64)
{
    assert(animation != null);
    if index < 0 || index >= animation.layers.count
    {
        log_warning("%: Trying to remove out of range layer %", animation.name, index);
        return;
    }

    for < *event, i: animation.events
    {
        if event.layer > index
        {
            event.layer -= 1;
        }
        else if event.layer == index
        {
            animation_remove_event(animation, i);
        }
    }

    deinit(*animation.layers[index]);
    array_ordered_remove_by_index(*animation.layers, index);
}

animation_add_event :: (using animation: *Animation, event: AnimationEvent, index: s64 = -1) -> s64
{
    assert(animation != null);
    if !is_loaded_without_errors
    {
        log_warning("%: Can't add event to unloaded Animation", name);
        return -1;
    }

    if index < 0
    {
        array_add(*events, event);
        return events.count-1;
    }
    else
    {
        array_insert_at(*events, event, index);
        return index;
    }
}

animation_remove_event :: (using animation: *Animation, index: s64)
{
    assert(animation != null);
    if index < 0 || index >= animation.events.count
    {
        log_warning("%: Trying to remove out of range event %", animation.name, index);
        return;
    }

    array_ordered_remove_by_index(*animation.events, index);
}

animation_duration :: (using animation: *Animation) -> float
{
    assert(animation != null);
    return frame_count / frames_per_second;
}

// @NOTE(remi): This is only forward ftm, we'll probably want to add a flag for evaluating backwards
animation_evaluate_movement :: (using animation: *Animation, frame_start: s32, frame_end_exclusive: s32) -> Vector2
{
    assert(animation != null);

    start_time: = cast(float)(frame_start) / animation.frames_per_second;
    end_time: = cast(float)(frame_end_exclusive) / animation.frames_per_second;
    return animation_evaluate_movement(animation, start_time, end_time);
}

animation_evaluate_movement :: (using animation: *Animation, start_time: float, end_time: float) -> Vector2
{
    assert(animation != null);
    if end_time == start_time { return .{}; }

    duration: = animation_duration(animation);
    frame_time: = 1.0 / animation.frames_per_second;
    total_loop_count: = floor((end_time - start_time) / duration);

    start_time = positive_mod(start_time, duration);
    end_time = positive_mod(end_time, duration);

    movement: Vector2 = .{};

    for event: animation.events
    {
        if event.type != .MOVEMENT continue;
        if event.disabled continue;

        if total_loop_count > 0
        {
            t_x: = ease(event.movement.x_easing, 1, event.movement.x_custom_curve);
            t_y: = ease(event.movement.y_easing, 1, event.movement.y_custom_curve);
            movement += .{t_x * event.movement.x_movement, t_y * event.movement.y_movement} * total_loop_count;
        }

        event_begin_time: = cast(float)(event.begin) * frame_time; 
        event_end_time: = cast(float)(event.end+1) * frame_time; 
        if !(
            (event_begin_time >= start_time && event_begin_time <= end_time) ||
            (event_end_time >= start_time && event_end_time <= end_time) ||
            (start_time >= event_begin_time && start_time <= event_end_time) ||
            (end_time >= event_begin_time && end_time <= event_end_time)
        )
        { continue; }

        event_duration: = event_end_time - event_begin_time;

        movememt_begin_time: = max(start_time, event_begin_time);
        movememt_end_time: = min(end_time, event_end_time);
        begin: = (movememt_begin_time - event_begin_time) / event_duration;
        end: = (movememt_end_time - event_begin_time) / event_duration;

        t_x: = 0.0;
        t_y: = 0.0;
        if end < begin
        {
            t_x += ease(event.movement.x_easing, 1, event.movement.x_custom_curve) - ease(event.movement.x_easing, begin, event.movement.x_custom_curve);
            t_y += ease(event.movement.y_easing, 1, event.movement.y_custom_curve) - ease(event.movement.y_easing, begin, event.movement.y_custom_curve);
            t_x += ease(event.movement.x_easing, end, event.movement.x_custom_curve) - ease(event.movement.x_easing, 0, event.movement.x_custom_curve);
            t_y += ease(event.movement.y_easing, end, event.movement.y_custom_curve) - ease(event.movement.y_easing, 0, event.movement.y_custom_curve);
        }
        else
        {
            t_x += ease(event.movement.x_easing, end, event.movement.x_custom_curve) - ease(event.movement.x_easing, begin, event.movement.x_custom_curve);
            t_y += ease(event.movement.y_easing, end, event.movement.y_custom_curve) - ease(event.movement.y_easing, begin, event.movement.y_custom_curve);
        }

        movement += .{t_x * event.movement.x_movement, t_y * event.movement.y_movement};
    }
    return movement;
}

#scope_file

animation_load :: (resource: *Resource) -> bool
{
    using t: = cast(*Animation) resource;
    return true;
}

animation_unload :: (resource: *Resource)
{
    using t: = cast(*Animation) resource;

    array_reset(*events);

    for *layer: layers
    {
        deinit(layer);
    }
    array_reset(*layers);
}

deinit :: (layer: *AnimationLayer)
{
    assert(layer != null);
    free(layer.name);
}
