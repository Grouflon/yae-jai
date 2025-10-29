CurveExtrapolation :: enum
{
    CLAMP;
    REPEAT;
    PING_PONG;
}

Curve :: struct(MAX_POINTS: s64 = 16)
    @custom_serialize(serialize_curve)
{
    points: [MAX_POINTS]CurvePoint; // points must be kept ordered by increasing values of x
    point_count: s16;
    extrapolation: CurveExtrapolation = .CLAMP;
}

CurvePoint :: struct
{
    position: Vector2; @serialize
    back_tangent: float; @serialize
    front_tangent: float; @serialize
}

curve_segment_bounds :: (p0: Vector2, d0: float, d1: float, p1: Vector2) -> Bounds
{
    bounds: = make_bounds(p0, p1);
    normalized_bounds: = parametric_curve_bounds(d0, d1);
    w: = width(bounds);
    h: = height(bounds);

    bounds.min.x = bounds.min.x + normalized_bounds.min.x * w;
    bounds.min.y = bounds.min.y + normalized_bounds.min.y * h;
    bounds.max.x = bounds.min.x + normalized_bounds.max.x * w;
    bounds.max.y = bounds.min.y + normalized_bounds.max.y * h;

    return bounds;
}

curve_bounds :: (using curve: Curve) -> Bounds
{
    if point_count == 0 { return .{}; }
    bounds: = make_bounds(points[0].position);
    for i: 0.. point_count - 2
    {
        segment_bounds: = curve_segment_bounds(
            points[i].position,
            points[i].front_tangent,
            points[i+1].back_tangent,
            points[i+1].position,
        );
        bounds = combine(bounds, segment_bounds);
    }
    return bounds;
}

curve_evaluate :: (using curve: Curve, x: float) -> float
{
    if curve.point_count == 0 { return 0.0; }
    min: float = curve.points[0].position.x;
    max: float = curve.points[curve.point_count-1].position.x;
    range: = max - min;
    if range == 0 { return min; }

    if extrapolation ==
    {
        case .CLAMP;
        {
            x = clamp(x, min, max);
        }

        case .REPEAT;
        {
            x = positive_mod(x, range);
        }

        case .PING_PONG;
        {
            flip: = floor_to_int(x / range) % 2;
            x = positive_mod(x, range);
            if flip { x = range - x; }
        }
    }

    for i: 0..(point_count-2)
    {
        p0: = points[i];
        p1: = points[i+1];
        if x >= p0.position.x && x <= p1.position.x
        {
            dx: = p1.position.x - p0.position.x;
            dy: = p1.position.y - p0.position.y;
            _x: = (x - p0.position.x) / dx;
            _y: = parametric_curve(sign(dy) * p0.front_tangent, sign(dy) * p1.back_tangent, _x);
            return p0.position.y + _y * dy;
        }
    }
    assert(false);
    return 0.0;
}

curve_set_point_position :: (using curve: *Curve, index: int, position: Vector2)
{
    assert(curve != null);
    assert(index >= 0 && index < point_count);

    lower_limit: float = -FLOAT32_INFINITY;
    upper_limit: float = FLOAT32_INFINITY;
    if index > 0 { lower_limit = points[index-1].position.x; }
    if index < point_count-1 { upper_limit = points[index+1].position.x; }

    points[index].position = .{ clamp(position.x, lower_limit, upper_limit), position.y };
}

curve_add_point_position :: (using curve: *Curve, index: int, delta: Vector2)
{
    assert(curve != null);
    assert(index >= 0 && index < point_count);

    curve_set_point_position(curve, index, points[index].position + delta);
}

curve_insert_point :: (using curve: *Curve($MAX_POINTS), point: Vector2)
{
    assert(curve != null);

    if point_count >= MAX_POINTS
    {
        log_error("Exceeding curve points capacity(%). Increase curve capacity in code", MAX_POINTS);
        return;
    }

    i: = 0;
    while i < point_count
    {
        if point.x < points[i].position.x { break; }
        i += 1;
    }

    fixed_array_insert_at(*curve.points, .{point, 0, 0 }, i);
    point_count += 1;
}

curve_remove_point :: (using curve: *Curve, index: int)
{
    assert(curve != null);
    assert(index >= 0 && index < point_count);

    fixed_array_remove_at(*points, index);
    point_count -= 1;
}

serialize_curve :: (serializer: *Serializer, data: *void, info: *Type_Info, key: string) -> bool
{
    if !serializer_begin_object(serializer, null, key) return false;

    // Get members pointers
    keys, key_to_member_info, notes: = get_flattened_struct_members(xx info);
    point_count_ptr: *u16 = data + table_find_pointer(*key_to_member_info, "point_count").offset;
    points_ptr: *CurvePoint = data + table_find_pointer(*key_to_member_info, "points").offset;
    extrapolation_ptr: *CurveExtrapolation = data + table_find_pointer(*key_to_member_info, "extrapolation").offset;

    // Serialize points array
    point_count: s64 = xx <<point_count_ptr;
    if !serializer_begin_array(serializer, *point_count, "points") return false;
    max_points: s64 = xx get_polymorphic_argument(u64, xx info, 0);
    if point_count > max_points
    {
        log_warning("Curve points array is greater than the curve capacity. Cropping excess values");
        point_count = max_points;
    }
    <<point_count_ptr = xx point_count;

    for i: 0..point_count-1
    {
        serializer_set_array_index(serializer, i);
        serialize(serializer, points_ptr + i);
    }

    serializer_end_array(serializer);

    // Serialize additional data
    serialize(serializer, extrapolation_ptr, "extrapolation");

    serializer_end_object(serializer);
    return true;
}
