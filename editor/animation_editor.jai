AnimationEditor :: struct
{
    player: AnimationPlayer;
    viewport: ViewportBase;

    is_dragging_viewport: = false;
    is_dragging_frame: = false;
    drag_event_mode: = AnimationDragEventMode.NONE;
    drag_frame_offset: = -1;

    is_drag_zone_hovered: = false;

    edited_layer_name_index: s64 = -1;
    selected_event_index: s64 = -1;

    popup_layer_index: s64 = -1;
    popup_event_index: s64 = -1;
    popup_frame_index: s64 = -1;

    default_resource_editor: bool = false;

    frame_count: = -1;

    show_movement: bool = true;
    show_boxes: bool = true;
}

AnimationDragEventMode :: enum
{
    NONE;
    LEFT;
    CENTER;
    RIGHT;
}

animation_editor_init :: (resource_editor: *ResourceEditor)
{
    assert(resource_editor != null);

    editor: = New(AnimationEditor);
    resource_editor.payload = editor;

    animation_player_set_animation(*editor.player, cast(*Animation) resource_editor.resource);
}

animation_editor_shutdown :: (resource_editor: *ResourceEditor)
{
    assert(resource_editor != null);
    using t: = cast(*AnimationEditor)resource_editor;

    if is_drag_zone_hovered
    {
        editor_pop_window_drag_disabled();
    }

    free(resource_editor.payload);
    resource_editor.payload = null;
}

animation_editor_update :: (resource_editor: *ResourceEditor, dt: float) -> bool
{
    assert(resource_editor != null);
    using editor: = cast(*AnimationEditor) resource_editor.payload;
    assert(editor != null);

    frame_count += 1;

    if ImGui.BeginMenuBar()
    {
        if ImGui.BeginMenu("Debug")
        {
            defer ImGui.EndMenu();

            ImGui.MenuItem("Default Resource Editor", "", *default_resource_editor);
        }

        if ImGui.BeginMenu("View")
        {
            defer ImGui.EndMenu();
            ImGui.MenuItem("Show Movement", "", *show_movement);
            ImGui.MenuItem("Show Boxes", "", *show_boxes);
        }
    }
    ImGui.EndMenuBar();

    if default_resource_editor
    {
        return default_resource_editor_update(resource_editor, dt);
    }

    animation: = player.current_animation;
    if animation == null
    {
        resource_editor.is_open = false;
        return false;
    }

    dockspace_id: = ImGui.GetID(tprint("% animation_dockspace", resource_editor.resource.name));
    animation_editor_window_class: = ImGui.WindowClass.{ ClassId = dockspace_id };
    dockspace_size: = max(ImGui.GetContentRegionAvail(), xy(16));
    animation_changed: = false;

    // Build default dockspace
    if ImGui.DockBuilderGetNode(dockspace_id) == null
    {
        ImGui.DockBuilderRemoveNode(dockspace_id); // Clear out existing layout
        ImGui.DockBuilderAddNode(dockspace_id, cast(ImGui.DockNodeFlags) ImGui.DockNodeFlagsPrivate_.DockNodeFlags_DockSpace); // Add empty node
        ImGui.DockBuilderSetNodeSize(dockspace_id, dockspace_size);

        dock_main_id: = dockspace_id; // This variable will track the document node, however we are not using it here as we aren't docking anything into it.
        dock_id_prop: = ImGui.DockBuilderSplitNode(dock_main_id, .ImGuiDir_Right, 0.30, null, *dock_main_id);
        dock_id_bottom: = ImGui.DockBuilderSplitNode(dock_main_id, .ImGuiDir_Down, 0.40, null, *dock_main_id);

        ImGui.DockBuilderDockWindow(properties_window_name(resource_editor), dock_id_prop);
        ImGui.DockBuilderDockWindow(timeline_window_name(resource_editor), dock_id_bottom);
        ImGui.DockBuilderDockWindow(viewport_window_name(resource_editor), dock_main_id);
        ImGui.DockBuilderFinish(dockspace_id);
    }
    else
    {
        ImGui.DockSpace(dockspace_id, *dockspace_size, window_class = *animation_editor_window_class);
    }

    // Properties
    ImGui.SetNextWindowClass(*animation_editor_window_class);
    if ImGui.Begin(properties_window_name(resource_editor), null)
    {
        animation_changed = animation_editor_properties_update(editor) || animation_changed;
    }
    ImGui.End();

    // Timeline
    ImGui.SetNextWindowClass(*animation_editor_window_class);
    if ImGui.Begin(timeline_window_name(resource_editor), null)
    {
        animation_changed = animation_editor_timeline_update(editor) || animation_changed;
    }
    ImGui.End();

    // Viewport
    ImGui.SetNextWindowClass(*animation_editor_window_class);
    if ImGui.Begin(viewport_window_name(resource_editor), null)
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

    return false; // Implement if we ever need to detect modifications
}

