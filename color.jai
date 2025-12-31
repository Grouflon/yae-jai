// Litterature about linear space and gamma correction
// https://blog.demofox.org/2018/03/10/dont-convert-srgb-u8-to-linear-u8/
// https://developer.nvidia.com/gpugems/gpugems3/part-iv-image-effects/chapter-24-importance-being-linear

Color :: struct
{
    r: u8;
    g: u8;
    b: u8;
    a: u8;
}

LIGHTGRAY :: Color.{  200, 200, 200, 255  };
GRAY :: Color.{  130, 130, 130, 255  };
DARKGRAY :: Color.{  80, 80, 80, 255  };
YELLOW :: Color.{  253, 249, 0, 255  };
GOLD :: Color.{  255, 203, 0, 255  };
ORANGE :: Color.{  255, 161, 0, 255  };
PINK :: Color.{  255, 109, 194, 255  };
RED :: Color.{  230, 41, 55, 255  };
MAROON :: Color.{  190, 33, 55, 255  };
GREEN :: Color.{  0, 228, 48, 255  };
LIME :: Color.{  0, 158, 47, 255  };
DARKGREEN :: Color.{  0, 117, 44, 255  };
SKYBLUE :: Color.{  102, 191, 255, 255  };
BLUE :: Color.{  0, 121, 241, 255  };
DARKBLUE :: Color.{  0, 82, 172, 255  };
PURPLE :: Color.{  200, 122, 255, 255  };
VIOLET :: Color.{  135, 60, 190, 255  };
DARKPURPLE :: Color.{  112, 31, 126, 255  };
BEIGE :: Color.{  211, 176, 131, 255  };
BROWN :: Color.{  127, 106, 79, 255  };
DARKBROWN :: Color.{  76, 63, 47, 255  };
WHITE :: Color.{  255, 255, 255, 255  };
BLACK :: Color.{  0, 0, 0, 255  };
BLANK :: Color.{  0, 0, 0, 0  };
MAGENTA :: Color.{  255, 0, 255, 255  };
RAYWHITE :: Color.{  245, 245, 245, 255  };

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
        hovered=    hsv_to_color(hsv.x, hsv.y + (1.0 - hsv.y) * 0.2, hsv.z + (1.0 - hsv.z) * 0.9),
        selected=   hsv_to_color(hsv.x, hsv.y + (1.0 - hsv.y) * 0.2, hsv.z + (1.0 - hsv.z) * 0.6)
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

color_to_normalized_vector4 :: (c: Color) -> Vector4
{
    return .{cast(float)c.r / 255, cast(float)c.g / 255, cast(float)c.b / 255, cast(float)c.a / 255};
}

color_to_normalized_vector4 :: (c: u32) -> Vector4
{
    return color_to_normalized_vector4(u32_to_color(c));
}

u32_to_color :: (c:u32) -> Color
{
    return (*c).(*Color).*;
}