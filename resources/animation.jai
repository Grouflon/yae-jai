Animation :: struct
{
    #as using _resource: Resource;

    load_function = animation_load;
    unload_function = animation_unload;

    frames_per_second: float = 10.0; @serialize
    frame_count: s32 = 0; @serialize

    sprite_events: [..]SpriteAnimationEvent; @serialize
    box_events: [..]BoxAnimationEvent; @serialize
}

AnimationEvent :: struct
{
    begin: s32; @serialize
    end: s32 = -1; @serialize // included
}

SpriteAnimationEvent :: struct
{
    #as using _event: AnimationEvent;
    sprite: *Sprite; @serialize
    offset: Vector2; @serialize;
    flip_x: bool; @serialize;
    flip_y: bool; @serialize;
}

BoxAnimationEvent :: struct
{
    #as using _event: AnimationEvent;
    rect: Rect; @serialize
    layer: u8; @serialize
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

    array_reset(*sprite_events);
    array_reset(*box_events);
}
