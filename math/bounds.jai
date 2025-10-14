BoundsBase :: struct(vector_type: Type)
{
    min: vector_type; @serialize
    max: vector_type; @serialize
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

left :: inline (using bounds: $T/BoundsBase) -> float
{
    return min.x;
}

right :: inline (using bounds: $T/BoundsBase) -> float
{
    return max.x;
}

top :: inline (using bounds: $T/BoundsBase) -> float
{
    return max.y;
}

bottom :: inline (using bounds: $T/BoundsBase) -> float
{
    return min.y;
}

center :: inline (using bounds: $T/BoundsBase) -> T.vector_type
{
    return (min + max) * 0.5;
}

width :: inline (using bounds: $T/BoundsBase) -> float
{
    return max.x - min.x;
}

height :: inline (using bounds: $T/BoundsBase) -> float
{
    return max.y - min.y;
}

size :: inline  (using bounds: $T/BoundsBase) -> T.vector_type
{
    return max - min;
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

operator == :: (a: $T/BoundsBase, b: T) -> bool
{
    return a.min == b.min && a.max == b.max;
}

operator + :: (a: BoundsBase($T), b: T) -> BoundsBase(T)
{
    return .{a.min + b, a.max + b};
}

operator + :: (a: T, b: BoundsBase($T)) -> BoundsBase(T)
{
    return b + a;
}

operator - :: (a: BoundsBase($T), b: T) -> BoundsBase(T)
{
    return .{a.min - b, a.max - b};
}

operator - :: (a: T, b: BoundsBase($T)) -> BoundsBase(T)
{
    return .{b - a.min, b - a.max};
}

to_rect :: (bounds: Bounds) -> Rect
{
    return .{
        bounds.min.x,
        bounds.min.y,
        bounds.max.x - bounds.min.x,
        bounds.max.y - bounds.min.y,
    };
}

#scope_file

get_hash :: (bounds: $T/BoundsBase) -> u32
{
    return Hash.sdbm_hash(*bounds, type_info(T).runtime_size);
}

Hash :: #import "Hash";
#poke_name Hash get_hash;
