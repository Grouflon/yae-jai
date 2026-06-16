NoteArgument :: struct
{
    boolean: bool;
    integer: int;
    decimal: float;
    text: string;
}

has_note :: (ti: *Type_Info_Struct, note: string, check_parents: bool = false) -> bool
{
    if ti == null return false;

    if check_parents
    {
        for member: ti.members
        {
            if !(member.flags & .AS) continue;
            if member.type.type != .STRUCT continue;

            if has_note(xx member.type, note, true)
            {
                return true;
            }
        }
    }

    return has_note(ti.notes, note);
}

has_note :: (ti: *Type_Info_Struct_Member, note: string) -> bool
{
    if ti == null return false;
    return has_note(ti.notes, note);
}

has_note :: (ph: *Code_Procedure_Header, note: string) -> bool
{
    if ph == null return false;
    for ph.notes if it.text == note return true;
    return false;
}

has_note :: (notes: []string, note: string) -> bool
{
    for n: notes
    {
        note_name: = stop_at_any(n, "(");
        if compare(note_name, note) == 0 return true;
    }
    return false;
}

has_note_with_args :: (ti: *Type_Info_Struct_Member, note: string) -> bool, []NoteArgument
{
    if ti == null return false, .[];
    found, args: = has_note_with_args(ti.notes, note);
    return found, args;
}

has_note_with_args :: (ti: *Type_Info_Struct, note: string, check_parents: bool = false) -> bool, []NoteArgument
{
    if ti == null return false, .[];

    if check_parents
    {
        for member: ti.members
        {
            if !(member.flags & .AS) continue;
            if member.type.type != .STRUCT continue;

            found, args: = has_note_with_args(xx member.type.type, note, true);
            if found
            {
                return true, args;
            }
        }
    }

    found, args: = has_note_with_args(ti.notes, note);
    return found, args;
}

has_note_with_args :: (notes: []string, note: string) -> bool, []NoteArgument
{
    for n: notes
    {
        note_name: = stop_at_any(n, "(");
        if compare(note_name, note) != 0 continue;

        if note_name.count == n.count return true, .[]; // No parentheses

        offset: = note_name.count + 1;
        args_string: = string.{ data = note_name.data + offset, count = n.count - offset };
        args_string = stop_at_any(args_string, ")");
        push_allocator(temporary_allocator);

        result: [..]NoteArgument;
        args: = split(args_string, ",");
        for arg, i: args
        {
            trimmed_arg: = trim(arg);
            // I'm not 100% sure we should exclude empty args
            // @note() should for sure be equivalent to @note, but what about @note(,)?
            // Let's do it for now because it makes things a lot simpler
            if trimmed_arg.count == 0 continue;

            array_add(*result, .{
                boolean = ifx trimmed_arg == "true" then true else false,
                integer =  string_to_int(trimmed_arg),
                decimal =  string_to_float(trimmed_arg),
                text =  trimmed_arg,
            });
        }
        return true, result;
    }
    return false, .[];
}

is_subclass_of :: ($T1: Type, $T2: Type, check_self: bool = true) -> bool
{
    return is_subclass_of(type_info(T1), type_info(T2), check_self);
}

is_subclass_of :: (info: *Type_Info, $T: Type, check_self: bool = true) -> bool
{
    return is_subclass_of(info, type_info(T), check_self);
}

is_subclass_of :: (info: *Type_Info, of: *Type_Info, check_self: bool = true) -> bool
{
    if check_self && info == of return true;

    if info.type != .STRUCT return false;
    if of.type != .STRUCT return false;

    info_struct := cast(*Type_Info_Struct) info;
    of_struct := cast(*Type_Info_Struct) of;

    if check_self && info_struct.name == of_struct.name return true;

    if info_struct.members.count == 0 return false;

    member: = info_struct.members[0];
    if !(member.flags & .AS) return false;

    sub_type := member.type;
    return is_subclass_of(sub_type, of);
}

get_parent_type :: (tis: *Type_Info_Struct) -> *Type_Info
{
    if tis == null return null;

    for member: tis.members
    {
        if member.flags & .AS
        {
            return member.type;
        }
    }
    return null;
}