#scope_file

properties_window_name :: inline (editor: *ResourceEditor) -> *u8 { return temp_c_string(tprint("\uf03a Properties##%", editor.resource)); }
timeline_window_name :: inline (editor: *ResourceEditor) -> *u8 { return temp_c_string(tprint("\uf008 Timeline##%", editor.resource)); }
viewport_window_name :: inline (editor: *ResourceEditor) -> *u8 { return temp_c_string(tprint("Viewport##%", editor.resource)); }

ZOOM_STEP :: 0.5;

animation_editor_properties_update :: (using editor: *AnimationEditor) -> bool
{
    animation_modified: = false;
    animation: = editor.player.current_animation;
    assert(animation != null);

    if selected_event_index >= 0
    {
        animation_modified = ImGui_EditValue("", *animation.events[selected_event_index]) || animation_modified;
    }
    else
    {
        ImGui.SetNextItemWidth(85.0);
        animation_modified = ImGui_EditValue("frames per second", *animation.frames_per_second) || animation_modified;
        ImGui.SetNextItemWidth(85.0);
        animation_modified = ImGui_EditValue("preview loop count", *animation.preview_loop_count) || animation_modified;
    }

    return animation_modified;
}

animation_editor_timeline_update :: (using editor: *AnimationEditor) -> bool
{
    animation_changed: = false;
    animation: = editor.player.current_animation;
    assert(animation != null);
    TOP_BAR_HEIGHT :: 17;
    LAYER_HEIGHT :: 18;
    LAYER_WIDTH :: 150;
    FRAME_WIDTH :: 30;
    EVENT_SIDE_HANDLE_WIDTH :: 6;
    EDIT_LAYER_POPUP_NAME :: "edit_layer";
    EDIT_EVENT_POPUP_NAME :: "edit_event";

    WHITE_IDLE : u32 : 0xffaaaaaa;
    WHITE_HOVERED : u32 : 0xffffffff;

    color_strong: = ImGui.GetColorU32(ImGui.GetStyle().Colors[ImGui.Col.TableBorderStrong]);
    color_light: = ImGui.GetColorU32(ImGui.GetStyle().Colors[ImGui.Col.TableBorderLight]);

    previous_is_drag_zone_hovered: = is_drag_zone_hovered;

    get_event_local_bounds :: (animation: *Animation, event_index: s64) -> Bounds
    {
        event: = *animation.events[event_index];
        end_frame: = ifx event.end < event.begin then event.begin else event.end;
        begin: Vector2 = .{
            xx (LAYER_WIDTH + 1 + event.begin * (FRAME_WIDTH+1)),
            xx (TOP_BAR_HEIGHT + 1 + event.layer * (LAYER_HEIGHT+1))
        };
        end: Vector2 = .{
            begin.x + xx ((end_frame-event.begin+1) * (FRAME_WIDTH+1) - 1),
            begin.y + LAYER_HEIGHT
        };
        return .{ begin, end };
    }

    if ImGui.BeginChild("timeline", .{}, .Borders, .AlwaysHorizontalScrollbar | .AlwaysVerticalScrollbar)
    {
        available_size: = ImGui.GetContentRegionAvail();
        content_size: Vector2 = .{
            max(available_size.x, xx (LAYER_WIDTH + 1 + (FRAME_WIDTH + 1) * animation.frame_count)),
            max(available_size.y, xx (TOP_BAR_HEIGHT + 1 + (LAYER_HEIGHT + 1) * (animation.layers.count+1))) // We make size for an additional layer so that it is simpler to create them with a double click
        };

        // ImGui.PushStyleColor(.ChildBg, .{1,0,0,1});
        // defer ImGui.PopStyleColor();

        if ImGui.BeginChild("timeline_content", content_size, 0, .NoScrollbar)
        {
            cursor: = ImGui.GetCursorScreenPos();
            mouse_position: = ImGui.GetMousePos();
            local_mouse_pos: = mouse_position - cursor;

            is_drag_zone_hovered = ImGui.IsWindowHovered(); // @NOTE(remi): maybe reduce zone to layer & frames
            is_top_bar_hovered: = false;
            is_layer_bar_hovered: = false;
            is_event_zone_hovered: = false;
            hovered_layer: = -1;
            hovered_event: = -1;
            hovered_frame: = -1;
            clamped_hovered_frame: = 0;
            next_drag_event_mode: = AnimationDragEventMode.NONE;

            just_edited_layer: = false;

            // Input
            // Mouse
            if is_drag_zone_hovered
            {
                // Hovering
                is_top_bar_hovered = ImGui.IsMouseHoveringRect(cursor + .{LAYER_WIDTH+1, 0}, cursor + .{content_size.x, TOP_BAR_HEIGHT+1});
                is_layer_bar_hovered = ImGui.IsMouseHoveringRect(cursor + .{0, LAYER_HEIGHT+1}, cursor + .{LAYER_WIDTH, content_size.y});
                is_event_zone_hovered = ImGui.IsMouseHoveringRect(cursor + .{LAYER_WIDTH+1, LAYER_HEIGHT+1}, cursor + content_size);

                hovered_frame = floor_to_s32((local_mouse_pos.x - LAYER_WIDTH) / (FRAME_WIDTH + 1));
                clamped_hovered_frame = clamp(hovered_frame, 0, animation.frame_count-1);
                if hovered_frame != clamped_hovered_frame { hovered_frame = -1; }

                // Layers
                for i: 0..animation.layers.count-1
                {
                    y: float = xx (TOP_BAR_HEIGHT+1 + i * (LAYER_HEIGHT+1));
                    if ImGui.IsMouseHoveringRect(cursor + .{0, y}, cursor + .{content_size.x, y + LAYER_HEIGHT+1})
                    {
                        hovered_layer = i;
                        break;
                    }
                }

                // Events
                for i: 0..animation.events.count-1
                {
                    bounds: = cursor + get_event_local_bounds(animation, i);
                    if ImGui.IsMouseHoveringRect(bounds.min, bounds.max)
                    {
                        if mouse_position.x <= bounds.min.x + EVENT_SIDE_HANDLE_WIDTH
                        {
                            next_drag_event_mode = .LEFT;
                        }
                        else if mouse_position.x >= bounds.max.x - EVENT_SIDE_HANDLE_WIDTH
                        {
                            next_drag_event_mode = .RIGHT;
                        }
                        else
                        {
                            next_drag_event_mode = .CENTER;
                        }
                        hovered_event = i;
                    }
                }

                // Clicks
                if ImGui.IsMouseClicked(.Left)
                {
                    if is_event_zone_hovered
                    {
                        if hovered_event >= 0
                        {
                            selected_event_index = hovered_event;
                            drag_event_mode = next_drag_event_mode;
                            drag_frame_offset = hovered_frame - animation.events[selected_event_index].begin;
                        }
                        else
                        {
                            selected_event_index = -1;
                        }
                    }
                    else if is_layer_bar_hovered
                    {
                        if hovered_layer != edited_layer_name_index
                        {
                            edited_layer_name_index = -1;
                        }
                    }
                    else if is_top_bar_hovered
                    {
                        is_dragging_frame = true;
                        animation_player_stop(*player);
                    }
                }

                if ImGui.IsMouseClicked(.Right)
                {
                    if is_event_zone_hovered && hovered_frame >= 0 && hovered_layer >= 0
                    {
                        popup_layer_index = hovered_layer;
                        popup_frame_index = hovered_frame;
                        popup_event_index = hovered_event;
                        ImGui.OpenPopup(EDIT_EVENT_POPUP_NAME);
                    }
                    else if is_layer_bar_hovered
                    {
                        popup_layer_index = hovered_layer;
                        ImGui.OpenPopup(EDIT_LAYER_POPUP_NAME);
                    }
                    else if is_top_bar_hovered
                    {

                    }
                }

                if ImGui.IsMouseDoubleClicked(.Left)
                {
                    if is_event_zone_hovered
                    {
                        if hovered_event < 0 && hovered_layer >= 0 && hovered_frame >= 0
                        {
                            selected_event_index = animation_add_event(animation, .{ begin=xx hovered_frame, end=xx hovered_frame, layer=xx hovered_layer });
                            animation_changed = true;
                        }
                    }
                    else if is_layer_bar_hovered
                    {
                        if hovered_layer >= 0
                        {
                            edited_layer_name_index = hovered_layer;
                            just_edited_layer = true;
                        }
                        else
                        {
                            array_add(*animation.layers, .{});
                            edited_layer_name_index = animation.layers.count-1;
                            just_edited_layer = true;
                            animation_changed = true;
                        }
                    }
                    else if is_top_bar_hovered
                    {

                    }
                }

                if !ImGui.IsMouseDown(.Left)
                {
                    is_dragging_frame = false;
                    drag_frame_offset = -1;
                    drag_event_mode = .NONE;
                }
            }

            // Drag
            // Cursor
            current_drag_event_mode: = ifx drag_event_mode != .NONE then drag_event_mode else next_drag_event_mode;
            if current_drag_event_mode ==
            {
                case .LEFT; #through;
                case .RIGHT;
                {
                    ImGui.SetMouseCursor(.ResizeEW);
                }
            }

            // Drag Event
            if drag_event_mode != .NONE && selected_event_index >= 0
            {
                event: = *animation.events[selected_event_index];
                if drag_event_mode ==
                {
                    case .LEFT;
                    {
                        prev_value: = event.begin;
                        event.begin = xx min(clamped_hovered_frame, event.end);
                        animation_changed = animation_changed || prev_value != event.begin;
                    }
                    case .RIGHT;
                    {
                        prev_value: = event.end;
                        event.end = xx max(clamped_hovered_frame, event.begin);
                        animation_changed = animation_changed || prev_value != event.end;
                    }
                    case .CENTER;
                    {
                        prev_begin_value: = event.begin;
                        size: = event.end - event.begin;
                        event.begin = xx clamp(clamped_hovered_frame - drag_frame_offset, 0, animation.frame_count-1 - size);
                        event.end = event.begin + size;

                        prev_layer_value: = event.layer;
                        if hovered_layer >= 0 event.layer = xx hovered_layer;

                        event_moved: = prev_begin_value != event.begin || prev_layer_value != event.layer;
                        if event_moved
                        {
                            e: = <<event;
                            array_ordered_remove_by_index(*animation.events, selected_event_index);
                            array_add(*animation.events, e);
                            selected_event_index = animation.events.count-1;
                            event = *animation.events[selected_event_index];
                        }
                        animation_changed = animation_changed || event_moved;
                    }
                }
            }
            // Drag frame
            else if is_dragging_frame
            {
                animation_player_set_frame(*editor.player, xx clamped_hovered_frame);
            }

            // Keyboard
            if ImGui.IsWindowFocused()
            {
                if ImGui.IsKeyPressed(.Delete)
                {
                    if selected_event_index >= 0
                    {
                        animation_remove_event(animation, selected_event_index);
                        selected_event_index = -1;
                        drag_event_mode = .NONE;
                        drag_frame_offset = -1;
                        animation_changed = true;
                    }
                }
            }

            // Popups
            if ImGui.BeginPopup(EDIT_LAYER_POPUP_NAME)
            {
                defer ImGui.EndPopup();

                if popup_layer_index >= 0
                {
                    if ImGui.MenuItem("Delete Layer")
                    {
                        if selected_event_index >= 0 && animation.events[selected_event_index].layer == popup_layer_index
                        {
                            selected_event_index = -1;
                        }
                        animation_remove_layer(animation, popup_layer_index);
                        animation_changed = true;
                    }
                }

                if ImGui.MenuItem("Add Layer")
                {
                    edited_layer_name_index = animation_add_layer(animation, "");
                    just_edited_layer = true;
                    animation_changed = true;
                }
            }
            else if ImGui.BeginPopup(EDIT_EVENT_POPUP_NAME)
            {
                defer ImGui.EndPopup();

                if popup_event_index >= 0
                {
                    if ImGui.MenuItem("Delete Event")
                    {
                        animation_remove_event(animation, popup_event_index);
                        if selected_event_index > popup_event_index
                        {
                            selected_event_index -= 1;
                        }
                        else
                        {
                            selected_event_index = -1;
                        }
                        animation_changed = true;
                    }
                }
                
                if popup_event_index < 0 && popup_layer_index >= 0 && popup_frame_index >= 0
                {
                    if ImGui.MenuItem("Add Event")
                    {
                        selected_event_index = animation_add_event(animation, .{ begin=xx popup_frame_index, end=xx popup_frame_index, layer=xx popup_layer_index });
                        animation_changed = true;
                    }
                }
            }
            else
            {
                popup_layer_index = -1;
            }

            // Draw
            draw_list: = ImGui.GetWindowDrawList();

            draw_list.AddLine(draw_list, cursor + .{LAYER_WIDTH, 0}, cursor + .{LAYER_WIDTH, content_size.y}, color_strong);
            draw_list.AddLine(draw_list, cursor + .{0, LAYER_HEIGHT}, cursor + .{content_size.x, LAYER_HEIGHT}, color_strong);

            frame_start: = cursor + .{LAYER_WIDTH+1, 0};
            for i: 0..animation.frame_count-1
            {
                frame_pos: = Vector2.{
                    frame_start.x + (FRAME_WIDTH + 1) * i,
                    cursor.y
                };
                draw_list.AddText(draw_list, frame_pos + .{2,2}, WHITE_IDLE, tprint("%", i));
                draw_list.AddLine(draw_list, frame_pos + .{FRAME_WIDTH, 0}, frame_pos + .{FRAME_WIDTH, content_size.y}, color_light);
            }

            for *layer, i: animation.layers
            {
                y: float = xx (TOP_BAR_HEIGHT + 1 + (LAYER_HEIGHT+1) * i);

                if edited_layer_name_index == i
                {
                    ImGui.PushID("layer_name_edit");
                    defer ImGui.PopID();

                    if just_edited_layer
                    {
                        ImGui.SetKeyboardFocusHere(0);
                    }

                    ImGui.SetCursorScreenPos(cursor + .{0,y});
                    ImGui.SetNextItemWidth(LAYER_WIDTH);
                    animation_changed = ImGui_InputText("", *layer.name, .AutoSelectAll) || animation_changed;

                    if (!ImGui.IsItemHovered() && ImGui.IsMouseClicked(.Left)) ||
                        ImGui.IsKeyPressed(.Escape) ||
                        ImGui.IsKeyPressed(.Enter)
                    {
                        edited_layer_name_index = -1;
                    }
                }
                else
                {
                    c: = ifx (is_layer_bar_hovered && hovered_layer == i) then WHITE_HOVERED else WHITE_IDLE;
                    draw_list.AddText(draw_list, cursor + .{0, y + 3}, c, tprint("%", layer.name));
                }
                draw_list.AddLine(draw_list, cursor + .{0, y + LAYER_HEIGHT}, cursor + .{content_size.x, y + LAYER_HEIGHT}, color_light);
            }

            for *event, i: animation.events
            {
                color_set: = get_event_color_set(event);
                c: = color_set.idle;
                if i == hovered_event
                {
                    if ImGui.IsMouseDown(.Left)
                    {
                        c = color_set.selected;
                    }
                    else
                    {
                        c = color_set.hovered;
                    }
                }
                else if i == selected_event_index
                {
                    c = color_set.selected;
                }
                bounds: = cursor + get_event_local_bounds(animation, i);
                draw_list.AddRectFilled(draw_list, bounds.min, bounds.max, IM_COL32(c), 4.0, .RoundCornersAll);
            }

            // Frame cursor
            {
                x: float = xx (LAYER_WIDTH + editor.player.current_frame * (FRAME_WIDTH+1));
                draw_list.AddLine(draw_list, cursor + .{x , 0}, cursor + .{x, content_size.y}, IM_COL32(255,255,0,255));
            }
        }
        ImGui.EndChild();
    }
    ImGui.EndChild();

    // Disable window drag
    if !previous_is_drag_zone_hovered && is_drag_zone_hovered
    {
        editor_push_window_drag_disabled();
    }
    else if previous_is_drag_zone_hovered && !is_drag_zone_hovered
    {
        editor_pop_window_drag_disabled();
    }

    return animation_changed;
}

