ResourceManager :: struct
{
    resources: [..]*Resource;
    resource_by_name: Table(StringHash, *Resource);
    resource_by_path: Table(StringHash, *Resource);
    resources_by_type: Table(*Type_Info_Struct, [..]*Resource);

    file_dependencies: Table(StringHash, [..]*Resource);
    resources_to_reload: Table(*Resource, u8); // just a hashset

    #if FILE_WATCH_SUPPORTED
    {
        watcher: File_Watcher;
    }
}
resource_manager: ResourceManager;

resource_manager_init :: (resource_types: []*Type_Info_Struct)
{
    using resource_manager;

    #if FILE_WATCH_SUPPORTED
    {
        // File watch
        on_file_modified :: (watcher: *File_Watcher(void), change: *File_Change, user_data: *void)
        {
            if change.events != .MODIFIED { return; }
            path: = normalize_path(change.full_path);

            resources: = table_find_pointer(*resource_manager.file_dependencies, string_hash(path));
            if resources == null { return; }

            for resource: <<resources
            {
                table_set(*resource_manager.resources_to_reload, resource, 0);
            }
        }
        if !init(*watcher, on_file_modified, events_to_watch = .MODIFIED)
        {
            log_error("Could not initialize watcher", section= *RESOURCE_LOG_SECTION);
        }
        resource_folders: []string = .["data"];
        if !add_directories(*watcher, ..resource_folders)
        {
            log_error("Could not watch directories %", resource_folders, section= *RESOURCE_LOG_SECTION);
        }
    }
}

resource_manager_shutdown :: ()
{
    using resource_manager;

    #if FILE_WATCH_SUPPORTED
    {
        deinit(*watcher);
    }

    for resource: resources
    {
        assert(resource.load_count == 0);
    }
    array_reset(*resources);

    table_reset_and_free(*resource_by_name);
    table_reset_and_free(*resource_by_path);

    for resources: resources_by_type
    {
        array_free(resources);
    }
    table_reset_and_free(*resources_by_type);

    for resources: file_dependencies
    {
        array_free(resources);
    }
    table_reset_and_free(*file_dependencies);

    table_reset_and_free(*resources_to_reload);
}

register_resource :: (resource: *Resource)
{
    using resource_manager;

    assert(resource != null);
    assert(resource.type != null);

    assert(array_find(resources, resource) == false);
    array_add(*resources, resource);

    if resource.name.count > 0
    {
        name_hash: = string_hash(resource.name);
        assert(table_contains(*resource_by_name, name_hash) == false);
        table_add(*resource_by_name, name_hash, resource);
    }

    if resource.path.count > 0
    {
        path_hash: = string_hash(normalize_path(resource.path));
        assert(table_contains(*resource_by_path, path_hash) == false);
        table_add(*resource_by_path, path_hash, resource);
    }

    info: = resource.type;
    while info != null
    {
        type_array: = find_or_add(*resources_by_type, info);
        array_add(type_array, resource);

        t: = get_parent_type(info);
        info = ifx t == null || t.type != .STRUCT then null else cast(*Type_Info_Struct) t;
    }

    // Add filewatch
}

// Unregistering is unused and untested so far
unregister_resource :: (resource: *Resource)
{
    using resource_manager;

    assert(resource != null);
    assert(resource.type != null);
    assert(array_find(*resources, resource) == true);

    name_hash: = string_hash(resource.name);
    assert(table_contains(*resource_by_name, name_hash) == true);
    
    type_array: = table_find_pointer(*resources_by_type, resource.type);
    assert(type_array != null);
    array_unordered_remove_by_value(*type_array, resource);

    table_remove(*resource_by_name, name_hash);
    array_unordered_remove_by_value(*resources, resource);
}

register_resources :: (resources: *$T)
{
    ti: = type_info(T);
    if ti.type != .STRUCT return;
    info: *Type_Info_Struct = xx ti;

    for member: info.members
    {
        if !is_subclass_of(member.type, Resource) continue;
        member_info: *Type_Info_Struct = xx member.type;
        resource: *Resource = xx ((cast(*void)resources) + member.offset_in_bytes);
        resource.name = member.name;
        register_resource(resource);
    }
}

