#load "animation_player.jai";
#load "compile_time.jai";
#load "color.jai";
#load "draw.jai";
#load "entity.jai";
#load "log.jai";
#load "pixel_perfect_viewport.jai";
#load "physics.jai";
#load "pool.jai";
#load "raylib_imgui.jai";
#load "resource.jai";
#load "resource_manager.jai";
#load "statemachine.jai";
#load "string_hash.jai";
#load "tilemap.jai";
#load "undo_redo.jai";
#load "viewport.jai";
#load "yae.jai";

#load "imgui/imgui.jai";
#load "imgui/imgui_canvas.jai";

#load "math/bounds.jai";
#load "math/collision.jai";
#load "math/curve.jai";
#load "math/ease.jai";
#load "math/math.jai";
#load "math/rect.jai";
#load "math/spline.jai";

#load "resources/texture_file.jai";
#load "resources/aseprite_file.jai";
#load "resources/animation.jai";

#load "serialization/json_serializer.jai";
#load "serialization/reflection_serialization.jai";
#load "serialization/serializer.jai";

#load "tools/aseprite.jai";
#load "tools/filesystem.jai";
#load "tools/json.jai";
#load "tools/misc.jai";
#load "tools/reflection.jai";
#load "tools/os.jai";

#load "editor/editor.jai";
#load "editor/animation_editor.jai";
#load "editor/aseprite_file_editor.jai";
#load "editor/resource_browser.jai";
#load "editor/resource_editor.jai";
#load "editor/texture_file_editor.jai";

#scope_module

#import,dir "./modules/jaison";
ImGui :: #import,dir "./modules/ImGui";

#poke_name (#import "Hash_Table") operator ==;
#poke_name (#import "Basic") operator ==;