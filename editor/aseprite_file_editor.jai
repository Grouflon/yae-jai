aseprite_file_editor_init :: (resource_editor: *ResourceEditor)
{
    assert(resource_editor != null);
}

aseprite_file_editor_shutdown :: (resource_editor: *ResourceEditor)
{
    assert(resource_editor != null);
}

aseprite_file_editor_update :: (resource_editor: *ResourceEditor, dt: float) -> bool
{
    assert(resource_editor != null);
    assert(resource_editor.resource != null);

    aseprite_file: = cast(*AsepriteFile)resource_editor.resource;

    COLUMNS :: ImGui.ColumnDefinition.[
        .{"Name", 0, 0},
        .{"Linked Resource", 0, 0},
    ];

    table_flags: ImGui.TableFlags = .BordersV | .BordersOuterV | .BordersH | .Resizable | .RowBg | .Sortable | .Hideable;

    ImGui.SeparatorText("Texture");
    {
        if ImGui.BeginTable("animations", COLUMNS.count, table_flags, .{0, 0})
        {
            defer ImGui.EndTable();

            ImGui.TableSetupColumns(COLUMNS);
            ImGui.TableHeadersRow();

            if aseprite_file.texture != null
            {
                ImGui.TableNextRow();
                ImGui.TableNextColumn();
                ImGui.Selectable(temp_c_string(aseprite_file.texture.name), false, .SpanAllColumns | .AllowOverlap);
                if ImGui.IsItemClicked(.Left) && ImGui.IsMouseDoubleClicked(.Left)
                {
                    editor_open_resource(aseprite_file.texture);
                }

                ImGui.TableNextColumn();
                if ImGui.Button("Sync Sprites")
                {
                    aseprite_file_sync_sprites(aseprite_file);
                    resource_save_to_disk(aseprite_file.texture);
                }
            }
        }
    }

    ImGui.SeparatorText("Animations");
    {
        if ImGui.BeginTable("animations", COLUMNS.count, table_flags, .{0, 0})
        {
            defer ImGui.EndTable();

            ImGui.TableSetupColumns(COLUMNS);
            ImGui.TableHeadersRow();

            for animation, hash : aseprite_file.animations
            {
                ImGui.TableNextRow();

                ImGui.TableNextColumn();
                ImGui.Text("%", hash.str);
            }
        }
    }

    return false;
}