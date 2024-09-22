
get_console_window_handle :: () -> *void
{
#if OS == .WINDOWS
{
    return GetConsoleWindow();
}
else
{
    return null;
}
}

find_window_by_title_containing :: (substring: string) -> *void
{
    #if OS == .WINDOWS
    {
        Closure :: struct
        {
            substring: string;
            window: Windows.HWND;
        }
        closure: = Closure.{substring, null};
        EnumWindows((window: Windows.HWND, data: *void) -> bool #c_call
        {
            ctx: Context;
            push_context ctx
            {
                closure: *Closure = data;
                c_title: [512]u8;
                length: = GetWindowTextA(window, c_title.data, size_of(type_of(c_title)));
                title: = to_string(c_title.data, length);
                if contains_nocase(title, closure.substring)
                {
                    closure.window = window;
                    return false;
                }
            }

            return true;
        }
        , *closure);

        return closure.window;
    }
    else
    {
        return null;
    }
}

get_window_position :: (handle: *void) -> (x: int, y: int, width: int, height: int)
{
    #if OS == .WINDOWS
    {
        rect: Windows.RECT;
        Windows.GetWindowRect(handle, *rect);
        return rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top;
    }
    else
    {
        return 0,0,0,0;
    }
}

set_window_position :: (handle: *void, x: int, y: int, width: int, height: int)
{
    #if OS == .WINDOWS
    {
        Windows.SetWindowPos(handle, null,xx x,xx y,xx width,xx height, 0);
    }
    else
    {
    }
}

#scope_file

#if OS == .WINDOWS
{

GetConsoleWindow :: () -> Windows.HWND #foreign kernel32;

GetWindowTextA :: (window: Windows.HWND, out_str: *u8, max_string_length: s32) -> s32 #foreign user32;
EnumWindows :: (f: #type (window: Windows.HWND, data: *void) -> bool #c_call, data: *void) -> bool #foreign user32;

Windows :: #import "Windows";
kernel32 :: #system_library "kernel32";
user32 :: #system_library "user32";

}
else
{
}
