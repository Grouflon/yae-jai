SplinePoint :: struct
{
    //NOTE: some routines makes assumptions based on the memory layout of this struct. Do not change it, insert new things at the end
    point: Vector2;
    backward_tangent: Vector2;
    forward_tangent: Vector2;
}

Spline2D :: struct
{
    points: [..]SplinePoint;
    is_looping: bool;
}

deinit :: (using spline: *Spline2D)
{
    deinit(points);
}

spline_add_point :: (using spline: *Spline2D, point: Vector2) -> *SplinePoint
{
    return spline_add_point(spline, point, point, point);
}

spline_add_point :: (using spline: *Spline2D, point: Vector2, forward_tangent: Vector2) -> *SplinePoint
{
    return spline_add_point(spline, point, forward_tangent, point - (forward_tangent - point));
}

spline_add_point :: (using spline: *Spline2D, point: Vector2, forward_tangent: Vector2, backward_tangent: Vector2) -> *SplinePoint
{
    assert(spline != null);

    array_add(*points, .{
        backward_tangent = backward_tangent,
        point = point,
        forward_tangent = forward_tangent,
    });

    return *points[points.count-1];
}

spline_segment_count :: inline (using spline: *Spline2D) -> u32
{
    if points.count < 2 { return 0; }
    if is_looping { return xx points.count; }
    return xx (points.count - 1);
}

spline_sample_position :: (using spline: *Spline2D, t: float) -> Vector2
{
    if points.count == 0 { return .{}; }
    if points.count == 1 { return points[0].point; }
    
    segment_count: = spline_segment_count(spline);
    segment_size:= 1.0 / cast(float) segment_count;

    if is_looping { t = positive_mod(t, 1.0); }
    else { t = saturate(t); }

    segment_index: = floor_to_u32(t / segment_size);
    segment_t: = (t - (segment_size * xx segment_index)) / segment_size;

    return spline_sample_segment_position(spline, segment_index, segment_t);
}

spline_find_closest_position :: (using spline: *Spline2D, point: Vector2, iterations: int = 10) -> Vector2, float
{
    if points.count == 0 { return .{}, 0; }
    if points.count == 1 { return points[0].point, 0; }

    SUBDIVISIONS :: 4;
    STEP :: 1.0 / xx SUBDIVISIONS;

    closest_segment: u32;
    closest_distance_squared: = FLOAT32_INFINITY;
    for i: 0..spline_segment_count(spline)-1
    {
        for j: 0..SUBDIVISIONS-1
        {
            subdivision: [2]Vector2;
            subdivision[0] = spline_sample_segment_position(spline, i, j * STEP);
            subdivision[1] = spline_sample_segment_position(spline, i, (j+1) * STEP);

            // rl.DrawLineV(subdivision[0], subdivision[1], rl.YELLOW);

            segment_point, t: = find_closest_point_on_segment(point, subdivision[0], subdivision[1]);
            d: = distance_squared(point, segment_point);
            if d < closest_distance_squared
            {
                closest_distance_squared = d;
                closest_segment = i;
            }
            else if d == closest_distance_squared && ((j == 0 && t == 0.0) || (j == (SUBDIVISIONS-1) && t == 1.0))
            {
                junction_index: u32;
                if t == 0.0 junction_index = i;
                else junction_index = (i + 1) % xx points.count;

                local_forward_tangent: = points[junction_index].forward_tangent - points[junction_index].point;
                local_backward_tangent: = points[junction_index].backward_tangent - points[junction_index].point;
                junction_to_point: = point - points[junction_index].point;
                forward_dot: = dot(local_forward_tangent, junction_to_point);
                backward_dot: = dot(local_backward_tangent, junction_to_point);
                if sign(forward_dot) != sign(backward_dot)
                {
                    if forward_dot > 0
                    {
                        closest_segment = junction_index;
                    }
                    else if backward_dot > 0
                    {
                        closest_segment = positive_mod(junction_index-1, xx points.count);
                    }
                }
            }
        }
    }

    curve: [4]Vector2;
    curve[0] = points[closest_segment].point;
    curve[1] = points[closest_segment].forward_tangent;
    curve[2] = points[(closest_segment + 1) % points.count].backward_tangent;
    curve[3] = points[(closest_segment + 1) % points.count].point;
    p, t: = approximate_closest_point_on_bezier_curve(point, curve, iterations);
    return p, t; 
}

spline_sample_segment_position :: (using spline: *Spline2D, segment_index: u32, t: float) -> Vector2
{
    if points.count == 0 { return .{}; }
    if points.count == 1 { return points[0].point; }

    t = saturate(t);

    if is_looping { segment_index = positive_mod(segment_index, xx points.count); }
    else
    {
        segment_count: = spline_segment_count(spline);
        if segment_index < 0 { segment_index = 0; t = 0.0; }
        else if segment_index > segment_count - 1 { segment_index = segment_count - 1; t = 1.0; }
    }
    next_segment_index: = (segment_index + 1) % (points.count);

    curve: [4]Vector2;
    curve[0] = points[segment_index].point;
    curve[1] = points[segment_index].forward_tangent;
    curve[2] = points[next_segment_index].backward_tangent;
    curve[3] = points[next_segment_index].point;

    return bezier_cubic_interpolation(curve, t);
}

