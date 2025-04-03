AnimationEditor :: struct
{
    player: AnimationPlayer;
    viewport: ViewportBase;
    is_dragging: = false;
    edited_layer_name_index: s32 = -1;
    selected_event_index: s32 = -1;
    focus_requested: bool = false;
    event_popup_frame: s32 = -1;
    event_popup_layer: s32 = -1;
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
        animation_changed = animation_editor_properties_update(editor) || animation_changed;
    }
    ImGui.End();

    // Timeline
    ImGui.SetNextWindowClass(*animation_editor_window_class);
    if ImGui.Begin(TIMELINE_NAME, null)
    {
        animation_changed = animation_editor_timeline_update(editor) || animation_changed;
    }
    ImGui.End();

    // Viewport
    ImGui.SetNextWindowClass(*animation_editor_window_class);
    if ImGui.Begin(VIEWPORT_NAME, null)
    {
        animation_changed = animation_editor_viewport_update(editor) || animation_changed;
    }
    ImGui.End();

    // Save resource
    if animation_changed
    {
        resource_save_to_disk(animation);
    }

    // Animation
    animation_player_update(*player, dt);

    // Draw viewport scene
    animation_editor_viewport_draw(editor);
}

#scope_file

ZOOM_STEP :: 0.5;

animation_editor_properties_update :: (using editor: *AnimationEditor) -> bool
{
    ImGui.Text("props");
    ImGui.Value("zoom", editor.viewport.zoom);
    return false;
}

