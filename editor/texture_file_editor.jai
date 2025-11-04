TextureFileEditor :: struct
{
    selected_sprite_index: = -1;
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

    hovered_sprite_index: = -1;
    modified: = false;

    size_available: = ImGui.GetContentRegionAvail();

    LEFT_COLUMN_SIZE :: 180;
    RIGHT_COLUMN_SIZE :: 250;

    if ImGui.BeginChild("sprites", .{LEFT_COLUMN_SIZE, size_available.y}, window_flags = .AlwaysVerticalScrollbar)
    {
        ImGui.SeparatorText("Sprites");
        for sprite, i: texture_file.sprites
        {
            if ImGui.Selectable(temp_c_string(sprite.name.str), i == selected_sprite_index)
            {
                selected_sprite_index = i;
            }
            if ImGui.IsItemHovered()
            {
                hovered_sprite_index = i;
            }
        }
    }
    ImGui.EndChild();

    ImGui.SameLine();

    if ImGui.BeginChild("texture", .{size_available.x - LEFT_COLUMN_SIZE - RIGHT_COLUMN_SIZE - 10, size_available.y})
    {
        size_available: = ImGui.GetContentRegionAvail();
        cursor: = ImGui.GetCursorScreenPos();
        draw_list: = ImGui.GetWindowDrawList();

        ratio_x: = size_available.x / cast(float)texture_file.texture.width;
        ratio_y: = size_available.y / cast(float)texture_file.texture.height;
        ratio: = min(ratio_x, ratio_y);
        ImGui.Image(texture_file.texture.handle, ratio * Vector2.{cast(float)texture_file.texture.width, cast(float)texture_file.texture.height});
        is_image_hovered: = ImGui.IsWindowHovered() && ImGui.IsItemHovered();

        for sprite, i: texture_file.sprites
        {
            min: = cursor + sprite.bounds.min * ratio;
            max: = cursor + sprite.bounds.max * ratio;

            if is_image_hovered && ImGui.IsMouseHoveringRect(min, max)
            {
                hovered_sprite_index = i;
                if ImGui.IsMouseClicked(.Left)
                {
                    selected_sprite_index = i;
                }
            }

            color: = IM_COL32(255,255,255,60);
            if i == hovered_sprite_index && !ImGui.IsMouseDown(.Left)
            {
                color = IM_COL32(255,255,255,255);
            }
            else if i == selected_sprite_index
            {
                color = IM_COL32(255,255,255,170);
            }

            draw_list.AddRect(draw_list, min, max, color);

            ORIGIN_SIZE :: 5;
            origin: = floor(.{
                min.x + sprite.origin.x * ratio,
                max.y - sprite.origin.y * ratio
            });
            draw_list.AddLine(draw_list, origin - .{ORIGIN_SIZE, 0}, origin + .{ORIGIN_SIZE+1, 0}, IM_COL32(255,0,0,255));
            draw_list.AddLine(draw_list, origin - .{0, ORIGIN_SIZE}, origin + .{0, ORIGIN_SIZE}, IM_COL32(255,0,0,255));
        }

        if is_image_hovered && hovered_sprite_index < 0 && ImGui.IsMouseClicked(.Left)
        {
            selected_sprite_index = -1;
        }
    }
    ImGui.EndChild();

    ImGui.SameLine();

    if ImGui.BeginChild("properties", .{RIGHT_COLUMN_SIZE, size_available.y}, child_flags = 0,  window_flags = .AlwaysVerticalScrollbar)
    {
        if selected_sprite_index >= 0
        {
            selected_sprite: = *texture_file.sprites[selected_sprite_index];
            ImGui.SeparatorText("Sprite Properties");
            modified = ImGui_EditValue("", selected_sprite) || modified;

            if ImGui.Button("Apply origin to all sprites")
            {
                for *sprite: texture_file.sprites
                {
                    sprite.origin = selected_sprite.origin;
                }
                modified = true;
            }
        }
        else
        {
            if ImGui_EditStructMembers(*texture_file.parameters)
            {
                set_texture_parameters(texture_file.texture, texture_file.parameters);
                modified = true;
            }
        }
    }
    ImGui.EndChild();

    

    if ImGui.IsWindowFocused(.RootAndChildWindows) && ImGui.IsKeyPressed(.Escape)
    {
        selected_sprite_index = -1;
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

    return modified;
}