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
