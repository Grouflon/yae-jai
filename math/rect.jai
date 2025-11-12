RectBase :: struct($T: Type)
{
    x, y, w, h: T; @serialize
}

Rect :: RectBase(float);
IntRect :: RectBase(s32);

rect_contains :: (rect: RectBase, p: Vector2) -> bool
{
    return false;
}

dilate :: (rect: Rect, size: Vector2) -> Rect
{
    return .{
        rect.x - size.x,
        rect.y - size.y,
        rect.w + size.x * 2.0,
        rect.h + size.y * 2.0,
    };
}


operator == :: (a: RectBase, b: RectBase) -> bool
{
    return (a.x == b.x) && (a.y == b.y) && (a.w == b.w) && (a.h == b.h);
}

operator + :: (a: RectBase($T), b: Vector2) -> RectBase(T) #symmetric
{
    return .{a.x + xx b.x, a.y + xx b.y, a.w, a.h};
}

to_bounds :: (rect: RectBase($T)) -> Bounds
{
    return make_bounds(Vector2.{rect.x, rect.y}, Vector2.{rect.x + rect.w, rect.y + rect.h});
}