get_polymorphic_argument :: ($T: Type, info_struct: *Type_Info_Struct, index: s64) -> T
{
    assert(info_struct.specified_parameters.count > index);
    return (info_struct.constant_storage.data + info_struct.specified_parameters[index].offset_into_constant_storage).(*T).*;
}

enum_value_to_index :: (value: *void, info_enum: *Type_Info_Enum) -> s64
{
    assert(info_enum != null);

    s64_value: s64;
    if info_enum.internal_type.signed
    {
        if info_enum.internal_type.runtime_size ==
        {
            case 1; { s64_value = xx value.(*s8).*; }
            case 2; { s64_value = xx value.(*s16).*; }
            case 4; { s64_value = xx value.(*s32).*; }
            case 8; { s64_value = xx value.(*s64).*; }
        }
    }
    else
    {
        if info_enum.internal_type.runtime_size ==
        {
            case 1; { s64_value = xx value.(*u8).*; }
            case 2; { s64_value = xx value.(*u16).*; }
            case 4; { s64_value = xx value.(*u32).*; }
            case 8; { s64_value = xx value.(*u64).*; }
        }
    }

    for enum_value, i : info_enum.values
    {
        if enum_value == s64_value return i;
    }
    return -1;
}

enum_index_to_value :: (index: s64, info_enum: *Type_Info_Enum, value: *void)
{
    assert(info_enum != null);

    if index < 0 || index >= info_enum.values.count return;

    s64_value: = info_enum.values[index];
    if info_enum.internal_type.signed
    {
        if info_enum.internal_type.runtime_size ==
        {
            case 1; { typed_value: = cast(*s8)value; typed_value.* = xx s64_value; }
            case 2; { typed_value: = cast(*s16)value; typed_value.* = xx s64_value; }
            case 4; { typed_value: = cast(*s32)value; typed_value.* = xx s64_value; }
            case 8; { typed_value: = cast(*s64)value; typed_value.* = xx s64_value; }
        }
    }
    else
    {
        if info_enum.internal_type.runtime_size ==
        {
            case 1; { typed_value: = cast(*u8)value; typed_value.* = xx s64_value; }
            case 2; { typed_value: = cast(*u16)value; typed_value.* = xx s64_value; }
            case 4; { typed_value: = cast(*u32)value; typed_value.* = xx s64_value; }
            case 8; { typed_value: = cast(*u64)value; typed_value.* = xx s64_value; }
        }
    }
}

MemberInfo :: struct
{
    tis_member: *Type_Info_Struct_Member;
    offset: s64; // Relative to the base data pointer of the final struct. Might be different than the tis_member offset_in_bytes if we have inheritance
}

get_flattened_struct_members :: (info: *Type_Info_Struct, note_filter: string = "") -> keys: []string, key_to_type: Table(string, MemberInfo), notes: []string
{
    keys: [..]string;
    keys.allocator = temporary_allocator;

    key_to_member_info: Table(string, MemberInfo);
    key_to_member_info.allocator = temporary_allocator;

    notes: [..]string;
    notes.allocator = temporary_allocator;

    get_flattened_struct_members(info, note_filter, 0, *keys, *key_to_member_info, *notes);
    return keys, key_to_member_info, notes;
}

#scope_file

get_flattened_struct_members :: (info: *Type_Info_Struct, note_filter: string, base_offset: s64, keys: *[..]string, key_to_type: *Table(string, MemberInfo), notes: *[..]string)
{
    assert(info != null);
    assert(keys != null);
    assert(key_to_type != null);
    assert(notes != null);

    array_add(notes, ..info.notes);

    for member_type_info, i : info.members
    {
        offset: = base_offset + member_type_info.offset_in_bytes;

        if member_type_info.type.type == .STRUCT
        {
            member_tis: *Type_Info_Struct = xx member_type_info.type;

            // Flatten special structs
            // #as
            if member_type_info.flags & .AS
            {
                get_flattened_struct_members(member_tis, note_filter, offset, keys, key_to_type, notes);
                continue;
            }

            // union
            if member_tis.textual_flags & .UNION
            {
                get_flattened_struct_members(member_tis, note_filter, offset, keys, key_to_type, notes);
                continue;
            }
        }
        
        if note_filter.count > 0 && !has_note(*member_type_info, note_filter) { continue; }

        array_add(keys, member_type_info.name);
        table_add(key_to_type, member_type_info.name, .{*info.members[i], offset});
    }
}
