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

imgui_edit :: (label: string, value: *void, info: *Type_Info) -> bool
{
    c_label: = temp_c_string(label);
    modified: bool = false;

    if info.type == {
        case .BOOL;
        {
            modified = ImGui.Checkbox(c_label, value);
        }
        case .INTEGER;
        {
            info_int: = cast(*Type_Info_Integer) info;
            value_s32: s32;
            min: s32;
            max: s32;

            if info_int.signed
            {
                if info_int.runtime_size == {
                    case 1; { value_s32 = cast(s32)<<cast(*s8)value; min = S8_MIN; max = S8_MAX; }
                    case 2; { value_s32 = cast(s32)<<cast(*s16)value; min = S16_MIN; max = S16_MAX; }
                    case 4; { value_s32 = cast(s32)<<cast(*s32)value; min = S32_MIN; max = S32_MAX; }
                    case 8; { value_s32 = cast(s32)<<cast(*s64)value; min = S32_MIN; max = S32_MAX; }
                }
            }
            else
            {
                if info_int.runtime_size == {
                    case 1; { value_s32 = cast(s32)<<cast(*u8)value; min = 0; max = U8_MAX; }
                    case 2; { value_s32 = cast(s32)<<cast(*u16)value; min = 0; max = U16_MAX; }
                    case 4; { value_s32 = cast(s32)<<cast(*u32)value; min = 0; max = S32_MAX; }
                    case 8; { value_s32 = cast(s32)<<cast(*u64)value; min = 0; max = S32_MAX; }
                }
            }

            if ImGui.DragInt(c_label, *value_s32, v_min = min, v_max = max)
            {
                modified = true;

                value_s32 = clamp(value_s32, min, max);

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
            min: float;
            max: float;

            if info.runtime_size == {
                case 4; { value_float = cast(float)<<cast(*float32)value; min = FLOAT32_MIN; max = FLOAT32_MAX; }
                case 8; { value_float = cast(float)<<cast(*float32)value; min = FLOAT32_MIN; max = FLOAT32_MAX; }
            }

            if ImGui.DragFloat(c_label, *value_float, v_min = min, v_max = max)
            {
                modified = true;

                value_float = clamp(value_float, min, max);

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
        case .STRUCT;
        {
            info_struct: = cast(*Type_Info_Struct) info;

            if ImGui.TreeNodeEx(c_label, .DefaultOpen)
            {
                defer ImGui.TreePop();

                for member_type_info: info_struct.members
                {
                    modified = imgui_edit(member_type_info.name, value + member_type_info.offset_in_bytes, member_type_info.type) || modified;
                }
            }
        }
    }
    return modified;
}


#scope_file

ImGui:: #import "ImGui";
