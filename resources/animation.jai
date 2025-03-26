Animation :: struct
{
    #as using base: Resource;

    load_function = animation_load;
    unload_function = animation_unload;
    release_function = animation_release;

    frames_per_second: float = 10.0; @serialize
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

    array_free(frames);
}