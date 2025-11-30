collision_bounds_bounds :: inline (a: Bounds, b: Bounds) -> bool
{
    return !(
        a.min.x >= b.max.x ||
        b.min.x >= a.max.x ||
        a.min.y >= b.max.y ||
        b.min.y >= a.max.y
    );
}

collision_circle_circle :: inline (a_center: Vector2, a_radius: float, b_center: Vector2, b_radius: float) -> bool
{
    r: = a_radius + b_radius;
    return distance_squared(a_center, b_center) <= (r*r);
}

collision_circle_bounds :: inline (a_center: Vector2, a_radius: float, b: Bounds) -> bool
{
    return distance_point_bounds(a_center, b) <= a_radius;
}

distance_squared_point_bounds :: inline (a: Vector2, b: Bounds) -> float
{
    dx: = max(b.min.x - a.x, 0, a.x - b.max.x);
    dy: = max(b.min.y - a.y, 0, a.y - b.max.y);
    return dx*dx + dy*dy;
}

closest_point_on_bounds :: inline (a: Vector2, b: Bounds) -> Vector2
{
    dx1: = b.min.x - a.x;
    dx2: = a.x - b.max.x;
    dx: float = (ifx dx2 > 0 && dx2 > dx1 then -1 else 1) * max(dx1, 0, dx2);

    dy1: = b.min.y - a.y;
    dy2: = a.y - b.max.y;
    dy: float = (ifx dy2 > 0 && dy2 > dy1 then -1 else 1) * max(dy1, 0, dy2);

    return a + .{dx, dy};
}

distance_point_bounds :: inline (a: Vector2, b: Bounds) -> float
{
    return sqrt(distance_squared_point_bounds(a, b));
}