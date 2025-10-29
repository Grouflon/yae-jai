// dash_stroke_shader : Shader;
// dash_stroke_shader_uniforms : [3]s32;

antialiased_circle_shader: rl.Shader;
texture_1px_white: rl.Texture2D;

draw_init :: ()
{
    // dash_stroke_shader = LoadShader("data/shaders/dashed_line.vert", "data/shaders/dashed_line.frag");
    // dash_stroke_shader_uniforms[0] = GetShaderLocation(dash_stroke_shader, "points");
    // dash_stroke_shader_uniforms[1] = GetShaderLocation(dash_stroke_shader, "dashSize");
    // dash_stroke_shader_uniforms[2] = GetShaderLocation(dash_stroke_shader, "dashOffset");

    image: = rl.GenImageColor(1, 1, rl.WHITE);
    texture_1px_white = rl.LoadTextureFromImage(image);
    rl.UnloadImage(image);

    antialiased_circle_shader = rl.LoadShader(null, temp_c_string(tprint("%/data/shaders/antialiased_circle.fs", yae.yae_directory)));
}

draw_shutdown :: ()
{
    // UnloadShader(dash_stroke_shader);
    rl.UnloadShader(antialiased_circle_shader);

    rl.UnloadTexture(texture_1px_white);
}

draw_antialiased_circle :: (center: Vector2, radius: float, color: Color = rl.WHITE)
{
    // rl.PushMatrix();
    // defer rl.PopMatrix();
    // rl.Translatef(center.x, center.y ,-0.5);
    // rl.Rotatef(-90, 1,0,0);

    BeginShaderMode(antialiased_circle_shader);
    defer EndShaderMode();

    rl.DrawTexturePro(texture_1px_white, .{0,0,1,1}, .{center.x-radius, center.y-radius, radius*2, radius*2}, .{}, 0, color);

    // rl.DrawLine3D(.{0,0,0}, .{10,7,0}, color);
    // rl.DrawPlane(.{}, .{radius, radius} * 2, color);
}

// draw_dashed_line :: (_startPos: Vector2, _endPos: Vector2, _color: Color, _dash_size: float = 4.0, _dash_offset: float = 0.0)
// {
//     BeginShaderMode(dash_stroke_shader);
//     defer EndShaderMode();

//     points: [2]Vector2 = .[_startPos, _endPos];
//     dash_size: = _dash_size;
//     dash_offset: = _dash_offset;

//     SetShaderValueV(dash_stroke_shader, dash_stroke_shader_uniforms[0], points.data, xx ShaderUniformDataType.RL_SHADER_UNIFORM_VEC2, 2);
//     SetShaderValue(dash_stroke_shader, dash_stroke_shader_uniforms[1], *dash_size, xx ShaderUniformDataType.RL_SHADER_UNIFORM_FLOAT);
//     SetShaderValue(dash_stroke_shader, dash_stroke_shader_uniforms[2], *dash_offset, xx ShaderUniformDataType.RL_SHADER_UNIFORM_FLOAT);

//     DrawLineV(_startPos, _endPos, _color);
// }

draw_cone :: (_start: Vector2, _target: Vector2, _angle_rad: float, _length: float, _color: Color)
{
    aim_direction: = _target - _start;
    babord: = normalize(rotate(aim_direction, -_angle_rad/2));
    tribord: = normalize(rotate(aim_direction, _angle_rad/2));

    DrawLineV(_start, _start + babord * _length, _color);
    DrawLineV(_start, _start + tribord * _length, _color);
}

draw_outlined_rect :: (rect: Rect, color: Color = RED)
{
    bg_color: = color;
    bg_color.a = bg_color.a / 2;

    bounds: = to_bounds(rect);
    rect_size: = size(bounds);

    DrawRectangleV(bounds.min, rect_size, bg_color);
    DrawRectangleLinesEx(.{bounds.min.x, bounds.min.y, rect_size.x, rect_size.y}, 1.0, color);
}

draw_sprite :: (_position: Vector2, _texture: Texture2D, _data:*AsepriteData, _frame_index: s32 = 0, _flip_x: bool = false, _flip_y: bool = false, _tint: Color = WHITE)
{
    if _frame_index >= _data.frames.count { return; }

    x: = cast(float) _data.frames[_frame_index].frame.x;
    y: = cast(float) _data.frames[_frame_index].frame.y;
    w: = (ifx _flip_x then -1.0 else 1.0) * cast(float)_data.frames[_frame_index].frame.w;
    h: = (ifx _flip_y then 1.0 else -1.0) * cast(float)_data.frames[_frame_index].frame.h;

    DrawTextureRec(
        _texture,
        .{ x, y, w, h },
        _position,
        _tint,
    );
}

draw_sprite :: (_position: Vector2, _texture: Texture2D, _data:*AsepriteData, _frame_name: string, _flip_x: bool = false, _flip_y: bool = false, _tint: Color = WHITE)
{
    index, found: = table_find(*_data.name_to_frame, _frame_name);
    if !found { return; }
    draw_sprite(_position, _texture, _data, index, _flip_x, _flip_y, _tint);
}

draw_sprite :: (_position: Vector2, _sprite: SpriteHandle, _flip_x: bool = false, _flip_y: bool = false, _tint: Color = WHITE)
{
    sprite, texture: = get_sprite(_sprite);
    if sprite == null return;
    if texture == null return;
    draw_sprite(_position, texture, sprite, _flip_x, _flip_y, _tint);
}

draw_sprite :: (_position: Vector2, _texture: *TextureFile, _sprite: TextureFile.Sprite, _flip_x: bool = false, _flip_y: bool = false, _tint: Color = WHITE)
{
    if _texture == null return;
    if !is_loaded(_texture) return;

    x: = left(_sprite.bounds);
    y: = bottom(_sprite.bounds);
    w: = width(_sprite.bounds);
    h: = height(_sprite.bounds);

    origin: = Vector2.{
        _sprite.origin.x,
        h - _sprite.origin.y
    };
    if _flip_x
    {
        origin.x = w - _sprite.origin.x;
        w *= -1;
    }

    if !_flip_y
    {
        origin.y = _sprite.origin.y;
        h *= -1;
    }

    DrawTextureRec(
        _texture.texture,
        .{ x, y, w, h },
        _position - origin,
        _tint,
    );
}

draw_loading_bar :: (_rectangle: Rectangle, _percentage: float, _color: Color)
{
    DrawRectangleLinesEx(_rectangle, 1, _color);
    percentage_bar: = _rectangle.width / 100 * _percentage;
    rectangle: = Rectangle.{_rectangle.x, _rectangle.y, percentage_bar, _rectangle.height};
    DrawRectangleRec(rectangle, _color);
}

draw_bezier_quad :: (_start: Vector2, _mid: Vector2, _end: Vector2, _color: Color, percent: float = 0)
{
    mid_air: = get_mid_curve_position(_start, _end);
    temp: = percent;
    while temp < 1
    {
        temp += 0.1;
        if (temp > 1)
        {
            temp = 1;
        }
        position: = get_percent_pos_bezier_quad(_start, mid_air, _end, temp);
        
        DrawPixelV(position, _color);
    }
}

#scope_file

rl :: #import "raylib";