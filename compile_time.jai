// a YAE_COMPILE_TIME_INFO constant is generated at compile time. see `yae_notify_compiler_message` TYPECHECKED_ALL_WE_CAN notify
// Runtime
YaeCompileTimeInfo :: struct
{
    named_types: []*Type_Info_Struct;
    resource_types: []*Type_Info_Struct;
    custom_serialize_types: []TypeFunction(CustomSerializationFunction);
    custom_editor_types: []TypeFunction(CustomEditorFunction);
    serialize_filter_types: []TypeFunction(SerializeFilterFunction);
    deinit_functions: []TypeFunction(DeinitFunction);
}

CustomSerializationFunction :: #type (serializer: *Serializer, data: *void, info: *Type_Info,  key: string, params: SerializationParams, ctx: ReflectionContext) -> (default_serialize: bool, success: bool);
CustomEditorFunction :: #type (data: *void, info: *Type_Info) -> bool;
// @NOTE(remi): in the case of #as or unions, Type_Info_Struct_Member might come from a different Type_Info than the parent_info. Maybe it is not a good idea to give it as is
SerializeFilterFunction :: #type (parent_data: *void, parent_info: *Type_Info_Struct, member_info: *Type_Info_Struct_Member) -> bool;
DeinitFunction :: #type (ptr: *void);

TypeFunction :: struct(function_type: Type)
{
    ti: *Type_Info;
    function: function_type;
}

compile_time_registry : struct 
{
    custom_serialize_registry: Table(*Type_Info, CustomSerializationFunction);
    custom_editor_registry: Table(*Type_Info, CustomEditorFunction);
    serialize_filter_registry: Table(*Type_Info, SerializeFilterFunction);
    deinit_registry: Table(*Type_Info_Struct, DeinitFunction);
    named_types_registry: Table(StringHash, *Type_Info_Struct);
};



compile_time_registry_init :: (compile_time_info: *YaeCompileTimeInfo)
{
    using compile_time_registry;

    for type: compile_time_info.custom_serialize_types
    {
        if type.ti == null || type.function == null { continue; }
        table_add(*custom_serialize_registry, type.ti, type.function);
    }

    for type: compile_time_info.custom_editor_types
    {
        if type.ti == null || type.function == null { continue; }
        table_add(*custom_editor_registry, type.ti, type.function);
    }

    for type: compile_time_info.serialize_filter_types
    {
        if type.ti == null || type.function == null { continue; }
        table_add(*serialize_filter_registry, type.ti, type.function);
    }

    for type: compile_time_info.deinit_functions
    {
        if type.ti == null || type.function == null { continue; }
        table_add(*deinit_registry, xx type.ti, type.function);
    }

    for tis: compile_time_info.named_types
    {
        table_add(*named_types_registry, string_hash(tis.name), tis);
    }
}

compile_time_registry_shutdown :: ()
{
    using compile_time_registry;

    deinit(*custom_serialize_registry);
    deinit(*custom_editor_registry);
    deinit(*serialize_filter_registry);
    deinit(*named_types_registry);
}

get_serialize_filter_function :: (ti: *Type_Info) -> SerializeFilterFunction
{
    using compile_time_registry;

    found, f: = table_find_new(*serialize_filter_registry, ti);
    if found return f;
    return null;
}

get_custom_serialize_function :: (ti: *Type_Info) -> CustomSerializationFunction
{
    using compile_time_registry;

    found, f: = table_find_new(*custom_serialize_registry, ti);
    if found return f;
    return null;
}

get_custom_editor_function :: (ti: *Type_Info) -> CustomEditorFunction
{
    using compile_time_registry;

    found, f: = table_find_new(*custom_editor_registry, ti);
    if found return f;
    return null;
}

get_type_by_name :: (name: string) -> *Type_Info_Struct
{
    return get_type_by_name(string_hash(name));
}

get_type_by_name :: (name: StringHash) -> *Type_Info_Struct
{
    using compile_time_registry;

    found, tis: = table_find_new(*named_types_registry, name);
    if !found return null;
    return tis;
}

polymorphic_get_type :: (ptr: *$T) -> *Type_Info_Struct
{
    ti :: type_info(T);
    #assert ti.type == .STRUCT;
    #assert T != void;
    return polymorphic_get_type(ptr, xx ti);
}

is_polymorphic :: (tis: *Type_Info_Struct) -> bool
{
    return has_note(tis, "polymorphic");
}

polymorphic_get_type :: (ptr: *void, tis: *Type_Info_Struct) -> *Type_Info_Struct
{
    found, args: = has_note_with_args(tis, "polymorphic");
    if !found return null;
    assert(args.count == 1); // This is already checked for validity at compile time

    polymorphic_tis: *Type_Info_Struct;
    for tis_member: tis.members
    {
        if tis_member.name != args[0].text continue;

        polymorphic_tis = <<cast(**Type_Info_Struct)(ptr + tis_member.offset_in_bytes);
        break;
    }
    return polymorphic_tis;
}

polymorphic_deinit :: (ptr: *$T)
{
    ti :: type_info(T);
    #assert ti.type == .STRUCT;
    #assert T != void;
    polymorphic_deinit(ptr, xx ti);
}

polymorphic_deinit :: (ptr: *void, tis: *Type_Info_Struct)
{
    using compile_time_registry;

    polymorphic_tis: = polymorphic_get_type(ptr, tis);
    assert(polymorphic_tis != null);

    found, f: = table_find_new(*deinit_registry, polymorphic_tis);
    if !found return;
    f(ptr);
}

