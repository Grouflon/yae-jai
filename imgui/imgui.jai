IM_COL32 :: (r: u8, g: u8, b: u8, a: u8) -> u32 #expand
{
    return ((cast(u32)r) << IM_COL32_R_SHIFT) | ((cast(u32)g) << IM_COL32_G_SHIFT) | ((cast(u32)b) << IM_COL32_B_SHIFT) | ((cast(u32)a) << IM_COL32_A_SHIFT);
}

#scope_file

IM_COL32_R_SHIFT :: 0;
IM_COL32_G_SHIFT :: 8;
IM_COL32_B_SHIFT :: 16;
IM_COL32_A_SHIFT :: 24;

ColumnDefinition :: struct
{
    name: *u8;
    flags: ImGui.TableColumnFlags;
    base_width: float;
}

TableSetupColumns :: (columns: []ColumnDefinition)
{
    for column: columns
    {
        ImGui.TableSetupColumn(column.name, column.flags, column.base_width);
    }
}

// str modifications will always be allocated with the temporary allocator
InputText :: (label: string, str: *string, flags: ImGui.InputTextFlags = .None, callback: ImGui.InputTextCallback = null, user_data: *void = null) -> bool
{
    InputTextCallback_UserData :: struct
    {
        str: *string;
        chain_callback: ImGui.InputTextCallback;
        chain_callback_userdata: *void;
    };

    InputText_Callback :: (data: *ImGui.InputTextCallbackData) -> s32 #c_call
    {
        ctx: #Context;
        push_context ctx {

            user_data: = cast(*InputTextCallback_UserData) data.UserData;
            if data.EventFlag == .ImGuiInputTextFlags_CallbackResize
            {
                new_buffer: *u8 = talloc(data.BufSize);
                memset(new_buffer, 0, data.BufSize);
                memcpy(new_buffer, data.Buf, min(data.BufTextLen, cast(s32)user_data.str.count));
                data.Buf = new_buffer;
            }
            else if data.EventFlag == .CallbackEdit
            {
                <<(user_data.str) = copy_temporary_string(to_string(data.Buf));
            }
            else if (user_data.chain_callback != null)
            {
                // Forward to user callback, if any
                data.UserData = user_data.chain_callback_userdata;
                return user_data.chain_callback(data);
            }
            return 0;
        }
    }

    assert((flags & .ImGuiInputTextFlags_CallbackResize) == 0);
    assert((flags & .ImGuiInputTextFlags_CallbackEdit) == 0);
    flags |= .CallbackResize;
    flags |= .CallbackEdit;

    cb_user_data: InputTextCallback_UserData;
    cb_user_data.str = str;
    cb_user_data.chain_callback = callback;
    cb_user_data.chain_callback_userdata = user_data;

    
    buffer: *u8 = talloc(str.count+1);
    memcpy(buffer, str.data, str.count);
    buffer[str.count] = 0;

    modified: = ImGui.InputText(temp_c_string(label), buffer, xx (str.count+1), flags, InputText_Callback, *cb_user_data);
    return modified;
}

EditValue :: (label: string, value: *$T) -> bool
{
    return EditValue(label, value, type_info(T));
}

EditStructMembers :: (value: *$T) -> bool
{
    info: = type_info(T);
    if info.type != .STRUCT return false;

    return EditStructMembers(value, value, cast(*Type_Info_Struct)info);
}

EditStructMembers :: (value: *void, info_struct: *Type_Info_Struct) -> bool
{
    modified: = false;
    for member_type_info: info_struct.members
    {
        modified = EditValue(member_type_info.name, value + member_type_info.offset_in_bytes, member_type_info.type, member_type_info.notes) || modified;
    }
    return modified;
}

