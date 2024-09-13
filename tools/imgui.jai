imgui_input_text :: (label: string, str: *string, flags: ImGui.InputTextFlags = .None, callback: ImGui.InputTextCallback = null, user_data: *void = null) -> bool
{
    InputTextCallback_UserData :: struct
    {
        str: *string;
        chain_callback: ImGui.InputTextCallback;
        chain_callback_userdata: *void;
    };

    InputText_Callback :: (data: *ImGui.InputTextCallbackData) -> s32 #c_call
    {
        ctx: Context;
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
                free(user_data.str.data);
                <<(user_data.str) = copy_string(to_string(data.Buf));
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
    flags |= .CallbackResize;
    flags |= .CallbackEdit;

    cb_user_data: InputTextCallback_UserData;
    cb_user_data.str = str;
    cb_user_data.chain_callback = callback;
    cb_user_data.chain_callback_userdata = user_data;

    
    buffer: *u8 = talloc(str.count+1);
    memcpy(buffer, str.data, str.count);
    buffer[str.count] = 0;

    return ImGui.InputText(temp_c_string(label), buffer, xx (str.count+1), flags, InputText_Callback, *cb_user_data);
}

imgui_edit :: (label: string, value: *$T) -> bool
{
    return imgui_edit(label, value, type_info(T));
}

imgui_edit :: (label: string, value: *void, info: *Type_Info, notes: []string = .[]) -> bool
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
                    modified = imgui_edit(label, cast(*Curve)value);
                }

                case; // Generic structs
                {
                    info_struct: = cast(*Type_Info_Struct) info;

                    if ImGui.TreeNodeEx(c_label, .DefaultOpen)
                    {
                        defer ImGui.TreePop();

                        for member_type_info: info_struct.members
                        {
                            modified = imgui_edit(member_type_info.name, value + member_type_info.offset_in_bytes, member_type_info.type, member_type_info.notes) || modified;
                        }
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
            value_s32: s32;
            min_s32: s32;
            max_s32: s32;

            if info_int.signed
            {
                if info_int.runtime_size == {
                    case 1; { value_s32 = cast(s32)<<cast(*s8)value; min_s32 = S8_MIN; max_s32 = S8_MAX; }
                    case 2; { value_s32 = cast(s32)<<cast(*s16)value; min_s32 = S16_MIN; max_s32 = S16_MAX; }
                    case 4; { value_s32 = cast(s32)<<cast(*s32)value; min_s32 = S32_MIN; max_s32 = S32_MAX; }
                    case 8; { value_s32 = cast(s32)<<cast(*s64)value; min_s32 = S32_MIN; max_s32 = S32_MAX; }
                }
            }
            else
            {
                if info_int.runtime_size == {
                    case 1; { value_s32 = cast(s32)<<cast(*u8)value; min_s32 = 0; max_s32 = U8_MAX; }
                    case 2; { value_s32 = cast(s32)<<cast(*u16)value; min_s32 = 0; max_s32 = U16_MAX; }
                    case 4; { value_s32 = cast(s32)<<cast(*u32)value; min_s32 = 0; max_s32 = S32_MAX; }
                    case 8; { value_s32 = cast(s32)<<cast(*u64)value; min_s32 = 0; max_s32 = S32_MAX; }
                }
            }

            step: float = 0.1;
            if has_step_override { step = xx step_override; }
            if has_min_override { min_s32 = max(min_s32, cast(s32)min_override); }
            if has_max_override { max_s32 = min(max_s32, cast(s32)max_override); }

            if widget_type ==
            {
                case .DRAG;   { modified = ImGui.DragInt(c_label, *value_s32, step, min_s32, max_s32); }
                case .SLIDER; { modified = ImGui.SliderInt(c_label, *value_s32, min_s32, max_s32); }
                case;         { modified = ImGui.InputInt(c_label, *value_s32, cast(s32)step); }
            }

            if modified
            {
                value_s32 = clamp(value_s32, min_s32, max_s32);

                if info_int.signed
                {
                    if info_int.runtime_size == {
                        case 1; { <<cast(*s8)value = cast(s8)value_s32; }
                        case 2; { <<cast(*s16)value = cast(s16)value_s32; }
                        case 4; { <<cast(*s32)value = cast(s32)value_s32; }
                        case 8; { <<cast(*s64)value = cast(s64)value_s32; }
                    }
                }
                else
                {
                    if info_int.runtime_size == {
                        case 1; { <<cast(*u8)value = cast(u8)value_s32; }
                        case 2; { <<cast(*u16)value = cast(u16)value_s32; }
                        case 4; { <<cast(*u32)value = cast(u32)value_s32; }
                        case 8; { <<cast(*u64)value = cast(u64)value_s32; }
                    }
                }
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
            modified = imgui_input_text(label, value);
        }
    }
    return modified;
}

#scope_file

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

ImGui:: #import "ImGui";
#import "String";
