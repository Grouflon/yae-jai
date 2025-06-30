RESOURCE_LOG_SECTION :: Log_Section.{ "Resource" };
RESOURCE_EXTENSION :: ".res";

// Resource
Resource :: struct @serialize_optin
{
    #as using _object: Object;

    load_function: #type (resource: *Resource) -> bool;
    unload_function: #type (resource: *Resource);

    data_path: string;
    load_count: u32;
    is_loaded_without_errors: bool = false;
}

resource_set_data_path :: (resource: *Resource, data_path: string)
{
    assert(resource != null);

    free(resource.data_path);
    resource.data_path = copy_string(normalize_path(data_path));
}

resource_load :: ($T: Type, name: string) -> *T, bool
{
    resource: = object_get_or_create(T, name);
    if resource == null { return null, false; }

    success: = resource_load(resource);
    return resource, success;
}

resource_load :: (resource: *Resource) -> bool
{
    if resource == null return false;

    if resource.load_count == 0 && resource.load_function != null
    {
        log_verbose("loading % %...", resource.type.name, resource.name, section = *RESOURCE_LOG_SECTION);
        log_indent();

        if resource.data_path.count > 0
        {
            serializer: JsonSerializer;
            if json_serializer_open_json_file(*serializer, resource.data_path)
            {
                serializer_begin(*serializer, .READ);
                defer serializer_end(*serializer);

                resource_serialize(*serializer, *resource);
            }
        }

        resource.is_loaded_without_errors = resource.load_function(resource);
        log_unindent();
        log_verbose("loaded % %", resource.type.name, resource.name, section = *RESOURCE_LOG_SECTION);
    }
    resource.load_count += 1;
    return resource.is_loaded_without_errors;
}

resource_unload :: (id: ID($T))
{
    resource_unload(get(id));
}

resource_unload :: (resource: *Resource)
{
    if resource == null return;

    assert(resource.load_count > 0);

    resource.load_count -= 1;
    if resource.load_count == 0 && resource.unload_function != null
    {
        log_verbose("unloading % %...", resource.type.name, resource.name, section = *RESOURCE_LOG_SECTION);
        resource.is_loaded_without_errors = false;
        resource.unload_function(resource);
        log_verbose("unloaded % %", resource.type.name, resource.name, section = *RESOURCE_LOG_SECTION);
    }
}

resource_save_to_disk :: (resource: *Resource) -> bool
{
    if resource == null return false;
    if resource.data_path.count == 0 return false;

    return resource_save_to_disk(resource, resource.data_path);
}

resource_save_to_disk :: (resource: *Resource, file_path: string) -> bool
{
    if resource == null return false;

    serializer: JsonSerializer;
    serializer_begin(*serializer, .WRITE);
    resource_serialize(*serializer, *resource);
    serializer_end(*serializer);

    make_directory_if_it_does_not_exist(get_directory(file_path), true);
    json_serializer_write_json_file(*serializer, file_path);
    return true;
}

resource_get_or_create :: ($T: Type, path: string) -> resource: *T, created: bool
{
    normalized_path: = normalize_resource_name(path);
    resource, created: = object_get_or_create(T, normalized_path);

    if created
    {
        resource_set_data_path(resource, tprint("%0%", normalized_path, RESOURCE_EXTENSION));
        resource_save_to_disk(resource);
    }

    return resource, created;
}

resource_serialize :: (serializer: *Serializer, resource_ptr: **Resource) -> bool
{
    object: *Object = *(<<resource_ptr)._object;
    result: = object_serialize(serializer, *object);
    <<resource_ptr = cast(*Resource) object;
    return result;
}

is_loaded :: (resource: *Resource) -> bool
{
    if resource == null return false;
    return resource.is_loaded_without_errors;
}

resource_add_file_watch :: (resource: *Resource, file_path: string)
{
    using manager: = resource_manager();

    assert(resource != null);
    path: = normalize_path(file_path);
    if !file_exists(path)
    {
        log_error("Can't add file watch: Incorrect path (%)", file_path, section= *RESOURCE_LOG_SECTION);
        return;
    }

    resource_dependencies: = table_find_pointer(*file_dependencies, path);
    if resource_dependencies == null
    {
        resource_dependencies = table_add(*file_dependencies, copy_string(path), [..]*Resource.{});
    }
    array_add(resource_dependencies, resource);
}

