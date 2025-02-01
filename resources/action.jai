Action :: struct
{
    #as using base: Resource;
    type = Action;

    duration: int; // in frames

    Layer :: struct
    {
        name: string;
        // keys: [..]Key;
    }
    
}

ActionManager :: struct
{
    actions: [..]*Action;
}
g_action_manager : ActionManager;
action_manager :: () -> *ActionManager { return *g_action_manager; }

gather_actions :: (path: string)
{
    using manager: = action_manager();
    visit_files(path, true, manager,
        (info: *File_Visit_Info, manager: *ActionManager)
        {
            if path_extension(info.short_name) == "action"
            {
                action: = resource_get(Action, info.full_name);
                array_add(*manager.actions, action);
            }
        }
    );
}

ActionEditor :: struct
{
    selected_action: *Action;
}
g_action_editor: ActionEditor;

actions_editor :: ()
{
    using g_action_editor;

    if ImGui.BeginChild("LeftList", .{200, 0}, child_flags = .Borders|.ResizeX)
    {
        actions: = get_resources(Action);
        for action: actions
        {
            if ImGui.Selectable(temp_c_string(action.name), selected_action == action)
            {
                selected_action = action;
            }
        }
    }
    ImGui.EndChild();
    ImGui.SameLine();

    if ImGui.BeginChild("RightDisplay")
    {
        if action_editor()
        {
            // save action
        }
    }
    ImGui.EndChild();
}

action_editor :: () -> bool
{
    using g_action_editor;
    if selected_action == null { return false; }

    edited: = false;



    return edited;
}

#scope_file
#import "File_Utilities";

ImGui :: #import "ImGui";