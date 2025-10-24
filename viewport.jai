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

VIEWPORT_ZOOM_STEP :: 0.5;

Viewport :: struct
{
    target: Vector2;
    zoom: Vector2 = .{1,1};

    render_texture: rl.RenderTexture2D;
    mouse_input: ViewportMouseInput;
}

ViewportMouseInput :: struct
{
    BUTTON_COUNT :: 3;

    viewport_position: Vector2;
    viewport_delta: Vector2;
    world_position: Vector2;
    world_delta: Vector2;

    pressed: [BUTTON_COUNT] bool;
    released: [BUTTON_COUNT] bool;
    down: [BUTTON_COUNT] bool;

    viewport_hovered: bool;
    viewport_panned: bool;
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

ViewportFlags :: enum_flags u32
{
    ALLOW_ZOOM :: 1 << 0;
    ALLOW_PAN :: 1 << 1;

    DEFAULT_FLAGS :: ALLOW_ZOOM|ALLOW_PAN;
}

imgui_viewport :: (viewport: *Viewport, flags: ViewportFlags = .DEFAULT_FLAGS, size: Vector2 = .{})
{
    // Draw ImGui Image
    available_size: = ImGui.GetContentRegionAvail();
    image_size: = size;
    viewport_screen_origin: = ImGui.GetCursorScreenPos();
    if image_size.x == 0 image_size.x = available_size.x;
    if image_size.y == 0 image_size.y = available_size.y;

    viewport_update(viewport, image_size);
    ImGui.Image(viewport.render_texture.texture.id, image_size);

    // Sanitize Input
    io: = ImGui.GetIO();
    viewport_screen_rect: = to_rect(Bounds.{ ImGui.GetItemRectMin(), ImGui.GetItemRectMax() });
    mouse_world_position: = viewport_screen_to_world_position(viewport, viewport_screen_rect, io.MousePos);
    prev_mouse_world_position: = viewport_screen_to_world_position(viewport, viewport_screen_rect, io.MousePos - io.MouseDelta);

    viewport.mouse_input.viewport_position = io.MousePos - viewport_screen_origin;
    viewport.mouse_input.viewport_delta =    io.MouseDelta;
    viewport.mouse_input.world_position =    mouse_world_position;
    viewport.mouse_input.world_delta =       mouse_world_position - prev_mouse_world_position;
    viewport.mouse_input.pressed =           .[io.MouseClicked[0], io.MouseClicked[1], io.MouseClicked[2]];
    viewport.mouse_input.released =          .[io.MouseReleased[0], io.MouseReleased[1], io.MouseReleased[2]];
    viewport.mouse_input.down =              .[io.MouseDown[0], io.MouseDown[1], io.MouseDown[2]];
    viewport.mouse_input.viewport_hovered =  ImGui.IsItemHovered();

    // Zoom
    if viewport.mouse_input.viewport_hovered
    {
        wanted_zoom: = clamp(viewport.zoom + xy(VIEWPORT_ZOOM_STEP * ImGui.GetIO().MouseWheel), 0.5, 50.0);
        viewport_set_zoom_focused(viewport, viewport.mouse_input.viewport_position, wanted_zoom);
    }

    // Pan
    PAN_BUTTON :: ImGui.MouseButton.Middle;
    pan_button_pressed: = viewport.mouse_input.pressed[PAN_BUTTON];
    pan_button_down: = viewport.mouse_input.down[PAN_BUTTON];
    if viewport.mouse_input.viewport_hovered && pan_button_pressed
    {
        viewport.mouse_input.viewport_panned = true;
    }
    if viewport.mouse_input.viewport_panned && !pan_button_down
    {
        viewport.mouse_input.viewport_panned = false;
    }

    if viewport.mouse_input.viewport_panned
    {
        viewport_pan(viewport, viewport.mouse_input.viewport_delta);
    }
}

viewport_release :: (using viewport: *Viewport)
{
    if render_texture.texture.id != 0
    {
        rl.UnloadRenderTexture(render_texture);
        render_texture = .{};
    }
}

rendered_viewport: *Viewport;

viewport_begin_render :: (using viewport: *Viewport)
{
    assert(rendered_viewport == null);
    rendered_viewport = viewport;
    
    rl.BeginTextureMode(render_texture);

    camera: = rl.Camera2D.{
        offset = size(viewport) * 0.5,
        target = target,
        zoom = zoom.x,
    };
    rl.BeginMode2D(camera);
}

viewport_end_render :: (using viewport: *Viewport)
{
    assert(rendered_viewport == viewport);

    rl.EndMode2D();
    rl.EndTextureMode();

    rendered_viewport = null;
}

size :: (viewport: *Viewport) -> Vector2 #expand
{
    return .{ xx viewport.render_texture.texture.width, xx viewport.render_texture.texture.height };
}

#scope_file
rl :: #import "raylib";

