R2D :: (180.0 / PI);
D2R :: (PI / 180.0);

floor :: inline (_value: Vector2) -> Vector2
{
    return .{floor(_value.x), floor(_value.y)};
}

floor_to_int :: inline (_value: float) -> int
{
    return cast(int)floor(_value);
}

floor_to_s32 :: inline (_value: float) -> s32
{
    return cast(s32)floor(_value);
}

floor_to_s32 :: inline (_value: Vector2) -> s32, s32
{
    return floor_to_s32(_value.x), floor_to_s32(_value.y);
}

ceil_to_int :: inline (_value: float) -> int
{
    return cast(int)ceil(_value);
}

ceil_to_s32 :: inline (_value: float) -> s32
{
    return cast(s32)ceil(_value);
}

ceil_to_s32 :: inline (_value: Vector2) -> s32, s32
{
    return ceil_to_s32(_value.x), ceil_to_s32(_value.y);
}

sign :: inline (value: float) -> float
{
    if value >= 0
    {
        return 1.0;
    }
    else
    {
        return -1.0;
    }
}

signed_angle_between :: (a: Vector2, b: Vector2) -> float
{
    angle_sign: = -sign(a.x * a.y - a.y * b.x);
    return angle_sign * acos(dot(normalize(a), normalize(b)));
}

#scope_file

#import "Math";
