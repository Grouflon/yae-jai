ResourceIDBase :: u32;

ResourceID :: struct($ResourceType: Type)
{
    #as base: ResourceIDBase;
}

Resource :: struct @serialize_optin
{
    type: *Type_Info_Struct;
    id: ResourceIDBase;
    data_path: string;
    name: string;

    load_count: u32;
    load_function: #type (resource: *Resource) -> bool;
    unload_function: #type (resource: *Resource);

    is_loaded_without_errors: bool = false;
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

resource_set_data_path :: (resource: *Resource, data_path: string)
{
    assert(resource != null);

    free(resource.data_path);
    resource.data_path = copy_string(normalize_path(data_path));
}

normalize_resource_name :: (name: string) -> string
{
    // If not a file, leave it as is
    if !file_exists(name)
        return name;

    return normalize_path(name);
}