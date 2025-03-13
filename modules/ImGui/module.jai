// Bindings for Dear ImGui.

ImVec2      :: Vector2;
ImVec4      :: Vector4;
ImColor     :: Vector4;

ImVector :: struct (T: Type) {
    Size: s32;
    Capacity: s32;
    Data: *T;
}

Value :: (prefix: *u8, v: Vector2)
{
    Text("%: {%,%}", to_string(prefix), v.x, v.y);
}

Value :: (prefix: *u8, v: Vector3)
{
    Text("%: {%,%,%}", to_string(prefix), v.x, v.y, v.z);
}

Value :: (prefix: *u8, v: Vector4)
{
    Text("%: {%,%,%,%}", to_string(prefix), v.x, v.y, v.z, v.w);
}

ImDrawCallback :: #type (parent_list: *ImDrawList, cmd: *ImDrawCmd) #c_call;

#scope_module

#import "Basic";
#import "Math";

// overloads for compiling with some unknown imgui_internal.h types that we should never be using anyway.
ImFileHandle :: *void;
TextBuffer :: *void;
ImBitArrayForNamedKeys :: *void;

#if OS == .WINDOWS {
    #load "windows.jai";
    #system_library,link_always "user32"; // Needed by imgui unless ImGui is compiled it with "IMGUI_DISABLE_WIN32_DEFAULT_CLIPBOARD_FUNCS"
    #system_library,link_always "shell32"; // @docking: Needed for ShellExecuteW call
} else {
    #load "unix.jai";
}

