ImGuiCanvas :: struct
{
    scrolling: Vector2 = .{0,0};
    zoom: Vector2 = .{1,1};
    draw_origin: Vector2;
    draw_size: Vector2;
    grid_step: float = 64.0;

    fit_to_bounds_requested: bool;
    fit_bounds: Bounds;
    fit_margin: float;
}

imgui_canvas_begin :: (using canvas: *ImGuiCanvas, size: Vector2 = .{0,0}) -> bool
{
    io: = ImGui.GetIO();

    draw_size = ImGui.GetContentRegionAvail();
    if size.x > 0 { draw_size.x = size.x; }
    if size.y > 0 { draw_size.y = size.y; }
    draw_origin = ImGui.GetCursorScreenPos(); 
    draw_end: = draw_origin + draw_size;

    if fit_to_bounds_requested
    {
        imgui_canvas_fit_to_points(
            canvas,
            draw_origin + .{0, draw_size.y} + .{fit_margin, -fit_margin},
            fit_bounds.min,
            draw_origin + .{draw_size.x, 0} + .{-fit_margin, fit_margin},
            fit_bounds.max
        );
        fit_to_bounds_requested = false;
    }

    opened: = ImGui.BeginChild(ImGui.GetID(canvas), draw_size);

    draw_list: = ImGui.GetWindowDrawList();
    ImGui.ImDrawList.PushClipRect(draw_list, draw_origin, draw_end, true);

    if opened
    {
        ImGui.ImDrawList.AddRectFilled(draw_list, draw_origin, draw_end, IM_COL32(50, 50, 50, 255));
        ImGui.ImDrawList.AddRect(draw_list, draw_origin, draw_end, IM_COL32(200, 200, 200, 255));

        ImGui.InvisibleButton("canvas", draw_size, .MouseButtonLeft | .MouseButtonRight | .MouseButtonMiddle);
        ImGui.SetItemKeyOwner(.MouseWheelY);
        is_hovered: = ImGui.IsItemHovered(); // Hovered
        is_active: = ImGui.IsItemActive(); // Held

        if (is_active && ImGui.IsMouseDragging(.Middle))
        {
            scrolling += io.MouseDelta;
        }
        if (is_hovered)
        {
            ZOOM_IN_FACTOR :: 1.1;
            ZOOM_OUT_FACTOR :: 0.9;

            wanted_zoom: = zoom;

            if io.KeyCtrl
            {
                if io.MouseWheel > 0 { wanted_zoom.x *= ZOOM_IN_FACTOR; }
                else if io.MouseWheel < 0 { wanted_zoom.x *= ZOOM_OUT_FACTOR; }
            }
            else if io.KeyShift
            {
                if io.MouseWheel > 0 { wanted_zoom.y *= ZOOM_IN_FACTOR; }
                else if io.MouseWheel < 0 { wanted_zoom.y *= ZOOM_OUT_FACTOR; }
            }
            else
            {
                if io.MouseWheel > 0 { wanted_zoom *= 1.1; }
                else if io.MouseWheel < 0 { wanted_zoom *= 0.9; }
            }
            
            if wanted_zoom != zoom
            {
                canvas_zoom(canvas, io.MousePos, wanted_zoom);
            }
        }

        origin_col: = IM_COL32(200, 200, 200, 120);
        default_col: = IM_COL32(200, 200, 200, 40);
        canvas_bounds: = imgui_canvas_bounds(canvas);

        {
            x: = ceil(canvas_bounds.min.x);
            while x < canvas_bounds.max.x
            {
                line_origin: = canvas_to_screen(canvas, .{x, canvas_bounds.min.y});
                ImGui.ImDrawList.AddLine(draw_list, line_origin, .{line_origin.x, draw_origin.y}, ifx x == 0 then origin_col else default_col);
                x += 1.0;
            }
        }
        {
            y: = ceil(canvas_bounds.min.y);
            while y < canvas_bounds.max.y
            {
                line_origin: = canvas_to_screen(canvas, .{canvas_bounds.min.x, y});
                ImGui.ImDrawList.AddLine(draw_list, line_origin, .{draw_origin.x + draw_size.x, line_origin.y}, ifx y == 0 then origin_col else default_col);
                y += 1.0;
            }
        }
    }
    return opened;    
}

imgui_canvas_end :: (using canvas: *ImGuiCanvas)
{
    draw_list: = ImGui.GetWindowDrawList();
    ImGui.ImDrawList.PopClipRect(draw_list);
    ImGui.EndChild();

    // ImGui.Value("zoom", zoom);
    // ImGui.Value("scrolling", scrolling);
}

