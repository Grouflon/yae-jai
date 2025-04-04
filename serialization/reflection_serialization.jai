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

    // Resource ID, override
    if is_subclass_of(info, ResourceIDBase)
    {
        // If embed, serialize data directyly
        if has_note(ctx.member, "embed")
        {
            id_ptr: = cast(*ResourceIDBase) data;
            resource: = get(<<id_ptr);
            if !resource_serialize(serializer, *resource, key) return false;
            <<id_ptr = ifx resource != null then resource.id else 0;

            return true;
        }
        else // else serialize id
        {
            return serialize(serializer, cast(*ResourceIDBase) data, key);
        }
    }

    // Resource pointer, override
    if info.type == .POINTER
    {
        ti: = (cast(*Type_Info_Pointer) info).pointer_to;
        if is_subclass_of(ti, Resource)
        {
            resource_ptr: = cast(**Resource) data;
            resource: = <<resource_ptr;

            // If embed, serialize data directyly
            success: = false;
            if has_note(ctx.member, "embed")
            {
                success = resource_serialize(serializer, *resource, key);
            }
            else // else serialize id
            {
                id: ResourceIDBase = ifx resource != null then resource.id else 0;
                success = serialize(serializer, *id, key);
                <<resource_ptr = get(id);
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
                    assert(size == 2);
                    verify(serialize(serializer, vector));
                    verify(serialize(serializer, vector+1));
                    verify(serializer_end_array(serializer));
                }
                case type_info(Vector3);
                {
                    vector: *float = data;
                    size: s64 = 3;
                    if !serializer_begin_array(serializer, *size, key) return false;
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
                    if !serializer_begin_array(serializer, *size, key) return false;
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

                    keys, key_to_type_info: = gather_members_flat(info_struct);

                    if !serializer_begin_object(serializer, *keys, key) return false;

                    for key : keys
                    {
                        member_type_info, success: = table_find(*key_to_type_info, key);
                        if !success { continue; } // For now we just skip unfound entries. We'll see if we need something more elaborate in the future

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
                        verify(serialize(serializer, member_data, member_type_info.type, key, params, next_context));
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
        }
        case .FLOAT;
        {
            if info.runtime_size ==
            {
                case 4; { if !serialize(serializer, cast(*float32)data, key) return false; }
                case 8; { if !serialize(serializer, cast(*float64)data, key) return false; }
            }
        }
        case .BOOL;
        {
            if !serialize(serializer, cast(*bool)data, key) return false;
        }
        case .STRING;
        {
            if !serialize(serializer, cast(*string)data, key) return false;
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
        }
    }
    return true;
}

#scope_file

gather_members_flat :: (info: *Type_Info_Struct) -> keys: []string, key_to_type: Table(string, *Type_Info_Struct_Member)
{
    keys: [..]string;
    keys.allocator = temporary_allocator;

    key_to_type_info: Table(string, *Type_Info_Struct_Member);
    key_to_type_info.allocator = temporary_allocator;

    gather_members_flat(info, *keys, *key_to_type_info);
    return keys, key_to_type_info;
}

gather_members_flat :: (info: *Type_Info_Struct, keys: *[..]string, key_to_type: *Table(string, *Type_Info_Struct_Member))
{
    for member_type_info, i : info.members
    {
        if member_type_info.flags & .AS
        {
            assert(i == 0, "#as members are only supported in first position for now");
            if member_type_info.type.type == .STRUCT
            {
                gather_members_flat(xx member_type_info.type, keys, key_to_type);
            }
        }
        else
        {
            array_add(keys, member_type_info.name);
            table_add(key_to_type, member_type_info.name, info.members.data + i);
        }
    }
}