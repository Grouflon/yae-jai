EasingType :: enum
{
    LINEAR :: 0;
    QUAD_IN;
    QUAD_OUT;
    QUAD_IN_OUT;
    CUBE_IN;
    CUBE_OUT;
    CUBE_IN_OUT;
    QUART_IN;
    QUART_OUT;
    QUART_IN_OUT;
    QUINT_IN;
    QUINT_OUT;
    QUINT_IN_OUT;
    SINE_IN;
    SINE_OUT;
    SINE_IN_OUT;
    BOUNCE_IN;
    BOUNCE_OUT;
    BOUNCE_IN_OUT;
    CIRC_IN;
    CIRC_OUT;
    CIRC_IN_OUT;
    EXPO_IN;
    EXPO_OUT;
    EXPO_IN_OUT;
    BACK_IN;
    BACK_OUT;
    BACK_IN_OUT;
    CUSTOM;
};


/** Quadratic in. */
quad_in :: (t: float) -> float
{
    return t * t;
}

/** Quadratic out. */
quad_out :: (t: float) -> float
{
    return -t * (t - 2.0);
}

/** Quadratic in and out. */
quad_in_out :: (t: float) -> float
{
    if (t <= 0.5)
    {
        return t * t * 2.0;
    } 
    else
    {
        t -= 1.0;
        return 1.0 - t * t * 2.0;
    }
}

/** Cubic in. */
cube_in :: (t: float) -> float
{
    return t * t * t;
}

/** Cubic out. */
cube_out :: (t: float) -> float
{
    t -= 1.0;
    return 1.0 + t * t * t;
}

/** Cubic in and out. */
cube_in_out :: (t: float) -> float
{
    if (t <= 0.5)
    {
        return t * t * t * 4.0;
    }
    else
    {
        return (t - 1.0) * (2.0 * t - 2.0) * (2.0 * t - 2.0) + 1.0;
    }
}

/** Quart in. */
quart_in :: (t: float) -> float
{
    return t * t * t * t;
}

/** Quart out. */
quart_out :: (t: float) -> float
{
    t -= 1.0;
    return 1 - t * t * t * t;
}

/** Quart in and out. */
quart_in_out :: (t: float) -> float
{
    if (t <= 0.5)
    {
        return t * t * t * t * 8.0;
    } 
    else
    {
        t = t * 2.0 - 2.0;
        return (1.0 - t * t * t * t) / 2.0 + 0.5;
    }
}

/** Quint in. */
quint_in :: (t: float) -> float
{
    return t * t * t * t * t;
}

/** Quint out. */
quint_out :: (t: float) -> float
{
    t = t - 1.0;
    return t * t * t * t * t + 1.0;
}

/** Quint in and out. */
quint_in_out :: (t: float) -> float
{
    t *= 2.0;
    if (t < 1.0)
    {
        return (t* t * t * t * t) / 2.0;
    } 
    else
    {
        t -= 2.0;
        return (t * t * t * t * t + 2.0) / 2.0;
    }
}

/** Sine in. */
sine_in :: (t: float) -> float
{
    return 1.0 - cos(t *  PI * 0.5);
}

/** Sine out. */
sine_out :: (t: float) -> float
{
    return sin(t * PI * 0.5);
}

/** Sine in and out. */
sine_in_out :: (t: float) -> float
{
    return (1.0 - cos(t * PI)) * 0.5;
}

/** Bounce in. */
bounce_in :: (t: float) -> float
{
    t = 1.0 - t;
    if (t < B1) return 1.0 - 7.5625 * t* t;
    if (t < B2) return 1.0 - (7.5625 * (t - B3) * (t - B3) + 0.75);
    if (t < B4) return 1.0 - (7.5625 * (t - B5) * (t - B5) + 0.9375);
    return 1.0 - (7.5625 * (t - B6) * (t - B6) + 0.984375);
}

/** Bounce out. */
bounce_out :: (t: float) -> float
{
    if (t < B1) return 7.5625 * t * t;
    if (t < B2) return 7.5625 * (t - B3) * (t - B3) + 0.75;
    if (t < B4) return 7.5625 * (t - B5) * (t - B5) + 0.9375;
    return 7.5625 * (t - B6) * (t - B6) + 0.984375;
}