EditValue :: (label: string, value: *void, info: *Type_Info, notes: []string = .[]) -> bool
{
    // Parse metadata
    WidgetType :: enum
    {
        NONE;
        DRAG;
        SLIDER;
    };
    widget_type: WidgetType = .NONE;
    has_step_override: bool;
    step_override: float = 0.0;
    has_min_override: bool;
    min_override: float = 0.0;
    has_max_override: bool;
    max_override: float = 0.0;

    for note_string: notes
    {
        note: = parse_note(note_string);
        if note.name == {
            case "drag"; { widget_type = .DRAG; }
            case "slider"; { widget_type = .SLIDER; }
            case "step"; { has_step_override = true; step_override = note.value.decimal; }
            case "min"; { has_min_override = true; min_override = note.value.decimal; }
            case "max"; { has_max_override = true; max_override = note.value.decimal; }
        }
    }

    // Display widget
    c_label: = temp_c_string(label);
    modified: bool = false;

    if info.type == {
        case .STRUCT;
        {
            if info ==
            {
                case type_info(Curve);
                {
                    modified = EditValue(label, cast(*Curve)value);
                }

                case type_info(StringHash);
                {
                    hash_ptr: = cast(*StringHash)value;
                    temp_str: = copy_temporary_string(hash_ptr.str); // unnecessary copy probably
                    if InputText(label, *temp_str)
                    {
                        <<hash_ptr = string_hash(temp_str);
                        modified = true;
                    }
                }

                case; // Generic structs
                {
                    info_struct: = cast(*Type_Info_Struct) info;

                    if ImGui.TreeNodeEx(c_label, .DefaultOpen)
                    {
                        defer ImGui.TreePop();

                        modified = EditStructMembers(value, info_struct);
                    }
                }
            }
        }
        case .BOOL;
        {
            modified = ImGui.Checkbox(c_label, value);
        }
        case .INTEGER;
        {
            info_int: = cast(*Type_Info_Integer) info;

            data_type: ImGui.DataType;
            signed_min: s64;
            signed_max: s64;
            signed_step: s64;
            unsigned_min: u64;
            unsigned_max: u64;
            unsigned_step: u64;
            data_min: *void;
            data_max: *void;
            data_step: *void;

            float_step: float = 1.0;
            if has_step_override { float_step = xx step_override; }

            if info_int.signed
            {
                if info_int.runtime_size == {
                    case 1; { data_type = .S8; signed_min = S8_MIN; signed_max = S8_MAX; }
                    case 2; { data_type = .S16; signed_min = S16_MIN; signed_max = S16_MAX; }
                    case 4; { data_type = .S32; signed_min = S32_MIN; signed_max = S32_MAX; }
                    case 8; { data_type = .S64; signed_min = S64_MIN; signed_max = S64_MAX; }
                }
                if has_min_override { signed_min = max(signed_min, cast(s64)min_override); }
                if has_max_override { signed_max = min(signed_max, cast(s64)max_override); }
                signed_step = xx float_step;
                data_min = *signed_min;
                data_max = *signed_max;
                data_step = *signed_step;
            }
            else
            {
                if info_int.runtime_size == {
                    case 1; { data_type = .U8; unsigned_min = 0; unsigned_max = U8_MAX; }
                    case 2; { data_type = .U16; unsigned_min = 0; unsigned_max = U16_MAX; }
                    case 4; { data_type = .U32; unsigned_min = 0; unsigned_max = U32_MAX; }
                    case 8; { data_type = .U64; unsigned_min = 0; unsigned_max = U64_MAX; }
                }
                if has_min_override { unsigned_min = max(unsigned_min, cast(u64)min_override); }
                if has_max_override { unsigned_max = min(unsigned_max, cast(u64)max_override); }
                unsigned_step = xx float_step;
                data_min = *unsigned_min;
                data_max = *unsigned_max;
                data_step = *unsigned_step;
            }

            if widget_type ==
            {
                case .DRAG;   { modified = ImGui.DragScalar(c_label, data_type, value, float_step, data_min, data_max); }
                case .SLIDER; { modified = ImGui.SliderScalar(c_label, data_type, value, data_min, data_max); }
                case;         { modified = ImGui.InputScalar(c_label, data_type, value, data_step); }
            }
        }
        case .FLOAT;
        {
            value_float: float;
            min_float: float;
            max_float: float;

            if info.runtime_size == {
                case 4; { value_float = cast(float)<<cast(*float32)value; min_float = FLOAT32_MIN; max_float = FLOAT32_MAX; }
                case 8; { value_float = cast(float)<<cast(*float32)value; min_float = FLOAT32_MIN; max_float = FLOAT32_MAX; }
            }

            step: = 0.1;
            if has_step_override { step = step_override; }
            if has_min_override { min_float = max(min_float, min_override); }
            if has_max_override { max_float = min(max_float, max_override); }

            if widget_type ==
            {
                case .DRAG;   { modified = ImGui.DragFloat(c_label, *value_float, step, min_float, max_float); }
                case .SLIDER; { modified = ImGui.SliderFloat(c_label, *value_float, min_float, max_float); }
                case;         { modified = ImGui.InputFloat(c_label, *value_float, step); }
            }

            if modified
            {
                value_float = clamp(value_float, min_float, max_float);

                if info.runtime_size == {
                    case 4; { <<cast(*float32)value = cast(float32)value_float; }
                    case 8; { <<cast(*float64)value = cast(float64)value_float; }
                }
            }
        }
        case .STRING;
        {
            str_ptr: = cast(*string)value;
            temp_str: = copy_temporary_string(<<str_ptr);
            if InputText(label, *temp_str)
            {
                free(str_ptr.data);
                <<str_ptr = copy_string(temp_str);
                modified = true;
            }
        }
        case .ENUM;
        {
            info_enum: = cast(*Type_Info_Enum) info;

            getter :: (user_data: *void, idx: s32) -> *u8 #c_call
            {
                ctx: #Context;
                push_context ctx
                {
                    info_enum: = cast(*Type_Info_Enum) user_data;
                    if idx < 0 || idx >= info_enum.names.count { return ""; }
                    return temp_c_string(info_enum.names[idx]);
                }
            }

            // Combo :: (label: *u8, current_item: *s32, getter: #type (user_data: *void, idx: s32) -> *u8 #c_call, user_data: *void, items_count: s32, popup_max_height_in_items: s32 = -1) -> bool
            index: s32 = xx enum_value_to_index(value, info_enum);
            modified = ImGui.Combo(c_label, *index, getter, xx info_enum, xx info_enum.names.count);
            enum_index_to_value(xx index, info_enum, value);
        }
    }
    return modified;
}

Note :: struct
{
    Value :: struct
    {
        boolean: bool;
        integer: int;
        decimal: float;
        text: string;
    }

    name: string;
    value: Value;
}

parse_note :: (note_string: string) -> Note
{
    note: Note;
    index: = find_index_from_left(note_string, #char "=");
    if index < 0
    {
        note.name = trim(note_string);
    }
    else
    {
        note.name = trim(slice(note_string, 0, index));
        value_string: = trim(slice(note_string, index+1, note_string.count - index + 1));
        if value_string == "true" { note.value.boolean = true; }
        note.value.integer = string_to_int(value_string);
        note.value.decimal = string_to_float(value_string);
        note.value.text = value_string;
    }
    return note;
    // find = sign, trim both sides, convert right side to all possible types
}

#import "String";

#poke_name ImGui InputText;
#poke_name ImGui EditValue;
#poke_name ImGui EditStructMembers;
#poke_name ImGui ColumnDefinition;
#poke_name ImGui TableSetupColumns;

