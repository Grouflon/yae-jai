RectBase :: struct($T: Type)
{
    x, y, w, h: T; @serialize
}

Rect :: RectBase(float);
IntRect :: RectBase(s32);

operator == :: (a: RectBase, b: RectBase) -> bool
{
    return (a.x == b.x) && (a.y == b.y) && (a.w == b.w) && (a.h == b.h);
}

operator + :: (a: RectBase($T), b: Vector2) -> RectBase(T)
{
    return .{a.x + xx b.x, a.y + xx b.y, a.w, a.h};
}

operator + :: (a: Vector2, b: RectBase($T)) -> RectBase(T)
{
    return b + a;
}

get_rect_bounds :: (rect: RectBase($T)) -> min_x: T, min_y: T, max_x: T, max_y: T
{
    return min(rect.x, rect.x + rect.w), min(rect.y, rect.y + rect.h), max(rect.x, rect.x + rect.w), max(rect.y, rect.y + rect.h);
}
