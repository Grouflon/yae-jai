SerializationMode :: enum
{
    NONE :: 0;
    READ;
    WRITE;
}

Serializer :: struct
{
    mode: SerializationMode = .NONE;
    last_error: string;

    begin: #type (serializer: *Serializer);
    end:   #type (serializer: *Serializer);

    begin_array:     #type (serializer: *Serializer, size: *s64, key: string) -> bool;
    set_array_index: #type (serializer: *Serializer, index: s64) -> bool;
    end_array:       #type (serializer: *Serializer) -> bool;

    begin_object: #type (serializer: *Serializer, keys: *[]string, key: string) -> bool;
    end_object:   #type (serializer: *Serializer) -> bool;

    _serialize_null:    #type (serializer: *Serializer, key: string) -> bool;
    serialize_bool:     #type (serializer: *Serializer, value: *bool, key: string) -> bool;
    serialize_u8:       #type (serializer: *Serializer, value: *u8, key: string) -> bool;
    serialize_u16:      #type (serializer: *Serializer, value: *u16, key: string) -> bool;
    serialize_u32:      #type (serializer: *Serializer, value: *u32, key: string) -> bool;
    serialize_u64:      #type (serializer: *Serializer, value: *u64, key: string) -> bool;
    serialize_s8:       #type (serializer: *Serializer, value: *s8, key: string) -> bool;
    serialize_s16:      #type (serializer: *Serializer, value: *s16, key: string) -> bool;
    serialize_s32:      #type (serializer: *Serializer, value: *s32, key: string) -> bool;
    serialize_s64:      #type (serializer: *Serializer, value: *s64, key: string) -> bool;
    serialize_float32:  #type (serializer: *Serializer, value: *float32, key: string) -> bool;
    serialize_float64:  #type (serializer: *Serializer, value: *float64, key: string) -> bool;
    serialize_string:   #type (serializer: *Serializer, value: *string, key: string, allocator: *Allocator) -> bool;
};

serializer_begin :: (serializer: *Serializer, mode: SerializationMode)
{
    assert(serializer != null);
    assert(serializer.mode == .NONE);
    serializer.mode = mode;
    serializer.begin(serializer);
}

serializer_end :: (serializer: *Serializer)
{
    assert(serializer != null);
    assert(serializer.mode != .NONE);
    serializer.end(serializer);
    serializer.mode = .NONE;
}

serializer_begin_array :: (serializer: *Serializer, size: *s64, key: string = "") -> bool
{
    assert(serializer != null);
    return serializer.begin_array(serializer, size, key);
}

serializer_set_array_index :: (serializer: *Serializer, index: s64) -> bool
{
    assert(serializer != null);
    return serializer.set_array_index(serializer, index);
}

serializer_end_array :: (serializer: *Serializer) -> bool
{
    assert(serializer != null);
    return serializer.end_array(serializer);
}

serializer_begin_object :: (serializer: *Serializer, keys: *[]string = null, key: string = "") -> bool
{
    assert(serializer != null);
    return serializer.begin_object(serializer, keys, key);
}

serializer_end_object :: (serializer: *Serializer) -> bool
{
    assert(serializer != null);
    return serializer.end_object(serializer);
}

serialize_null :: (serializer: *Serializer, key: string = "") -> bool
{
    assert(serializer != null);
    return serializer._serialize_null(serializer, key);
}

serialize :: (serializer: *Serializer, value: *bool, key: string = "") -> bool
{
    assert(serializer != null);
    return serializer.serialize_bool(serializer, value, key);
}

serialize :: (serializer: *Serializer, value: *u8, key: string = "") -> bool
{
    assert(serializer != null);
    return serializer.serialize_u8(serializer, value, key);
}

serialize :: (serializer: *Serializer, value: *u16, key: string = "") -> bool
{
    assert(serializer != null);
    return serializer.serialize_u16(serializer, value, key);
}

serialize :: (serializer: *Serializer, value: *u32, key: string = "") -> bool
{
    assert(serializer != null);
    return serializer.serialize_u32(serializer, value, key);
}

serialize :: (serializer: *Serializer, value: *u64, key: string = "") -> bool
{
    assert(serializer != null);
    return serializer.serialize_u64(serializer, value, key);
}

serialize :: (serializer: *Serializer, value: *s8, key: string = "") -> bool
{
    assert(serializer != null);
    return serializer.serialize_s8(serializer, value, key);
}

serialize :: (serializer: *Serializer, value: *s16, key: string = "") -> bool
{
    assert(serializer != null);
    return serializer.serialize_s16(serializer, value, key);
}

serialize :: (serializer: *Serializer, value: *s32, key: string = "") -> bool
{
    assert(serializer != null);
    return serializer.serialize_s32(serializer, value, key);
}

serialize :: (serializer: *Serializer, value: *s64, key: string = "") -> bool
{
    assert(serializer != null);
    return serializer.serialize_s64(serializer, value, key);
}

serialize :: (serializer: *Serializer, value: *float32, key: string = "") -> bool
{
    assert(serializer != null);
    return serializer.serialize_float32(serializer, value, key);
}

serialize :: (serializer: *Serializer, value: *float64, key: string = "") -> bool
{
    assert(serializer != null);
    return serializer.serialize_float64(serializer, value, key);
}

serialize :: (serializer: *Serializer, value: *string, key: string = "", allocator: *Allocator = null) -> bool
{
    assert(serializer != null);
    return serializer.serialize_string(serializer, value, key, allocator);
}

