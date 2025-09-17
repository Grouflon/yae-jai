RESOURCE_EDIT_BUFFER_TIME :: 0.3;

ResourceEditor :: struct
{
    resource: *Resource; @serialize
    is_open: bool; @serialize

    payload: *void;

    last_modification_time: float64 = -1;
    cached_before_modification_data: string;
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
    free(resource_editor.cached_before_modification_data);
}

resource_editor_clear_window_settings :: (resource_editor: *ResourceEditor)
{
    ImGui.ClearWindowSettings(temp_c_string(get_editor_window_name(resource_editor)));
}

resource_editor_update :: (resource_editor: *ResourceEditor, dt: float) -> bool
{
    assert(resource_editor != null);
    if resource_editor.resource == null return false;

    if resource_editor.cached_before_modification_data.count == 0
    {
        serializer: JsonSerializer;
        serializer_begin(*serializer, .WRITE);
        resource_serialize(*serializer, resource_editor.resource);
        serializer_end(*serializer);
        resource_editor.cached_before_modification_data = json_serializer_get_json_string(*serializer, context.default_allocator);
    }

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

    if modified
    {
        resource_editor.last_modification_time = get_time();
    }

    validate_modification: = false;
    if resource_editor.last_modification_time >= 0 && (get_time() - resource_editor.last_modification_time) >= RESOURCE_EDIT_BUFFER_TIME
    {
        resource_editor.last_modification_time = -1.0;

        serializer: JsonSerializer;
        serializer_begin(*serializer, .WRITE);
        resource_serialize(*serializer, resource_editor.resource);
        serializer_end(*serializer);
        after_modification_data: = json_serializer_get_json_string(*serializer, context.default_allocator);

        add_data_change_command(
            resource_editor.resource,
            resource_editor.resource.type,
            resource_editor.cached_before_modification_data,
            after_modification_data,
            (data_ptr: *void)
            {
                resource: *Resource = xx data_ptr;
                resource_editor: = editor_get_resource_editor(resource);
                resource_editor_clear_cache(resource_editor);
                resource_save_to_disk(resource);
            }
        );
        free(resource_editor.cached_before_modification_data);
        resource_editor.cached_before_modification_data = after_modification_data;
        validate_modification = true;
    }

    return validate_modification;
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

resource_editor_clear_cache :: (resource_editor: *ResourceEditor)
{
    free(resource_editor.cached_before_modification_data);
    resource_editor.cached_before_modification_data = "";
}