spline_draw :: (using spline: *Spline2D, thickness: float = 1.0, color: Color = WHITE, segments_per_curve: u32 = 32)
{
    if points.count < 2 { return; }

    step: float = 1.0 / xx segments_per_curve; 

    last_segment_index: = spline_segment_count(spline) - 1;
    for i: 0..last_segment_index
    {
        for j: 0..segments_per_curve-1
        {
            segment_begin: = spline_sample_segment_position(spline, i, step * xx j);
            segment_end: = spline_sample_segment_position(spline, i, step * xx (j+1));
            rl.DrawLineEx(segment_begin, segment_end, thickness, color);
        }
    }
}

// Editor
MouseState :: struct
{
    position: Vector2;
    left_button_down: bool;
    right_button_down: bool;
}

SplineEditorSettings :: struct
{
    selection_threshold: float = 5.0; @drag
    point_handle_size: int = 7; @drag
    tangent_handle_size: int = 5; @drag
}

SplineEditor :: struct
{
    spline: *Spline2D;
    settings: SplineEditorSettings;

    hovered_point: = -1;
    hovered_offset: = -1;

    dragged_point: = -1;
    dragged_offset: = -1;

    previous_mouse_state: MouseState;
}

spline_editor_update :: (using editor: *SplineEditor, mouse_state: MouseState) -> bool
{
    modified: = false;
    if spline == null { return modified; }

    delta: = mouse_state.position - previous_mouse_state.position;

    if !mouse_state.left_button_down 
    {
        hovered_point = -1;
        hovered_offset = -1;

        closest_distance_squared: = FLOAT32_INFINITY;
        closest_point: = -1;
        closest_offset: = -1;
        for point, i: spline.points
        {
            for offset: 0..2
            {
                handle_position: *Vector2 = (cast(*Vector2) *spline.points[i]) + offset;
                mouse_handle_distance_squared: = distance_squared(handle_position, mouse_state.position);
                if mouse_handle_distance_squared < closest_distance_squared
                {
                    closest_distance_squared = mouse_handle_distance_squared;
                    closest_point = i;
                    closest_offset = offset;
                }
            }
        }

        threshold_squared: = editor.settings.selection_threshold * editor.settings.selection_threshold;
        if closest_distance_squared <= threshold_squared
        {
            hovered_point = closest_point;
            hovered_offset = closest_offset;
        }
    }
    else
    {
        if hovered_point >= 0
        {
            if hovered_offset == {
                case 0;
                {
                    spline.points[hovered_point].point += delta;
                    spline.points[hovered_point].backward_tangent += delta;
                    spline.points[hovered_point].forward_tangent += delta;
                }
                case 1;
                {
                    spline.points[hovered_point].backward_tangent += delta;
                }
                case 2;
                {
                    spline.points[hovered_point].forward_tangent += delta;
                }
            }
            modified = true;
        }
    }

    previous_mouse_state = mouse_state;
    return modified;
}

spline_editor_draw :: (using editor: *SplineEditor)
{
    spline_draw(spline, segments_per_curve = 32);

    for point, i: spline.points
    {
        point_color: = rl.BLUE;
        idle_alpha: = 0.3;
        hovered_alpha: = 0.7;

        point_hovered: = i == hovered_point && hovered_offset == 0;
        back_tangent_hovered: = i == hovered_point && hovered_offset == 1;
        front_tangent_hovered: = i == hovered_point && hovered_offset == 2;

        rl.DrawLineEx(point.point, point.backward_tangent, 1.0, point_color);
        rl.DrawLineEx(point.point, point.forward_tangent, 1.0, point_color);

        draw_handle(point.point, xx editor.settings.point_handle_size, point_color, ifx point_hovered then hovered_alpha else idle_alpha);
        draw_handle(point.backward_tangent, xx editor.settings.tangent_handle_size, point_color, ifx back_tangent_hovered then hovered_alpha else idle_alpha);
        draw_handle(point.forward_tangent, xx editor.settings.tangent_handle_size, point_color, ifx front_tangent_hovered then hovered_alpha else idle_alpha);
    }
}

#scope_file

draw_handle :: (center: Vector2, size: float, color: Color, alpha: float)
{
    size_v: = Vector2.{ size, size };
    rl.DrawRectangleV(center - (size_v * 0.5), size_v, .{color.r, color.g, color.b, xx (alpha * 255)});
    rl.DrawRectangleLinesEx(.{
        center.x - size_v.x * 0.5,
        center.y - size_v.y * 0.5,
        size_v.x,
        size_v.y,
    }, 1.0, color);
}

rl:: #import "raylib";