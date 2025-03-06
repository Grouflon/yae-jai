RESOURCE_LOG_SECTION :: Log_Section.{ "Resource" };

ResourceIDBase :: u32;

ResourceID :: struct($ResourceType: Type)
{
    #as base: ResourceIDBase;
}

Resource :: struct
{
    type: *Type_Info_Struct;
    id: ResourceIDBase;
    name: string;

    load_count: u32;
    load_function: #type (resource: *Resource) -> bool;
    unload_function: #type (resource: *Resource);

    is_loaded_without_errors: bool = false;
}

ResourceManager :: struct
{
    resource_by_id: Table(ResourceIDBase, *Resource);
    resource_name_to_id: Table(string, ResourceIDBase);
    resources: [..]*Resource;

    resource_type_by_name: Table(string, *Type_Info_Struct);

    file_dependencies: Table(string, [..]*Resource);
    resources_to_reload: [..]*Resource;

    watcher: File_Watcher;
}
g_resource_manager: ResourceManager;
resource_manager :: () -> *ResourceManager { return *g_resource_manager; }

resource_manager_init :: (resource_types: []*Type_Info_Struct, resource_folders: ..string)
{
    using manager: = resource_manager();

    // Init resource types
    for ti: resource_types
    {
        table_add(*resource_type_by_name, ti.name, ti);
    }

    // Gather resources
    for resource_folder: resource_folders
    {
        visit_files(resource_folder, true, manager, (info: *File_Visit_Info, user_data: *ResourceManager)
        {
            if ends_with(info.short_name, ".res")
            {
                resource: = resource_load_from_disk(info.full_name);
                resource_name: = slice(info.full_name, 0, info.full_name.count - 4);
                resource_rename(resource, resource_name);
                log_verbose("gathered resource %", info.full_name, section= *RESOURCE_LOG_SECTION);
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

resource_manager_shutdown :: ()
{
    using manager: = resource_manager();

    deinit(*watcher);

    for resource: resource_by_id
    {
        assert(resource.load_count == 0);
        free(resource.name);
        free(resource);
    }

    deinit(*resource_by_id);
    deinit(*resource_name_to_id);
    array_reset(*resources);
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

resource_load :: ($T: Type, name: string) -> *T, bool #must
{
    resource: = resource_get_or_create(T, name);
    if resource == null { return null, false; }

    success: = resource_load(resource);
    return resource, success;
}

resource_load :: (resource: *Resource) -> bool
{
    if resource == null return false;

    if resource.load_count == 0 && resource.load_function != null
    {
        resource.is_loaded_without_errors = resource.load_function(resource);
    }
    resource.load_count += 1;
    return resource.is_loaded_without_errors;
}

resource_unload :: (id: ResourceID($T))
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
        resource.is_loaded_without_errors = false;
        resource.unload_function(resource);
    }
}

resource_save_to_disk :: (resource: *Resource, file_path: string)
{
    if resource == null return;

    serializer: JsonSerializer;
    serializer_begin(*serializer, .WRITE);
    serializer_begin_object(*serializer, null);

    serialize(*serializer, *resource.id, "id");
    serialize(*serializer, *resource.type.name, "type");

    resource_serialize(*serializer, resource);

    serializer_end_object(*serializer);
    serializer_end(*serializer);

    json_serializer_write_json_file(*serializer, file_path);
}

resource_load_from_disk :: (file_path: string) -> *Resource
{
    using manager: = resource_manager();

    serializer: JsonSerializer;
    if !json_serializer_open_json_file(*serializer, file_path)
    {
        log_warning("could not parse resource %", file_path, section= *RESOURCE_LOG_SECTION);
        return null;
    }

    serializer_begin(*serializer, .READ);
    serializer_begin_object(*serializer);

    // Mandatory fields
    id: ResourceIDBase;
    if !serialize(*serializer, *id, "id")
    {
        log_warning("resource % does not contain an id field", file_path, section= *RESOURCE_LOG_SECTION);
        return null;
    }

    type: string;
    if !serialize(*serializer, *type, "type", *temporary_allocator)
    {
        log_warning("resource % does not contain a type field", file_path, section= *RESOURCE_LOG_SECTION);
        return null;
    }

    ti, found: = table_find(*resource_type_by_name, type);
    if !found
    {
        log_warning("resource % has unknown type %", file_path, type, section= *RESOURCE_LOG_SECTION);
        return null;
    }

    // Create resource
    resource: = resource_get_or_create(ti, id);
    if !resource
    {
        log_warning("Failed to create resource % from id % and type %", file_path, id, ti.name, section= *RESOURCE_LOG_SECTION);
        return null;
    }

    // Serialize resource
    if !resource_serialize(*serializer, resource)
    {
    }

    serializer_end_object(*serializer);
    serializer_end(*serializer);
    return resource;
}

resource_rename :: (resource: *Resource, name: string)
{
    assert(resource != null);

    using manager: = resource_manager();

    if compare(name, resource.name) == 0 return;

    if resource.name.count > 0
    {
        table_remove(*resource_name_to_id, resource.name);
        free(resource.name);
        resource.name.count = 0;
    }
    
    normalized_name: = normalize_resource_name(name); // Not sure this should be done automatically here, or manually outside
    resource.name = copy_string(normalized_name);

    if resource.name.count > 0
    {
        table_add(*resource_name_to_id, resource.name, resource.id);
    }
}

resource_create :: (ti: *Type_Info_Struct, id: ResourceIDBase = 0) -> *Resource
{
    assert(ti != null);
    assert(is_subclass_of(ti, "Resource"));

    using manager: = resource_manager();

    actual_id: = id;
    // If it is undefined, generate one
    if actual_id == 0
    {
        actual_id = generate_resource_id();
        while table_contains(*resource_by_id, id)
        {
            // If there is an id collision, just pick a new one
            actual_id = generate_resource_id();
        }
    }

    if (table_contains(*resource_by_id, actual_id))
    {
        log_error("resource id collision (%)", actual_id, section= *RESOURCE_LOG_SECTION);
        return null;
    }

    resource: *Resource = alloc(ti.runtime_size);
    ti.initializer(resource);

    resource.id = actual_id;
    resource.type = ti;

    table_add(*resource_by_id, resource.id, resource);
    array_add(*resources, resource);

    return resource;
}

resource_get_or_create :: (ti: *Type_Info_Struct, id: ResourceIDBase) -> *Resource
{
    assert(ti != null);

    using manager: = resource_manager();
    resource, found: = table_find(*resource_by_id, id);
    if !found
    {
        resource = resource_create(ti, id);
        assert(resource != null);
    }
    return resource;
}

resource_get_or_create :: ($T: Type, name: string) -> *T
{
    using manager: = resource_manager();

    if name.count == 0
    {
        log_warning("Can't get Resource with empty name.", section= *RESOURCE_LOG_SECTION);
        return null;
    }

    normalized_name: = normalize_resource_name(name);
    id, found: = table_find(*resource_name_to_id, normalized_name);
    ti: = cast(*Type_Info_Struct) type_info(T);
    resource: = resource_get_or_create(ti, id);
    assert(resource != null);
    if resource.type != type_info(T)
    {
        log_error("Can't get Resource \"%\": Does not match the requested type (is %, expects %).", name, resource.type.name, ti.name, section= *RESOURCE_LOG_SECTION);
        return null;
    }
    resource_rename(resource, normalized_name);
    return xx resource;
}

get :: (id: ResourceID($T)) -> *T
{
    resource: = get(id);
    assert(resource.type == T);
    return cast(*T) resource;
}

get :: (id: ResourceIDBase) -> *Resource
{
    using manager: = resource_manager();

    resource, success: = table_find(*resource_by_id, id);
    if !success { return null; }
    return resource;
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

#scope_file

resource_serialize :: (serializer: *Serializer, resource: *Resource) -> bool
{
    assert(serializer != null);
    assert(resource != null);

    name: = copy_temporary_string(resource.name);
    serialize(serializer, *name, "name", *temporary_allocator);
    if serializer.mode == .READ
    {
        resource_rename(resource, name);
    }

    return true;
}

normalize_resource_name :: (name: string) -> string
{
    // If not a file, leave it as is
    if !file_exists(name)
        return name;

    return normalize_path(name);
}

generate_resource_id :: () -> ResourceIDBase
{
    // Until we need something more sophisticated, Resource id is just a hash of the current time
    current_time: = current_time_consensus();
    date_hash: = sdbm_hash(*current_time, xx size_of(Apollo_Time));
    id: ResourceIDBase = date_hash;
    return id;
}

#import "Hash";
#import "File_Watcher";
#import "Compiler";