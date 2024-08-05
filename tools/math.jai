R2D :: (180.0 / PI);
D2R :: (PI / 180.0);

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
