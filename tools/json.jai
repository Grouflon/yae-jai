json_get :: (value: JSON_Value, key: string, expected_type: JSON_Type) -> JSON_Value
{
    key_value: = json_get(value, key);
    assert(key_value.type == expected_type);
    return key_value;
}

json_get :: (value: JSON_Value, key: string) -> JSON_Value
{
    assert(value.type == .OBJECT);
    
    success, key_value: = json_try_get(value, key);
    assert(success);
    return key_value;
}

json_try_get :: (value: JSON_Value, key: string) -> bool, JSON_Value
{
    assert(value.type == .OBJECT);
    
    table := value.object;
    key_value, success := table_find(table, key);
    return success, key_value;
}

json_try_copy_string :: (value: JSON_Value, key: string, out_string: *string) -> bool
{
    assert(out_string != null);
    assert(value.type == .OBJECT);

    key_value, success := table_find(value.object, key);
    if !success { return false; }
    if key_value.type != .STRING { return false; }

    <<out_string = copy_string(key_value.str);
    return true;
}

read_json_file :: (path: string, data: *$T) -> bool
{
    if data == null return false;

    serializer: JsonSerializer;
    if !json_serializer_open_json_file(*serializer, path) return false;

    serializer_begin(*serializer, .READ);
    success: = serialize(*serializer, data);
    serializer_end(*serializer);

    return success;
}

write_json_file :: (path: string, data: *$T) -> bool
{
    if data == null return false;

    serializer: JsonSerializer;
    serializer_begin(*serializer, .WRITE);
    success: = serialize(*serializer, data);
    serializer_end(*serializer);
    
    if !success return false;

    return json_serializer_write_json_file(*serializer, path);
}


#scope_file

