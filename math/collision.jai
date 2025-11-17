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

distance_point_bounds :: inline (a: Vector2, b: Bounds) -> float
{
  dx: = max(b.min.x - a.x, 0, a.x - b.max.x);
  dy: = max(b.min.y - a.y, 0, a.y - b.max.y);
  return sqrt(dx*dx + dy*dy);
}