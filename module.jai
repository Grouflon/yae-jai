WITH_EDITOR :: (OS != .WASM);
// WITH_EDITOR :: false;
FILE_WATCH_SUPPORTED :: (OS != .WASM);
IMGUI_SUPPORTED :: WITH_EDITOR;
YAE_DEBUG_MEMORY :: (OS != .WASM);

yae_resources: struct
{
    generic_shader: Shader = .{ vs_path = "yae_data://shaders/generic.vs", fs_path = "yae_data://shaders/generic.fs" };
    circle_shader: Shader = .{ fs_path = "yae_data://shaders/circle.fs" };
    circle_outline_shader: Shader = .{ fs_path = "yae_data://shaders/circle_outline.fs" };
};

// #load "animation_player.jai";
#load "aseprite_animation_player.jai";
#load "camera.jai";
#load "color.jai";
#load "compile_time.jai";
#load "draw.jai";
#load "entity.jai";
#load "input.jai";
#load "log.jai";
#load "physics.jai";
#load "pid.jai";
#load "pool.jai";
#load "resource.jai";
#load "resource_manager.jai";
#load "settings.jai";
#load "smoother.jai";
// #load "statemachine.jai";
#load "string_hash.jai";
// #load "tilemap.jai";
#load "undo_redo.jai";
// #load "viewport.jai";
#load "yae.jai";

#load "math/bounds.jai";
#load "math/collision.jai";
#load "math/curve.jai";
#load "math/ease.jai";
#load "math/int_vector.jai";
#load "math/math.jai";
// #load "math/spline.jai";

#load "renderer/renderer.jai";

// #load "resources/animation.jai";
#load "resources/aseprite_file.jai";
#load "resources/shader.jai";
#load "resources/texture_file.jai";

#load "platform/platform.jai";

#load "serialization/json_serializer.jai";
#load "serialization/reflection_serialization.jai";
#load "serialization/serializer.jai";

#load "tools/aseprite.jai";
#load "tools/filesystem.jai";
#load "tools/hash.jai";
#load "tools/json.jai";
#load "tools/misc.jai";
#load "tools/os.jai";
#load "tools/reflection.jai";

#if WITH_EDITOR
{
    // #load "editor/animation_editor.jai";
    #load "editor/aseprite_file_editor.jai";
    #load "editor/curve_editor.jai";
    #load "editor/editor.jai";
    #load "editor/gizmo.jai";
    #load "editor/resource_browser.jai";
    #load "editor/resource_editor.jai";
    #load "editor/pools_inspector.jai";
    #load "editor/texture_file_editor.jai";
}

#if IMGUI_SUPPORTED
{
    #load "imgui/imgui.jai";
    #load "imgui/imgui_backend.jai";
    #load "imgui/imgui_canvas.jai";
    ImGui :: #import,dir "./modules/ImGui";
}
    

#scope_module

#import,dir "./modules/jaison";

#poke_name (#import "Hash_Table") operator ==;
#poke_name (#import "Basic") operator ==;