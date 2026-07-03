// a YAE_COMPILE_TIME_INFO constant is generated at compile time. see `yae_notify_compiler_message` TYPECHECKED_ALL_WE_CAN notify
// Runtime
YaeCompileTimeInfo :: struct
{
    resource_types: []*Type_Info_Struct;
    child_types: []ChildType;
    custom_serialize_types: []TypeFunction(CustomSerializationFunction);
    custom_editor_types: []TypeFunction(CustomEditorFunction);
    serialize_filter_types: []TypeFunction(SerializeFilterFunction);

    initialize_functions: []TypeFunction(InitializeFunction);
    shutdown_functions: []TypeFunction(ShutdownFunction);
    update_functions: []TypeFunction(UpdateFunction);
    draw_functions: []TypeFunction(DrawFunction);
}

CustomSerializationFunction :: #type (serializer: *Serializer, data: *void, info: *Type_Info,  key: string) -> (success: bool);
CustomEditorFunction :: #type (data: *void, info: *Type_Info) -> bool;
// @NOTE(remi): in the case of #as or unions, Type_Info_Struct_Member might come from a different Type_Info than the parent_info. Maybe it is not a good idea to give it as is
SerializeFilterFunction :: #type (parent_data: *void, parent_info: *Type_Info_Struct, member_info: *Type_Info_Struct_Member) -> bool;
InitializeFunction :: #type (ptr: *void);
ShutdownFunction :: #type (ptr: *void);
UpdateFunction :: #type (ptr: *void, dt: float);
DrawFunction :: #type (ptr: *void);

TypeFunction :: struct(function_type: Type)
{
    ti: *Type_Info;
    group: string;
    function: function_type;
}

ChildType :: struct
{
    tis: *Type_Info_Struct;
    parent: *Type_Info_Struct;
}

FunctionGroup :: struct(function_type: Type)
{
    functions_by_type: Table(*Type_Info_Struct, function_type); // using a table here is not great cause update order can vary as we add new things to the table
}

compile_time_registry : struct 
{
    custom_serialize_registry: Table(*Type_Info, CustomSerializationFunction);
    serialize_filter_registry: Table(*Type_Info, SerializeFilterFunction);

    custom_editor_registry: Table(*Type_Info, CustomEditorFunction);

    type_by_name: Table(StringHash, *Type_Info_Struct);
    children_by_type: Table(*Type_Info_Struct, [..]*Type_Info_Struct);

    initialize_registry: Table(StringHash, FunctionGroup(InitializeFunction));
    shutdown_registry: Table(StringHash, FunctionGroup(ShutdownFunction));
    update_registry: Table(StringHash, FunctionGroup(UpdateFunction));
    draw_registry: Table(StringHash, FunctionGroup(DrawFunction));
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

    for function_group: compile_time_info.initialize_functions
    {
        if function_group.ti == null || function_group.function == null { continue; }
        group_hash: = string_hash(function_group.group);
        group: = find_or_add(*initialize_registry, group_hash);
        table_add(*group.functions_by_type, xx function_group.ti, function_group.function);
    }

    for function_group: compile_time_info.shutdown_functions
    {
        if function_group.ti == null || function_group.function == null { continue; }
        group_hash: = string_hash(function_group.group);
        group: = find_or_add(*shutdown_registry, group_hash);
        table_add(*group.functions_by_type, xx function_group.ti, function_group.function);
    }

    for function_group: compile_time_info.update_functions
    {
        if function_group.ti == null || function_group.function == null { continue; }
        group_hash: = string_hash(function_group.group);
        group: = find_or_add(*update_registry, group_hash);
        table_add(*group.functions_by_type, xx function_group.ti, function_group.function);
    }

    for function_group: compile_time_info.draw_functions
    {
        if function_group.ti == null || function_group.function == null { continue; }
        group_hash: = string_hash(function_group.group);
        group: = find_or_add(*draw_registry, group_hash);
        table_add(*group.functions_by_type, xx function_group.ti, function_group.function);
    }

    for child_type: compile_time_info.child_types
    {
        table_add(*type_by_name, string_hash(child_type.tis.name), child_type.tis);
        table_add(*type_by_name, string_hash(child_type.parent.name), child_type.parent);

        children: = find_or_add(*children_by_type, child_type.parent);
        array_add_if_unique(children, child_type.tis);
    }
}

