// a YAE_COMPILE_TIME_INFO constant is generated at compile time. see `yae_notify_compiler_message` TYPECHECKED_ALL_WE_CAN notify
// Runtime
YaeCompileTimeInfo :: struct
{
    resource_types: []*Type_Info_Struct;
    custom_serialize_types: []TypeFunction(CustomSerializationFunction);
    custom_editor_types: []TypeFunction(CustomEditorFunction);
}

CustomSerializationFunction :: #type (serializer: *Serializer, data: *void, info: *Type_Info,  key: string, params: SerializationParams, ctx: ReflectionContext) -> (default_serialize: bool, success: bool);
CustomEditorFunction :: #type (data: *void, info: *Type_Info) -> bool;

TypeFunction :: struct(function_type: Type)
{
    ti: *Type_Info;
    function: function_type;
}

custom_function_registry : struct 
{
    custom_serialize_registry: Table(*Type_Info, CustomSerializationFunction);
    custom_editor_registry: Table(*Type_Info, CustomEditorFunction);
};

custom_function_registry_init :: (compile_time_info: *YaeCompileTimeInfo)
{
    using custom_function_registry;

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
}

serialization_manager_shutdown :: ()
{
    using custom_function_registry;

    deinit(*custom_serialize_registry);
    deinit(*custom_editor_registry);
}

get_custom_serialize_function :: (ti: *Type_Info) -> CustomSerializationFunction
{
    using custom_function_registry;

    found, f: = table_find_new(*custom_serialize_registry, ti);
    if found return f;
    return null;
}

get_custom_editor_function :: (ti: *Type_Info) -> CustomEditorFunction
{
    using custom_function_registry;

    found, f: = table_find_new(*custom_editor_registry, ti);
    if found return f;
    return null;
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
                struct_type_info: = st.expression.defined_type;

                // Resource Types
                if is_subclass_of(struct_type_info, Resource, false)
                {
                    array_add(*resource_types, struct_type_info);
                }

                // Custom Serialize
                {
                    found, args: = has_note_with_args(struct_type_info, "custom_serialize");
                    if found && args.count > 0
                    {
                        table_add(*custom_serialize_table, struct_type_info, args[0]);
                    }
                }

                // Custom Editor
                {
                    found, args: = has_note_with_args(struct_type_info, "custom_editor");
                    if found && args.count > 0
                    {
                        table_add(*custom_editor_table, struct_type_info, args[0]);
                    }
                }
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
                            append(*sb, "resource_types= .[\n");
                            for struct_type_info, i: resource_types
                            {
                                if i > 0 append(*sb, ",\n");
                                append(*sb, tprint("type_info(%)", struct_type_info.name));
                            }
                            append(*sb, "],\n");
                        }

                        // Custom Serialize
                        {
                            append(*sb, "custom_serialize_types= .[\n");
                            i: = 0;
                            for function_name, ti: custom_serialize_table
                            {
                                if i > 0 append(*sb, ",\n");
                                append(*sb, tprint(".{ti=type_info(%), function=%}", ti.name, function_name));
                                i+=1;
                            }
                            append(*sb, "],\n");
                        }

                        // Custom Editor
                        {
                            append(*sb, "custom_editor_types= .[\n");
                            i: = 0;
                            for function_name, ti: custom_editor_table
                            {
                                if i > 0 append(*sb, ",\n");
                                append(*sb, tprint(".{ti=type_info(%), function=%}", ti.name, function_name));
                                i+=1;
                            }
                            append(*sb, "],\n");
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
object_types: [..]*Type_Info_Struct;
resource_types: [..]*Type_Info_Struct;
custom_serialize_table: Table(*Type_Info_Struct, string);
custom_editor_table: Table(*Type_Info_Struct, string);
generated_compile_time_info: = false;

#import "Compiler";
#import "Hash_Table";