/** Bounce in and out. */
bounce_in_out :: (t: float) -> float
{
    if (t < 0.5)
    {
        t = 1.0 - t * 2.0;
        if (t < B1) return (1.0 - 7.5625 * t * t) / 2.0;
        if (t < B2) return (1.0 - (7.5625 * (t - B3) * (t - B3) + 0.75)) / 2.0;
        if (t < B4) return (1.0 - (7.5625 * (t - B5) * (t - B5) + 0.9375)) / 2.0;
        return (1.0 - (7.5625 * (t - B6) * (t - B6) + 0.984375)) / 2.0;
    }
    t = t * 2.0 - 1.0;
    if (t < B1) return (7.5625 * t * t) / 2.0 + 0.5;
    if (t < B2) return (7.5625 * (t - B3) * (t - B3) + 0.75) / 2.0 + 0.5;
    if (t < B4) return (7.5625 * (t - B5) * (t - B5) + 0.9375) / 2.0 + 0.5;
    return (7.5625 * (t - B6) * (t - B6) + .984375) / 2.0 + 0.5;
}

/** Circle in. */
circ_in :: (t: float) -> float
{
    return -(sqrt(1.0 - t * t) - 1.0);
}

/** Circle out. */
circ_out :: (t: float) -> float
{
    return sqrt(1.0 - (t - 1.0) * (t - 1.0));
}

/** Circle in and out. */
circ_in_out :: (t: float) -> float
{
    return ifx t <= 0.5 then (sqrt(1.0 - t * t * 4.0) - 1.0) / -2.0 else (sqrt(1.0 - (t * 2.0 - 2.0) * (t * 2.0 - 2.0)) + 1.0) / 2.0;
}

/** Exponential in. */
expo_in :: (t: float) -> float
{
    return pow(2.0, 10.0 * (t - 1.0));
}

/** Exponential out. */
expo_out :: (t: float) -> float
{
    return -pow(2.0, -10.0 * t) + 1;
}

/** Exponential in and out. */
expo_in_out :: (t: float) -> float
{
    return ifx t < 0.5 then pow(2.0, 10.0 * (t * 2.0 - 1.0)) / 2.0 else (-pow(2.0, -10.0 * (t * 2.0 - 1.0)) + 2.0) / 2.0;
}

/** Back in. */
back_in :: (t: float) -> float
{
    return t * t * (2.70158 * t - 1.70158);
}

/** Back out. */
back_out :: (t: float) -> float
{
    t -= 1.0;
    return 1.0 - t * t * (-2.70158 * t - 1.70158);
}

/** Back in and out. */
back_in_out :: (t: float) -> float
{
    t *= 2.0;

    if (t < 1.0)
    {
        return t * t* (2.70158 * t - 1.70158) / 2.0;
    }
    else
    {
        t -= 2.0;
        return (1.0 - t * t * (-2.70158 * t - 1.70158)) / 2.0 + 0.5;
    }
}

ease :: (type: EasingType, t: float, custom_curve: Curve = .{}) -> float
{
    if #complete type ==
    {
    case .LINEAR;           return t;
    case .QUAD_IN;          return quad_in(t);
    case .QUAD_OUT;         return quad_out(t);
    case .QUAD_IN_OUT;      return quad_in_out(t);
    case .CUBE_IN;          return cube_in(t);
    case .CUBE_OUT;         return cube_out(t);
    case .CUBE_IN_OUT;      return cube_in_out(t);
    case .QUART_IN;         return quart_in(t);
    case .QUART_OUT;        return quart_out(t);
    case .QUART_IN_OUT;     return quart_in_out(t);
    case .QUINT_IN;         return quint_in(t);
    case .QUINT_OUT;        return quint_out(t);
    case .QUINT_IN_OUT;     return quint_in_out(t);
    case .SINE_IN;          return sine_in(t);
    case .SINE_OUT;         return sine_out(t);
    case .SINE_IN_OUT;      return sine_in_out(t);
    case .BOUNCE_IN;        return bounce_in(t);
    case .BOUNCE_OUT;       return bounce_out(t);
    case .BOUNCE_IN_OUT;    return bounce_in_out(t);
    case .CIRC_IN;          return circ_in(t);
    case .CIRC_OUT;         return circ_out(t);
    case .CIRC_IN_OUT;      return circ_in_out(t);
    case .EXPO_IN;          return expo_in(t);
    case .EXPO_OUT;         return expo_out(t);
    case .EXPO_IN_OUT;      return expo_in_out(t);
    case .BACK_IN;          return back_in(t);
    case .BACK_OUT;         return back_out(t);
    case .BACK_IN_OUT;      return back_in_out(t);
    case .CUSTOM;           return curve_evaluate(custom_curve, t);
    }
}

#scope_file

B1 :: 1.0 / 2.75;
B2 :: 2.0 / 2.75;
B3 :: 1.5 / 2.75;
B4 :: 2.5 / 2.75;
B5 :: 2.25 / 2.75;
B6 :: 2.625 / 2.75;
