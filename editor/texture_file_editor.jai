texture_file_editor_init :: (resource_editor: *ResourceEditor)
{
    assert(resource_editor != null);
}

texture_file_editor_shutdown :: (resource_editor: *ResourceEditor)
{
    assert(resource_editor != null);
}

texture_file_editor_update :: (resource_editor: *ResourceEditor, dt: float) -> bool
{
    assert(resource_editor != null);
    assert(resource_editor.resource != null);

    texture_file: = cast(*TextureFile)resource_editor.resource;

    ImGui.SeparatorText("Full Texture");
    {
        size_available: = ImGui.GetContentRegionAvail();
        ratio: = size_available.x / cast(float)texture_file.texture.width;
        ImGui.Image(texture_file.texture.id, .{size_available.x, ratio * cast(float)texture_file.texture.height});
    }
    
    // Sprites
    ImGui.SeparatorText(temp_c_string(tprint("Sprites (%)", texture_file.sprites.count)));
    {
        size_available: = ImGui.GetContentRegionAvail();

        SPACING: = 10.0;
        line_width: = 0.0;

        for sprite, i: texture_file.sprites
        {
            sprite_size: = size(sprite.bounds);

            if line_width != 0
            {
                line_width += SPACING;
                if line_width + sprite_size.x <= size_available.x
                {
                    ImGui.SameLine(spacing=SPACING);
                }
                else
                {
                    line_width = 0;
                }
            }
            line_width += sprite_size.x;

            texture_size: = Vector2.{ xx texture_file.texture.width, xx texture_file.texture.height };
            uv0: = sprite.bounds.min / texture_size;
            uv1: = sprite.bounds.max / texture_size;

            ImGui.Image(texture_file.texture.id, sprite_size, uv0, uv1);
            ImGui.SetItemTooltip("%", sprite.name.str);
        }
    }

    return false;
}