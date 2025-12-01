
get_window_title :: (handle: *void) -> string
{
    #if OS == .WINDOWS
    {
        c_title: [512]u8;
        length: = GetWindowTextA(handle, c_title.data, size_of(type_of(c_title)));
        return copy_temporary_string(to_string(c_title.data, length));
    }
    else
    {
        return "";
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
            ctx: #Context;
            push_context ctx
            {
                closure: *Closure = data;
                title: = get_window_title(window);
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

get_window_rect :: (handle: *void) -> bool, IntBounds
{
    if handle == null { return false, .{}; }

    #if OS == .WINDOWS
    {
        rect: Windows.RECT;
        Windows.GetWindowRect(handle, *rect);
        if rect.left == 0 && rect.top == 0 && rect.right == 0 && rect.bottom == 0 { return false, .{}; };
        if rect.left < -2000 || rect.top < -2000 || rect.right < -2000 || rect.bottom < -2000 { return false, .{}; }; // Try to catch fucked up window that we sometimes get

        return true, .{
            .{rect.left, rect.top},
            .{rect.right, rect.bottom}
        };
    }
    else
    {
        return false, .{};
    }
}

set_window_rect :: (handle: *void, rect: IntBounds)
{
    if handle == null { return; }

    #if OS == .WINDOWS
    {
        Windows.SetWindowPos(handle, null, rect.min.x, rect.min.y, width(rect), height(rect), 0);
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


SaveFileDialogParams :: struct
{
    initial_path: string;
    extension: string;

    Filter :: struct
    {
        name: string;
        wildcard: string;
    }
    filters: []Filter;

    max_path_length: u32 = 512;
}

save_file_dialog :: (initial_path: string, extension: string, extension_description: string) -> bool, string
{
    params: = SaveFileDialogParams.{
        initial_path = initial_path,
        extension = extension
    };

    filters: [..]SaveFileDialogParams.Filter;
    filters.allocator = temporary_allocator;
    array_add(*filters, .{ extension_description, tprint("*.%", extension) });
    array_add(*filters, .{ "All Files", "*.*" });
    params.filters = filters;

    success, path: = save_file_dialog(params);
    path = normalize_path(path);
    return success, path;
}

save_file_dialog :: (params: SaveFileDialogParams) -> bool, string
{
    push_allocator(temporary_allocator);
    file_name: *u8 = xx alloc(params.max_path_length);
    memset(file_name, 0, params.max_path_length);

    filter_str_builder: String_Builder;
    init_string_builder(*filter_str_builder);
    for filter: params.filters
    {
        append(*filter_str_builder, tprint("%1 (%2)\0%2\0", filter.name, filter.wildcard));
    }

    arg_struct: Windows.OPENFILENAMEA;
    arg_struct.lStructSize = size_of(Windows.OPENFILENAMEA);
    arg_struct.lpstrFilter = temp_c_string(builder_to_string(*filter_str_builder));
    arg_struct.lpstrFile = file_name;
    arg_struct.nMaxFile = params.max_path_length;
    arg_struct.lpstrInitialDir = temp_c_string(get_absolute_path(params.initial_path));
    arg_struct.Flags = 0x00080000 | 0x00000004 | 0x00000008; // .OFN_EXPLORER | .OFN_HIDEREADONLY | .OFN_NOCHANGEDIR;
    arg_struct.lpstrDefExt = temp_c_string(params.extension);

    result: = Windows.GetSaveFileNameA(*arg_struct) == .TRUE;

    return result, copy_temporary_string(to_string(file_name));
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