resource_remove_file_watch :: (resource: *Resource, file_path: string)
{
    using manager: = resource_manager();

    assert(resource != null);
    path: = normalize_path(file_path);
    if !file_exists(path)
    {
        log_error("Can't remove file watch: Incorrect path (%)", file_path, section= *RESOURCE_LOG_SECTION);
        return;
    }

    resource_dependencies: = table_find_pointer(*file_dependencies, path);
    assert(resource_dependencies != null, "Trying to remove an unknown file watch (%)", file_path);
    removed: = array_unordered_remove_by_value(resource_dependencies, resource, true);
    assert(removed == 1, "Trying to remove an unknown file watch (%)", file_path);
}

// Manager
ResourceManager :: struct
{
    file_dependencies: Table(string, [..]*Resource);
    resources_to_reload: [..]*Resource;

    watcher: File_Watcher;
}
g_resource_manager: ResourceManager;
resource_manager :: () -> *ResourceManager { return *g_resource_manager; }

resource_manager_init :: (resource_types: []*Type_Info_Struct)
{
    using manager: = resource_manager();
}

resource_manager_shutdown :: ()
{
    using manager: = resource_manager();

    deinit(*watcher);

    resources: = get_objects_by_type(Resource);
    for resource: resources
    {
        assert(resource.load_count == 0);

        free(resource.data_path);
    }
}

resource_manager_gather_and_watch_resources :: (resource_folders: ..string)
{
    using manager: = resource_manager();

    for resource_folder: resource_folders
    {
        visit_files(resource_folder, true, manager, (info: *File_Visit_Info, user_data: *ResourceManager)
        {
            if ends_with(info.short_name, RESOURCE_EXTENSION)
            {
                resource: = resource_read_headers_from_disk(info.full_name);
                if resource == null
                {
                    log_warning("couldn't read resource from \"%\"", info.full_name, section= *RESOURCE_LOG_SECTION);
                    return;
                }

                assert(resource.data_path.count > 0);
                object_register_name(resource, resource.data_path);

                log_verbose("gathered resource %", resource.data_path, section= *RESOURCE_LOG_SECTION);
            }
        });
    }

    // File watch
    on_file_modified :: (watcher: *File_Watcher(void), change: *File_Change, user_data: *void)
    {
        if change.events != .MODIFIED { return; }
        path: = normalize_path(change.full_path);

        manager: = resource_manager();

        resources: = table_find_pointer(*manager.file_dependencies, path);
        if resources == null { return; }

        for resource: <<resources
        {
            array_add(*manager.resources_to_reload, resource);
        }
    }
    if !init(*watcher, on_file_modified, events_to_watch = .MODIFIED)
    {
        log_error("Could not initialize watcher", section= *RESOURCE_LOG_SECTION);
    }
    if !add_directories(*watcher, ..resource_folders)
    {
        log_error("Could not watch directories %", resource_folders, section= *RESOURCE_LOG_SECTION);
    }
}

resource_manager_update :: ()
{
    using manager: = resource_manager();

    process_changes(*watcher);

    for resource: resources_to_reload
    {
        if resource.load_count == 0 { continue; }
        log_verbose("Reloading \"%\"...", resource.name, section= *RESOURCE_LOG_SECTION);
        if resource.unload_function != null { resource.unload_function(resource); }
        if resource.load_function != null { resource.load_function(resource); }
        log("Reloaded \"%\"", resource.name, section= *RESOURCE_LOG_SECTION);
    }
    array_clear(*resources_to_reload);
}

#scope_file

resource_read_headers_from_disk :: (file_path: string) -> *Resource
{
    using manager: = resource_manager();

    serializer: JsonSerializer;
    if !json_serializer_open_json_file(*serializer, file_path)
    {
        return null;
    }

    // we recursively visit the whole file to pre-create all embedded objects
    visit_header :: (serializer: *Serializer, key: string = "") -> *Resource
    {
        resource: *Resource;
        keys: []string;
        size: s64;

        if serializer_begin_object(serializer, *keys, key)
        {
            defer serializer_end_object(serializer);

            object_serialize_header(serializer, cast(**Object) *resource);

            for member_key: keys
            {
                visit_header(serializer, member_key);
            }
        }
        else if serializer_begin_array(serializer, *size, key)
        {
            defer serializer_end_array(serializer);

            for i: 0..size-1
            {
                visit_header(serializer);
            }
        }

        return resource;
    }

    serializer_begin(*serializer, .READ);
    resource: = visit_header(*serializer);
    serializer_end(*serializer);

    if resource != null
    {
        resource_set_data_path(resource, file_path);
    }

    return resource;
}

normalize_resource_name :: (name: string) -> string
{
    // If not a file, leave it as is
    if !file_exists(name)
        return name;

    return normalize_path(name);
}

#import "Hash";
#import "File_Watcher";