get_resource_by_name :: (name: string) -> *Resource
{
    using resource_manager;

    found, resource: = table_find_new(*resource_by_name, string_hash(name));
    if !found return null;
    return resource;
}

get_resource_by_name :: ($T: Type, name: string) -> *T
{
    resource: = get_resource_by_name(name);
    if resource == null return null;

    if type_info(T) != resource.type
    {
        log_warning("Trying to get resource \"%\" (%) with unmatching type %", name, resource.type.name, T);
        return null;
    }
    return xx resource;
}

get_resource_by_path :: (path: string) -> *Resource
{
    using resource_manager;

    _path: = normalize_path(path);
    found, resource: = table_find_new(*resource_by_path, string_hash(_path));
    if !found return null;
    return resource;
}

get_resource_by_path :: ($T: Type, path: string) -> *T
{
    resource: = get_resource_by_path(path);
    if resource == null return null;

    if type_info(T) != resource.type
    {
        log_warning("Trying to get resource \"%\" (%) with unmatching type %", path, resource.type.name, T);
        return null;
    }
    return xx resource;
}

get_resources_by_type :: ($T: Type) -> []*T
{
    return cast,force([]*T)get_resources_by_type_info(type_info(T));
}

get_resources_by_type_info :: (info: *Type_Info) -> []*Resource
{
    using resource_manager;

    if !is_subclass_of(info, Resource) return .[];

    type_array: = find_or_add(*resources_by_type, cast(*Type_Info_Struct)info);
    return <<type_array;
}

resource_add_file_watch :: (resource: *Resource, file_path: string)
{
    #if !FILE_WATCH_SUPPORTED { return; }

    using resource_manager;

    assert(resource != null);
    path: = normalize_path(file_path);
    if !file_exists(path)
    {
        log_error("Can't add file watch: Incorrect path (%)", file_path, section= *RESOURCE_LOG_SECTION);
        return;
    }

    path_hash: = string_hash(path);
    resource_dependencies: = table_find_pointer(*file_dependencies, path_hash);
    if resource_dependencies == null
    {
        resource_dependencies = table_add(*file_dependencies, path_hash, [..]*Resource.{});
    }
    array_add(resource_dependencies, resource);
}

resource_remove_file_watch :: (resource: *Resource, file_path: string)
{
    #if !FILE_WATCH_SUPPORTED { return; }
    
    using resource_manager;

    assert(resource != null);
    path: = normalize_path(file_path);
    if !file_exists(path)
    {
        log_error("Can't remove file watch: Incorrect path (%)", file_path, section= *RESOURCE_LOG_SECTION);
        return;
    }

    resource_dependencies: = table_find_pointer(*file_dependencies, string_hash(path));
    assert(resource_dependencies != null, "Trying to remove an unknown file watch (%)", file_path);
    removed: = array_unordered_remove_by_value(resource_dependencies, resource, true);
    assert(removed == 1, "Trying to remove an unknown file watch (%)", file_path);
}

resource_manager_update :: ()
{
    using resource_manager;

    #if FILE_WATCH_SUPPORTED
    {
        process_changes(*watcher);
    }

    for _, resource: resources_to_reload
    {
        if resource.skip_next_reload
        {
            resource.skip_next_reload = false;
            continue;
        }

        if resource.load_count == 0 { continue; }
        log_verbose("Reloading \"%\"...", resource.name, section= *RESOURCE_LOG_SECTION);
        resource_unload(resource);
        resource_load(resource);
        log("Reloaded \"%\"", resource.name, section= *RESOURCE_LOG_SECTION);
    }
    table_clear(*resources_to_reload);
}

load_all_resources :: ()
{
    using resource_manager;

    for resource: resources
    {
        data_path: = resource_data_path(resource);
        if data_path.count > 0 && !file_exists(data_path)
        {
            resource_save_to_disk(resource);
            log("%.%: Created resource file \"%\".", resource.name, resource.type.name, data_path);
        }

        resource_load(resource);
    }
}

unload_all_resources :: ()
{
    using resource_manager;
    for resource: resources
    {
        resource_unload(resource);
    }
}


#scope_file

#if FILE_WATCH_SUPPORTED
{
    #import "File_Watcher";
}
