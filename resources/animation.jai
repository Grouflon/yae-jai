Animation :: struct
{
    #as using base: Resource;

    load_function = animation_load;
    unload_function = animation_unload;

    frames_per_second: float = 10.0; @serialize
    frame_count: s32 = 0; @serialize

    layers: [..]AnimationLayer; @serialize
    events: [..]AnimationEvent; @serialize
}

AnimationLayer :: struct
{
    name: string;
}

AnimationEventType :: enum
{
    NONE :: 0;
    SPRITE;
}

AnimationEvent :: struct @custom_serialize(serialize_animation_event)
{
    type: AnimationEventType;
    layer_index: s32;
    begin: s32;
    end: s32 = -1; // included

    union {
        sprite: AnimationEventSprite;
    }
}

AnimationEventSprite :: struct
{
    sprite: *Sprite;
}

animation_add_layer :: (using animation: *Animation, layer_name: string) -> s32
{
    array_add(*animation.layers, .{
        name = copy_string(layer_name),
    });

    return xx (animation.layers.count - 1);
}

animation_remove_layer :: (using animation: *Animation, index: s32)
{
    assert(animation != null);
    valid: = index >= 0 && index < animation.layers.count;
    if !valid { log_warning(tprint("animation \"%\": can't remove layer at index %", animation.name, index)); return; }

    for *< event, i: events
    {
        if event.layer_index == index { animation_remove_event(animation, xx i); }
        if event.layer_index > index { event.layer_index -= 1; }
    }

    free(animation.layers[index].name);
    array_ordered_remove_by_index(*animation.layers, index);
}

animation_add_event :: (using animation: *Animation, event: AnimationEvent)
{
    assert(animation != null);
    array_add(*animation.events, event);
}

animation_remove_event :: (using animation: *Animation, index: s32)
{
    assert(animation != null);
    valid: = index >= 0 && index < animation.events.count;
    if !valid { log_warning(tprint("animation \"%\": can't remove event at index %", animation.name, index)); return; }

    array_ordered_remove_by_index(*animation.events, index);
}

animation_get_events_for_frame :: (using animation: *Animation, frame: s32) -> [..]AnimationEvent
{
    result: [..]AnimationEvent;
    result.allocator = temporary_allocator;

    valid: = frame >= 0 && frame < frame_count;
    if !valid { log_warning(tprint("animation \"%\": can't get event at frame %", animation.name, frame)); return result; }

    for * event: events
    {
        if frame < event.begin { continue; }
        if frame == event.begin || frame <= event.end { array_add(*result, event); }
    }

    return result;
}

animation_frame_bounds :: (using animation: *Animation, frame: s32) -> Bounds
{
    bounds: Bounds;
    initialized: = false;
    frame_events: = animation_get_events_for_frame(animation, frame);
    for event: frame_events
    {
        if event.type != .SPRITE continue;
        if event.sprite.sprite == null continue;

        if !initialized
        {
            bounds = event.sprite.sprite.bounds;
            initialized = true;
        }
        else
        {
            bounds = combine(bounds, event.sprite.sprite.bounds);
        }
    }

    return bounds;
}

serialize_animation_event :: (serializer: *Serializer, data: *void, info: *Type_Info,  key: string, params: SerializationParams, ctx: ReflectionContext) -> bool, bool
{
    event: *AnimationEvent = xx data;

    if !serializer_begin_object(serializer, null, key) return false, false;
    defer serializer_end_object(serializer);

    if !serialize(serializer, *event.type, "type", params) return false, false;

    serialize(serializer, *event.layer_index, "layer_index", params);
    serialize(serializer, *event.begin, "begin", params);
    serialize(serializer, *event.end, "end", params);

    if event.type ==
    {
        case .SPRITE; serialize(serializer, *event.sprite, "sprite", params);
    }

    return false, true;
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

    for layer: layers
    {
        free(layer.name);
    }

    array_free(layers);
    array_free(events);
}
