Editor :: struct @serialize_optin
{
    resources_open: bool; @serialize
    imgui_demo_open: bool; @serialize
    imgui_font_open: bool; @serialize

    edited_resources: [..]ResourceEditor; @serialize
}

editor_init :: ()
{
    using YAE.editor;

    for *resource_editor: edited_resources
    {
        resource_editor_init(resource_editor);
    }
}

editor_shutdown :: ()
{
    using YAE.editor;

    for *resource_editor: edited_resources
    {
        resource_editor_shutdown(resource_editor);
    }
}

editor_update :: (dt: float)
{
    using YAE.editor;

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
    }
    ImGui.EndMainMenuBar();

    prev_resources_open: = resources_open;
    if resources_open
    {
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

        resource_editor_update(*resource_editor, dt);
    }
}

editor_open_resource :: (resource: *Resource)
{
    using YAE.editor;

    if array_find(
        edited_resources,
        (item: ResourceEditor, user_data: *void) -> bool { return item.resource == user_data; },
        resource
    ) return;

    resource_editor: ResourceEditor = .{ resource = resource, is_open = true };
    resource_editor_init(*resource_editor);

    array_add(*edited_resources, resource_editor);
}

editor_close_resource :: (resource: *Resource)
{
    using YAE.editor;
    
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
    using YAE.editor;
    resource_editor: = *edited_resources[index];

    resource_editor_clear_window_settings(resource_editor);
    resource_editor_shutdown(resource_editor);
    array_ordered_remove_by_index(*edited_resources, index);
}