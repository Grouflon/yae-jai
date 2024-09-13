CurveExtrapolation :: enum
{
    CLAMP;
    REPEAT;
    PING_PONG;
}

Curve :: struct
{
    points: [..]CurvePoint; // points must be kept ordered by increasing values of x
    extrapolation: CurveExtrapolation = .CLAMP;
}

CurvePoint :: struct
{
    position: Vector2;
    back_tangent: float;
    front_tangent: float;
}

curve_evaluate :: (using curve: Curve, x: float) -> float
{
    if curve.points.count == 0 { return 0.0; }
    min: float = first(curve.points).position.x;
    max: float = last(curve.points).position.x;
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

    for i: 0..(points.count-2)
    {
        p0: = points[i];
        p1: = points[i+1];
        if x >= p0.position.x && x <= p1.position.x
        {
            _x: = (x - p0.position.x) / (p1.position.x - p0.position.x);
            _y: = parametric_curve(p0.front_tangent, p1.back_tangent, _x);
            return p0.position.y + _y * (p1.position.y - p0.position.y);
        }
    }
    assert(false);
    return 0.0;
}

imgui_edit :: (label: string, value: *Curve) -> bool
{
    STEPS :: 32;
    func :: (data: *void, idx: s32) -> float #c_call
    {
        ctx: Context;
        push_context ctx
        {
            curve: *Curve = data;
            if curve.points.count == 0 { return 0.0; }

            min: float = first(curve.points).position.x;
            max: float = last(curve.points).position.x;
            step: float = (1.0 / xx STEPS) * (max - min);

            return curve_evaluate(curve, min + (step * xx idx));
        }
    };
    ImGui.PlotLines(temp_c_string(label), func, value, STEPS);

    return false;
}

#scope_file

ImGui:: #import "ImGui";
