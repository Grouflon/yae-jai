// a YAE_COMPILE_TIME_INFO constant is generated at compile time. see `yae_notify_compiler_message` TYPECHECKED_ALL_WE_CAN notify
YaeCompileTimeInfo :: struct
{
    resource_types: []*Type_Info_Struct;
    custom_serialize_types: []CustomSerializeType;
}

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

                if is_subclass_of(struct_type_info, Resource, false)
                {
                    array_add(*resource_types, struct_type_info);
                }

                found, args: = has_note_with_args(struct_type_info, "custom_serialize");
                if found && args.count > 0
                {
                    table_add(*custom_serialize_table, struct_type_info, args[0]);
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

                        // Custom serialization procedures
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

object_types: [..]*Type_Info_Struct;
resource_types: [..]*Type_Info_Struct;
custom_serialize_table: Table(*Type_Info_Struct, string);

generated_compile_time_info: = false;

#import "Compiler";
#import "Hash_Table";