animation_editor_timeline_update :: (using editor: *AnimationEditor) -> bool
{
    animation_changed: = false;
    animation: = editor.player.current_animation;
    frame_count: s32 = cast(s32) animation.frame_count;
    CELL_WIDTH :: 24;
    CELL_HEIGHT :: 17;
    COLUMN_WIDTH :: CELL_WIDTH - 9;

    timeline_frame_origin: Vector2;
    timeline_frame_begin: Vector2;
    timeline_frame_end: Vector2 = ImGui.GetCursorScreenPos() + ImGui.GetContentRegionAvail() + .{-1,-1};

    table_flags: ImGui.TableFlags = .ScrollX | .ScrollY | .BordersV | .BordersOuterV | .BordersH | .HighlightHoveredColumn | .Resizable | .RowBg;
    column_count: s32 = frame_count + 3;
    if ImGui.BeginTable("timeline", xx column_count, table_flags, .{0, 0})
    {
        ImGui.TableSetupColumn("Tracks", .NoHide | .NoReorder | .WidthFixed, 100.0);

        column_flags: ImGui.TableColumnFlags = .WidthFixed | .NoResize | .NoReorder | .NoHide;
        for i: 0..frame_count-1
        {
            ImGui.TableSetupColumn(temp_c_string(tprint("%", i)), column_flags, COLUMN_WIDTH);
        }
        ImGui.TableSetupColumn("E", column_flags, COLUMN_WIDTH);
        ImGui.TableSetupColumn("", column_flags, COLUMN_WIDTH);

        ImGui.TableSetupScrollFreeze(1, 1);

        ImGui.TableNextRow(.Headers);
        for i: 0..(column_count-1)
        {
            name: = ImGui.TableGetColumnName(xx i);
            ImGui.TableSetColumnIndex(xx i);

            if i == 0
            {
                timeline_frame_begin = ImGui.GetCursorScreenPos() + .{ImGui.GetContentRegionAvail().x + 5, CELL_HEIGHT-1};
            }
            else
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

            // Layer Name
            if edited_layer_name_index == i
            {
                if focus_requested
                {
                    focus_requested = false;
                    ImGui.SetKeyboardFocusHere(0);
                }

                ImGui.SetNextItemWidth(ImGui.GetContentRegionAvail().x);
                if ImGui.InputText("", *layer.name, .AutoSelectAll)
                {
                    animation_changed = true;
                }

                // Edit exit
                if (!ImGui.IsItemHovered() && ImGui.IsMouseClicked(.Left)) ||
                    ImGui.IsKeyPressed(.Escape) ||
                    ImGui.IsKeyPressed(.Enter)
                {
                    edited_layer_name_index = -1;
                }
            }
            else
            {
                ImGui.Selectable(temp_c_string(layer.name));

                // Edit enter
                if ImGui.IsItemHovered() && ImGui.IsMouseDoubleClicked(.Left)
                {
                    edited_layer_name_index = xx i;
                    focus_requested = true;
                }
            }

            // Layer Context menu
            if ImGui.BeginPopupContextItem()
            {
                if ImGui.MenuItem("Delete layer")
                {
                    layer_to_delete = xx i;
                    if edited_layer_name_index == i
                    {
                        edited_layer_name_index = -1;
                    }
                    else if edited_layer_name_index > i
                    {
                        edited_layer_name_index -= 1;
                    }
                }

                ImGui.EndPopup();
            }

            if i == 0
            {
                ImGui.TableSetColumnIndex(1);
                timeline_frame_origin = ImGui.GetCursorScreenPos() + .{-4, -1};
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

        // Draw events
        if ImGui.GetScrollMaxX() > 0 timeline_frame_end.y -= 12;
        if ImGui.GetScrollMaxY() > 0 timeline_frame_end.x -= 12;
        draw_list: = ImGui.GetWindowDrawList();
        draw_list.PushClipRect(draw_list, timeline_frame_begin, timeline_frame_end);
        // draw_list.AddRect(draw_list, timeline_frame_begin, timeline_frame_end, 0xFF0000FF); // debug: see clipping rect
        clicked_on_something: = false;
        for event, event_i: animation.events
        {
            DIAMOND_RADIUS :: 5;
            center: Vector2 = timeline_frame_origin + Vector2.{ cast(float)(event.begin+1) * CELL_WIDTH, (CELL_HEIGHT * 0.5) + cast(float)event.layer_index * CELL_HEIGHT };
            color: u32 = 0xffe0873d;

            if ImGui.IsWindowHovered() && length(ImGui.GetMousePos() - center) <= DIAMOND_RADIUS
            {
                color = 0xffffb679;

                if ImGui.IsMouseClicked(.Left)
                {
                    selected_event_index = xx event_i;
                    clicked_on_something = true;
                }
            }

            draw_list.AddNgonFilled(draw_list, center, DIAMOND_RADIUS, color, 4);
            if selected_event_index == event_i
            {
                draw_list.AddNgon(draw_list, center, DIAMOND_RADIUS+1, 0xffffb679, 4);
            }
        }

        // Clicks on timeline
        if ImGui.IsWindowHovered() && ImGui.IsMouseHoveringRect(timeline_frame_begin, timeline_frame_end, false)
        {
            relative_mouse_pos: = ImGui.GetMousePos() - timeline_frame_origin;
            hovered_frame: = cast(s32) round(relative_mouse_pos.x / CELL_WIDTH) - 1;
            hovered_layer: = cast(s32) floor(relative_mouse_pos.y / CELL_HEIGHT);
            is_valid_cell: = hovered_frame >= 0 && hovered_frame < xx animation.frame_count && hovered_layer >= 0 && hovered_layer < animation.layers.count;

            ImGui.GetIO().ConfigWindowsMoveFromTitleBarOnly = true;

            if ImGui.IsMouseClicked(.Left) && !clicked_on_something
            {
                selected_event_index = -1;
            }

            EVENT_POPUP_NAME :: "frame event";
            if is_valid_cell && ImGui.IsMouseClicked(.Right)
            {
                event_popup_frame = hovered_frame;
                event_popup_layer = hovered_layer;
                ImGui.OpenPopup(EVENT_POPUP_NAME);
            }

            if is_valid_cell && selected_event_index >= 0 && ImGui.IsMouseDragging(.Left)
            {
                animation.events[selected_event_index].layer_index = hovered_layer;
                animation.events[selected_event_index].begin = hovered_frame;
            }
        }
        else
        {
            ImGui.GetIO().ConfigWindowsMoveFromTitleBarOnly = false;
        }

        // Event popup
        if ImGui.BeginPopup("frame event")
        {
            if ImGui.BeginMenu("Add Event")
            {
                enum_info: = cast(*Type_Info_Enum) type_info(AnimationEventType);

                for value: enum_info.values
                {
                    if value == xx AnimationEventType.NONE continue;

                    if ImGui.MenuItem(temp_c_string(enum_value_to_name(cast(AnimationEventType) value)))
                    {
                        animation_add_event(animation, .{ type = .SPRITE, layer_index = xx event_popup_layer, begin = xx event_popup_frame });
                        animation_changed = true;
                    }
                }
                ImGui.EndMenu();
            }

            ImGui.EndPopup();
        }

        // Keyboard shortcuts
        if selected_event_index >= 0 && ImGui.IsWindowFocused() && ImGui.IsKeyPressed(.Delete)
        {
            animation_remove_event(animation, selected_event_index);
            selected_event_index = -1;
            animation_changed = true;
        }

        ImGui.EndTable();
    }

    return animation_changed;
}

animation_editor_viewport_update :: (using editor: *AnimationEditor) -> bool
{
    animation_changed: = false;
    animation: = editor.player.current_animation;
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

    // Controls
    controls_size: = Vector2.{120, 0};
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

        ImGui.SameLine(0,10);
        ImGui.Text("%/", player.current_frame);
        ImGui.SameLine(0,0);
        frame_count: s32 = xx animation.frame_count;
        ImGui.PushID("frame_count"); defer ImGui.PopID();
        ImGui.SetNextItemWidth(25);
        if ImGui.DragInt("", *frame_count, 0.1)
        {
            animation.frame_count = xx max(frame_count, 0);
            animation_changed = true;
        }
    }
    ImGui.EndChild();
    ImGui.PopStyleVar(2);
    ImGui.PopStyleColor();

    return animation_changed;
}

animation_editor_viewport_draw :: (using editor: *AnimationEditor)
{
    viewport_begin_render(*viewport);
    defer viewport_end_render(*viewport);

    rl.ClearBackground(rl.LIGHTGRAY);

    // Draw Grid
    {
        GRID_STEP :: 100.0;
        viewport_min: = viewport_to_world_position(*viewport, .{0, viewport.size.y});
        viewport_max: = viewport_to_world_position(*viewport, .{viewport.size.x, 0});
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
}

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
