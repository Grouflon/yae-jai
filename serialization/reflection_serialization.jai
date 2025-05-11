CustomSerializationFunction :: #type (serializer: *Serializer, data: *void, info: *Type_Info,  key: string, params: SerializationParams, ctx: ReflectionContext) -> (default_serialize: bool, success: bool);

SerializationFilter :: struct
{
    type: enum
    {
        IN;  // Only serialize members that have the note
        OUT; // Do not serialize members that have the note
    }
    subclass: *Type_Info; // Restrict the filter to subclasses of this
    note: string;   
}

SerializationParams :: struct
{
    filters: []SerializationFilter;
    custom_serialization_function: CustomSerializationFunction;
}

ReflectionContext :: struct
{
    parent: *Type_Info_Struct;
    member: *Type_Info_Struct_Member;
}

serialize :: (serializer: *Serializer, value: *$T, key: string = "", params: SerializationParams = .{}) -> bool
{
    return serialize(serializer, value, type_info(T), key, params);
}

serialize :: (serializer: *Serializer, data: *void, info: *Type_Info, key: string = "", params: SerializationParams = .{}, ctx: ReflectionContext = .{}) -> bool
{
    if params.custom_serialization_function != null
    {
        fallback_to_default, success := params.custom_serialization_function(serializer, data, info, key, params, ctx);
        if !fallback_to_default
        {
            return success;
        }
    }

    // Object ID, override
    if is_subclass_of(info, ObjectIDBase)
    {
        // If embed, serialize data directyly
        if has_note(ctx.member, "embed")
        {
            id_ptr: = cast(*ObjectIDBase) data;
            object: = get(<<id_ptr);
            if !object_serialize(serializer, *object, key) return false;
            <<id_ptr = ifx object != null then object.id else 0;

            return true;
        }
        else // else serialize id
        {
            return serialize(serializer, cast(*ObjectIDBase) data, key);
        }
    }

    // Object pointer, override
    if info.type == .POINTER
    {
        ti: = (cast(*Type_Info_Pointer) info).pointer_to;
        if is_subclass_of(ti, Object)
        {
            object_ptr: = cast(**Object) data;

            // If embed, serialize data directyly
            success: = false;
            if has_note(ctx.member, "embed")
            {
                success = object_serialize(serializer, object_ptr, key);
            }
            else // else serialize id
            {
                object: = <<object_ptr;
                id: ObjectIDBase = ifx object != null then object.id else 0;
                success = serialize(serializer, *id, key);
                <<object_ptr = get(id);
            }

            return success;
        }
    }

    // Basic types
    if info.type == {
        case .STRUCT;
        {
            if info ==
            {
                case type_info(Vector2);
                {
                    vector: *float = data;
                    size: s64 = 2;
                    if !serializer_begin_array(serializer, *size, key) return false;
                    if size != 2 return false;
                    verify(serialize(serializer, vector));
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
                    verify(serialize(serializer, vector));
                    verify(serialize(serializer, vector+1));
                    verify(serialize(serializer, vector+2));
                    verify(serializer_end_array(serializer));
                    return true;
                }
                case type_info(Quaternion);
                {
                    vector: *float = data;
                    size: s64 = 4;
                    if !serializer_begin_array(serializer, *size, key) return false;
                    if size != 4 return false;
                    verify(serialize(serializer, vector));
                    verify(serialize(serializer, vector+1));
                    verify(serialize(serializer, vector+2));
                    verify(serialize(serializer, vector+3));
                    verify(serializer_end_array(serializer));
                    return true;
                }

                case;
                {
                    info_struct: = cast(*Type_Info_Struct) info;

                    // Table
                    if info_struct.name == "Table"
                    {
                        assert(info_struct.specified_parameters.count == 6);
                        assert(info_struct.specified_parameters[0].type.type == .TYPE);
                        assert(info_struct.specified_parameters[0].offset_into_constant_storage >= 0);
                        assert(info_struct.specified_parameters[1].type.type == .TYPE);
                        assert(info_struct.specified_parameters[1].offset_into_constant_storage >= 0);

                        key_type: *Type_Info = <<cast(**Type_Info)(info_struct.constant_storage.data + info_struct.specified_parameters[0].offset_into_constant_storage);
                        value_type: *Type_Info = <<cast(**Type_Info)(info_struct.constant_storage.data + info_struct.specified_parameters[1].offset_into_constant_storage);

                        if key_type != type_info(StringHash)
                        {
                            log_warning("unsupported Table key type (%): Only StringHash is supported for now", <<key_type);
                            return false;
                        }

                        serialize_table :: (serializer: *Serializer, table: *Table(StringHash, $Dummy_Value_Type), value_type_info: *Type_Info, key: string, params: SerializationParams, ctx: ReflectionContext) -> bool
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
                                serialize(serializer, value_ptr, value_type_info, key, params, ctx);
                            }
                            return true;
                        }

                        if value_type.runtime_size ==
                        {
                            case 1; return serialize_table(serializer, cast(*Table(StringHash,u8))data, value_type, key, params, ctx);
                            case 2; return serialize_table(serializer, cast(*Table(StringHash,u16))data, value_type, key, params, ctx);
                            case 4; return serialize_table(serializer, cast(*Table(StringHash,u32))data, value_type, key, params, ctx);
                            case 8; return serialize_table(serializer, cast(*Table(StringHash,u64))data, value_type, key, params, ctx);
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
                        fallback_to_default, success: = custom_serialize_function(serializer, data, info_struct, key, params, ctx);
                        if !fallback_to_default
                        {
                            return success;
                        }
                    }

                    // We do not serialize unions
                    if info_struct.textual_flags & .UNION return true;

                    next_context: ReflectionContext;
                    next_context.parent = info_struct;

                    // NOTE: we may want to not flatten the keys and notes at some point, so we can consider each struct notes separately
                    keys, key_to_type_info, notes: = gather_members_flat(info_struct);
                    serialize_optin: = has_note(notes, "serialize_optin");

                    if !serializer_begin_object(serializer, *keys, key) return false;

                    for key : keys
                    {
                        member_type_info, success: = table_find(*key_to_type_info, key);
                        if !success { continue; } // For now we just skip unfound entries. We'll see if we need something more elaborate in the future

                        // @serialize filter
                        if serialize_optin && !has_note(member_type_info, "serialize") { continue; }

                        // params filters
                        skip: = false;
                        for filter: params.filters
                        {
                            if filter.subclass != null && !is_subclass_of(info_struct, filter.subclass) { continue; }

                            match: = has_note(member_type_info, filter.note);
                            if filter.type == .IN && !match { skip = true; break; }
                            else if filter.type == .OUT && match { skip = true; break; }
                        }
                        if skip { continue; }

                        next_context.member = member_type_info;
                        member_data: = data + member_type_info.offset_in_bytes;

                        // NOTE: for now we don't do anything if one of the members fails. We'll probably need a flag to define behavior but let's wait for use cases
                        serialize(serializer, member_data, member_type_info.type, key, params, next_context);
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
                    if serializer.mode == .READ
                    {
                        array_resizable.count = size;
                        maybe_grow(array_resizable, info_array.element_type.runtime_size);
                    }
                    array_data = array_resizable.data;
                }
            }

            for i : 0..(size-1)
            {
                element_data: = array_data + i * info_array.element_type.runtime_size;

                // What to do if only one element of the array fails?
                verify(serialize(serializer, element_data, info_array.element_type, "", params, ctx));
            }
            verify(serializer_end_array(serializer));
            return true;
        }
    }
    return false;
}

