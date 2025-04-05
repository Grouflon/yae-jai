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
