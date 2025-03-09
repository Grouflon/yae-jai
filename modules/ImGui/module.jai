// Bindings for Dear ImGui.

ImVec2      :: Vector2;
ImVec4      :: Vector4;
ImColor     :: Vector4;

ImVector :: struct (T: Type) {
    Size: s32;
    Capacity: s32;
    Data: *T;
}

ImDrawCallback :: #type (parent_list: *ImDrawList, cmd: *ImDrawCmd) #c_call;

#scope_module

#import "Basic";
#import "Math";

#if OS == .WINDOWS {
    #load "windows.jai";
    #system_library,link_always "user32"; // Needed by imgui unless ImGui is compiled it with "IMGUI_DISABLE_WIN32_DEFAULT_CLIPBOARD_FUNCS"
    #system_library,link_always "shell32"; // @docking: Needed for ShellExecuteW call
} else {
    #load "unix.jai";
}

