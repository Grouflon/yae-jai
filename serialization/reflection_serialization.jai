serialize :: (serializer: *Serializer, value: *$T, key: string = "") -> bool
{
    return serialize(serializer, value, type_info(T), key);
}

serialize :: (serializer: *Serializer, data: *void, info: *Type_Info, key: string = "") -> bool
{
    if info.type == .POINTER
    {
        ti: = (cast(*Type_Info_Pointer) info).pointer_to;
        if ti.type != .STRUCT return false;
        tis: *Type_Info_Struct = xx ti;

        // Resource pointer, override
        if is_subclass_of(tis, Resource)
        {
            resource_ptr: = cast(**Resource) data;

            resource: = <<resource_ptr;
            name: string;
            if serializer.mode == .WRITE
            {
                name = ifx resource != null then resource.name else "";
            }
            success: = serialize(serializer, *name, key, *temporary_allocator);
            <<resource_ptr = get_resource_by_name(name);

            return success;
        }

        // Polymorphic type, instantiate with a simple factory and fall back to standard struct serialization
        // @NOTE(remi): Maybe this should be allowed for any pointer and not just polymorphic types honestly
        // Maybe it is a different case where serializing type does not matter, but I don't know the actual use case yet

        // The deinit thing does not seem to be related to being polymorphic or not, and probably not even being a pointer
        // I think reading over a struct should trigger it, just like with strings, but it is probably best to avoid the pattern in the first place
        // polymorphic pointer is specific though cause we are dropping and replacing the whole chunk of memory, and not writing over it
        if is_polymorphic(tis)
        {
            object_ptr: *void = <<cast(**void)data;

            if serializer.mode == .WRITE && object_ptr == null
            {
                return serialize_null(serializer, key);
            }

            // First incursion into the object to get the type
            if !serializer_begin_object(serializer, null, key) return false;

            polymorphic_tis: *Type_Info_Struct;
            type_name: StringHash;

            if serializer.mode == .WRITE
            {
                polymorphic_tis = polymorphic_get_type(object_ptr, tis);
                assert(polymorphic_tis != null);
                type_name = string_hash(polymorphic_tis.name);
            }
            serialize(serializer, *type_name, "type");
            if serializer.mode == .READ
            {
                polymorphic_tis = get_type_by_name(type_name);
            }

            verify(serializer_end_object(serializer));

            // Unknown type, we fail
            if polymorphic_tis == null return false;

            // Instantiate o
            if serializer.mode == .READ
            {
                if object_ptr != null
                {
                    polymorphic_deinit(object_ptr, polymorphic_tis);
                    free(object_ptr);
                }
                object_ptr = alloc(polymorphic_tis.runtime_size);
                <<cast(**void)data = object_ptr;
                default_init(object_ptr, polymorphic_tis);
            }
            return serialize(serializer, object_ptr, polymorphic_tis, key);
        }
    }

    // Basic types
    if info.type == {
        case .STRUCT;
        {
            if info ==
            {
                case type_info(IntVector2);
                {
                    vector: *s32 = data;
                    size: s64 = 2;
                    if !serializer_begin_array(serializer, *size, key) return false;
                    if size != 2 return false;
                    verify(serializer_set_array_index(serializer, 0));
                    verify(serialize(serializer, vector));
                    verify(serializer_set_array_index(serializer, 1));
                    verify(serialize(serializer, vector+1));
                    verify(serializer_end_array(serializer));
                    return true;
                }
                case type_info(Vector2);
                {
                    vector: *float = data;
                    size: s64 = 2;
                    if !serializer_begin_array(serializer, *size, key) return false;
                    if size != 2 return false;
                    verify(serializer_set_array_index(serializer, 0));
                    verify(serialize(serializer, vector));
                    verify(serializer_set_array_index(serializer, 1));
                    verify(serialize(serializer, vector+1));
                    verify(serializer_end_array(serializer));
                    return true;
                }
                case type_info(Vector3);
                {
                    vector: *float = data;
                    size: s64 = 3;
                    if !serializer_begin_array(serializer, *size, key) return false;
                    if size != 3 return false;
                    verify(serializer_set_array_index(serializer, 0));
                    verify(serialize(serializer, vector));
                    verify(serializer_set_array_index(serializer, 1));
                    verify(serialize(serializer, vector+1));
                    verify(serializer_set_array_index(serializer, 2));
                    verify(serialize(serializer, vector+2));
                    verify(serializer_end_array(serializer));
                    return true;
                }
                case type_info(Vector4);
                {
                    vector: *float = data;
                    size: s64 = 4;
                    if !serializer_begin_array(serializer, *size, key) return false;
                    if size != 4 return false;
                    verify(serializer_set_array_index(serializer, 0));
                    verify(serialize(serializer, vector));
                    verify(serializer_set_array_index(serializer, 1));
                    verify(serialize(serializer, vector+1));
                    verify(serializer_set_array_index(serializer, 2));
                    verify(serialize(serializer, vector+2));
                    verify(serializer_set_array_index(serializer, 3));
                    verify(serialize(serializer, vector+3));
                    verify(serializer_end_array(serializer));
                    return true;
                }
                case type_info(Quaternion);
                {
                    vector: *float = data;
                    size: s64 = 4;
                    if !serializer_begin_array(serializer, *size, key) return false;
                    if size != 4 return false;
                    verify(serializer_set_array_index(serializer, 0));
                    verify(serialize(serializer, vector));
                    verify(serializer_set_array_index(serializer, 1));
                    verify(serialize(serializer, vector+1));
                    verify(serializer_set_array_index(serializer, 2));
                    verify(serialize(serializer, vector+2));
                    verify(serializer_set_array_index(serializer, 3));
                    verify(serialize(serializer, vector+3));
                    verify(serializer_end_array(serializer));
                    return true;
                }

                case type_info(StringHash);
                {
                    string_hash_ptr: = cast(*StringHash)data;
                    str: =  string_hash_ptr.str;
                    if !serialize(serializer, *str, key, *temporary_allocator) return false;
                    <<string_hash_ptr = string_hash(str);
                    return true;
                }

                case;
                {
                    info_struct: = cast(*Type_Info_Struct) info;

                    // Table
                    if info_struct.name == "Table"
                    {
                        assert(info_struct.specified_parameters.count == 6);

                        key_type: = get_polymorphic_argument(*Type_Info, info_struct, 0);
                        value_type: = get_polymorphic_argument(*Type_Info, info_struct, 1);

                        if key_type != type_info(StringHash)
                        {
                            log_warning("unsupported Table key type (%): Only StringHash is supported for now", <<key_type);
                            return false;
                        }

                        serialize_table :: (serializer: *Serializer, table: *Table(StringHash, $Dummy_Value_Type), value_type_info: *Type_Info, key: string) -> bool
                        {
                            keys: [..]string;
                            keys.allocator = temporary_allocator;

                            if serializer.mode == .WRITE
                            {
                                for _, key: table
                                {
                                    array_add(*keys, tprint("%", key.str));
                                }
                            }

                            if !serializer_begin_object(serializer, *keys, key) return false;
                            defer verify(serializer_end_object(serializer));

                            for key: keys
                            {
                                //NOTE: Need to convert string to number for int types. Can do this with a preprocessor
                                key_hash: = string_hash(key);
                                value_ptr: = find_or_add(table, key_hash);
                                serialize(serializer, value_ptr, value_type_info, key);
                            }
                            return true;
                        }

                        if value_type.runtime_size ==
                        {
                            case 1; return serialize_table(serializer, cast(*Table(StringHash,u8))data, value_type, key);
                            case 2; return serialize_table(serializer, cast(*Table(StringHash,u16))data, value_type, key);
                            case 4; return serialize_table(serializer, cast(*Table(StringHash,u32))data, value_type, key);
                            case 8; return serialize_table(serializer, cast(*Table(StringHash,u64))data, value_type, key);
                            case;
                            {
                                log_warning("unsupported Table value type (%)", <<value_type);
                                return false;
                            }
                        }
                    }

                    // Custom serialize
                    custom_serialize_function: = get_custom_serialize_function(info_struct);
                    if custom_serialize_function != null
                    {
                        return custom_serialize_function(serializer, data, info_struct, key);
                    }

                    // We do not serialize unions
                    if info_struct.textual_flags & .UNION
                    {
                        return true;
                    }

                    // NOTE: we may want to not flatten the keys and notes at some point, so we can consider each struct notes separately
                    keys, key_to_member_info, notes: = get_flattened_struct_members(info_struct, "serialize");
                    serialize_filter_function: = get_serialize_filter_function(info_struct);

                    if !serializer_begin_object(serializer, *keys, key) return false;

                    for key : keys
                    {
                        success, member_info: = table_find_new(*key_to_member_info, key);
                        if !success { continue; } // For now we just skip unfound entries. We'll see if we need something more elaborate in the future

                        skip: = false;
                        // serialize filter
                        if serialize_filter_function != null
                        {
                            skip = !serialize_filter_function(data, info_struct, member_info.tis_member);
                        }
                        if skip { continue; }

                        member_data: = data + member_info.offset;

                        // NOTE: for now we don't do anything if one of the members fails. We'll probably need a flag to define behavior but let's wait for use cases
                        serialize(serializer, member_data, member_info.tis_member.type, key);
                    }
                    verify(serializer_end_object(serializer));

                    return true;
                }
            }
        }
        case .INTEGER;
        {
            info_int: = cast(*Type_Info_Integer) info;
            if info_int.signed
            {
                if info.runtime_size ==
                {
                    case 1; { if !serialize(serializer, cast(*s8)data, key) return false; }
                    case 2; { if !serialize(serializer, cast(*s16)data, key) return false; }
                    case 4; { if !serialize(serializer, cast(*s32)data, key) return false; }
                    case 8; { if !serialize(serializer, cast(*s64)data, key) return false; }
                }
            }
            else
            {
                if info.runtime_size ==
                {
                    case 1; { if !serialize(serializer, cast(*u8)data, key) return false; }
                    case 2; { if !serialize(serializer, cast(*u16)data, key) return false; }
                    case 4; { if !serialize(serializer, cast(*u32)data, key) return false; }
                    case 8; { if !serialize(serializer, cast(*u64)data, key) return false; }
                }
            }
            return true;
        }
        case .FLOAT;
        {
            if info.runtime_size ==
            {
                case 4; { if !serialize(serializer, cast(*float32)data, key) return false; }
                case 8; { if !serialize(serializer, cast(*float64)data, key) return false; }
            }
            return true;
        }
        case .BOOL;
        {
            if !serialize(serializer, cast(*bool)data, key) return false;
            return true;
        }
        case .STRING;
        {
            if !serialize(serializer, cast(*string)data, key) return false;
            return true;
        }
        case .ENUM;
        {
            serialize_enum_value :: (serializer: *Serializer, data: *$T, type: *Type_Info_Enum, key: string) -> bool
            {
                if serializer.mode == {
                    case .READ;
                    {
                        enum_name: string;
                        {
                            if !serialize(serializer, *enum_name, key, *temporary_allocator) return false;
                        }
                        for name, i : type.names
                        {
                            if name == enum_name
                            {
                                <<data = cast(T) type.values[i];
                                return true;
                            }
                        }
                    }
                    case .WRITE;
                    {
                        enum_value: s64 = cast(s64) <<data;
                        for value, i : type.values
                        {
                            if value == enum_value
                            {
                                if !serialize(serializer, *type.names[i], key) return false;
                                return true;
                            }
                        }
                    }
                }
                return false;
            }

            info_enum: = cast(*Type_Info_Enum) info;
            if info_enum.internal_type.signed
            {
                if info.runtime_size ==
                {
                    case 1; { if !serialize_enum_value(serializer, cast(*s8)data, info_enum, key) return false; }
                    case 2; { if !serialize_enum_value(serializer, cast(*s16)data, info_enum, key) return false; }
                    case 4; { if !serialize_enum_value(serializer, cast(*s32)data, info_enum, key) return false; }
                    case 8; { if !serialize_enum_value(serializer, cast(*s64)data, info_enum, key) return false; }
                }
            }
            else
            {
                if info.runtime_size ==
                {
                    case 1; { if !serialize_enum_value(serializer, cast(*u8)data, info_enum, key) return false; }
                    case 2; { if !serialize_enum_value(serializer, cast(*u16)data, info_enum, key) return false; }
                    case 4; { if !serialize_enum_value(serializer, cast(*u32)data, info_enum, key) return false; }
                    case 8; { if !serialize_enum_value(serializer, cast(*u64)data, info_enum, key) return false; }
                }
            }
            return true;
        }
        case .ARRAY;
        {
            info_array: = cast(*Type_Info_Array) info;
            size: s64;
            array_data: *void;

            if info_array.array_type == {
                case .FIXED;
                {
                    size = info_array.array_count;
                    if !serializer_begin_array(serializer, *size, key) return false;
                    if size > info_array.array_count
                    {
                        serializer.last_error = tprint("%: Read array element count is bigger than the fixed array size (% > %)", key, size, info_array.array_count);
                        return false;
                    }
                    array_data = data;
                }

                case .VIEW;
                {
                    array_view: *Array_View_64 = data;
                    size = array_view.count;
                    if !serializer_begin_array(serializer, *size, key) return false;
                    if serializer.mode == .READ
                    {
                        array_view.count = size;
                        array_view.data = alloc(size * info_array.element_type.runtime_size);
                    }
                    array_data = array_view.data;
                }

                case .RESIZABLE;
                {
                    array_resizable: *Resizable_Array = data;
                    size = array_resizable.count;
                    if !serializer_begin_array(serializer, *size, key) return false;
                    array_data = array_resizable.data;

                    if serializer.mode == .READ
                    {
                        previous_count: = array_resizable.count;
                        array_resizable.count = size;
                        
                        maybe_grow(array_resizable, info_array.element_type.runtime_size);
                        array_data = array_resizable.data;

                        default_init_range(array_data, previous_count, size-1, info_array.element_type);
                    }
                }
            }

            success: = true;
            for i : 0..(size-1)
            {
                serializer_set_array_index(serializer, i);
                element_data: = array_data + i * info_array.element_type.runtime_size;

                // What to do if only one element of the array fails?
                success = serialize(serializer, element_data, info_array.element_type, "") && success;
            }
            verify(serializer_end_array(serializer));
            return success;
        }
    }
    return false;
}

#scope_file
