ResourceEditor :: struct
{
    resource: *Resource; @serialize
    payload: *void;
    is_open: bool; @serialize
}

resource_editor_init :: (resource_editor: *ResourceEditor)
{
    assert(resource_editor != null);
    if resource_editor.resource == null return;

    if resource_editor.resource.type ==
    {
        case type_info(Animation); animation_editor_init(resource_editor);
        case type_info(AsepriteFile); aseprite_file_editor_init(resource_editor);
        case type_info(TextureFile); texture_file_editor_init(resource_editor);
    }
}

resource_editor_shutdown :: (resource_editor: *ResourceEditor)
{
    assert(resource_editor != null);
    if resource_editor.resource == null return;

    if resource_editor.resource.type ==
    {
        case type_info(Animation); animation_editor_shutdown(resource_editor);
        case type_info(AsepriteFile); aseprite_file_editor_shutdown(resource_editor);
        case type_info(TextureFile); texture_file_editor_shutdown(resource_editor);
    }
}

resource_editor_clear_window_settings :: (resource_editor: *ResourceEditor)
{
    ImGui.ClearWindowSettings(temp_c_string(get_editor_window_name(resource_editor)));
}

resource_editor_update :: (resource_editor: *ResourceEditor, dt: float) -> bool
{
    assert(resource_editor != null);
    if resource_editor.resource == null return false;

    modified: = false;
    ImGui.SetNextWindowSize(.{700, 500}, .FirstUseEver);
    if ImGui.Begin(temp_c_string(get_editor_window_name(resource_editor)), *resource_editor.is_open, .MenuBar)
    {
        ImGui.PushID(resource_editor.resource);
        defer ImGui.PopID();

        if resource_editor.resource.type ==
        {
            case type_info(Animation); modified = animation_editor_update(resource_editor, dt);
            case type_info(AsepriteFile); modified = aseprite_file_editor_update(resource_editor, dt);
            case type_info(TextureFile); modified = texture_file_editor_update(resource_editor, dt);
            
            case; modified = default_resource_editor_update(resource_editor, dt);
        }
    }
    ImGui.End();
    return modified;
}

default_resource_editor_update :: (resource_editor: *ResourceEditor, dt: float) -> bool
{
    assert(resource_editor != null);
    assert(resource_editor.resource != null);

    return ImGui_EditStructMembers(resource_editor.resource, resource_editor.resource.type);
}

#scope_file

get_editor_window_name :: (resource_editor: *ResourceEditor) -> string
{
    if resource_editor == null return "";
    if resource_editor.resource == null return "";

    return tprint("%: %", resource_editor.resource.type.name, resource_editor.resource.name);
}
