log_warning :: (format_string: string, args: .. Any, loc := #caller_location, flags := Log_Flags.NONE, user_flags : u32 = 0, section : *Log_Section = null)
{
    new_flags := flags | .WARNING;
    log(format_string, ..args, loc, new_flags, user_flags, section);
} @PrintLike

log_verbose :: (format_string: string, args: .. Any, loc := #caller_location, flags := Log_Flags.NONE, user_flags : u32 = 0, section : *Log_Section = null)
{
    new_flags := flags | .VERBOSE_ONLY;
    log(format_string, ..args, loc, new_flags, user_flags, section);
} @PrintLike

log_indent :: ()
{
    log_indent_level += 1;
}

log_unindent :: ()
{
    assert(log_indent_level > 0);
    log_indent_level -= 1;
}

yae_logger :: (message: string, data: *void, info: Log_Info)
{
    #if OS == .WINDOWS
    {
        COLOR_DEFAULT :: 7;
        COLOR_GREY :: 8;
        COLOR_YELLOW :: 6;
        COLOR_RED :: 4;
        COLOR_GREEN :: 2;
        STD_OUTPUT_HANDLE :: -11;
        STD_ERROR_HANDLE  :: -12;


        handle: Windows.HANDLE;
        color: u16;

        if info.common_flags & .ERROR
        {
            handle = Windows.GetStdHandle(STD_ERROR_HANDLE);
            color = COLOR_RED;
        }
        else if info.common_flags & .WARNING
        {
            handle = Windows.GetStdHandle(STD_OUTPUT_HANDLE);
            color = COLOR_YELLOW;
        }
        else if info.common_flags & .VERBOSE_ONLY || info.common_flags & .VERY_VERBOSE_ONLY
        {
            handle = Windows.GetStdHandle(STD_OUTPUT_HANDLE);
            color = COLOR_GREY;
        }
        else
        {
            handle = Windows.GetStdHandle(STD_OUTPUT_HANDLE);
            color = COLOR_DEFAULT;
        }

        Windows.SetConsoleTextAttribute(handle, color);
        defer Windows.SetConsoleTextAttribute(handle, COLOR_DEFAULT);
    }

    processed_message: = message;

    if log_indent_level > 0
    {
        push_allocator(*temporary_allocator);
        b: String_Builder;

        init_string_builder(*b, message.count + log_indent_level * 2);

        for i: 0..log_indent_level-1
        {
            append(*b, "  ");
        }
        append(*b, message);
        processed_message = builder_to_string(*b);
    }

    runtime_support_default_logger(processed_message, data, info);
}

#scope_file

log_indent_level: u8 = 0;

Windows :: #import "Windows";