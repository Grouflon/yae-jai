AnimationEditor :: struct
{
    player: AnimationPlayer;
    viewport: ViewportBase;

    is_dragging_viewport: = false;
    is_dragging_frame: = false;

    is_drag_zone_hovered: = false;

    edited_layer_name_index: s64 = -1;
    layer_popup_index: s64 = -1;

    selected_event_index: s32 = -1;
    event_popup_layer: s32 = -1;
    event_popup_frame: s32 = -1;

    default_resource_editor: bool = false;

    frame_count: = -1;
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
        ImGui.SetNextItemWidth(100.0);
        animation_modified = ImGui_EditValue("frames per second", *animation.frames_per_second) || animation_modified;
    }

    return animation_modified;
}

animation_editor_timeline_update :: (using editor: *AnimationEditor) -> bool
{
    animation_changed: = false;
    animation: = editor.player.current_animation;
    assert(animation != null);
    // CELL_WIDTH :: 24;
    // CELL_HEIGHT :: 17;
    // COLUMN_WIDTH :: CELL_WIDTH - 9;
    TOP_BAR_HEIGHT :: 17;
    LAYER_HEIGHT :: 18;
    LAYER_WIDTH :: 150;
    FRAME_WIDTH :: 30;
    EDIT_LAYER_POPUP_NAME :: "edit_layer";

    WHITE_IDLE : u32 : 0xffaaaaaa;
    WHITE_HOVERED : u32 : 0xffffffff;

    TEAL_IDLE : u32 : 0xffb0c445;
    TEAL_SELECTED : u32 : 0xffa3eb9a;
    TEAL_HOVERED : u32 : 0xffbafdda;

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
            max(available_size.y, xx (TOP_BAR_HEIGHT + 1 + (LAYER_HEIGHT + 1) * animation.layers.count))
        };

        // ImGui.PushStyleColor(.ChildBg, .{1,0,0,1});
        // defer ImGui.PopStyleColor();

        if ImGui.BeginChild("timeline_content", content_size, 0, .NoScrollbar)
        {
            cursor: = ImGui.GetCursorScreenPos();
            mouse_position: = ImGui.GetMousePos();

            hovered_layer: = -1;
            just_edited_layer: = false;
            hovered_event: = -1;
            hovered_frame: = -1;

            is_drag_zone_hovered = ImGui.IsWindowHovered(); // @NOTE(remi): maybe reduce zone to layer & frames

            // Mouse Input
            // Layers
            if is_drag_zone_hovered && ImGui.IsMouseHoveringRect(cursor + .{0, TOP_BAR_HEIGHT}, cursor + .{LAYER_WIDTH, content_size.y})
            {
                for i: 0..animation.layers.count-1
                {
                    y: float = xx (TOP_BAR_HEIGHT+1 + i * (LAYER_HEIGHT+1));
                    if ImGui.IsMouseHoveringRect(cursor + .{0, y}, cursor + .{LAYER_WIDTH, y + LAYER_HEIGHT+1})
                    {
                        hovered_layer = i;
                        break;
                    }
                }

                if hovered_layer >= 0
                {
                    if ImGui.IsMouseDoubleClicked(.Left)
                    {
                        edited_layer_name_index = hovered_layer;
                        just_edited_layer = true;
                    }
                }

                if hovered_layer != edited_layer_name_index && ImGui.IsMouseClicked(.Left)
                {
                    edited_layer_name_index = -1;
                }

                if ImGui.IsMouseClicked(.Right)
                {
                    layer_popup_index = hovered_layer;
                    ImGui.OpenPopup(EDIT_LAYER_POPUP_NAME);
                }
            }
            // Events
            for i: 0..animation.events.count-1
            {
                bounds: = cursor + get_event_local_bounds(animation, i);
                if ImGui.IsMouseHoveringRect(bounds.min, bounds.max)
                {
                    hovered_event = i;
                    if ImGui.IsMouseClicked(.Left)
                    {
                        selected_event_index = xx i;
                    }
                }
            }
            if hovered_event < 0 && ImGui.IsMouseHoveringRect(cursor + .{LAYER_WIDTH+1, TOP_BAR_HEIGHT+1}, cursor + available_size) && ImGui.IsMouseClicked(.Left)
            {
                selected_event_index = -1;
            }
            // Frames
            if ImGui.IsMouseHoveringRect(cursor + Vector2.{LAYER_WIDTH+1, 0}, cursor + Vector2.{xx (LAYER_WIDTH+1 + (animation.frame_count) * (FRAME_WIDTH+1)), TOP_BAR_HEIGHT})
            {
                if ImGui.IsMouseClicked(.Left)
                {
                    is_dragging_frame = true;
                }
            }
            {
                local_mouse_pos: = mouse_position - cursor;
                hovered_frame = floor_to_s32((local_mouse_pos.x - LAYER_WIDTH) / (FRAME_WIDTH + 1));
            }
            if !ImGui.IsMouseDown(.Left)
            {
                is_dragging_frame = false;
            }

            if is_dragging_frame
            {
                clamped_frame: = clamp(hovered_frame, 0, animation.frame_count-1);
                animation_player_set_frame(*editor.player, xx clamped_frame);
            }

            if ImGui.BeginPopup(EDIT_LAYER_POPUP_NAME)
            {
                defer ImGui.EndPopup();

                if layer_popup_index >= 0
                {
                    if ImGui.MenuItem("Delete Layer")
                    {
                        array_ordered_remove_by_index(*animation.layers, layer_popup_index);
                        animation_changed = true;
                    }
                }

                if ImGui.MenuItem("Add Layer")
                {
                    array_add(*animation.layers, .{});
                    edited_layer_name_index = animation.layers.count-1;
                    just_edited_layer = true;
                    animation_changed = true;
                }
            }
            else
            {
                layer_popup_index = -1;
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
                y: float = xx (TOP_BAR_HEIGHT + 1 + LAYER_HEIGHT * i);

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
                    c: = ifx hovered_layer == i then WHITE_HOVERED else WHITE_IDLE;
                    draw_list.AddText(draw_list, cursor + .{0, y + 3}, c, tprint("%", layer.name));
                }
                draw_list.AddLine(draw_list, cursor + .{0, y + LAYER_HEIGHT}, cursor + .{content_size.x, y + LAYER_HEIGHT}, color_light);
            }

            for *event, i: animation.events
            {
                c: = TEAL_IDLE;
                if i == hovered_event
                {
                    if ImGui.IsMouseDown(.Left)
                    {
                        c = TEAL_SELECTED;
                    }
                    else
                    {
                        c = TEAL_HOVERED;
                    }
                }
                else if i == selected_event_index
                {
                    c = TEAL_SELECTED;
                }
                bounds: = cursor + get_event_local_bounds(animation, i);
                draw_list.AddRectFilled(draw_list, bounds.min, bounds.max, c, 2.0, .RoundCornersAll);
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

    timeline_frame_origin: Vector2;
    timeline_frame_begin: Vector2;
    // timeline_frame_end: Vector2 = ImGui.GetCursorScreenPos() + ImGui.GetContentRegionAvail() + .{-1,-1};
    timeline_frame_end: Vector2 = ImGui.GetCursorScreenPos() + ImGui.GetContentRegionAvail();

    // table_flags: ImGui.TableFlags = .ScrollX | .ScrollY | .BordersV | .BordersOuterV | .BordersH | .Resizable | .RowBg;
    // column_count: s32 = frame_count + 3;
    // if ImGui.BeginTable("timeline", xx column_count, table_flags, .{0, 0})
    {
        // defer ImGui.EndTable();

        // ImGui.TableSetupColumn("Tracks", .NoHide | .NoReorder | .WidthFixed, 100.0);

        // column_flags: ImGui.TableColumnFlags = .WidthFixed | .NoResize | .NoReorder | .NoHide;
        // for i: 0..frame_count-1
        // {
        //     ImGui.TableSetupColumn(temp_c_string(tprint("%", i)), column_flags, COLUMN_WIDTH);
        // }
        // ImGui.TableSetupColumn("E", column_flags, COLUMN_WIDTH);
        // ImGui.TableSetupColumn("", column_flags, COLUMN_WIDTH);

        // ImGui.TableSetupScrollFreeze(1, 1);

        // ImGui.TableNextRow(.Headers);
        // for i: 0..(column_count-1)
        // {
        //     name: = ImGui.TableGetColumnName(xx i);
        //     ImGui.TableSetColumnIndex(xx i);

        //     if i == 0
        //     {
        //         timeline_frame_begin = ImGui.GetCursorScreenPos() + .{ImGui.GetContentRegionAvail().x + 5, -1};
        //     }
        //     else
        //     {
        //         size: = ImGui.CalcTextSize(name);
        //         ImGui.SameLine(COLUMN_WIDTH - size.x);
        //     }
            
        //     ImGui.TableHeader(name);
        // }

        // layer_to_delete: s32 = -1;
        // for layer, i: animation.layers
        // {
        //     ImGui.PushID(cast(s32) i);
        //     defer ImGui.PopID();

        //     ImGui.TableNextRow();
        //     ImGui.TableSetColumnIndex(0);

        //     // Layer Name
        //     if edited_layer_name_index == i
        //     {
        //         if focus_requested
        //         {
        //             focus_requested = false;
        //             ImGui.SetKeyboardFocusHere(0);
        //         }

        //         ImGui.SetNextItemWidth(ImGui.GetContentRegionAvail().x);
        //         if ImGui.InputText("", *layer.name, .AutoSelectAll)
        //         {
        //             animation_changed = true;
        //         }

        //         // Edit exit
        //         if (!ImGui.IsItemHovered() && ImGui.IsMouseClicked(.Left)) ||
        //             ImGui.IsKeyPressed(.Escape) ||
        //             ImGui.IsKeyPressed(.Enter)
        //         {
        //             edited_layer_name_index = -1;
        //         }
        //     }
        //     else
        //     {
        //         ImGui.Selectable(temp_c_string(layer.name));

        //         // Edit enter
        //         if ImGui.IsItemHovered() && ImGui.IsMouseDoubleClicked(.Left)
        //         {
        //             edited_layer_name_index = xx i;
        //             focus_requested = true;
        //         }
        //     }

        //     // Layer Context menu
        //     if ImGui.BeginPopupContextItem()
        //     {
        //         if ImGui.MenuItem("Delete layer")
        //         {
        //             layer_to_delete = xx i;
        //             if edited_layer_name_index == i
        //             {
        //                 edited_layer_name_index = -1;
        //             }
        //             else if edited_layer_name_index > i
        //             {
        //                 edited_layer_name_index -= 1;
        //             }
        //         }

        //         ImGui.EndPopup();
        //     }

        //     if i == 0
        //     {
        //         ImGui.TableSetColumnIndex(1);
        //         timeline_frame_origin = ImGui.GetCursorScreenPos() + .{-4, -1};
        //     }
        // }
        // if layer_to_delete >= 0
        // {
        //     animation_remove_layer(animation, layer_to_delete);
        //     animation_changed = true;
        // }

        // ImGui.TableNextRow();
        // ImGui.TableSetColumnIndex(0);
        // if ImGui.Button("New Layer", .{ImGui.GetContentRegionAvail().x, 0})
        // {
        //     animation_add_layer(animation, tprint("layer %", animation.layers.count));
        //     animation_changed = true;
        // }

        // // Frames section
        // if ImGui.GetScrollMaxX() > 0 timeline_frame_end.y -= 12;
        // if ImGui.GetScrollMaxY() > 0 timeline_frame_end.x -= 12;
        // draw_list: = ImGui.GetWindowDrawList();

        // // Draw frame line
        // draw_list.PushClipRect(draw_list, timeline_frame_begin, timeline_frame_end);
        // if editor.player.current_frame >= 0
        // {
        //     line_x: = (editor.player.current_frame + 1) * CELL_WIDTH - 1;
        //     draw_list.AddLine(draw_list, .{timeline_frame_origin.x + line_x, timeline_frame_origin.y - (CELL_HEIGHT+1)}, .{timeline_frame_origin.x + line_x, timeline_frame_end.y}, 0xff00ffff);
        // }

        // // Draw events
        // draw_list.PushClipRect(draw_list, timeline_frame_begin + .{0, CELL_HEIGHT}, timeline_frame_end);
        // // draw_list.AddRect(draw_list, timeline_frame_begin, timeline_frame_end, 0xFF0000FF); // debug: see clipping rect
        // clicked_on_something: = false;
        // for event, event_i: animation.events
        // {
        //     DIAMOND_RADIUS :: 5;
        //     center: Vector2 = timeline_frame_origin + Vector2.{ cast(float)(event.begin+1) * CELL_WIDTH, (CELL_HEIGHT * 0.5) + cast(float)event.layer_index * CELL_HEIGHT };
        //     color: u32 = 0xffe0873d;

        //     if ImGui.IsWindowHovered() && length(ImGui.GetMousePos() - center) <= DIAMOND_RADIUS
        //     {
        //         color = 0xffffb679;

        //         if ImGui.IsMouseClicked(.Left)
        //         {
        //             selected_event_index = xx event_i;
        //             clicked_on_something = true;
        //         }
        //     }

        //     draw_list.AddNgonFilled(draw_list, center, DIAMOND_RADIUS, color, 4);
        //     if selected_event_index == event_i
        //     {
        //         draw_list.AddNgon(draw_list, center, DIAMOND_RADIUS+1, 0xffffb679, 4);
        //     }
        // }

        // // Clicks on timeline
        // // @NOTE(remi): Should probably move above events drawing, so that we dont mix up logic and drawing like now
        // previous_is_drag_zone_hovered: = is_drag_zone_hovered;
        // is_drag_zone_hovered = ImGui.IsWindowHovered() && ImGui.IsMouseHoveringRect(timeline_frame_begin, timeline_frame_end, false);
        // if is_drag_zone_hovered
        // {
        //     relative_mouse_pos: = ImGui.GetMousePos() - timeline_frame_origin;
        //     hovered_frame: = cast(s32) round(relative_mouse_pos.x / CELL_WIDTH) - 1;
        //     hovered_layer: = cast(s32) floor(relative_mouse_pos.y / CELL_HEIGHT);
        //     is_valid_cell: = hovered_frame >= 0 && hovered_frame < xx animation.frame_count && hovered_layer >= 0 && hovered_layer < animation.layers.count;

        //     ImGui.GetIO().ConfigWindowsMoveFromTitleBarOnly = true;

        //     // Clear event
        //     if ImGui.IsMouseClicked(.Left) && !clicked_on_something
        //     {
        //         selected_event_index = -1;
        //     }

        //     // Hover events
        //     EVENT_POPUP_NAME :: "frame event";
        //     if is_valid_cell && ImGui.IsMouseClicked(.Right)
        //     {
        //         event_popup_frame = hovered_frame;
        //         event_popup_layer = hovered_layer;
        //         ImGui.OpenPopup(EVENT_POPUP_NAME);
        //     }

        //     // Drag event
        //     if is_valid_cell && selected_event_index >= 0 && ImGui.IsMouseDragging(.Left)
        //     {
        //         animation.events[selected_event_index].layer_index = hovered_layer;
        //         animation.events[selected_event_index].begin = hovered_frame;
        //     }

        //     // Pick Frame
        //     if selected_event_index < 0 && ImGui.IsMouseDown(.Left)
        //     {
        //         frame: = clamp(hovered_frame, 0, animation.frame_count-1);
        //         animation_player_stop(*editor.player);
        //         animation_player_set_frame(*editor.player, frame);
        //     }
        // }

        // // Disable window drag
        // if !previous_is_drag_zone_hovered && is_drag_zone_hovered
        // {
        //     editor_push_window_drag_disabled();
        // }
        // else if previous_is_drag_zone_hovered && !is_drag_zone_hovered
        // {
        //     editor_pop_window_drag_disabled();
        // }

        // // Event popup
        // if ImGui.BeginPopup("frame event")
        // {
        //     if ImGui.BeginMenu("Add Event")
        //     {
        //         enum_info: = cast(*Type_Info_Enum) type_info(AnimationEventType);

        //         for value: enum_info.values
        //         {
        //             if value == xx AnimationEventType.NONE continue;

        //             if ImGui.MenuItem(temp_c_string(enum_value_to_name(cast(AnimationEventType) value)))
        //             {
        //                 animation_add_event(animation, .{ type = .SPRITE, layer_index = xx event_popup_layer, begin = xx event_popup_frame });
        //                 animation_changed = true;
        //             }
        //         }
        //         ImGui.EndMenu();
        //     }

        //     ImGui.EndPopup();
        // }

        // // Keyboard shortcuts
        // if selected_event_index >= 0 && ImGui.IsWindowFocused() && ImGui.IsKeyPressed(.Delete)
        // {
        //     animation_remove_event(animation, selected_event_index);
        //     selected_event_index = -1;
        //     animation_changed = true;
        // }
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

    animation_player_draw(*player, .{});
}

animation_editor_frame_sprite :: (using editor: *AnimationEditor)
{
    FRAME_MARGIN :: Vector2.{50, 50};
    bounds: = animation_frame_bounds(player.current_animation, player.current_frame);
    sprite_size: = size(bounds);

    if length_squared(sprite_size) < 0.0001 return;

    viewport_align_points(*editor.viewport, FRAME_MARGIN, .{bounds.min.x, bounds.max.y}, editor.viewport.size - FRAME_MARGIN, .{bounds.max.x, bounds.min.y}, true);
    zoom: float = min(editor.viewport.zoom.x, editor.viewport.zoom.y);
    editor.viewport.zoom = xy(zoom - fmod_cycling(zoom, ZOOM_STEP));
}

rl :: #import "raylib";
