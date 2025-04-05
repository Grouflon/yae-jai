Editor :: struct @serialize_optin
{
    resources_open: bool; @serialize
    imgui_demo_open: bool; @serialize
    imgui_font_open: bool; @serialize

    animation_editor_open: bool; @serialize
    animation_editor: AnimationEditor;
}

editor_init :: (using editor: *Editor)
{

}

editor_shutdown :: (using editor: *Editor)
{

}

editor_update :: (using editor: *Editor, dt: float)
{
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
            ImGui.MenuItem("Animation Editor", "", *animation_editor_open);
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

    if animation_editor_open
    {
        if ImGui.Begin("Animation Editor", *animation_editor_open)
        {
            animation_editor_update(*animation_editor, dt);
        }
        ImGui.End();
    }
}