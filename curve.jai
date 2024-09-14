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
    scrolling: Vector2 = .{0,0};
    zoom: Vector2 = .{1,1};
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
        size: = ImGui.GetContentRegionAvail();
        size.y = 200.0;
        canvas_p0: = ImGui.GetCursorScreenPos(); 
        canvas_p1: = canvas_p0 + size; 

        draw_list: = ImGui.GetWindowDrawList();
        ImGui.ImDrawList.AddRectFilled(draw_list, canvas_p0, canvas_p1, IM_COL32(50, 50, 50, 255));
        ImGui.ImDrawList.AddRect(draw_list, canvas_p0, canvas_p1, IM_COL32(200, 200, 200, 255));

        ImGui.InvisibleButton("canvas", size, .MouseButtonLeft | .MouseButtonRight);
        is_hovered: = ImGui.IsItemHovered(); // Hovered
        is_active: = ImGui.IsItemActive(); // Held
        if ImGui.IsItemClicked(.Right)
        {
            
        }

        ImGui.ImDrawList.PushClipRect(draw_list, canvas_p0, canvas_p1, true);
        defer ImGui.ImDrawList.PopClipRect(draw_list);

        GRID_STEP :: 64.0;
        x: = 0.0;
        while x < size.x
        {
            ImGui.ImDrawList.AddLine(draw_list, .{canvas_p0.x + x, canvas_p0.y}, .{canvas_p0.x + x, canvas_p1.y}, IM_COL32(200, 200, 200, 40));
            x += GRID_STEP;
        }
        y: = 0.0;
        while y < size.y
        {
            ImGui.ImDrawList.AddLine(draw_list, .{canvas_p0.x, canvas_p0.y + y}, .{canvas_p1.x, canvas_p0.y + y}, IM_COL32(200, 200, 200, 40));
            y += GRID_STEP;
        }
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
