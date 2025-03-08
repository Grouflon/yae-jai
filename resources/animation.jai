Animation :: struct
{
    #as using base: Resource;

    load_function = animation_load;
    unload_function = animation_unload;

    frames_per_second: float = 10.0;

    frames: [..]AnimationFrame;
}

AnimationFrame :: struct
{
    sprite: *Sprite;
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

    array_reset(*frames);
}