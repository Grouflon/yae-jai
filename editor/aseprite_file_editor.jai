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