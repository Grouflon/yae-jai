ResourceIDBase :: struct
{
    id: u32;
}

ResourceID :: struct($ResourceType: Type)
{
    #as using base: ResourceIDBase;
}

operator == :: (a: ResourceIDBase, b: ResourceIDBase) -> bool
{
    return a.id == b.id;
}

operator == :: (a: ResourceIDBase, b: u32) -> bool
{
    return a.id == b;
}

get_hash :: (x: ResourceIDBase) -> u32
{
    return x.id;
}

Resource :: struct
{
    type: Type;
    id: ResourceIDBase;
    name: string;

    load_count: u32;
    load_function: #type (resource: *Resource);
    unload_function: #type (resource: *Resource);
}

ResourceManager :: struct
{
    resource_by_id: Table(ResourceIDBase, *Resource);
    resource_by_name: Table(string, *Resource);

    file_dependencies: Table(string, [..]*Resource);
    resources_to_reload: [..]*Resource;

    watcher: File_Watcher;

    next_id: u32 = 1;
}
g_resource_manager: ResourceManager;
resource_manager :: () -> *ResourceManager { return *g_resource_manager; }

resource_manager_init :: ()
{
    using manager: = resource_manager();

    on_file_modified :: (watcher: *File_Watcher(void), change: *File_Change, user_data: *void)
    {
        if change.events != .MODIFIED { return; }
        path, success: = normalize_path(change.full_path);
        if !success { return; }

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
        log_error("Could not initialize watcher");
    }
    watched_directories: []string = .[
        "data",
    ];
    if !add_directories(*watcher, ..watched_directories)
    {
        log_error("Could not watch directories %", watched_directories);
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
    deinit(*resource_by_name);
}

resource_manager_update :: ()
{
    using manager: = resource_manager();

    process_changes(*watcher);

    for resource: resources_to_reload
    {
        if resource.load_count == 0 { continue; }
        log("Reloading \"%\"...", resource.name);
        if resource.unload_function != null { resource.unload_function(resource); }
        if resource.load_function != null { resource.load_function(resource); }
        log("Reloaded \"%\"", resource.name);
    }
    array_clear(*resources_to_reload);
}

resource_get :: ($T: Type, name: string) -> *T
{
    if name.count == 0
    {
        log_error("Can't get Resource with empty name.");
        return null;
    }

    using manager: = resource_manager();
    resource, found: = table_find(*resource_by_name, name);
    if found && resource.type != T
    {
        log_error("Can't get Resource \"%\": Does not match the requested type (is %, expects %).", );
        return null;
    }

    if !found
    {
        id: ResourceIDBase = .{ id = next_id };
        next_id += 1;

        typed_resource: = New(T);
        typed_resource.id = id;
        assert(id == typed_resource.id);
        typed_resource.name = copy_string(name);

        resource = typed_resource;
        table_add(*resource_by_id, id, resource);
        table_add(*resource_by_name, typed_resource.name, resource);
    }

    return xx resource;
}

resource_load :: ($T: Type, name: string) -> *T
{
    resource: = resource_get(T, name);
    if resource == null { return null; }

    resource_load(resource);
    return resource;
}

resource_load :: (resource: *Resource)
{
    assert(resource != null);

    if resource.load_count == 0 && resource.load_function != null
    {
        resource.load_function(resource);
    }

    resource.load_count += 1;
}

resource_unload :: (id: ResourceID($T))
{
    resource: = get(id);
    assert(resource != null);
    resource_unload(resource);
}

resource_unload :: (resource: *Resource)
{
    assert(resource != null);
    assert(resource.load_count > 0);

    resource.load_count -= 1;

    if resource.load_count == 0 && resource.unload_function != null
    {
        resource.unload_function(resource);
    }
}

get :: (id: ResourceID($T)) -> *T
{
    resource: = get(cast(ResourceIDBase) id);
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
    path, success: = normalize_path(file_path);
    if !success
    {
        log_error("Can't add file watch: Incorrect path (%)", file_path);
        return;
    }

    resources: = table_find_pointer(*file_dependencies, path);
    if resources == null
    {
        resources = table_add(*file_dependencies, copy_string(path), [..]*Resource.{});
    }
    array_add(resources, resource);
}

resource_remove_file_watch :: (resource: *Resource, file_path: string)
{
    using manager: = resource_manager();

    assert(resource != null);
    path, success: = normalize_path(file_path);
    if !success
    {
        log_error("Can't remove file watch: Incorrect path (%)", file_path);
        return;
    }

    resources: = table_find_pointer(*file_dependencies, path);
    assert(resources != null, "Trying to remove an unknown file watch (%)", file_path);
    removed: = array_unordered_remove_by_value(resources, resource, true);
    assert(removed == 1, "Trying to remove an unknown file watch (%)", file_path);
}

#scope_file

normalize_path :: (path: string) -> string, bool
{
    if path.count == 0 { return "", false; }

    push_allocator(temporary_allocator); // get_absolute_path is leaking + path_to_string allocates

    absolute_path, success: = get_absolute_path(path);
    normalized_path: = path_to_string(parse_path(absolute_path));

    return normalized_path, success;
}

Hash_Table :: #import "Hash_Table";
#poke_name Hash_Table operator==;

Hash :: #import "Hash";
#poke_name Hash get_hash;

#import "File_Watcher";