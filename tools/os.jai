
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

kill_process_by_path :: (path: string) -> bool
{
    #if OS == .WINDOWS
    {
        Closure :: struct
        {
            path: string;
            success: bool;
        }
        closure: = Closure.{get_absolute_path(path), false};
        EnumWindows((window: Windows.HWND, data: *void) -> bool #c_call
        {
            ctx: #Context;
            push_context ctx
            {
                process_id: s32;
                GetWindowThreadProcessId(window, *process_id);

                hProcess: = OpenProcess(
                    0x0400, // PROCESS_QUERY_INFORMATION | PROCESS_VM_READ 
                    false,
                    process_id
                );
                defer CloseHandle(hProcess);

                closure: *Closure = data;
                filename: [512]u8;
                length: = GetModuleFileNameExA(hProcess, null, filename.data, 512);
                if (length != 0)
                {
                    path: = get_absolute_path(to_string(filename.data, length));
                    if path == closure.path
                    {
                        cmd: []string = .["cmd", "/C", "taskkill", "/f", "/pid", tprint("%", process_id)];
                        run_command(..cmd);
                        closure.success = true;
                        return false;
                    }
                }
            }

            return true;
        }
        , *closure);

        return closure.success;
    }
    else
    {
        return false;
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

close_window :: (handle: *void) -> bool
{
    #if OS == .WINDOWS
    {
        return DestroyWindow(handle);
    }
    return false;
}

#scope_file

#if OS == .WINDOWS
{

GetConsoleWindow :: () -> Windows.HWND #foreign kernel32;

GetWindowTextA :: (window: Windows.HWND, out_str: *u8, max_string_length: s32) -> s32 #foreign user32;
EnumWindows :: (f: #type (window: Windows.HWND, data: *void) -> bool #c_call, data: *void) -> bool #foreign user32;
GetModuleFileNameExA :: (hProcess: Windows.HANDLE, hModule: *void, lpFileName: *u8, nSize: s32) -> s32 #foreign psapi;
GetWindowThreadProcessId :: (hWnd: Windows.HWND, lpdwProcessId: *s32 ) -> s32 #foreign user32;
OpenProcess :: (dwDesiredAccess: s32, bInheritHandle: bool, dwProcessId: s32) -> Windows.HANDLE #foreign kernel32;
CloseHandle :: (hObject: Windows.HANDLE) -> bool #foreign kernel32;
DestroyWindow :: (hWnd: Windows.HWND) -> bool #foreign user32;

Windows :: #import "Windows";
kernel32 :: #system_library "kernel32";
psapi :: #system_library "psapi";
user32 :: #system_library "user32";

#import "Process";

}
else
{
}
