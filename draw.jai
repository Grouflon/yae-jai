dash_stroke_shader : Shader;
dash_stroke_shader_uniforms : [3]s32;

draw_init :: ()
{
    dash_stroke_shader = LoadShader("data/shaders/dashed_line.vert", "data/shaders/dashed_line.frag");
    dash_stroke_shader_uniforms[0] = GetShaderLocation(dash_stroke_shader, "points");
    dash_stroke_shader_uniforms[1] = GetShaderLocation(dash_stroke_shader, "dashSize");
    dash_stroke_shader_uniforms[2] = GetShaderLocation(dash_stroke_shader, "dashOffset");
}

draw_shutdown :: ()
{
    UnloadShader(dash_stroke_shader);
}

draw_dashed_line :: (_startPos: Vector2, _endPos: Vector2, _color: Color, _dash_size: float = 4.0, _dash_offset: float = 0.0)
{
    BeginShaderMode(dash_stroke_shader);
    defer EndShaderMode();

    points: [2]Vector2 = .[_startPos, _endPos];
    dash_size: = _dash_size;
    dash_offset: = _dash_offset;

    SetShaderValueV(dash_stroke_shader, dash_stroke_shader_uniforms[0], points.data, xx ShaderUniformDataType.RL_SHADER_UNIFORM_VEC2, 2);
    SetShaderValue(dash_stroke_shader, dash_stroke_shader_uniforms[1], *dash_size, xx ShaderUniformDataType.RL_SHADER_UNIFORM_FLOAT);
    SetShaderValue(dash_stroke_shader, dash_stroke_shader_uniforms[2], *dash_offset, xx ShaderUniformDataType.RL_SHADER_UNIFORM_FLOAT);

    DrawLineV(_startPos, _endPos, _color);
}

draw_cone :: (_start: Vector2, _target: Vector2, _angle_rad: float, _length: float, _color: Color)
{
    aim_direction: = _target - _start;
    babord: = normalize(rotate(aim_direction, -_angle_rad/2));
    tribord: = normalize(rotate(aim_direction, _angle_rad/2));

    DrawLineV(_start, _start + babord * _length, _color);
    DrawLineV(_start, _start + tribord * _length, _color);
}

draw_sprite :: (_position: Vector2, _texture: Texture2D, _data:*AsepriteData, _frame_index: s32 = 0, _flip_x: bool = false, _flip_y: bool = false, _tint: Color = WHITE)
{
    if _frame_index >= _data.frames.count { return; }

    x: = cast(float) _data.frames[_frame_index].frame.x;
    y: = cast(float) _data.frames[_frame_index].frame.y;
    w: = (ifx _flip_x then -1.0 else 1.0) * cast(float)_data.frames[_frame_index].frame.w;
    h: = (ifx _flip_y then -1.0 else 1.0) * cast(float)_data.frames[_frame_index].frame.h;

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

