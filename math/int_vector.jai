IntVector2 :: struct
{
    x: s32;
    y: s32;
}

operator == :: (a: IntVector2, b: IntVector2) -> bool
{
    return a.x == b.x && a.y == b.y;
}

operator + :: (a: IntVector2, b: IntVector2) -> IntVector2
{
    return .{a.x + b.x, a.y + b.y};
}

operator += :: (a: *IntVector2, b: IntVector2)
{
    a.x += b.x;
    a.y += b.y;
}

operator + :: (a: IntVector2, b: s32) -> IntVector2
{
    return .{a.x + b, a.y + b};
}

operator += :: (a: IntVector2, b: s32)
{
    a.x += b;
    a.y += b;
}

operator - :: (a: IntVector2, b: IntVector2) -> IntVector2
{
    return .{a.x - b.x, a.y - b.y};
}

operator -= :: (a: *IntVector2, b: IntVector2)
{
    a.x -= b.x;
    a.y -= b.y;
}

operator - :: (a: IntVector2, b: s32) -> IntVector2
{
    return .{a.x - b, a.y - b};
}

operator -= :: (a: *IntVector2, b: s32)
{
    a.x -= b;
    a.y -= b;
}

operator * :: (a: IntVector2, b: s32) -> IntVector2 #symmetric
{
    return .{a.x * b, a.y * b};
}

operator *= :: (a: *IntVector2, b: s32)
{
    a.x *= b;
    a.y *= b;
}

operator / :: (a: IntVector2, b: s32) -> IntVector2
{
    return .{a.x / b, a.y / b};
}

operator /= :: (a: *IntVector2, b: s32)
{
    a.x /= b;
    a.y /= b;
}