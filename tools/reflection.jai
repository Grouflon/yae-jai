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

has_note_with_args :: (ti: *Type_Info_Struct_Member, note: string) -> bool, []string
{
    if ti == null return false, .[];
    found, args: = has_note_with_args(ti.notes, note);
    return found, args;
}

has_note_with_args :: (ti: *Type_Info_Struct, note: string) -> bool, []string
{
    if ti == null return false, .[];
    found, args: = has_note_with_args(ti.notes, note);
    return found, args;
}

has_note_with_args :: (notes: []string, note: string) -> bool, []string
{
    for n: notes
    {
        note_name: = stop_at_any(n, "(");
        if compare(note_name, note) != 0 continue;

        offset: = note_name.count + 1;
        args_string: = string.{ data = note_name.data + offset, count = n.count - offset };
        args_string = stop_at_any(args_string, ")");
        push_allocator(temporary_allocator);
        args: = split(args_string, ",");
        for * arg: args
        {
            <<arg = trim(<<arg);
        }
        return true, args;
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

    info_struct := cast(*Type_Info_Struct) info;
    if info_struct.members.count == 0 return false;

    member: = info_struct.members[0];
    if !(member.flags & .AS) return false;

    sub_type := member.type;
    return is_subclass_of(sub_type, of);
}
