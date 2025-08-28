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
    x_movement: Curve; @serialize
    y_movement: Curve; @serialize
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
        if !is_frame_within_event(frame, *event) continue;

        sprite: = get_sprite(event.sprite.sprite);
        if sprite == null continue;

        if !initialized
        {
            bounds = sprite.bounds;
            initialized = true;
        }
        else
        {
            bounds = combine(bounds, sprite.bounds);
        }
    }

    return bounds;
}

animation_add_layer :: (using animation: *Animation, layer_name: string, index: s64 = -1) -> s64
{
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

#scope_file

animation_load :: (resource: *Resource) -> bool
{
    using t: = cast(*Animation) resource;
    return true;
}

animation_unload :: (resource: *Resource)
{
    using t: = cast(*Animation) resource;

    for event: events
    {
        if event.type == .MOVEMENT
        {
            curve_reset(*event.movement.x_movement);
            curve_reset(*event.movement.y_movement);
        }
    }
    array_reset(*events);

    for layer: layers
    {
        free(layer.name);
    }
    array_reset(*layers);
}

