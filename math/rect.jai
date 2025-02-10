Rect :: struct
{
    x: float;
    y: float;
    w: float;
    h: float;
}

rect_center :: (rect: Rect) -> Vector2
{
    using rect;
    return .{(x + x + w) * 0.5, (y + y + h) * 0.5};
}

rect_left :: (rect: Rect) -> float
{
    using rect;
    return min(x, x + w);
}

rect_right :: (rect: Rect) -> float
{
    using rect;
    return max(x, x + w);
}

rect_bottom :: (rect: Rect) -> float
{
    using rect;
    return min(y, y + h);
}

rect_top :: (rect: Rect) -> float
{
    using rect;
    return max(y, y + h);
}

#scope_file

#import "Math";