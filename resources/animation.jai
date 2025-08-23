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
    @custom_serialize(animation_event_serialize) // @NOTE(remi): custom serialize handles union
    @custom_editor(animation_event_editor)
{
    type: AnimationEventType;
    begin: s32;
    end: s32 = -1; // included
    layer: u32 = 0;

    union
    {
        sprite: SpriteAnimationEvent;
        box: BoxAnimationEvent;
        movement: MovementAnimationEvent;
    }
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
    return frame == event.begin || (frame > event.begin && frame <= event.end);
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

animation_event_serialize :: (serializer: *Serializer, data: *void, info: *Type_Info,  key: string, params: SerializationParams, ctx: ReflectionContext) -> (default_serialize: bool, success: bool)
{
    event: *AnimationEvent = xx data;

    if !serializer_begin_object(serializer, null, key) return false, false;
    defer serializer_end_object(serializer);

    success: = true;

    success = serialize(serializer, *event.type, "type", params, ctx) && success;
    success = serialize(serializer, *event.begin, "begin", params, ctx) && success;
    success = serialize(serializer, *event.end, "end", params, ctx) && success;
    success = serialize(serializer, *event.layer, "layer", params, ctx) && success;

    if event.type ==
    {
        case .SPRITE; { success = serialize(serializer, *event.sprite, "sprite", params, ctx) && success; }
        case .BOX; { success = serialize(serializer, *event.box, "box", params, ctx) && success; }
        case .MOVEMENT; { success = serialize(serializer, *event.movement, "movement", params, ctx) && success; }
    }
    return false, success;
}

animation_event_editor :: (data: *void, info: *Type_Info) -> bool
{
    assert(info == type_info(AnimationEvent));
    event: *AnimationEvent = xx data;

    modified: = false;
    modified = ImGui_EditValue("type", *event.type) || modified;
    modified = ImGui_EditValue("begin", *event.begin) || modified;
    modified = ImGui_EditValue("end", *event.end) || modified;
    modified = ImGui_EditValue("layer", *event.layer) || modified;

    if event.type ==
    {
        case .SPRITE; modified = ImGui_EditStructMembers(*event.sprite) || modified;
    }

    return modified;
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
        curve_reset(*event.movement.x_movement);
        curve_reset(*event.movement.y_movement);
    }
    array_reset(*events);

    for layer: layers
    {
        free(layer.name);
    }
    array_reset(*layers);
}

