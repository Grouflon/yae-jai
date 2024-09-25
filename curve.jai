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
    if points.count == 0 { return .{}; }
    bounds: = make_bounds(points[0].position);
    for i: 0.. points.count - 2
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

set_curve_point_position :: (curve: *Curve, index: int, position: Vector2)
{
    assert(curve != null);
    assert(index >= 0 && index < curve.points.count);

    lower_limit: float = -FLOAT32_INFINITY;
    upper_limit: float = FLOAT32_INFINITY;
    if index > 0 { lower_limit = curve.points[index-1].position.x; }
    if index < curve.points.count-1 { upper_limit = curve.points[index+1].position.x; }

    curve.points[index].position = .{ clamp(position.x, lower_limit, upper_limit), position.y };
}

add_curve_point_position :: (curve: *Curve, index: int, delta: Vector2)
{
    assert(curve != null);
    assert(index >= 0 && index < curve.points.count);

    set_curve_point_position(curve, index, curve.points[index].position + delta);
}

CurveEditor :: struct
{
    edited_curve: *Curve;
    canvas: ImGuiCanvas;

    PointPart :: enum
    {
        Point;
        BackTangent;
        FrontTangent;
    }

    hovered_point: int = -1;
    hovered_part: PointPart;

    dragged_point: int = -1;
    dragged_part: PointPart;

    context_menu_point: int = -1;
}
curve_editor: CurveEditor;

