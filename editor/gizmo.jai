

gizmo_rect :: (rect: *Rect, color: Color) -> bool
{
    assert(rendered_viewport != null);

    draw_outlined_rect(rect, color);

    return false;
}