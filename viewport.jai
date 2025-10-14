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
// A -> {0,0} relative = {-w/2,h/2} absolute
// B -> {w/2,h/2} relative = {0,0} absolute


Viewport :: struct
{
    target: Vector2;
    zoom: Vector2 = .{1,1};

    render_texture: rl.RenderTexture2D;
}

viewport_align_points :: (viewport: *Viewport, viewport_p0: Vector2, world_p0: Vector2, viewport_p1: Vector2, world_p1: Vector2, uniform_zoom: bool = true)
{
    if viewport_p0 == viewport_p1 return;
    if world_p0 == world_p1 return;

    viewport.zoom = (viewport_p0 - viewport_p1) / (world_p0 - world_p1);
    // zoom: float = max(viewport.zoom.x, viewport.zoom.y);
    // viewport.zoom = .{zoom, zoom};
    viewport.zoom.y *= -1;

    viewport_align_point(viewport, viewport_p0, world_p0);
}

viewport_align_point :: (viewport: *Viewport, viewport_position: Vector2, world_position: Vector2)
{
    assert(viewport.zoom.x != 0.0);
    assert(viewport.zoom.y != 0.0);

    render_size: = size(viewport);
    zoom: = Vector2.{viewport.zoom.x, -viewport.zoom.y};
    viewport.target = world_position - (viewport_position - render_size * 0.5) / zoom;
}

viewport_pan :: (viewport: *Viewport, viewport_translation: Vector2)
{
    assert(viewport != null);

    viewport.target += Vector2.{-viewport_translation.x, viewport_translation.y} / viewport.zoom;
}

viewport_set_zoom_focused :: (viewport: *Viewport, focus_viewport_position: Vector2, zoom: Vector2)
{
    if viewport.zoom == zoom return;

    assert(viewport != null);
    assert(zoom.x != 0);
    assert(zoom.y != 0);

    render_size: = size(viewport);
    a: = (focus_viewport_position - (render_size * 0.5)) * .{1, -1};
    viewport.target = viewport.target + (a / viewport.zoom) - (a / zoom);
    viewport.zoom = zoom;
}

viewport_to_world_position :: (viewport: *Viewport, viewport_position: Vector2) -> Vector2
{
    assert(viewport != null);
    assert(viewport.zoom.x != 0.0);
    assert(viewport.zoom.y != 0.0);

    render_size: = size(viewport);
    zoom: = Vector2.{viewport.zoom.x, -viewport.zoom.y};
    return viewport.target + (viewport_position - render_size * 0.5) / zoom;
}

viewport_from_world_position :: (viewport: *Viewport, world_position: Vector2) -> Vector2
{
    assert(viewport != null);
    assert(viewport.zoom.x != 0.0);
    assert(viewport.zoom.y != 0.0);

    render_size: = size(viewport);
    zoom: = Vector2.{viewport.zoom.x, -viewport.zoom.y};
    return (world_position - viewport.target) * zoom + render_size * 0.5;
}

viewport_screen_to_world_position :: (viewport: *Viewport, viewport_screen_rect: Rect, screen_mouse_position: Vector2) -> Vector2
{
    assert(viewport != null);
    
    viewport_size: = size(viewport);
    ratio: = viewport_size / Vector2.{viewport_screen_rect.w, viewport_screen_rect.h};
    viewport_mouse_position: = (screen_mouse_position - Vector2.{viewport_screen_rect.x, viewport_screen_rect.y}) * ratio;
    return viewport_to_world_position(viewport, viewport_mouse_position);
}

viewport_update :: (viewport: *Viewport, render_size: Vector2) -> bool
{
    assert(viewport != null);
    return resize_render_texture(*viewport.render_texture, render_size);
}

viewport_release :: (using viewport: *Viewport)
{
    if render_texture.texture.id != 0
    {
        rl.UnloadRenderTexture(render_texture);
        render_texture = .{};
    }
}

viewport_begin_render :: (using viewport: Viewport)
{
    rl.BeginTextureMode(render_texture);


    camera: = rl.Camera2D.{
        offset = size(viewport) * 0.5,
        target = target,
        zoom = zoom.x,
    };
    rl.BeginMode2D(camera);
}

viewport_end_render :: (using viewport: Viewport)
{
    rl.EndMode2D();
    rl.EndTextureMode();
}

size :: (viewport: Viewport) -> Vector2 #expand
{
    return .{ xx viewport.render_texture.texture.width, xx viewport.render_texture.texture.height };
}

#scope_file
rl :: #import "raylib";