compile_time_registry_shutdown :: ()
{
    using compile_time_registry;

    deinit(*custom_serialize_registry);
    deinit(*custom_editor_registry);
    deinit(*serialize_filter_registry);
    deinit(*type_by_name);

    for children: children_by_type
    {
        array_free(children);
    }
    deinit(*children_by_type);

    for group: initialize_registry
    {
        deinit(*group.functions_by_type);
    }
    deinit(*initialize_registry);

    for group: shutdown_registry
    {
        deinit(*group.functions_by_type);
    }
    deinit(*shutdown_registry);

    for group: update_registry
    {
        deinit(*group.functions_by_type);
    }
    deinit(*update_registry);

    for group: draw_registry
    {
        deinit(*group.functions_by_type);
    }
    deinit(*draw_registry);
}

get_serialize_filter_function :: (ti: *Type_Info) -> SerializeFilterFunction
{
    using compile_time_registry;

    found, f: = table_find(*serialize_filter_registry, ti);
    if found return f;
    return null;
}

get_custom_serialize_function :: (ti: *Type_Info) -> CustomSerializationFunction
{
    using compile_time_registry;

    found, f: = table_find(*custom_serialize_registry, ti);
    if found return f;
    return null;
}

get_custom_editor_function :: (ti: *Type_Info) -> CustomEditorFunction
{
    using compile_time_registry;

    found, f: = table_find(*custom_editor_registry, ti);
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

    found, tis: = table_find(*type_by_name, name);
    if !found return null;
    return tis;
}

get_initialize_function :: (ti: *Type_Info, group_name: string = "") -> InitializeFunction
{
    using compile_time_registry;

    group: = table_find_pointer(*initialize_registry, string_hash(group_name));
    if group == null return null;

    success, function: = table_find(*group.functions_by_type, xx ti);
    if !success return null;
    return function;
}

get_shutdown_function :: (ti: *Type_Info, group_name: string = "") -> ShutdownFunction
{
    using compile_time_registry;

    group: = table_find_pointer(*shutdown_registry, string_hash(group_name));
    if group == null return null;

    success, function: = table_find(*group.functions_by_type, xx ti);
    if !success return null;
    return function;
}

// polymorphic_get_type :: (ptr: *$T) -> *Type_Info_Struct
// {
//     ti :: type_info(T);
//     #assert ti.type == .STRUCT;
//     #assert T != void;
//     return polymorphic_get_type(ptr, xx ti);
// }

// is_polymorphic :: (tis: *Type_Info_Struct) -> bool
// {
//     return has_note(tis, "polymorphic");
// }

// polymorphic_cast :: (ptr: *$BaseType, $DestType: Type) -> *DestType
// {
//     if polymorphic_get_type(ptr) != type_info(DestType) return null;
//     return xx ptr;
// }

// polymorphic_get_type :: (ptr: *void, tis: *Type_Info_Struct) -> *Type_Info_Struct
// {
//     if ptr == null return null;

//     found, args: = has_note_with_args(tis, "polymorphic");
//     if !found return tis;
//     assert(args.count == 1); // This is already checked for validity at compile time

//     polymorphic_tis: *Type_Info_Struct;
//     for tis_member: tis.members
//     {
//         if tis_member.name != args[0].text continue;

//         polymorphic_tis = (ptr + tis_member.offset_in_bytes).(**Type_Info_Struct).*;
//         break;
//     }
//     return polymorphic_tis;
// }

update_group :: (dt: float, group_name: string = "")
{
    using compile_time_registry;

    group: = table_find_pointer(*update_registry, string_hash(group_name));
    if group == null return;

    for update_func, tis: group.functions_by_type
    {
        pool: = get_pool(tis);
        if pool == null continue;

        for item: pool
        {
            update_func(item, dt);
        }
    }
}

