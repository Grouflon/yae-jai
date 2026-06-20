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

operator * :: (a: Vector2, b: IntVector2) -> Vector2 #symmetric
{
    return .{a.x * b.x.(float), a.y * b.y.(float)};
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

operator / :: (a: Vector2, b: IntVector2) -> Vector2
{
    return .{a.x / b.x.(float), a.y / b.y.(float)};
}

operator / :: (a: IntVector2, b: Vector2) -> Vector2
{
    return .{a.x.(float) / b.x, a.y.(float) / b.y};
}

operator /= :: (a: *IntVector2, b: s32)
{
    a.x /= b;
    a.y /= b;
}