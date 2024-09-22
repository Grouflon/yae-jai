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

CurveEditor :: struct
{
    edited_curve: *Curve;
    canvas: ImGuiCanvas;
}
curve_editor: CurveEditor;

imgui_edit :: (label: string, value: *Curve) -> bool
{
    using curve_editor;

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
    if edited_curve == value
    {
        if imgui_canvas_begin(*canvas, .{0, 300})
        {
            canvas_min, canvas_max: = imgui_canvas_bounds(*canvas);

            SCREEN_STEP :: 2.0;
            step: = (SCREEN_STEP / canvas.draw_size.x) * (canvas_max.x - canvas_min.x); 
            x1: = canvas_min.x;
            while x1 < canvas_max.x
            {
                x2: = x1 + step;

                y1: = curve_evaluate(edited_curve, x1);
                y2: = curve_evaluate(edited_curve, x2);

                imgui_canvas_draw_line(*canvas, .{x1, y1}, .{x2, y2});

                x1 = x2;
            }

            for i: 0..edited_curve.points.count-1
            {
                imgui_canvas_curve_point(*canvas, edited_curve.points.data + i);
            }
        }
        imgui_canvas_end(*canvas);
    }
    else
    {
        ImGui.PlotLines(temp_c_string(label), func, value, STEPS);
        if ImGui.IsItemClicked()
        {
            curve_editor = .{};
            edited_curve = value;
        }
    }

    return false;
}

#scope_file

ImGui:: #import "ImGui";