animation_editor_viewport_update :: (using editor: *AnimationEditor) -> bool
{
    ImGui.PushStyleColor(.ImGuiCol_ChildBg, Vector4.{0,0,0, 0.5});
    ImGui.PushStyleVar(.WindowPadding, xy(2));
    ImGui.PushStyleVar(.ChildRounding, 4);

    animation_changed: = false;
    animation: = editor.player.current_animation;
    viewport_size: = ImGui.GetContentRegionAvail();
    viewport_screen_origin: = ImGui.GetCursorScreenPos();
    viewport_update(*viewport, viewport_size);
    ImGui.Image(viewport.render_target.texture.id, viewport_size);

    if frame_count == 2 // @NOTE(remi): Viewport is all over the place for between 1 and 2 frames when the window first appears
    {
        animation_editor_frame_sprite(editor);
    }

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
        if drag_button_pressed { editor.is_dragging_viewport = true; }
    }

    if !drag_button_down
    {
        editor.is_dragging_viewport = false;
    }

    if editor.is_dragging_viewport
    {
        d: = ImGui.GetMouseDragDelta(DRAG_BUTTON, 0);
        ImGui.ResetMouseDragDelta(DRAG_BUTTON);
        viewport_pan(*editor.viewport, d);
    }

    // Zoom Display
    ImGui.SetCursorPos(.{viewport_size.x - 30, 33});
    if ImGui.BeginChild("zoom", .{}, .AlwaysUseWindowPadding | .AutoResizeX | .AutoResizeY)
    {
        ImGui.Text("%\%", cast(u32)(editor.viewport.zoom.x * 100));
    }
    ImGui.EndChild();

    // Controls
    controls_size: = Vector2.{120, 0};
    ImGui.SetCursorPos(.{(viewport_size.x - controls_size.x) * 0.5 + 9, viewport_size.y - controls_size.y - 10});
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
            animation_player_set_frame(*player, player.current_animation.frame_count - 1);
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

    
    position: Vector2;
    if show_movement
    {
        time: = (player.current_loop_count % xx player.current_animation.preview_loop_count) * animation_duration(player.current_animation);
        time += player.current_time_s;
        position = animation_evaluate_movement(player.current_animation, 0, time);
    }
    animation_player_draw(*player, position);

    if show_boxes
    {
        box_events: = animation_player_get_current_box_events(*player);
        for event: box_events
        {
            draw_outlined_rect(position + event.rect, physics_layer_to_color(event.physics_layer));
        }
    }
}

