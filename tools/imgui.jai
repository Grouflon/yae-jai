InputText :: (label: *u8, str: *string, flags: ImGui.InputTextFlags = .None, callback: ImGui.InputTextCallback = null, user_data: *void = null) -> bool
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
        ctx.allocator = temporary_allocator;
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

    return ImGui.InputText(label, buffer, xx (str.count+1), flags, InputText_Callback, *cb_user_data);
}

#scope_file

ImGui:: #import "ImGui";
