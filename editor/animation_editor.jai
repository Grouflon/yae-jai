AnimationEditor :: struct
{
    player: AnimationPlayer;
    viewport: ViewportBase;
    is_dragging: = false;
}

animation_editor_init :: (using editor: *AnimationEditor, animation: *Animation)
{
    animation_player_set_animation(*player, animation);
    viewport = .{};
}

animation_editor_update :: (using editor: *AnimationEditor, dt: float)
{
    if editor == null return;

    dockspace_id: = ImGui.GetID("animation_dockspace");
    animation_editor_window_class: = ImGui.WindowClass.{ ClassId = dockspace_id };
    dockspace_size: = ImGui.GetContentRegionAvail();
    animation: = editor.player.current_animation;
    animation_changed: = false;

    PROPERTIES_NAME :: "\uf03a Properties";
    TIMELINE_NAME :: "\uf008 Timeline";
    VIEWPORT_NAME :: "Viewport";

    // Build default dockspace
    if ImGui.DockBuilderGetNode(dockspace_id) == null
    {
        ImGui.DockBuilderRemoveNode(dockspace_id); // Clear out existing layout
        ImGui.DockBuilderAddNode(dockspace_id, cast(ImGui.DockNodeFlags) ImGui.DockNodeFlagsPrivate_.DockNodeFlags_DockSpace); // Add empty node
        ImGui.DockBuilderSetNodeSize(dockspace_id, dockspace_size);

        dock_main_id: = dockspace_id; // This variable will track the document node, however we are not using it here as we aren't docking anything into it.
        dock_id_prop: = ImGui.DockBuilderSplitNode(dock_main_id, .ImGuiDir_Right, 0.20, null, *dock_main_id);
        dock_id_bottom: = ImGui.DockBuilderSplitNode(dock_main_id, .ImGuiDir_Down, 0.40, null, *dock_main_id);

        ImGui.DockBuilderDockWindow(PROPERTIES_NAME, dock_id_prop);
        ImGui.DockBuilderDockWindow(TIMELINE_NAME, dock_id_bottom);
        ImGui.DockBuilderDockWindow(VIEWPORT_NAME, dock_main_id);
        ImGui.DockBuilderFinish(dockspace_id);
    }
    else
    {
        ImGui.DockSpace(dockspace_id, *dockspace_size, window_class = *animation_editor_window_class);
    }

    // Properties
    ImGui.SetNextWindowClass(*animation_editor_window_class);
    if ImGui.Begin(PROPERTIES_NAME, null)
    {
        ImGui.Text("props");
        ImGui.Value("zoom", editor.viewport.zoom);
    }
    ImGui.End();

    // Timeline
    ImGui.SetNextWindowClass(*animation_editor_window_class);
    if ImGui.Begin(TIMELINE_NAME, null)
    {
        line_height: = ImGui.GetTextLineHeightWithSpacing();

        table_flags: ImGui.TableFlags = .ScrollX | .ScrollY | .BordersV | .BordersH | .HighlightHoveredColumn | .Resizable | .RowBg;
        if ImGui.BeginTable("timeline", xx (animation.frames.count + 1), table_flags, .{0, 0})
        {
            COLUMN_WIDTH :: 15;
            ImGui.TableSetupColumn("Tracks", .NoHide | .NoReorder | .WidthFixed, 100.0);
            column_flags: ImGui.TableColumnFlags = .WidthFixed | .NoResize | .NoReorder | .NoHide;
            for i: 0..animation.frames.count-1
            {
                ImGui.TableSetupColumn(temp_c_string(tprint("%", i)), column_flags, COLUMN_WIDTH);
            }
            ImGui.TableSetupScrollFreeze(1, 1);

            ImGui.TableNextRow(.Headers);
            for i: 0..animation.frames.count
            {
                name: = ImGui.TableGetColumnName(xx i);
                ImGui.TableSetColumnIndex(xx i);

                if i != 0
                {
                    size: = ImGui.CalcTextSize(name);
                    ImGui.SameLine(COLUMN_WIDTH - size.x);
                }
                
                ImGui.TableHeader(name);
            }

            layer_to_delete: s32 = -1;
            for layer, i: animation.layers
            {
                ImGui.PushID(cast(s32) i);
                defer ImGui.PopID();

                ImGui.TableNextRow();
                ImGui.TableSetColumnIndex(0);
                // ImGui.SetNextItemWidth(-FLOAT32_MAX);
                ImGui.Selectable(temp_c_string(layer.name));
                if ImGui.BeginPopupContextItem()
                {
                    if ImGui.MenuItem("Delete layer")
                    {
                        layer_to_delete = xx i;
                    }

                    ImGui.EndPopup();
                }
                
            }
            if layer_to_delete >= 0
            {
                animation_remove_layer(animation, layer_to_delete);
                animation_changed = true;
            }

            ImGui.TableNextRow();
            ImGui.TableSetColumnIndex(0);
            if ImGui.Button("New Layer", .{ImGui.GetContentRegionAvail().x, 0})
            {
                animation_add_layer(animation, tprint("layer %", animation.layers.count));
                animation_changed = true;
            }
            // for (int row = 0; row < rows_count; row++)
            // {
            //     ImGui.PushID(row);
            //     ImGui.TableNextRow();
            //     ImGui.TableSetColumnIndex(0);
            //     ImGui.AlignTextToFramePadding();
            //     ImGui.Text("Track %d", row);
            //     for (int column = 1; column < columns_count; column++)
            //         if (ImGui.TableSetColumnIndex(column))
            //         {
            //             ImGui.PushID(column);
            //             ImGui.Checkbox("", &bools[row * columns_count + column]);
            //             ImGui.PopID();
            //         }
            //     ImGui.PopID();
            // }
            ImGui.EndTable();
        }

        // timeline_id: = ImGui.GetID("timeline_dockspace");
        // timeline_window_class: = ImGui.WindowClass.{ ClassId = dockspace_id };
        // TIMELINE_LAYERS_NAME :: "Timeline_Layers";
        // TIMELINE_FRAMES_NAME :: "Timeline_Frame";
        // timeline_size: = ImGui.GetContentRegionAvail();

        // // Build default dockspace
        // flags: ImGui.DockNodeFlags = .NoDockingOverCentralNode | .NoDockingSplit | .AutoHideTabBar | .NoUndocking | .NoSplit | .NoDockingInCentralNode | cast(ImGui.DockNodeFlags) ImGui.DockNodeFlagsPrivate_.DockNodeFlags_NoTabBar;
        // if ImGui.DockBuilderGetNode(timeline_id) == null
        // {
        //     ImGui.DockBuilderRemoveNode(timeline_id); // Clear out existing layout
        //     ImGui.DockBuilderAddNode(timeline_id, flags | cast(ImGui.DockNodeFlags) ImGui.DockNodeFlagsPrivate_.DockNodeFlags_DockSpace); // Add empty node
        //     ImGui.DockBuilderSetNodeSize(timeline_id, timeline_size);

        //     dock_id_frames: = timeline_id; // This variable will track the document node, however we are not using it here as we aren't docking anything into it.
        //     dock_id_layers: = ImGui.DockBuilderSplitNode(timeline_id, .ImGuiDir_Left, 0.20, null, *dock_id_frames);

        //     ImGui.DockBuilderDockWindow(TIMELINE_LAYERS_NAME, dock_id_layers);
        //     ImGui.DockBuilderDockWindow(TIMELINE_FRAMES_NAME, dock_id_frames);
        //     ImGui.DockBuilderFinish(timeline_id);
        // }
        // else
        // {
        //     ImGui.DockSpace(timeline_id, *timeline_size, window_class = *timeline_window_class, flags = flags);
        // }
        
        // ImGui.SetNextWindowClass(*timeline_window_class);
        // if ImGui.Begin(TIMELINE_LAYERS_NAME, null)
        // {
        //     ImGui.Text("layers");
        // }
        // ImGui.End();

        // ImGui.SetNextWindowClass(*timeline_window_class);
        // if ImGui.Begin(TIMELINE_FRAMES_NAME, null)
        // {
        //     ImGui.Text("frames");
        // }
        // ImGui.End();
    }
    ImGui.End();

    // Viewport
    ImGui.SetNextWindowClass(*animation_editor_window_class);
    if ImGui.Begin(VIEWPORT_NAME, null)
    {
        viewport_size: = ImGui.GetContentRegionAvail();
        viewport_screen_origin: = ImGui.GetCursorScreenPos();
        viewport_update(*viewport, viewport_size);
        ImGui.Image(viewport.render_target.texture.id, viewport_size);

        if ImGui.BeginPopupContextItem("viewport")
        {
            if ImGui.MenuItem("Frame sprite")
            {
                animation_editor_frame_sprite(editor);
            }

            ImGui.EndPopup();
        }

        DRAG_BUTTON :: ImGui.MouseButton.Middle;
        drag_button_pressed: = ImGui.IsMouseClicked(DRAG_BUTTON);
        drag_button_down: = ImGui.IsMouseDown(DRAG_BUTTON);
        mouse_viewport_position: = ImGui.GetIO().MousePos - viewport_screen_origin;
        if ImGui.IsItemHovered()
        {
            wanted_zoom: = clamp(editor.viewport.zoom + xy(ZOOM_STEP * ImGui.GetIO().MouseWheel), 0.5, 50.0);
            viewport_set_zoom_focused(*editor.viewport, mouse_viewport_position, wanted_zoom);
            if drag_button_pressed { editor.is_dragging = true; }
        }

        if !drag_button_down
        {
            editor.is_dragging = false;
        }

        if editor.is_dragging
        {
            d: = ImGui.GetMouseDragDelta(DRAG_BUTTON, 0);
            ImGui.ResetMouseDragDelta(DRAG_BUTTON);
            viewport_pan(*editor.viewport, d);
        }

        controls_size: = Vector2.{71, 0};
        ImGui.SetCursorPos(.{(viewport_size.x - controls_size.x) * 0.5 + 9, viewport_size.y - controls_size.y - 10});
        ImGui.PushStyleColor(.ImGuiCol_ChildBg, Vector4.{0,0,0, 0.7});
        ImGui.PushStyleVar(.WindowPadding, xy(2));
        ImGui.PushStyleVar(.ChildRounding, 4);
        if ImGui.BeginChild("controls", controls_size, .AlwaysUseWindowPadding | .AutoResizeY)
        {
            // rewind
            if ImGui.Button("\uf049")
            {
                animation_player_stop(*player);
                animation_player_set_frame(*player, 0);
            }
            ImGui.SameLine(0, 2);

            // play/stop
            if !player.is_playing
            {
                if ImGui.Button("\uf04b")
                {
                    animation_player_play(*player);
                }
            }
            else
            {
                if ImGui.Button("\uf04d")
                {
                    animation_player_stop(*player);
                }
            }
            ImGui.SameLine(0,2);

            // unwind
            if ImGui.Button("\uf050")
            {
                animation_player_stop(*player);
                animation_player_set_frame(*player, xx (player.current_animation.frames.count - 1));
            }
        }
        ImGui.EndChild();
        ImGui.PopStyleVar(2);
        ImGui.PopStyleColor();
    }
    ImGui.End();

    // Animation
    animation_player_update(*player, dt);

    // Draw viewport scene
    viewport_begin_render(*editor.viewport);
    defer viewport_end_render(*editor.viewport);

    rl.ClearBackground(rl.LIGHTGRAY);

    // Draw Grid
    {
        GRID_STEP :: 100.0;
        viewport_min: = viewport_to_world_position(*editor.viewport, .{0, editor.viewport.size.y});
        viewport_max: = viewport_to_world_position(*editor.viewport, .{editor.viewport.size.x, 0});
        viewport_range: = viewport_max - viewport_min;
        viewport_start: = viewport_min - .{fmod_cycling(viewport_min.x, GRID_STEP), fmod_cycling(viewport_min.y, GRID_STEP)};
        cells_count_h: = floor_to_s32(viewport_range.x / GRID_STEP) + 1;
        cells_count_v: = floor_to_s32(viewport_range.y / GRID_STEP) + 1;

        // Vertical lines
        for i: 0.. cells_count_h
        {
            start: = viewport_start + .{xx i * GRID_STEP, 0};
            color: = ifx abs(start.x) < rl.EPSILON then rl.GREEN else rl.GRAY;
            rl.DrawLineV(start, .{start.x, viewport_max.y}, color);
        }

        // Horizontal lines
        for i: 0.. cells_count_v
        {
            start: = viewport_start + .{0, xx i * GRID_STEP};
            color: = ifx abs(start.y) < rl.EPSILON then rl.RED else rl.GRAY;
            rl.DrawLineV(start, .{viewport_max.x, start.y}, color);
        }
    }

    animation_player_draw(*player, .{});

    if animation_changed
    {
        resource_save_to_disk(animation);
    }
}

#scope_file

ZOOM_STEP :: 0.5;

animation_editor_frame_sprite :: (using editor: *AnimationEditor)
{
    FRAME_MARGIN :: Vector2.{50, 50};
    i, frame: = animation_player_current_frame(*player);
    sprite_size: = size(frame.sprite.bounds);

    viewport_align_points(*editor.viewport, FRAME_MARGIN, .{0, sprite_size.y}, editor.viewport.size - FRAME_MARGIN, .{sprite_size.x, 0}, true);
    zoom: float = min(editor.viewport.zoom.x, editor.viewport.zoom.y);
    editor.viewport.zoom = xy(zoom - fmod_cycling(zoom, ZOOM_STEP));
}

rl :: #import "raylib";