animation_editor_frame_sprite :: (using editor: *AnimationEditor)
{
    if player.current_animation == null return;

    FRAME_MARGIN :: Vector2.{50, 50};
    bounds: = animation_frame_bounds(player.current_animation, player.current_frame);

    // include potential movement in frame
    movement_bounds: Bounds;
    for event: player.current_animation.events
    {
        if event.type != .MOVEMENT { continue; }
        movement_bounds = expand(movement_bounds, .{event.movement.x_movement, event.movement.y_movement});
    }
    total_movement: = animation_evaluate_movement(player.current_animation, 0, player.current_animation.frame_count) * cast(float)(player.current_animation.preview_loop_count);
    movement_bounds = expand(movement_bounds, total_movement);

    bounds.min -= movement_bounds.min;
    bounds.max += movement_bounds.max;

    sprite_size: = size(bounds);

    if length_squared(sprite_size) < 0.0001 return;

    viewport_align_points(*editor.viewport, FRAME_MARGIN, .{bounds.min.x, bounds.max.y}, editor.viewport.size - FRAME_MARGIN, .{bounds.max.x, bounds.min.y}, true);
    zoom: float = min(editor.viewport.zoom.x, editor.viewport.zoom.y);
    editor.viewport.zoom = xy(zoom - fmod_cycling(zoom, ZOOM_STEP));
}

get_event_color_set :: (event: *AnimationEvent) -> ButtonColorSet
{
    if event == null return .{};

    if event.type ==
    {
        case .NONE; return make_button_color_set(rl.GRAY);
        case .SPRITE; return make_button_color_set(.{101, 171, 184, 255});
        case .MOVEMENT; return make_button_color_set(.{190, 151, 196, 255});
        case .BOX; return make_button_color_set(.{186, 212, 95, 255});
        case;
        {
            name: = enum_value_to_name(event.type);
            return make_button_color_set(string_to_color(name, value_range = .[0.6, 0.7]));
        }
    }
}

rl :: #import "raylib";
