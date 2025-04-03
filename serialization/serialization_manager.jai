serialization_manager : struct 
{
    custom_serialize_registry: Table(*Type_Info, CustomSerializationFunction);
};

CustomSerializeType :: struct
{
    ti: *Type_Info;
    function: CustomSerializationFunction;
}

serialization_manager_init :: (types: []CustomSerializeType)
{
    using serialization_manager;

    for type: types
    {
        if type.ti == null || type.function == null { continue; }
        table_add(*custom_serialize_registry, type.ti, type.function);
    }
}

serialization_manager_shutdown :: ()
{
    using serialization_manager;

    deinit(*custom_serialize_registry);
}

get_custom_serialize_function :: (ti: *Type_Info) -> CustomSerializationFunction
{
    using serialization_manager;

    f, found: = table_find(*custom_serialize_registry, ti);
    if found return f;
    return null;
}