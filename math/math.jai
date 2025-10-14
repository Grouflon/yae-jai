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

floor_to_u32 :: inline (_value: float) -> u32
{
    return cast(u32)floor(_value);
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

round :: inline (value: float) -> float
{
    if (value < 0.0)
        return floor(value - 0.5);
    else
        return floor(value + 0.5);
}

round_to_s32 :: inline (value: float) -> s32
{
    return xx round(value);
}

sign :: inline (value: $T) -> T
{
    if value >= 0
    {
        return 1;
    }
    else
    {
        return -1;
    }
}

clamp :: inline (_value: Vector2, min: float, max: float) -> Vector2
{
    return .{
        clamp(_value.x, min, max),
        clamp(_value.y, min, max)
    };
}

signed_angle_between :: (a: Vector2, b: Vector2) -> float
{
    angle_sign: = -sign(a.x * a.y - a.y * b.x);
    return angle_sign * acos(dot(normalize(a), normalize(b)));
}

cross_product :: inline (a: Vector2, b: Vector2) -> float
{
    return a.x * b.y - a.y * b.x;
}

bezier_cubic_interpolation :: (points: []$T, t: float) -> T
{
    assert(points.count == 4);

    // return rl.GetSplinePointBezierCubic(
    //     points[0],
    //     points[1],
    //     points[2],
    //     points[3],
    //     t
    // );
    
    t2: = t*t;
    t3: = t2*t;
    p0: = points[0] * (-  t3 + 3*t2 - 3*t + 1);
    p1: = points[1] * ( 3*t3 - 6*t2 + 3*t);
    p2: = points[2] * (-3*t3 + 3*t2);
    p3: = points[3] * (   t3);

    return p0 + p1 + p2 + p3;
}

/*
for t between [0,1] return a f(t) value such as:
    f(0)=0
    f(1)=1
    f'(0)=tangent0 on the right side of 0
    f'(1)=tangent1 on the left side of 1
*/
parametric_curve :: inline (tangent0: float, tangent1: float, t: float) -> float
{
    t2: = t*t;
    t3: = t2*t;
    return ((tangent0+tangent1-2) * t3) + ((-2*tangent0-tangent1+3) * t2) + (tangent0 * t);
}

parametric_curve_bounds :: inline (tangent0: float, tangent1: float) -> Bounds
{
    bounds: Bounds;
    bounds.min = .{0, 0};
    bounds.max = .{1, 1};

    a: = 3*tangent0 + 3*tangent1 - 6;
    b: = -4*tangent0 - 2*tangent1 + 6;
    c: = tangent0;

    if a == 0 return bounds;
    d: = b*b - 4*a*c;
    determinant: = ifx d >= 0 sqrt(d) else 0; // @NOTE(remi): I'm really not sure what that means, but this case can happen and throw an error

    x0: = (-b + determinant) / (2*a);
    x1: = (-b - determinant) / (2*a);

    if x0 > 0 && x0 < 1 { bounds = expand(bounds, .{x0, parametric_curve(tangent0, tangent1, x0)}); }
    if x1 > 0 && x1 < 1 { bounds = expand(bounds, .{x1, parametric_curve(tangent0, tangent1, x1)}); }

    return bounds;
}

approximate_closest_point_on_bezier_curve :: (point: $T, points: []T, iterations: int = 10) -> T, float
{
    assert(points.count == 4);
    assert(iterations > 0);

    Limit :: struct
    {
        t: float;
        position: Vector2;
        distance_squared: float;
    }
    make_limit :: inline (t: float, point: T, points: []T) -> Limit
    {
        p: = bezier_cubic_interpolation(points, t);
        d: = distance_squared(point, p);
        return .{t, p, d};
    }

    STEPS :: 3;
    limits: [STEPS]Limit;

    start: = 0.0;
    end: = 1.0;
    inv_steps: = 1.0 / cast(float)(STEPS-1);

    closest_limit: int;
    while iterations > 0
    {
        step: = (end - start) * inv_steps;
        closest_distance: = FLOAT32_INFINITY;

        for i: 0..STEPS-1
        {
            limits[i] = make_limit(start + step * cast(float) i, point, points);
            if limits[i].distance_squared < closest_distance
            {
                closest_limit = i;
                closest_distance = limits[i].distance_squared;
            }
        }

        start = max(limits[closest_limit].t - step * 0.5, 0); 
        end = min(limits[closest_limit].t + step * 0.5, 1); 
        
        iterations -= 1;
    }

    return limits[closest_limit].position, limits[closest_limit].t;
}

find_closest_point_on_segment :: (point: $T, p0: T, p1: T) -> T, float
{
    v: = p1 - p0;
    u: = p0 - point;
    d: = dot(v, u);
    vv: = v.x * v.x + v.y * v.y;
    t: = -d / vv;
    if t < 0 { return p0, 0; }
    if t > 1 { return p1, 1; }
    return p0 + v * t, t;
}

positive_mod :: inline (v: $T, divisor: T) -> T
{
    return ((v % divisor) + divisor) % divisor;
}

positive_mod :: inline (v: float64, divisor: float64) -> float64
{
    return fmod_cycling(v, divisor);
}

positive_mod :: inline (v: float, divisor: float) -> float
{
    return fmod_cycling(v, divisor);
}

barycentric_coordinates :: (p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> Vector3
{
    v0: = b - a;
    v1: = c - a;
    v2: = p - a;
    d00: = dot(v0, v0);
    d01: = dot(v0, v1);
    d11: = dot(v1, v1);
    d20: = dot(v2, v0);
    d21: = dot(v2, v1);

    denom: = d00*d11 - d01*d01;

    result: Vector3 = ---;
    result.y = (d11*d20 - d01*d21)/denom;
    result.z = (d00*d21 - d01*d20)/denom;
    result.x = 1 - (result.z + result.y);

    return result;
}

normalized_sin :: (x: float) -> float
{
    return sin(x) * 0.5 + 0.5;
}

#scope_file

#import "Math";
// rl:: #import "raylib";