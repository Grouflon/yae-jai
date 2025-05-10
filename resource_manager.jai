RESOURCE_LOG_SECTION :: Log_Section.{ "Resource" };
RESOURCE_EXTENSION :: ".res";

ResourceManager :: struct
{
    resources: [..]*Resource;
    resource_by_id: Table(ResourceIDBase, *Resource);
    resource_name_to_id: Table(string, ResourceIDBase);
    resources_by_type: Table(*Type_Info_Struct, [..]*Resource);

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
            if ends_with(info.short_name, RESOURCE_EXTENSION)
            {
                resource: = resource_read_headers_from_disk(info.full_name);
                if resource == null
                {
                    log_warning("couldn't read resource from \"%\"", info.full_name, section= *RESOURCE_LOG_SECTION);
                    return;
                }

                assert(resource.data_path.count > 0);
                resource_register_name(resource, resource.data_path);

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

resource_manager_shutdown :: ()
{
    using manager: = resource_manager();

    deinit(*watcher);

    for resource: resources
    {
        assert(resource.load_count == 0);

        free(resource.data_path);
        free(resource.name);
        free(resource);
    }

    for * type_array: resources_by_type
    {
        array_reset(type_array);
    }

    deinit(*resources_by_type);
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

resource_register_name :: (resource: *Resource, name: string)
{
    assert(resource != null);

    using manager: = resource_manager();

    if table_contains(*resource_name_to_id, name)
    {
        log_warning("name \"%\" already registered for resource \"%\"", name, resource.name);
        return;
    }

    // note: we don't allocate memory for the name, we ideally should be there's no simple way to retrieve a pointer to the key when we remove it
    // I don't think that's a big issue cause once the key is generated, we theoretically only ever touch the hash, so even if the key is deallocated we should be good
    table_add(*resource_name_to_id, name, resource.id);
}

resource_unregister_name :: (resource: *Resource, name: string)
{
    assert(resource != null);

    using manager: = resource_manager();

    success, id: = table_remove(*resource_name_to_id, name);
    if !success
    {
        log_warning("name \"%\" not registered for resource \"%\"", name, resource.name);
        return;
    }
    assert(id == resource.id);
}

resource_create :: ($T: Type, id: ResourceIDBase = 0) -> *T
{
    resource: = resource_create(type_info(T), id);
    assert(resource.type == type_info(T));
    return cast(*T)resource;
}

resource_create :: (ti: *Type_Info_Struct, id: ResourceIDBase = 0) -> *Resource
{
    assert(ti != null);
    assert(is_subclass_of(ti, Resource));

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
    if ti.initializer != null ti.initializer(resource);

    resource.id = actual_id;
    resource.type = ti;

    resource_register(resource);

    return resource;
}

resource_get_or_create :: (ti: *Type_Info_Struct, id: ResourceIDBase) -> resource: *Resource, created: bool
{
    assert(ti != null);

    using manager: = resource_manager();
    resource, found: = table_find(*resource_by_id, id);
    if !found
    {
        resource = resource_create(ti, id);
        assert(resource != null);
    }
    return resource, !found;
}

resource_get_or_create :: ($T: Type, name: string) -> resource: *T, created: bool
{
    using manager: = resource_manager();

    if name.count == 0
    {
        log_warning("Can't get Resource with empty name.", section= *RESOURCE_LOG_SECTION);
        return null, false;
    }

    ti: = cast(*Type_Info_Struct) type_info(T);
    normalized_name: = normalize_resource_name(name);
    id, found: = table_find(*resource_name_to_id, normalized_name);
    if !found { id = 0; }
    resource, created: = resource_get_or_create(ti, id);
    assert(resource != null);
    if resource.type != type_info(T)
    {
        log_error("Can't get Resource \"%\": Does not match the requested type (is %, expects %).", name, resource.type.name, ti.name, section= *RESOURCE_LOG_SECTION);
        return null, false;
    }
    resource_rename(resource, normalized_name);
    return xx resource, created;
}

resource_register :: (resource: *Resource)
{
    assert(resource != null);
    using manager: = resource_manager();

    assert(array_find(resources, resource) == false);
    assert(table_contains(*resource_by_id, resource.id) == false);

    table_add(*resource_by_id, resource.id, resource);
    array_add(*resources, resource);

    type_array: = find_or_add(*resources_by_type, resource.type);
    array_add(type_array, resource);
}

// Unregistering is unused and untested
resource_unregister :: (resource: *Resource)
{
    assert(resource != null);
    using manager: = resource_manager();

    assert(array_find(*resources, resource) == true);
    assert(table_contains(*resource_by_id, resource.id) == true);
    
    type_array: = table_find_pointer(*resources_by_type, resource.type);
    assert(type_array != null);
    array_unordered_remove_by_value(*type_array, resource);

    table_remove(*resource_by_id, resource.id);
    array_unordered_remove_by_value(*resources, resource);
}

get_resources_by_type :: ($T: Type) -> []*T
{
    using manager: = resource_manager();
    if !is_subclass_of(T, Resource) return .[];

    ti: = cast(*Type_Info_Struct) type_info(T);
    type_array: = find_or_add(*resources_by_type, ti);
    return cast,force([]*T)<<type_array;
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

get_id :: (resource: *$T/Resource) -> ResourceID(T)
{
    if resource == null return .{};
    return .{resource.id};
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

resource_serialize :: (serializer: *Serializer, resource_ptr: **Resource, key: string = "") -> bool
{
    assert(serializer != null);

    if serializer.mode == .WRITE && <<resource_ptr == null
    {
        serialize_null(serializer, key);
        return true;
    }

    if !serializer_begin_object(serializer, null, key) { <<resource_ptr = null; return true; }
    defer serializer_end_object(serializer);

    if !resource_serialize_header(serializer, resource_ptr) return false;

    resource: = <<resource_ptr;
    assert(resource != null);

    return resource_serialize_body(serializer, resource);
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

    // we recursively visit the whole file to pre-create all embedded resources
    visit_header :: (serializer: *Serializer, key: string = "") -> *Resource
    {
        resource: *Resource;
        keys: []string;
        size: s64;

        if serializer_begin_object(serializer, *keys, key)
        {
            defer serializer_end_object(serializer);

            resource_serialize_header(serializer, *resource);

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

// This is supposed to be called with the object already opened
resource_serialize_header :: (serializer: *Serializer, resource_ptr: **Resource) -> bool
{
    assert(serializer != null);
    assert(resource_ptr != null);
    using manager: = resource_manager();

    if serializer.mode == .READ
    {
        // Read instantiation data
        temp_id: ResourceIDBase;
        if !serialize(serializer, *temp_id, "id")
        {
            return false;
        }

        type: *Type_Info_Struct;
        type_name: string;
        if !serialize(serializer, *type_name, "type", *temporary_allocator)
        {
            return false;
        }

        ti, success: = table_find(*resource_type_by_name, type_name);
        if !success
        {
            return false;
        }
        type = ti;

        // Get or create resource
        resource: = resource_get_or_create(type, temp_id);
        if resource == null
        {
            return false;
        }
        << resource_ptr = resource;
    }
    else
    {
        resource: = <<resource_ptr;
        if resource == null
        {
            return false;
        }

        serialize(serializer, *resource.id, "id");
        serialize(serializer, *resource.type.name, "type");
    }

    resource: = <<resource_ptr;
    assert(resource != null);

    name: = copy_temporary_string(resource.name);
    serialize(serializer, *name, "name", *temporary_allocator);
    if serializer.mode == .READ
    {
        resource_rename(resource, name);
    }
    return true;
}

resource_serialize_body :: (serializer: *Serializer, resource: *Resource) -> bool
{
    assert(resource != null);
    assert(resource.id != 0);
    assert(resource.type != null);

    return serialize(serializer, resource, resource.type, "data");
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