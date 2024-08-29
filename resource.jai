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

    next_id: u32 = 1;
}
g_resource_manager: ResourceManager;
resource_manager :: () -> *ResourceManager { return *g_resource_manager; }

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
    return null;
}

#scope_file
Hash_Table :: #import "Hash_Table";
#poke_name Hash_Table operator==;
Hash :: #import "Hash";
#poke_name Hash get_hash;