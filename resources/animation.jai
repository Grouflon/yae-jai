Animation :: struct
{
    #as using base: Resource;

    load_function = animation_load;
    unload_function = animation_unload;
    release_function = animation_release;

    frames_per_second: float = 10.0; @serialize
    frame_count: u32 = 0; @serialize

    layers: [..]AnimationLayer; @serialize
    events: [..]AnimationEvent; @serialize
    frames: [..]AnimationFrame;
}

AnimationFrame :: struct
{
    sprite: *Sprite;
}

AnimationLayer :: struct
{
    name: string;
}

AnimationEvent :: struct
{
    name: string;
}

animation_add_layer :: (using animation: *Animation, layer_name: string)
{
    array_add(*animation.layers, .{
        name = copy_string(layer_name),
    });
}

animation_remove_layer :: (using animation: *Animation, index: s32)
{
    assert(animation != null);
    valid: = index >= 0 && index < animation.layers.count;
    if !valid { log_warning(tprint("animation \"%\": can't remove layer at index %", animation.name, index)); return; }

    free(animation.layers[index].name);
    array_ordered_remove_by_index(*animation.layers, index);
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
}

animation_release :: (resource: *Resource)
{
    using t: = cast(*Animation) resource;

    for layer: layers
    {
        free(layer.name);
    }

    array_free(layers);
    array_free(events);
    array_free(frames);
}