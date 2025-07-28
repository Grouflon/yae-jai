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

get_rect_bounds :: (rect: RectBase($T)) -> Bounds
{
    return make_bounds(Vector2.{rect.x, rect.y}, Vector2.{rect.x + rect.w, rect.y + rect.h});
}
