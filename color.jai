ButtonColorSet :: struct
{
    disabled: Color;
    idle: Color;
    hovered: Color;
    selected: Color;
}

make_button_color_set :: (idle_color: Color) -> ButtonColorSet
{
    hsv: = color_to_hsv(idle_color);
    return .{
        disabled=   hsv_to_color(hsv.x, hsv.y, 0.5 * hsv.z),
        idle=       idle_color,
        hovered=    hsv_to_color(hsv.x, hsv.y, hsv.z + (1.0 - hsv.z) * 0.9),
        selected=   hsv_to_color(hsv.x, hsv.y, hsv.z + (1.0 - hsv.z) * 0.6)
    };
}

string_to_color :: (str: string, hue_range: [2]float = .[0.0, 360.0], saturation_range: [2]float = .[0.8, 1.0], value_range: [2]float = .[0.7, 1.0]) -> Color
{
    return string_to_color(string_hash(str), hue_range, saturation_range, value_range);
}

string_to_color :: (str: StringHash, hue_range: [2]float = .[0.0, 360.0], saturation_range: [2]float = .[0.8, 1.0], value_range: [2]float = .[0.7, 1.0]) -> Color
{
    h_amplitude: = hue_range[1] - hue_range[0];
    s_amplitude: = saturation_range[1] - saturation_range[0];
    v_amplitude: = value_range[1] - value_range[0];

    HI: u32 = (str.hash & 0xFF000000) >> 24;
    SI: u32 = (str.hash & 0x00FF0000) >> 16;
    VI: u32 = (str.hash & 0x0000FF00) >> 8;
    base: float = (1 << 8) - 1;

    H: = hue_range[0] + (cast(float)HI / base) * h_amplitude;
    S: = saturation_range[0] + (cast(float)SI / base) * s_amplitude;
    V: = value_range[0] + (cast(float)VI / base) * v_amplitude;

    return hsv_to_color(H, S, V);
}

color_to_hsv :: (c: Color) -> Vector3
{
    return ColorToHSV(c);
}

hsv_to_color :: (c: Vector3) -> Color
{
    return hsv_to_color(c.x, c.y, c.z);
}

hsv_to_color :: (h: float, s: float, v: float) -> Color
{
    return ColorFromHSV(h, s, v);
}
