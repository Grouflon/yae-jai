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
    modified: = false;

    ImGui.SeparatorText("Texture");
    {
        modified = ImGui_EditResourcePointer("texture", *aseprite_file.texture) || modified;
        if modified
        {
            aseprite_file_build_index_table(aseprite_file);
        }

        if aseprite_file.texture != null
        {
            if ImGui.Button("Sync")
            {
                aseprite_file_sync_sprites(aseprite_file);
            }
            ImGui.SameLine();

            index_table: = aseprite_file_build_index_table(aseprite_file);

            aseprite_sprite_count: = aseprite_file.bounds_to_frame_index.count;
            texture_sprite_count: = index_table.count;
            ImGui.TextColored(
                ifx texture_sprite_count == aseprite_sprite_count then Vector4.{0,1,0,1} else Vector4.{1,0,0,1},
                "% / % sprites synced",
                texture_sprite_count, aseprite_sprite_count
            );
        }
    }

    ImGui.SeparatorText("Animations");
    {
        COLUMNS :: ImGui_ColumnDefinition.[
            .{"Name", .WidthFixed, 100},
            .{"Resource", 0, 0},
            .{"Status", 0, 0},
        ];

        table_flags: ImGui.TableFlags = .BordersV | .BordersOuterV | .BordersH | .Resizable | .RowBg;

        if ImGui.BeginTable("animations", COLUMNS.count, table_flags, .{0, 0})
        {
            defer ImGui.EndTable();
            ImGui_TableSetupColumns(COLUMNS);
            ImGui.TableHeadersRow();

            for *animation_ptr, hash : aseprite_file.animations
            {
                ImGui.PushID(hash.str);
                defer ImGui.PopID();

                ImGui.TableNextRow();
                ImGui.TableNextColumn();
                ImGui.Text("%", hash.str);

                ImGui.TableNextColumn();
                modified = ImGui_EditResourcePointer("animation", animation_ptr) || modified;

                ImGui.TableNextColumn();

                animation: = <<animation_ptr;
                if animation != null
                {
                    if ImGui.Button("Sync")
                    {

                    }
                    ImGui.SameLine();
                    
                    success, index: = table_find_new(*aseprite_file.data.name_to_tag, hash.str);
                    assert(success);
                    tag: = *aseprite_file.data.frame_tags[index];

                    aseprite_frames: = tag.end_frame - tag.start_frame + 1;
                    animation_frames: = animation.frame_count;

                    ImGui.TextColored(
                        ifx aseprite_frames == animation_frames then Vector4.{0,1,0,1} else Vector4.{1,0,0,1},
                        "% / % frames synced",
                        animation_frames, aseprite_frames
                    );
                }
            }
        }
    }

    return modified;
}