imgui_edit :: (label: string, value: *Curve) -> bool
{
    using curve_editor;

    STEPS :: 32;
    FIT_MARGIN :: 70.0;

    edited: = false;

    if edited_curve == value
    {
        if imgui_canvas_begin(*canvas, .{0, 300})
        {
            tangent_screen_position :: (using canvas: *ImGuiCanvas, point: CurvePoint, sign: float) -> Vector2
            {
                assert(sign == 1.0 || sign == -1.0);

                TANGENT_RADIUS :: 75.0;

                point_screen: = canvas_to_screen(canvas, point.position);
                tangent: = point.position + rotate(Vector2.{sign,0}, atan(ifx sign > 0 then point.front_tangent else point.back_tangent));
                tangent_screen_direction: = normalize(canvas_to_screen(canvas, tangent) - point_screen);
                return point_screen + tangent_screen_direction * TANGENT_RADIUS;
            }

            // Find point closest to mouse
            closest_point: = -1;
            closest_position: Vector2;
            closest_part: = PointPart.Point;
            closest_distance_squared: float = FLOAT32_INFINITY;
            io: = ImGui.GetIO();
            for i: 0..edited_curve.points.count-1
            {
                point: = edited_curve.points[i];

                // point
                {
                    p: = canvas_to_screen(*canvas, point.position);
                    d: = distance_squared(io.MousePos, p);
                    if d < closest_distance_squared
                    {
                        closest_distance_squared = d;
                        closest_point = i;
                        closest_part = .Point;
                        closest_position = p;
                    }
                }

                // back tangent
                if i > 0
                {
                    p: = tangent_screen_position(*canvas, point, -1);
                    d: = distance_squared(io.MousePos, p);
                    if d < closest_distance_squared
                    {
                        closest_distance_squared = d;
                        closest_point = i;
                        closest_part = .BackTangent;
                        closest_position = p;
                    }
                }

                // front tangent
                if i < edited_curve.points.count-1
                {
                    p: = tangent_screen_position(*canvas, point, 1);
                    d: = distance_squared(io.MousePos, p);
                    if d < closest_distance_squared
                    {
                        closest_distance_squared = d;
                        closest_point = i;
                        closest_part = .FrontTangent;
                        closest_position = p;
                    }
                }
            }

            // Is closest point hovered
            hovered_point = -1;
            if closest_point != -1
            {
                THRESHOLD :: 6;
                t: = Vector2.{THRESHOLD, THRESHOLD};
                if ImGui.IsMouseHoveringRect(closest_position - t, closest_position + t)
                {
                    hovered_point = closest_point;
                    hovered_part = closest_part;
                }
            }

            // Drag
            if hovered_point >= 0 && ImGui.IsMouseClicked(.Left)
            {
                dragged_point = hovered_point;
                dragged_part = hovered_part;
            }
            if ImGui.IsMouseReleased(.Left)
            {
                dragged_point = -1;
            }
            if dragged_point >= 0
            {
                d: = ImGui.GetMouseDragDelta(.Left, 1.0) / (canvas.grid_step * canvas.zoom);
                d.y *= -1;

                if length_squared(d) > 0
                {
                    edited = true;

                    if dragged_part ==
                    {
                        case .Point;
                        {
                            add_curve_point_position(edited_curve, dragged_point, d);
                        }

                        case .FrontTangent;
                        {
                            mouse_position: = ImGui.GetMousePos();
                            canvas_mouse_position: = screen_to_canvas(*canvas, mouse_position);
                            canvas_mouse_position.x = max(canvas_mouse_position.x, edited_curve.points[dragged_point].position.x);
                            direction: = canvas_mouse_position - edited_curve.points[dragged_point].position;
                            edited_curve.points[dragged_point].front_tangent = direction.y / direction.x;
                        }

                        case .BackTangent;
                        {
                            mouse_position: = ImGui.GetMousePos();
                            canvas_mouse_position: = screen_to_canvas(*canvas, mouse_position);
                            canvas_mouse_position.x = min(canvas_mouse_position.x, edited_curve.points[dragged_point].position.x);
                            direction: = canvas_mouse_position - edited_curve.points[dragged_point].position;
                            edited_curve.points[dragged_point].back_tangent = direction.y / direction.x;
                        }
                    }
                }
                
                ImGui.ResetMouseDragDelta(.Left);
            }

            // Draw curve
            canvas_bounds: = imgui_canvas_bounds(*canvas);
            SCREEN_STEP :: 2.0;
            step: = (SCREEN_STEP / canvas.draw_size.x) * (canvas_bounds.max.x - canvas_bounds.min.x); 
            x1: = canvas_bounds.min.x;
            while x1 < canvas_bounds.max.x
            {
                x2: = x1 + step;

                y1: = curve_evaluate(edited_curve, x1);
                y2: = curve_evaluate(edited_curve, x2);

                imgui_canvas_draw_line(*canvas, .{x1, y1}, .{x2, y2});

                x1 = x2;
            }

            // Draw handles
            for i: 0..edited_curve.points.count-1
            {
                point: = edited_curve.points[i];
                color: = rl.WHITE;
                point_highlighted: bool;
                front_tangent_highlighted: bool;
                back_tangent_highlighted: bool;
                if i == dragged_point
                {
                    point_highlighted = dragged_part == .Point;
                    back_tangent_highlighted = dragged_part == .BackTangent;
                    front_tangent_highlighted = dragged_part == .FrontTangent;
                }
                else if dragged_point < 0 && i == hovered_point
                {
                    point_highlighted = hovered_part == .Point;
                    back_tangent_highlighted = hovered_part == .BackTangent;
                    front_tangent_highlighted = hovered_part == .FrontTangent;
                }

                imgui_canvas_draw_handle(*canvas, point.position, 11, rgba(color, ifx point_highlighted then 0.7 else 0.3));

                if i > 0
                {
                    p: = screen_to_canvas(*canvas, tangent_screen_position(*canvas, point, -1));
                    imgui_canvas_draw_line(*canvas, point.position, p, color);
                    imgui_canvas_draw_handle(*canvas, p, 7, rgba(color, ifx back_tangent_highlighted then 0.7 else 0.3));
                }
                if i < edited_curve.points.count-1
                {
                    p: = screen_to_canvas(*canvas, tangent_screen_position(*canvas, point, 1));
                    imgui_canvas_draw_line(*canvas, point.position, p, color);
                    imgui_canvas_draw_handle(*canvas, p, 7, rgba(color, ifx front_tangent_highlighted then 0.7 else 0.3));
                }
            }
        }
        imgui_canvas_end(*canvas);

        // Draw context menu
        if (ImGui.BeginPopupContextItem("curve_popup"))
        {
            // Point hovered options
            if context_menu_point < 0 { context_menu_point = hovered_point; }
            if context_menu_point >= 0
            {
                x: = edited_curve.points[context_menu_point].position.x;
                y: = edited_curve.points[context_menu_point].position.y;
                if ImGui.InputFloat("x", *x, flags = .EnterReturnsTrue)
                {
                    set_curve_point_position(edited_curve, context_menu_point, .{x, y});
                    edited = true;
                }
                if ImGui.InputFloat("y", *y, flags = .EnterReturnsTrue)
                {
                    set_curve_point_position(edited_curve, context_menu_point, .{x, y});
                    edited = true;
                }
            }

            // Common options
            if ImGui.Selectable("Fit canvas to curve")
            {
                imgui_canvas_request_fit_to_bounds(*canvas, curve_bounds(<<value), FIT_MARGIN);
            }

            ImGui.EndPopup();
        }
        else
        {
            context_menu_point = -1;
        }
    }
    else
    {
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
        if ImGui.IsItemClicked()
        {
            curve_editor = .{};
            edited_curve = value;

            imgui_canvas_request_fit_to_bounds(*canvas, curve_bounds(<<value), FIT_MARGIN);
        }
    }

    return edited;
}

#scope_file

ImGui:: #import "ImGui";
rl:: #import "raylib";
