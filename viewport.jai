// viewport_position is position relative to the upper left corner of the viewport
// world_position is position in the drawn world space which is centered and at a 1/1 scale in its default state

//             w
// A------------------------
// |                       |
// |                       |
// |           B           | h
// |                       |
// |                       |
// |_______________________|

// with zoom = {1,1}
// A -> {0,0} relative / {-w/2,h/2} absolute
// B -> {w/2,h/2} relative / {0,0} absolute


ViewportBase :: struct
{
    size: Vector2;
    target: Vector2;
    zoom: Vector2 = .{1,1};

    render_target: rl.RenderTexture2D;
}

viewport_align_points :: (viewport: *ViewportBase, viewport_p0: Vector2, world_p0: Vector2, viewport_p1: Vector2, world_p1: Vector2, uniform_zoom: bool = true)
{
    // if length(canvas.size) == 0
    // {
    //     canvas.target = .{};
    //     canvas.zoom = .{};
    //     return;
    // }    
    // assert(relative_p0 != relative_p1);
    // assert(absolute_p0 != absolute_p1);

    // // f: = Vector2.{grid_step, -grid_step};
    // zoom = ((relative_p1 - relative_p0) / (absolute_p1 - absolute_p0));

    // o: = draw_origin + .{0, draw_size.y};
    // scrolling = relative_p0 - o - (zoom * absolute_p0 * f);
}

viewport_align_point :: (viewport: *ViewportBase, relative_position: Vector2, absolute_position: Vector2)
{
    // if length(canvas.size) == 0
    // {
    //     canvas.target = .{};
    //     canvas.zoom = .{};
    //     return;
    // }    
    // assert(relative_p0 != relative_p1);
    // assert(absolute_p0 != absolute_p1);

    // // f: = Vector2.{grid_step, -grid_step};
    // zoom = ((relative_p1 - relative_p0) / (absolute_p1 - absolute_p0));

    // o: = draw_origin + .{0, draw_size.y};
    // scrolling = relative_p0 - o - (zoom * absolute_p0 * f);
}

viewport_pan :: (viewport: *ViewportBase, viewport_translation: Vector2)
{
    assert(viewport != null);

    viewport.target += Vector2.{-viewport_translation.x, viewport_translation.y} / viewport.zoom;
}

viewport_set_zoom_focused :: (viewport: *ViewportBase, focus_viewport_position: Vector2, zoom: Vector2)
{
    if viewport.zoom == zoom return;

    assert(viewport != null);
    assert(zoom.x != 0);
    assert(zoom.y != 0);

    a: = (focus_viewport_position - (viewport.size * 0.5)) * .{1, -1};
    viewport.target = viewport.target + (a / viewport.zoom) - (a / zoom);
    viewport.zoom = zoom;
}

viewport_to_world_position :: (viewport: *ViewportBase, viewport_position: Vector2) -> Vector2
{
    assert(viewport.zoom.x > 0.0);
    assert(viewport.zoom.y > 0.0);

    zoom: = Vector2.{viewport.zoom.x, -viewport.zoom.y};
    return viewport.target + (viewport_position - viewport.size * 0.5) / zoom;
}

viewport_from_world_position :: (viewport: *ViewportBase, world_position: Vector2) -> Vector2
{
    assert(viewport.zoom.x > 0.0);
    assert(viewport.zoom.y > 0.0);

    zoom: = Vector2.{viewport.zoom.x, -viewport.zoom.y};
    return (world_position - viewport.target) * zoom + viewport.size * 0.5;
}

viewport_update :: (viewport: *ViewportBase, size: Vector2) -> bool
{
    return viewport_update(viewport, xx size.x, xx size.y);
}

viewport_update :: (using viewport: *ViewportBase, width: s32, height: s32) -> bool
{
    if width == render_target.texture.width && height == render_target.texture.height
    {
        return false;
    }

    if render_target.texture.id != 0
    {
        rl.UnloadRenderTexture(render_target);
    }
    render_target = rl.LoadRenderTexture(width, height);
    return true;
}

viewport_begin_render :: (using viewport: *ViewportBase)
{
    rl.BeginTextureMode(render_target);

    camera: = rl.Camera2D.{
        offset = .{ xx viewport.render_target.texture.width, xx viewport.render_target.texture.height } * 0.5,
        target = target,
        zoom = zoom.x,
    };
    rl.BeginMode2D(camera);
}

viewport_end_render :: (using viewport: *ViewportBase)
{
    rl.EndMode2D();
    rl.EndTextureMode();
}

#scope_file
rl :: #import "raylib";