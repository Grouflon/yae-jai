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

                if is_subclass_of(struct_type_info, "Resource")
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
                    // Generate Resource Types array
                    if !generated_resource_types
                    {
                        sb: String_Builder;
                        init_string_builder(*sb);
                        append(*sb, "resource_types: []*Type_Info_Struct = .[");
                        for struct_type_info, i: resource_types
                        {
                            if i > 0 append(*sb, ",");
                            append(*sb, tprint("type_info(%)", struct_type_info.name));
                        }
                        append(*sb, "];");

                        add_build_string(builder_to_string(*sb), w);
                        generated_resource_types = true;
                    }

                    // Generate custom serialization routines array
                    if !generated_custom_serialize
                    {
                        sb: String_Builder;
                        init_string_builder(*sb);
                        append(*sb, "custom_serialize_types: []CustomSerializeType = .[");
                        i: = 0;
                        for function_name, ti: custom_serialize_table
                        {
                            if i > 0 append(*sb, ",");
                            append(*sb, tprint(".{ti=type_info(%), function=%}", ti.name, function_name));
                            i+=1;
                        }
                        append(*sb, "];");

                        add_build_string(builder_to_string(*sb), w);
                        generated_custom_serialize = true;
                    }
                }
            }
        }
    }
}

#scope_file

resource_types: [..]*Type_Info_Struct;
generated_resource_types: = false;
generated_custom_serialize: = false;
custom_serialize_table: Table(*Type_Info_Struct, string);

#import "Compiler";
#import "Hash_Table";
