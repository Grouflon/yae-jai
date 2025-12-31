RESOURCE_LOG_SECTION :: Log_Section.{ "Resource" };
RESOURCE_EXTENSION :: "res";

Resource :: struct
{
    type: *Type_Info_Struct;
    name: string;
    path: string;

    load_function: #type (resource: *Resource) -> bool;
    unload_function: #type (resource: *Resource);

    load_count: u32;
    is_loaded_without_errors: bool;
    skip_next_reload: bool;
}

resource_load :: (resource: *Resource) -> bool
{
    if resource == null return false;

    if resource.load_count == 0 && resource.load_function != null
    {
        log_verbose("loading % %...", resource.type.name, resource.name, section = *RESOURCE_LOG_SECTION);
        log_indent();

        data_path: = resource_data_path(resource);
        if data_path.count > 0
        {
            serializer: JsonSerializer;
            if json_serializer_open_json_file(*serializer, data_path)
            {
                serializer_begin(*serializer, .READ);
                defer serializer_end(*serializer);

                resource_serialize(*serializer, resource);
            }
        }

        if resource.path.count > 0
        {
            resource_add_file_watch(resource, resource.path);
        }

        if data_path.count > 0
        {
            resource_add_file_watch(resource, data_path);
        }

        resource.is_loaded_without_errors = resource.load_function(resource);
        log_unindent();

        if resource.is_loaded_without_errors
        {
            log_verbose("loaded % %", resource.type.name, resource.name, section = *RESOURCE_LOG_SECTION);
        }
        else
        {
            log_error("failed to load % %", resource.type.name, resource.name, section = *RESOURCE_LOG_SECTION);
        }
    }
    resource.load_count += 1;
    return resource.is_loaded_without_errors;
}

resource_unload :: (resource: *Resource)
{
    if resource == null return;

    assert(resource.load_count > 0);

    resource.load_count -= 1;
    if resource.load_count == 0 && resource.unload_function != null
    {
        log_verbose("unloading % %...", resource.type.name, resource.name, section = *RESOURCE_LOG_SECTION);

        data_path: = resource_data_path(resource);
        if data_path.count > 0
        {
            resource_remove_file_watch(resource, data_path);
        }
        if resource.path.count > 0
        {
            resource_remove_file_watch(resource, resource.path);
        }
        
        resource.is_loaded_without_errors = false;
        resource.unload_function(resource);
        log_verbose("unloaded % %", resource.type.name, resource.name, section = *RESOURCE_LOG_SECTION);
    }
}

is_loaded :: (resource: *Resource) -> bool
{
    if resource == null return false;
    return resource.is_loaded_without_errors;
}

resource_data_path :: (resource: *Resource) -> string
{
    if resource == null return "";
    if resource.path.count == 0 return "";

    path: string;
    if ends_with(resource.path, tprint(".%", RESOURCE_EXTENSION))
    {
        path = resource.path;
    }
    else
    {
        path = tprint("%.%", resource.path, RESOURCE_EXTENSION);
    }
    return yae_resolve_path(path);
}

resource_save_to_disk :: (resource: *Resource) -> bool
{
    if resource == null return false;
    if resource.path.count == 0 return false;

    return resource_save_to_disk(resource, resource_data_path(resource));
}

resource_save_to_disk :: (resource: *Resource, file_path: string) -> bool
{
    if resource == null return false;

    // Serialize
    serializer: JsonSerializer;
    serializer_begin(*serializer, .WRITE);
    resource_serialize(*serializer, resource);
    serializer_end(*serializer);

    // Write to disk
    make_directory_if_it_does_not_exist(get_directory(file_path), true);
    resource.skip_next_reload = true; // prevents file watch to trigger
    json_serializer_write_json_file(*serializer, file_path);

    log_verbose("Saved % % to \"%\".", resource.type.name, resource.name, file_path);
    return true;
}

resource_serialize :: (serializer: *Serializer, resource: *Resource) -> bool
{
    return serialize(serializer, resource, resource.type);
}
