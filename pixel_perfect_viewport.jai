/*
Using this viewport implies additional behaviour compared to vanilla raylib behaviour:
- The world is y-up instead of -y-up by default
- The camera target is the center of the viewport instead of upper left corner
*/

PixelPerfectViewport :: struct
{
    min_render_width, min_render_height: s32;
    min_pixel_ratio, max_pixel_ratio: u8;
    camera: rl.Camera2D = .{ zoom = 1.0 };

    render_target: rl.RenderTexture2D;
    pixel_ratio: u8 = 1;
}

viewport_update :: (using viewport: *PixelPerfectViewport, window_width: s32 = -1, window_height: s32 = -1) -> (resized: bool)
{
    if window_width < 0 { window_width = rl.GetRenderWidth(); }
    if window_height < 0 { window_height = rl.GetRenderHeight(); }

    pixel_ratio = xx min(window_width / min_render_width, window_height / min_render_height);
    pixel_ratio = clamp(pixel_ratio, min_pixel_ratio, max_pixel_ratio);

    render_width: = ceil_to_s32(cast(float)window_width / cast(float)pixel_ratio);
    render_height: = ceil_to_s32(cast(float)window_height / cast(float)pixel_ratio);

    if render_width == render_target.texture.width && render_height == render_target.texture.height
    {
        return false;
    }

    if render_target.texture.id != 0
    {
        rl.UnloadRenderTexture(render_target);
    }
    rl.SetWindowMinSize(min_render_width * min_pixel_ratio, min_render_height * min_pixel_ratio); // This is not useful at every resize but whatev
    render_target = rl.LoadRenderTexture(render_width, render_height);
    return true;
}

viewport_begin_render :: (using viewport: PixelPerfectViewport)
{
    rl.BeginTextureMode(render_target);
    rl.BeginMode2D(center_camera(viewport, camera));
}

viewport_end_render :: (using viewport: PixelPerfectViewport)
{
    rl.EndMode2D();
    rl.EndTextureMode();
}

viewport_draw :: (using viewport: PixelPerfectViewport)
{
    render_width: float = xx render_target.texture.width;
    render_height: float = xx render_target.texture.height;
    draw_width: float = render_width * pixel_ratio;
    draw_height: float = render_height * pixel_ratio;
    source_rect: = rl.Rectangle.{ 0.0, 0.0, render_width, render_height };
    target_rect: = rl.Rectangle.{ 0.0, 0.0, draw_width, draw_height };
    rl.DrawTexturePro(render_target.texture, source_rect, target_rect, .{0.0, 0.0}, 0.0, rl.WHITE);
}

screen_to_world_position :: (using viewport: *PixelPerfectViewport, screen_position: Vector2, window_width: s32 = -1, window_height: s32 = -1) -> Vector2
{
    if window_width < 0 { window_width = rl.GetRenderWidth(); }
    if window_height < 0 { window_height = rl.GetRenderHeight(); }

    normalized_position: = (screen_position) / Vector2.{ xx window_width, xx window_height };
    viewport_size: = Vector2.{ xx render_target.texture.width, xx render_target.texture.height };
    reverse_y: = Vector2.{1,-1};

    centered_camera: = center_camera(viewport, camera);
    world_position: = (((normalized_position * viewport_size) - centered_camera.offset) / centered_camera.zoom) + centered_camera.target * reverse_y; // Magic formula, figured it out just by trying out things until it displayed what I want
    world_position *= reverse_y;
    return world_position;
}

#scope_file

center_camera :: (viewport: PixelPerfectViewport, camera: rl.Camera2D) -> rl.Camera2D
{
    centered_camera: = camera;
    centered_camera.offset += 0.5 * Vector2.{ xx viewport.render_target.texture.width, xx viewport.render_target.texture.height };
    return centered_camera;
}

rl :: #import "raylib";