draw_group :: (group_name: string = "")
{
    using compile_time_registry;

    group: = table_find_pointer(*draw_registry, string_hash(group_name));
    if group == null return;

    for draw_func, tis: group.functions_by_type
    {
        pool: = get_pool(tis);
        if pool == null continue;

        for item: pool
        {
            draw_func(item);
        }
    }
    draw_all_commands();
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
                        parent: = get_parent_type(tis);
                        if parent != null && parent.type == .STRUCT
                        {
                            array_add(*child_types, .{tis = tis, parent = xx parent});
                        }
                    }
                }
            }

            for ph: mt.procedure_headers
            {
                if parse_group_procedure(*initialize_procedures, ph.expression, "initialize") continue;
                if parse_group_procedure(*shutdown_procedures, ph.expression, "shutdown") continue;
                if parse_group_procedure(*update_procedures, ph.expression, "update", .[.FLOAT]) continue;
                if parse_group_procedure(*draw_procedures, ph.expression, "draw") continue;
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

                        // Child Types
                        {
                            append(*sb, "child_types= .[");
                            for child_type, i: child_types
                            {
                                if i > 0 append(*sb, ",");
                                append(*sb, tprint("\n\t.{type_info(%),type_info(%)}", child_type.tis.name, child_type.parent.name));
                            }
                            append(*sb, "\n],\n");
                        }

                        // Initialize functions
                        {
                            append(*sb, "initialize_functions= .[");
                            i: = 0;
                            for procedure_group, tis: initialize_procedures
                            {
                                if i > 0 append(*sb, ",");
                                append(*sb, tprint("\n\t.{ti=type_info(%1), group=\"%3\", function=(ptr:*void){ %2(ptr.(*%1)); }}", tis.name, procedure_group.name, procedure_group.group));
                                i+=1;
                            }
                            append(*sb, "\n],\n");
                        }

                        // Shutdown functions
                        {
                            append(*sb, "shutdown_functions= .[");
                            i: = 0;
                            for procedure_group, tis: shutdown_procedures
                            {
                                if i > 0 append(*sb, ",");
                                append(*sb, tprint("\n\t.{ti=type_info(%1), group=\"%3\", function=(ptr:*void){ %2(ptr.(*%1)); }}", tis.name, procedure_group.name, procedure_group.group));
                                i+=1;
                            }
                            append(*sb, "\n],\n");
                        }

                        // Update functions
                        {
                            append(*sb, "update_functions= .[");
                            i: = 0;
                            for procedure_group, tis: update_procedures
                            {
                                if i > 0 append(*sb, ",");
                                append(*sb, tprint("\n\t.{ti=type_info(%1), group=\"%3\", function=(ptr:*void, dt:float){ %2(ptr.(*%1), dt); }}", tis.name, procedure_group.name, procedure_group.group));
                                i+=1;
                            }
                            append(*sb, "\n],\n");
                        }

                        // Draw functions
                        {
                            append(*sb, "draw_functions= .[");
                            i: = 0;
                            for procedure_group, tis: draw_procedures
                            {
                                if i > 0 append(*sb, ",");
                                append(*sb, tprint("\n\t.{ti=type_info(%1), group=\"%3\", function=(ptr:*void){ %2(ptr.(*%1)); }}", tis.name, procedure_group.name, procedure_group.group));
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

parse_group_procedure :: (table: *Table(*Type_Info_Struct, GroupProcedure), ph: *Code_Procedure_Header, function_name: string, additional_signature: []Type_Info_Tag = .[]) -> bool
{
    note_name: = tprint("%_group", function_name);

    // Functions with matching name are automatically put in the default group   
    is_matching_procedure: = ph.name == function_name;
    group_name: = "";

    // otherwise, any function with the @{name}_group() note are put to the corresponding group
    has_group_note, args: = has_note_with_args(ph, note_name);
    if has_group_note
    {
        is_matching_procedure = true;
        group_name = ifx args.count > 0 then args[0].text else "";
        group_name = trim(group_name, "\"");
    }
    if !is_matching_procedure return false;

    // Check signature
    is_valid_signature: = true;
    if ph.arguments.count != additional_signature.count+1 
    || ph.arguments[0].type_inst.result.type != .POINTER
    {
        // log("invalid: %, %, %", ph.name, ph.arguments[0].type_inst.result.(*Type_Info_Pointer).pointer_to.(*Type_Info_Struct).name, additional_signature);
        is_valid_signature = false;
    }
    else
    {
        for i: 1..ph.arguments.count-1
        {

            if ph.arguments[i].type_inst.result.type != additional_signature[i-1]
            {

                is_valid_signature = false;
                break;
            }
        }
    }

    if !is_valid_signature
    {
        if has_group_note
        {
            compiler_report(tprint("@% does not match required signature (*T + %)", note_name, additional_signature), make_location(ph));
        }
        return false;
    }

    // log("%", ph.name);
    ti: = ph.arguments[0].type_inst.result.(*Type_Info_Pointer).pointer_to;
    assert(ti.type == .STRUCT);
    table_add(table, xx ti, .{ph.name, group_name});
    return true;
}

GroupProcedure :: struct
{
    name: string;
    group: string;
}

// Compile time variables
resource_types: [..]*Type_Info_Struct;
child_types: [..]ChildType;
initialize_procedures: Table(*Type_Info_Struct, GroupProcedure);
shutdown_procedures: Table(*Type_Info_Struct, GroupProcedure);
update_procedures: Table(*Type_Info_Struct, GroupProcedure);
draw_procedures: Table(*Type_Info_Struct, GroupProcedure);
custom_serialize_table: Table(*Type_Info_Struct, string);
custom_editor_table: Table(*Type_Info_Struct, string);
serialize_filter_table: Table(*Type_Info_Struct, string);

generated_compile_time_info: = false;

#import "Compiler";
#import "Hash_Table";
