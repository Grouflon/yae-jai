Smoother :: struct($T: Type)
{
    time_to_90: float;
    value: T;
    velocity: T;
}

smoother_update :: (smoother: *Smoother($T), target: T, dt: float) -> T
{
    assert(smoother != null);

    damp_spring(*smoother.value, *smoother.velocity, target, smoother.time_to_90, dt);
    return smoother.value;
}

smoother_reset :: (smoother: *Smoother($T), value: T = .{})
{
    assert(smoother != null);

    smoother.value = value;
    smoother.velocity = .{};
}

damp_spring :: (v0: *$T, velocity: *T, target: T, time_to_90: float, dt: float)
{
    if (time_to_90 <= EPSILON)
    {
        v0.* = target;
        velocity.* = .{};
        return;
    }

    c0: = dt * 3.75 / time_to_90;

    if (c0 >= 1.0)
    {
        // here, constant is too small, spring too stiff.  so go the whole way to prevent oscillation.
        v0.* = target;
        velocity.* = .{};
        return;
    }

    delta: = target - v0;
    force: = delta - (2.0 * velocity.*);

    v0.* += velocity.* * c0;
    velocity.* += force * c0;
}