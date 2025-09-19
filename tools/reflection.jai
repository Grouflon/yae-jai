NoteArgument :: struct
{
    boolean: bool;
    integer: int;
    decimal: float;
    text: string;
}

has_note :: (ti: *Type_Info_Struct, note: string) -> bool
{
    if ti == null return false;
    return has_note(ti.notes, note);
}

has_note :: (ti: *Type_Info_Struct_Member, note: string) -> bool
{
    if ti == null return false;
    return has_note(ti.notes, note);
}

has_note :: (notes: []string, note: string) -> bool
{
    for n: notes
    {
        if compare(n, note) == 0 return true;
    }
    return false;
}

has_note_with_args :: (ti: *Type_Info_Struct_Member, note: string) -> bool, []NoteArgument
{
    if ti == null return false, .[];
    found, args: = has_note_with_args(ti.notes, note);
    return found, args;
}

has_note_with_args :: (ti: *Type_Info_Struct, note: string) -> bool, []NoteArgument
{
    if ti == null return false, .[];
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

get_parent_type :: (info: *Type_Info) -> *Type_Info
{
    if info == null return null;
    if info.type != .STRUCT return null;

    info_struct := cast(*Type_Info_Struct) info;
    for member: info_struct.members
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
    return <<cast(*T)(info_struct.constant_storage.data + info_struct.specified_parameters[index].offset_into_constant_storage);
}

enum_value_to_index :: (value: *void, info_enum: *Type_Info_Enum) -> s64
{
    assert(info_enum != null);

    s64_value: s64;
    if info_enum.internal_type.signed
    {
        if info_enum.internal_type.runtime_size ==
        {
            case 1; { s64_value = xx << cast(*s8)value; }
            case 2; { s64_value = xx << cast(*s16)value; }
            case 4; { s64_value = xx << cast(*s32)value; }
            case 8; { s64_value = xx << cast(*s64)value; }
        }
    }
    else
    {
        if info_enum.internal_type.runtime_size ==
        {
            case 1; { s64_value = xx << cast(*u8)value; }
            case 2; { s64_value = xx << cast(*u16)value; }
            case 4; { s64_value = xx << cast(*u32)value; }
            case 8; { s64_value = xx << cast(*u64)value; }
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
            case 1; { typed_value: = cast(*s8)value; <<typed_value = xx s64_value; }
            case 2; { typed_value: = cast(*s16)value; <<typed_value = xx s64_value; }
            case 4; { typed_value: = cast(*s32)value; <<typed_value = xx s64_value; }
            case 8; { typed_value: = cast(*s64)value; <<typed_value = xx s64_value; }
        }
    }
    else
    {
        if info_enum.internal_type.runtime_size ==
        {
            case 1; { typed_value: = cast(*u8)value; <<typed_value = xx s64_value; }
            case 2; { typed_value: = cast(*u16)value; <<typed_value = xx s64_value; }
            case 4; { typed_value: = cast(*u32)value; <<typed_value = xx s64_value; }
            case 8; { typed_value: = cast(*u64)value; <<typed_value = xx s64_value; }
        }
    }
}