imgui_canvas_draw_line :: (using canvas: *ImGuiCanvas, p0: Vector2, p1: Vector2, color: Color = rl.WHITE, thickness: float = 1.0)
{
    screen_p0: = canvas_to_screen(canvas, p0);
    screen_p1: = canvas_to_screen(canvas, p1);

    draw_list: = ImGui.GetWindowDrawList();
    draw_end: = draw_origin + draw_size;


    ImGui.ImDrawList.AddLine(draw_list, screen_p0, screen_p1, IM_COL32(color.r, color.g, color.b, color.a), thickness);
}

imgui_canvas_draw_bounds :: (using canvas: *ImGuiCanvas, bounds: Bounds, color: Color = rl.RED, thickness: float = 1.0)
{
    p_min: = canvas_to_screen(canvas, bounds.min);
    p_max: = canvas_to_screen(canvas, bounds.max);
    clean_min: = min(p_min, p_max);
    clean_max: = max(p_min, p_max);

    draw_list: = ImGui.GetWindowDrawList();

    ImGui.ImDrawList.AddRect(draw_list, clean_min, clean_max, IM_COL32(color.r, color.g, color.b, color.a), thickness = thickness);
}

imgui_canvas_draw_handle :: (using canvas: *ImGuiCanvas, position: Vector2, size: float, color: Color)
{
    screen_position: = canvas_to_screen(canvas, position);
    size_v: = Vector2.{ size, size };
    p_min: = screen_position - (size_v * 0.5);
    p_max: = screen_position + (size_v * 0.5);
    THICKNESS :: 2.0;

    draw_list: = ImGui.GetWindowDrawList();
    stroke_color: = IM_COL32(color.r, color.g, color.b, 255);
    bg_color: = IM_COL32(color.r, color.g, color.b, color.a);
    draw_list.AddRectFilled(draw_list, p_min, p_max, bg_color);
    draw_list.AddRect(draw_list, p_min, p_max, stroke_color, thickness = THICKNESS);
}

imgui_canvas_bounds :: (using canvas: *ImGuiCanvas) -> Bounds
{
    canvas_min: = screen_to_canvas(canvas, draw_origin + .{0, draw_size.y});
    canvas_max: = screen_to_canvas(canvas, draw_origin + .{draw_size.x, 0});
    return make_bounds(canvas_min, canvas_max);
}

imgui_canvas_screen_bounds :: (using canvas: *ImGuiCanvas) -> Bounds
{
    canvas_min: = draw_origin;
    canvas_max: = draw_origin + draw_size;
    return make_bounds(canvas_min, canvas_max);
}

imgui_canvas_request_fit_to_bounds :: (using canvas: *ImGuiCanvas, canvas_bounds: Bounds, screen_margin: float = 0.0)
{
    fit_to_bounds_requested = true;
    fit_bounds = canvas_bounds;
    fit_margin = screen_margin;
}

screen_to_canvas :: (using canvas: *ImGuiCanvas, position: Vector2) -> Vector2
{
    origin: = draw_origin + scrolling + .{0, draw_size.y};
    canvas_position: = (position - origin) / (grid_step * zoom);
    canvas_position.y *= -1.0;

    return canvas_position;
}

canvas_to_screen :: (using canvas: *ImGuiCanvas, position: Vector2) -> Vector2
{
    screen_position: = position;
    screen_position.y *= -1.0;
    origin: = draw_origin + scrolling + .{0, draw_size.y};
    screen_position = screen_position * (grid_step * zoom) + origin;
    return screen_position;
}

#scope_file

imgui_canvas_fit_to_points :: (using canvas: *ImGuiCanvas, screen_p0: Vector2, canvas_p0: Vector2, screen_p1: Vector2, canvas_p1: Vector2)
{
    assert(length(draw_size) != 0); // Can't call this on a canvas that has never been displayed once
    assert(screen_p0 != screen_p1);
    assert(canvas_p0 != canvas_p1);

    f: = Vector2.{grid_step, -grid_step};
    zoom = ((screen_p1 - screen_p0) / (canvas_p1 - canvas_p0)) / f;

    o: = draw_origin + .{0, draw_size.y};
    scrolling = screen_p0 - o - (zoom * canvas_p0 * f);
}

canvas_zoom :: (using canvas: *ImGuiCanvas, anchor_position: Vector2, new_zoom: Vector2)
{
    o: = anchor_position - draw_origin + .{0, -draw_size.y};
    scrolling = ((new_zoom / zoom) * (scrolling - o)) + o;
    zoom = new_zoom;
}

ImGui:: #import "ImGui";
rl:: #import "raylib";
