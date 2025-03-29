RESOURCE_LOG_SECTION :: Log_Section.{ "Resource" };
RESOURCE_EXTENSION :: ".res";

ResourceIDBase :: u32;

ResourceID :: struct($ResourceType: Type)
{
    #as base: ResourceIDBase;
}

Resource :: struct
{
    type: *Type_Info_Struct;
    id: ResourceIDBase;
    data_path: string;
    name: string;

    load_count: u32;
    load_function: #type (resource: *Resource) -> bool;
    unload_function: #type (resource: *Resource);
    release_function: #type (resource: *Resource);

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
            if ends_with(info.short_name, RESOURCE_EXTENSION)
            {
                resource: = resource_read_from_disk(info.full_name);
                if resource == null return;

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

        resource_release(resource);
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
        log_verbose("loading % %...", resource.type.name, resource.name, section = *RESOURCE_LOG_SECTION);
        resource.is_loaded_without_errors = resource.load_function(resource);
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

resource_release :: (resource: *Resource)
{
    if resource.release_function != null resource.release_function(resource);
    free(resource.data_path);
    free(resource.name);
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
    resource_serialize(*serializer, *resource.id);
    serializer_end(*serializer);

    make_directory_if_it_does_not_exist(get_directory(file_path), true);
    json_serializer_write_json_file(*serializer, file_path);
    return true;
}

resource_read_from_disk :: (file_path: string) -> *Resource
{
    using manager: = resource_manager();

    serializer: JsonSerializer;
    if !json_serializer_open_json_file(*serializer, file_path)
    {
        log_warning("could not parse resource %", file_path, section= *RESOURCE_LOG_SECTION);
        return null;
    }

    id: ResourceIDBase;
    serializer_begin(*serializer, .READ);
    if !resource_serialize(*serializer, *id)
    {
        log_warning("failed to serialize resource %", file_path);
        return null;
    }
    serializer_end(*serializer);

    resource: = get(id);
    assert(resource.data_path.count == 0);    
    resource.data_path = copy_string(normalize_path(file_path));

    return resource;
}

resource_rename :: (resource: *Resource, name: string)
{
    assert(resource != null);

    using manager: = resource_manager();

    if compare(name, resource.name) == 0 return;

    if resource.name.count > 0
    {
        resource_unregister_name(resource, name);
        free(resource.name);
        resource.name.count = 0;
    }
    
    normalized_name: = normalize_resource_name(name); // Not sure this should be done automatically here, or manually outside
    resource.name = copy_string(normalized_name);

    if resource.name.count > 0
    {
        resource_register_name(resource, resource.name);
    }
}

resource_register_name :: (resource: *Resource, name: string)
{
    assert(resource != null);

    using manager: = resource_manager();

    if table_contains(*resource_name_to_id, name)
    {
        log_warning("name \"%\" already registered for resource %", name, resource.name);
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
        log_warning("name \"%\" not registered for resource %", name, resource.name);
        return;
    }
    assert(id == resource.id);
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

    ti: = cast(*Type_Info_Struct) type_info(T);
    normalized_name: = normalize_resource_name(name);
    id, found: = table_find(*resource_name_to_id, normalized_name);
    if !found { id = 0; }
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

#scope_file

resource_serialize :: (serializer: *Serializer, id: *ResourceIDBase, key: string = "") -> bool
{
    assert(serializer != null);
    using manager: = resource_manager();

    resource: *Resource;

    // Resource header
    serializer_begin_object(serializer, null, key);
    defer serializer_end_object(serializer);

    if serializer.mode == .READ
    {
        // Read instantiation data
        temp_id: ResourceIDBase;
        if !serialize(serializer, *temp_id, "id")
        {
            log_warning("Missing id field in resource", section= *RESOURCE_LOG_SECTION);
            return false;
        }

        type: *Type_Info_Struct;
        type_name: string;
        if !serialize(serializer, *type_name, "type", *temporary_allocator)
        {
            log_warning("Missing type field in resource", section= *RESOURCE_LOG_SECTION);
            return false;
        }

        ti, success: = table_find(*resource_type_by_name, type_name);
        if !success
        {
            log_warning("Unknown resource type % in resource", type_name, section= *RESOURCE_LOG_SECTION);
            return false;
        }
        type = ti;

        // Get or create resource
        resource = resource_get_or_create(type, temp_id);
        if resource == null
        {
            log_warning("Failed to create resource % (%)", id, type.name);
            return false;
        }
        << id = resource.id;
    }
    else
    {
        resource = get(<<id);
        if resource == null
        {
            log_warning("Unable to find resource %", id);
            return false;
        }

        serialize(serializer, *resource.id, "id");
        serialize(serializer, *resource.type.name, "type");
    }

    name: = copy_temporary_string(resource.name);
    serialize(serializer, *name, "name", *temporary_allocator);
    if serializer.mode == .READ
    {
        resource_rename(resource, name);
    }

    // Resource Body
    assert(resource != null);
    assert(resource.id != 0);
    assert(resource.type != null);

    serialization_params: SerializationParams = .{

        filters = .[.{ .IN, type_info(Resource), "serialize" }],
        
        custom_serialization_function = (serializer: *Serializer, data: *void, info: *Type_Info,  key: string, params: SerializationParams, ctx: ReflectionContext) -> bool
        {
            // Resource ID, override
            if is_subclass_of(info, ResourceIDBase)
            {
                // If embed, serialize data directyly
                if has_note(ctx.member, "embed")
                {
                    resource_serialize(serializer, cast(*ResourceIDBase) data, key);
                }
                else // else serialize id
                {
                    serialize(serializer, data, type_info(ResourceIDBase), key, .{}, ctx);
                }
                return false;
            }

            // Resource ID, override
            if info.type == .POINTER
            {
                ti: = (cast(*Type_Info_Pointer) info).pointer_to;
                if is_subclass_of(ti, Resource)
                {
                    resource_ptr: = cast(**Resource) data;
                    resource: = <<resource_ptr;
                    id: ResourceIDBase = ifx resource != null then resource.id else 0;

                    // If embed, serialize data directyly
                    if has_note(ctx.member, "embed")
                    {
                        resource_serialize(serializer, *id, key);
                    }
                    else // else serialize id
                    {
                        serialize(serializer, *id, type_info(ResourceIDBase), key, .{}, ctx);
                    }

                    if serializer.mode == .READ
                    {
                        <<resource_ptr = get(id);
                    }
                    return false;
                }
            }

            // else normal serialization
            return true;
        }
    };
    serialize(serializer, resource, resource.type, "data", params = serialization_params);

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
