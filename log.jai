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

    runtime_support_default_logger(message, data, info);
}

#scope_file

Windows :: #import "Windows";