TextureFileEditor :: struct
{
    selected_sprite: = -1;
}

texture_file_editor_init :: (resource_editor: *ResourceEditor)
{
    assert(resource_editor != null);

    editor: = New(TextureFileEditor);
    resource_editor.payload = editor;
}

texture_file_editor_shutdown :: (resource_editor: *ResourceEditor)
{
    assert(resource_editor != null);

    free(resource_editor.payload);
    resource_editor.payload = null;
}

texture_file_editor_update :: (resource_editor: *ResourceEditor, dt: float) -> bool
{
    assert(resource_editor != null);
    using editor: = cast(*TextureFileEditor) resource_editor.payload;
    assert(editor != null);

    assert(resource_editor.resource != null);
    texture_file: = cast(*TextureFile)resource_editor.resource;

    hovered_sprite: = -1;
    ImGui.BeginChild("sprites", .{180, ImGui.GetContentRegionAvail().y}, window_flags = .AlwaysVerticalScrollbar);
    ImGui.SeparatorText("Sprites");
    for sprite, i: texture_file.sprites
    {
        if ImGui.Selectable(temp_c_string(sprite.name.str), i == selected_sprite)
        {
            selected_sprite = i;
        }
        if ImGui.IsItemHovered()
        {
            hovered_sprite = i;
        }
    }
    ImGui.EndChild();

    ImGui.SameLine();
    {
        size_available: = ImGui.GetContentRegionAvail();
        cursor: = ImGui.GetCursorScreenPos();
        draw_list: = ImGui.GetWindowDrawList();

        ratio_x: = size_available.x / cast(float)texture_file.texture.width;
        ratio_y: = size_available.y / cast(float)texture_file.texture.height;
        ratio: = min(ratio_x, ratio_y);
        ImGui.Image(texture_file.texture.id, ratio * Vector2.{cast(float)texture_file.texture.width, cast(float)texture_file.texture.height});
        is_image_hovered: = ImGui.IsWindowHovered() && ImGui.IsItemHovered();

        for sprite, i: texture_file.sprites
        {
            min: = cursor + sprite.bounds.min * ratio;
            max: = cursor + sprite.bounds.max * ratio;

            if is_image_hovered && ImGui.IsMouseHoveringRect(min, max)
            {
                hovered_sprite = i;
                if ImGui.IsMouseClicked(.Left)
                {
                    selected_sprite = i;
                }
            }

            color: = IM_COL32(255,255,255,60);
            if i == hovered_sprite && !ImGui.IsMouseDown(.Left)
            {
                color = IM_COL32(255,255,255,255);
            }
            else if i == selected_sprite
            {
                color = IM_COL32(255,255,255,170);
            }

            draw_list.AddRect(draw_list, min, max, color);
        }

        if is_image_hovered && hovered_sprite < 0 && ImGui.IsMouseClicked(.Left)
        {
            selected_sprite = -1;
        }
    }

    // ImGui.SeparatorText("Full Texture");
    // {
        
    // }
    
    // // Sprites
    // ImGui.SeparatorText(temp_c_string(tprint("Sprites (%)", texture_file.sprites.count)));
    // {
    //     size_available: = ImGui.GetContentRegionAvail();

    //     SPACING: = 10.0;
    //     line_width: = 0.0;

    //     for sprite, i: texture_file.sprites
    //     {
    //         sprite_size: = size(sprite.bounds);

    //         if line_width != 0
    //         {
    //             line_width += SPACING;
    //             if line_width + sprite_size.x <= size_available.x
    //             {
    //                 ImGui.SameLine(spacing=SPACING);
    //             }
    //             else
    //             {
    //                 line_width = 0;
    //             }
    //         }
    //         line_width += sprite_size.x;

    //         texture_size: = Vector2.{ xx texture_file.texture.width, xx texture_file.texture.height };
    //         uv0: = sprite.bounds.min / texture_size;
    //         uv1: = sprite.bounds.max / texture_size;

    //         ImGui.Image(texture_file.texture.id, sprite_size, uv0, uv1);
    //         ImGui.SetItemTooltip("%", sprite.name.str);
    //     }
    // }

    return false;
}