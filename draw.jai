
draw_sprite :: (texture: Texture, position: Vector2)
{
    draw_sprite(
        texture,
        Rect.{0, 0, xx texture.width, xx texture.height},
        Rect.{position.x, position.y, xx texture.width, xx texture.height}
    );
}

draw_sprite :: (texture: Texture, source_rect: Rect, position: Vector2)
{
    draw_sprite(
        texture,
        source_rect,
        Rect.{position.x, position.y, source_rect.w, source_rect.h}
    );
}

draw_sprite :: (texture: Texture, source_rect: Rect, target_rect: Rect)
{
    if texture.handle == RENDERER_INVALID_HANDLE { return; }
    assert(texture.width != 0);
    assert(texture.height != 0);

    l: = target_rect.x;
    r: = target_rect.x + target_rect.w;
    b: = target_rect.y;
    t: = target_rect.y + target_rect.h;

    inv_width: float = 1.0 / xx texture.width;
    inv_height: float = 1.0 / xx texture.height;

    uv_l: = source_rect.x * inv_width;
    uv_r: = (source_rect.x + source_rect.w) * inv_width;
    uv_b: = source_rect.y * inv_height;
    uv_t: = (source_rect.y + source_rect.h) * inv_height;

    vertices: = Vertex.[
        .{.{l, b, 0.0}, .{uv_l, uv_b}, .{1.0, 1.0, 1.0, 1.0} },
        .{.{l, t, 0.0}, .{uv_l, uv_t}, .{1.0, 1.0, 1.0, 1.0} },
        .{.{r, t, 0.0}, .{uv_r, uv_t}, .{1.0, 1.0, 1.0, 1.0} },
        .{.{r, b, 0.0}, .{uv_r, uv_b}, .{1.0, 1.0, 1.0, 1.0} },
    ];

    indices: []u32 = .[
        0, 1, 2,
        0, 2, 3
    ];

    renderer_draw_command(vertices, indices, texture.handle);
}