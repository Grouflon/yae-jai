BoundsBase :: struct(vector_type: Type)
{
    min: vector_type;
    max: vector_type;
}

Bounds :: BoundsBase(Vector2);
Bounds3D :: BoundsBase(Vector3);

make_bounds :: (points: ..$T) -> Bounds
{
    bounds: BoundsBase(T) = .{
        points[0],
        points[0],
    };

    for i: 1..points.count-1
    {
        bounds = expand(bounds, points[i]);
    }
    return bounds;
}

width :: inline (using bounds: $T/BoundsBase) -> float
{
    return max.x - min.x;
}

height :: inline (using bounds: $T/BoundsBase) -> float
{
    return max.y - min.y;
}

depth :: inline (using bounds: Bounds3D) -> float
{
    return max.z - min.z;
}

dilate :: (bounds: $T/BoundsBase, size: T.vector_type) -> T
{
    return .{
        bounds.min - size,
        bounds.max + size,
    };
}

expand :: (a: $T/BoundsBase, p: T.vector_type) -> T
{
    return .{
        min(a.min, p),
        max(a.max, p),
    };
}

combine :: (a: $T/BoundsBase, b :T) -> T
{
    return .{
        min(a.min, b.min),
        max(a.max, b.max),
    };
}

combine :: (a: $T/BoundsBase, bounds: ..T) -> T
{
    final_bounds: = a;
    for bound: bounds
    {
        final_bounds = combine(final_bounds, bound);
    }
    return final_bounds;
}