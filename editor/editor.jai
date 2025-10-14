Editor :: struct
{
    resources_open: bool; @serialize
    imgui_demo_open: bool; @serialize
    imgui_font_open: bool; @serialize
    display_colliders: bool; @serialize

    edited_resources: [..]ResourceEditor; @serialize

    window_drag_disabled_count: s32 = 0;
}

editor_init :: ()
{
    using yae.editor;
}

editor_shutdown :: ()
{
    using yae.editor;

    for *resource_editor: edited_resources
    {
        resource_editor_shutdown(resource_editor);
    }

}

editor_register_settings_section :: ()
{
    using yae.editor;

    register_settings_section("editor", *yae.editor,
    (data: *void)
    {
        using t: *Editor = xx data;
        for *resource_editor: edited_resources
        {
            resource_editor_shutdown(resource_editor);
        }
    },
    (data: *void)
    {
        using t: *Editor = xx data;
        for *resource_editor: edited_resources
        {
            resource_editor_init(resource_editor);
        }
    });
}

editor_unregister_settings_section :: ()
{
    using yae.editor;

    unregister_settings_section("editor");
}

editor_update :: (dt: float)
{
    using yae.editor;

    if ImGui.IsKeyChordPressed(xx(ImGui.Key.ImGuiMod_Ctrl | ImGui.Key.ImGuiKey_Z))
    {
        undo();
    }
    if ImGui.IsKeyChordPressed(xx(ImGui.Key.ImGuiMod_Ctrl | ImGui.Key.ImGuiKey_Y))
    {
        redo();
    }

    if (imgui_demo_open)
    {
        ImGui.ShowDemoWindow(*imgui_demo_open);
    }

    if (imgui_font_open)
    {
        font_atlas: = ImGui.GetIO().Fonts;
        atlas_size: = ImGui.ImVec2.{xx font_atlas.TexWidth, xx font_atlas.TexHeight};

        ImGui.SetNextWindowContentSize(atlas_size);
        if ImGui.Begin("ImGui Font", null, /*.NoResize |*/ .NoTitleBar | .NoScrollbar| .NoScrollWithMouse)
        {
            ImGui.Image(font_atlas.TexID, atlas_size);
        }
        ImGui.End();
    }

    if ImGui.BeginMainMenuBar()
    {
        if ImGui.BeginMenu("Windows")
        {
            ImGui.MenuItem("Resources", "", *resources_open);
            ImGui.MenuItem("ImGui Demo", "", *imgui_demo_open);
            ImGui.MenuItem("ImGui Font", "", *imgui_font_open);

            ImGui.EndMenu();
        }

        if ImGui.BeginMenu("Edit")
        {
            {
                is_valid, command: = get_next_undo();
                if ImGui.MenuItem(temp_c_string(tprint("Undo %", command.name)), "ctrl+Z", enabled=is_valid)
                {
                    undo();
                }
            }
            
            {
                is_valid, command: = get_next_redo();
                if ImGui.MenuItem(temp_c_string(tprint("Redo %", command.name)), "ctrl+Y", enabled=is_valid)
                {
                    redo();
                }
            }

            ImGui.EndMenu();
        }

        if ImGui.BeginMenu("Debug")
        {
            ImGui.MenuItem("Display Colliders", "", *display_colliders);

            ImGui.EndMenu();
        }

        // FPS Counter
        {
            window_size: = ImGui.GetWindowSize();
            fps_text: = tprint("% FPS", round_to_s32(1 / dt));
            fps_text_size: = ImGui.CalcTextSize(fps_text);
            ImGui.SetCursorScreenPos(.{window_size.x - fps_text_size.x - 5, 0});
            ImGui.TextColored(.{1,1,1,0.6}, fps_text);
        }
    }
    ImGui.EndMainMenuBar();

    prev_resources_open: = resources_open;
    if resources_open
    {
        ImGui.SetNextWindowSize(.{500, 300}, .FirstUseEver);
        if ImGui.Begin("Resources", *resources_open)
        {
            resource_browser_update();
        }
        ImGui.End();
    }

    for < resource_editor, i: edited_resources
    {
        if !resource_editor.is_open || resource_editor.resource == null
        {
            editor_close_resource(i);
            continue;
        }

        if resource_editor_update(*resource_editor, dt)
        {
            resource_save_to_disk(resource_editor.resource);
        }
    }
}

editor_draw :: ()
{
    using yae.editor;

    if display_colliders
    {
        physics_draw_colliders();
    }
}

// @NOTE(remi): This pointer comes from a linear array. Do not store it
editor_get_resource_editor :: (resource: *Resource)-> *ResourceEditor
{
    using yae.editor;

    success, index: = array_find(
        edited_resources,
        (item: ResourceEditor, user_data: *void) -> bool { return item.resource == user_data; },
        resource
    );
    if !success return null;
    return *edited_resources[index];
}

editor_open_resource :: (resource: *Resource)
{
    using yae.editor;

    resource_editor_ptr: = editor_get_resource_editor(resource);
    if resource_editor_ptr == null
    {
        resource_editor: ResourceEditor = .{ resource = resource };
        resource_editor_init(*resource_editor);
        array_add(*edited_resources, resource_editor);
        resource_editor_ptr = array_back(edited_resources);
    }

    resource_editor_ptr.is_open = true;

    resource_window_name: = temp_c_string(get_editor_window_name(resource_editor_ptr));
    ImGui.SetWindowCollapsed(resource_window_name, false);
    ImGui.SetWindowFocus(resource_window_name);
}

editor_close_resource :: (resource: *Resource)
{
    using yae.editor;
    
    found, i: = array_find(
        edited_resources,
        (item: ResourceEditor, user_data: *void) -> bool { return item.resource == user_data; },
        resource
    );
    if !found return;

    editor_close_resource(i);
}

editor_close_resource :: (index: s64)
{
    using yae.editor;
    resource_editor: = *edited_resources[index];

    resource_editor_clear_window_settings(resource_editor);
    resource_editor_shutdown(resource_editor);
    array_ordered_remove_by_index(*edited_resources, index);
}

editor_push_window_drag_disabled :: ()
{
    using yae.editor;

    if window_drag_disabled_count == 0
    {
        ImGui.GetIO().ConfigWindowsMoveFromTitleBarOnly = true;
    }
    window_drag_disabled_count += 1;
}

editor_pop_window_drag_disabled :: ()
{
    using yae.editor;

    window_drag_disabled_count -= 1;
    if window_drag_disabled_count == 0
    {
        ImGui.GetIO().ConfigWindowsMoveFromTitleBarOnly = false;
    }
}