#scope_file

gather_members_flat :: (info: *Type_Info_Struct) -> keys: []string, key_to_type: Table(string, *Type_Info_Struct_Member), notes: []string
{
    keys: [..]string;
    keys.allocator = temporary_allocator;

    key_to_type_info: Table(string, *Type_Info_Struct_Member);
    key_to_type_info.allocator = temporary_allocator;

    notes: [..]string;
    notes.allocator = temporary_allocator;

    gather_members_flat(info, *keys, *key_to_type_info, *notes);
    return keys, key_to_type_info, notes;
}

gather_members_flat :: (info: *Type_Info_Struct, keys: *[..]string, key_to_type: *Table(string, *Type_Info_Struct_Member), notes: *[..]string)
{
    assert(info != null);
    assert(keys != null);
    assert(key_to_type != null);
    assert(notes != null);

    array_add(notes, ..info.notes);

    for member_type_info, i : info.members
    {
        if member_type_info.flags & .AS
        {
            assert(i == 0, "#as members are only supported in first position for now");
            if member_type_info.type.type == .STRUCT
            {
                gather_members_flat(xx member_type_info.type, keys, key_to_type, notes);
            }
        }
        else
        {
            array_add(keys, member_type_info.name);
            table_add(key_to_type, member_type_info.name, info.members.data + i);
        }
    }
}