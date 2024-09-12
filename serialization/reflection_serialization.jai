serialize :: (serializer: *Serializer, value: *$T, key: string = "") -> bool
{
    return serialize(serializer, value, type_info(T), key);
}

serialize :: (serializer: *Serializer, data: *void, info: *Type_Info, key: string = "") -> bool
{
    if info.type == {
        case .STRUCT;
        {
            if info ==
            {
                case type_info(Vector2);
                {
                    vector: *float = data;
                    size: s64 = 2;
                    verify(serializer_begin_array(serializer, *size, key));
                    assert(size == 2);
                    verify(serialize(serializer, vector));
                    verify(serialize(serializer, vector+1));
                    verify(serializer_end_array(serializer));
                }
                case type_info(Vector3);
                {
                    vector: *float = data;
                    size: s64 = 3;
                    verify(serializer_begin_array(serializer, *size, key));
                    assert(size == 3);
                    verify(serialize(serializer, vector));
                    verify(serialize(serializer, vector+1));
                    verify(serialize(serializer, vector+2));
                    verify(serializer_end_array(serializer));
                }
                case type_info(Quaternion);
                {
                    vector: *float = data;
                    size: s64 = 4;
                    verify(serializer_begin_array(serializer, *size, key));
                    assert(size == 4);
                    verify(serialize(serializer, vector));
                    verify(serialize(serializer, vector+1));
                    verify(serialize(serializer, vector+2));
                    verify(serialize(serializer, vector+3));
                    verify(serializer_end_array(serializer));
                }

                case;
                {
                    info_struct: = cast(*Type_Info_Struct) info;

                    keys: []string;
                    keys.count = info_struct.members.count;
                    keys.data = talloc(keys.count * size_of(string));

                    key_to_type_info: Table(string, *Type_Info_Struct_Member);
                    key_to_type_info.allocator = temporary_allocator;

                    for member_type_info, i : info_struct.members
                    {
                        keys[i] = member_type_info.name;
                        table_add(*key_to_type_info, member_type_info.name, info_struct.members.data + i);
                    }

                    verify(serializer_begin_object(serializer, *keys, key));
                    for key : keys
                    {
                        member_type_info, success: = table_find(*key_to_type_info, key);
                        if !success { continue; } // For now we just skip unfound entries. We'll see if we need something more elaborate in the future
                        
                        member_data: = data + member_type_info.offset_in_bytes;
                        verify(serialize(serializer, member_data, member_type_info.type, key));
                    }
                    verify(serializer_end_object(serializer));
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
                    case 1; { verify(serialize(serializer, cast(*s8)data, key)); }
                    case 2; { verify(serialize(serializer, cast(*s16)data, key)); }
                    case 4; { verify(serialize(serializer, cast(*s32)data, key)); }
                    case 8; { verify(serialize(serializer, cast(*s64)data, key)); }
                }
            }
            else
            {
                if info.runtime_size ==
                {
                    case 1; { verify(serialize(serializer, cast(*u8)data, key)); }
                    case 2; { verify(serialize(serializer, cast(*u16)data, key)); }
                    case 4; { verify(serialize(serializer, cast(*u32)data, key)); }
                    case 8; { verify(serialize(serializer, cast(*u64)data, key)); }
                }
            }
        }
        case .FLOAT;
        {
            if info.runtime_size ==
            {
                case 4; { verify(serialize(serializer, cast(*float32)data, key)); }
                case 8; { verify(serialize(serializer, cast(*float64)data, key)); }
            }
        }
        case .BOOL;
        {
            verify(serialize(serializer, cast(*bool)data, key));
        }
        case .STRING;
        {
            verify(serialize(serializer, cast(*string)data, key));
        }
        case .ENUM;
        {
            serialize_enum_value :: (serializer: *Serializer, data: *$T, type: *Type_Info_Enum, key: string) -> bool
            {
                if serializer.mode == {
                    case .READ;
                    {
                        enum_name: string;
                        verify(serialize(serializer, *enum_name, key));
                        for name, i : type.names
                        {
                            if name == enum_name
                            {
                                <<data = cast(T) type.values[i];
                                break;
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
                                verify(serialize(serializer, *type.names[i], key));
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
                    case 1; { verify(serialize_enum_value(serializer, cast(*s8)data, info_enum, key)); }
                    case 2; { verify(serialize_enum_value(serializer, cast(*s16)data, info_enum, key)); }
                    case 4; { verify(serialize_enum_value(serializer, cast(*s32)data, info_enum, key)); }
                    case 8; { verify(serialize_enum_value(serializer, cast(*s64)data, info_enum, key)); }
                }
            }
            else
            {
                if info.runtime_size ==
                {
                    case 1; { verify(serialize_enum_value(serializer, cast(*u8)data, info_enum, key)); }
                    case 2; { verify(serialize_enum_value(serializer, cast(*u16)data, info_enum, key)); }
                    case 4; { verify(serialize_enum_value(serializer, cast(*u32)data, info_enum, key)); }
                    case 8; { verify(serialize_enum_value(serializer, cast(*u64)data, info_enum, key)); }
                }
            }
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
                    verify(serializer_begin_array(serializer, *size, key));
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
                    verify(serializer_begin_array(serializer, *size, key));
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
                    verify(serializer_begin_array(serializer, *size, key));
                    if serializer.mode == .READ
                    {
                        if array_resizable.allocated < size
                        {
                            allocator: Allocator = ifx array_resizable.allocator.proc != null then array_resizable.allocator else context.allocator;
                            push_allocator(allocator);
                            array_resizable.data = realloc(array_resizable.data, size, array_resizable.allocated);
                            array_resizable.allocated = size;
                        }
                    }
                    array_resizable.count = size;
                    array_data = array_resizable.data;
                }
            }

            for i : 0..(size-1)
            {
                element_data: = array_data + i * info_array.element_type.runtime_size;
                verify(serialize(serializer, element_data, info_array.element_type));
            }
            verify(serializer_end_array(serializer));
        }
    }
    return true;
}