// Compile Time
yae_notify_compiler_message :: (w: Workspace, message: *Message)
{
    if message.kind ==
    {
        case .TYPECHECKED;
        {
            mt := cast(*Message_Typechecked) message;
            for st: mt.structs
            {
                tis: = st.expression.defined_type;

                // Resource Types
                if is_subclass_of(tis, Resource, false)
                {
                    array_add(*resource_types, tis);
                }

                // Custom Serialize
                {
                    found, args: = has_note_with_args(tis, "custom_serialize");
                    if found && args.count > 0
                    {
                        table_add(*custom_serialize_table, tis, args[0].text);
                    }
                }

                // Custom Editor
                {
                    found, args: = has_note_with_args(tis, "custom_editor");
                    if found && args.count > 0
                    {
                        table_add(*custom_editor_table, tis, args[0].text);
                    }
                }

                // Serialize Filter
                {
                    found, args: = has_note_with_args(tis, "serialize_filter");
                    if found && args.count > 0
                    {
                        table_add(*serialize_filter_table, tis, args[0].text);
                    }
                }

                // Polymorphic Types
                {
                    // Check syntax
                    found, args: = has_note_with_args(tis, "polymorphic");
                    if found
                    {
                        is_valid: = false;
                        if args.count == 1
                        {
                            for tis_member: tis.members
                            {
                                if tis_member.name != args[0].text continue;
                                if tis_member.type.type != .POINTER continue;
                                tip: *Type_Info_Pointer = xx tis_member.type;
                                if tip.pointer_to.type != .STRUCT continue;
                                pointer_tis: *Type_Info_Struct = xx tip.pointer_to;
                                if pointer_tis.name != "Type_Info_Struct" continue;
                                is_valid = true;
                            }
                        }
                        assert(is_valid, "Malformed polymorphic note: must be @polymorphic({member_name}) where {member_name} is a *Type_Info_Struct");
                    }

                    // Add all polymorphic hierarchy
                    if has_note(tis, "polymorphic", true)
                    {
                        array_add(*polymorphic_types, tis);
                    }
                }

                // Deinit procedures
                {
                    found, args: = has_note_with_args(tis, "deinit");
                    if found && args.count > 0
                    {
                        table_add(*deinit_procedures, tis, args[0].text);
                    }
                }
            }

            for ph: mt.procedure_headers
            {
            }
        }

        case .PHASE;
        {
            mp := cast(*Message_Phase) message;

            if mp.phase ==
            {
                case .TYPECHECKED_ALL_WE_CAN;
                {
                    if !generated_compile_time_info
                    {
                        sb: String_Builder;
                        init_string_builder(*sb);
                        append(*sb, "YAE_COMPILE_TIME_INFO : YaeCompileTimeInfo : .{\n");

                        // Resource Types
                        {
                            append(*sb, "resource_types= .[");
                            for tis, i: resource_types
                            {
                                if i > 0 append(*sb, ",");
                                append(*sb, tprint("\n\ttype_info(%)", tis.name));
                            }
                            append(*sb, "\n],\n");
                        }

                        // Deinit functions
                        {
                            append(*sb, "deinit_functions= .[");
                            i: = 0;
                            for function_name, tis: deinit_procedures
                            {
                                if i > 0 append(*sb, ",");
                                append(*sb, tprint("\n\t.{ti=type_info(%1), function=(ptr:*void){ %(cast(*%1)ptr); }}", tis.name, function_name));
                                i+=1;
                            }
                            append(*sb, "\n],\n");
                        }

                        // Custom Serialize
                        {
                            append(*sb, "custom_serialize_types= .[");
                            i: = 0;
                            for function_name, tis: custom_serialize_table
                            {
                                if i > 0 append(*sb, ",");
                                append(*sb, tprint("\n\t.{ti=type_info(%), function=%}", tis.name, function_name));
                                i+=1;
                            }
                            append(*sb, "\n],\n");
                        }

                        // Custom Editor
                        {
                            append(*sb, "custom_editor_types= .[");
                            i: = 0;
                            for function_name, tis: custom_editor_table
                            {
                                if i > 0 append(*sb, ",");
                                append(*sb, tprint("\n\t.{ti=type_info(%), function=%}", tis.name, function_name));
                                i+=1;
                            }
                            append(*sb, "\n],\n");
                        }

                        // Serialize Filter
                        {
                            append(*sb, "serialize_filter_types= .[");
                            i: = 0;
                            for function_name, tis: serialize_filter_table
                            {
                                if i > 0 append(*sb, ",");
                                append(*sb, tprint("\n\t.{ti=type_info(%), function=%}", tis.name, function_name));
                                i+=1;
                            }
                            append(*sb, "\n],\n");
                        }

                        // Named Types
                        {
                            append(*sb, "named_types= .[");
                            for tis, i: polymorphic_types
                            {
                                if i > 0 append(*sb, ",");
                                append(*sb, tprint("\n\ttype_info(%)", tis.name));
                            }
                            append(*sb, "\n],\n");
                        }

                        append(*sb, "};\n");

                        add_build_string(builder_to_string(*sb), w);
                        generated_compile_time_info = true;
                    }
                }
            }
        }
    }
}

#scope_file

// Compile time variables
resource_types: [..]*Type_Info_Struct;
polymorphic_types: [..]*Type_Info_Struct;
custom_serialize_table: Table(*Type_Info_Struct, string);
custom_editor_table: Table(*Type_Info_Struct, string);
serialize_filter_table: Table(*Type_Info_Struct, string);
deinit_procedures: Table(*Type_Info_Struct, string);

generated_compile_time_info: = false;

#import "Compiler";
#import "Hash_Table";
