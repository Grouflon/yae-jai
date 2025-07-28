collision_bounds_bounds :: inline (a: Bounds, b: Bounds) -> bool
{
    return !(
        a.min.x >= b.max.x ||
        b.min.x >= a.max.x ||
        a.min.y >= b.max.y ||
        b.min.y >= a.max.y
    );
}