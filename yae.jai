YAE_DEBUG_MEMORY :: (OS != .WASM);

EditorState :: struct
{
    app_window_rect: IntRect = .{0, 30, 800, 600}; @serialize
    console_window_rect: IntRect = .{50, 80, 800, 600}; @serialize
    debugger_window_rect: IntRect = .{50, 80, 800, 600}; @serialize

    resources_open: bool; @serialize
    imgui_demo_open: bool; @serialize
    imgui_font_open: bool; @serialize

    animation_editor_open: bool; @serialize
}

animation_editor: AnimationEditor;
editor_settings_save_requested: = false;

YAE : struct
{
    debugger_handle : *void;
    editor_state: EditorState;
};

// a YAE_COMPILE_TIME_INFO constant is generated at compile time. See compile_time.jai
YaeCompileTimeInfo :: struct
{
    resource_types: []*Type_Info_Struct;
    custom_serialize_types: []CustomSerializeType;
}

yae_init :: (compile_time_info: YaeCompileTimeInfo, width: s32, height: s32, title: string)
{
    using YAE;
    context.logger = yae_logger;

    log_verbose("Initializing yae...");

    debugger_handle = find_window_by_title_containing("RemedyBG");


    // Normalize working directory
    exe_directory: = path_strip_filename(get_path_of_running_executable());
    root_directory: = tprint("%/..", exe_directory);
    set_working_directory(root_directory);
    log_verbose("working directory: %", get_working_directory());

    // Init basic stuff
    serialization_manager_init(compile_time_info.custom_serialize_types); // custom_serialize_types is generated at build time. See build.jai
    resource_manager_init(compile_time_info.resource_types, "data"); // resource_types is generated at build time. See build.jai

    // Init Window
    window_flags: rl.ConfigFlags;
    window_flags |= .FLAG_WINDOW_RESIZABLE;
    rl.InitWindow(width, height, temp_c_string(title));
    rl.SetWindowState(xx window_flags);
    rl.SetTargetFPS(60);
    rl.SetExitKey(.KEY_NULL);

    // Set windows positions
    if read_json_file(EDITOR_SETTINGS_PATH, *editor_state, DEFAULT_SERIALIZATION_PARAMS)
    {
        console_handle: = get_console_window_handle();

        if editor_state.app_window_rect != IntRect.{} { set_window_rect(rl.GetWindowHandle(), editor_state.app_window_rect); }
        if editor_state.console_window_rect != IntRect.{} { set_window_rect(get_console_window_handle(), editor_state.console_window_rect); }
        if editor_state.debugger_window_rect != IntRect.{} { set_window_rect(debugger_handle, editor_state.debugger_window_rect); }
    }

    // Init ImGui
    imgui_config: RaylibImGuiConfig = .{
        theme = .DARK,
        fonts = .[
            .{
                // path = "./data/fonts/Font Awesome 6 Free-Regular-400.otf",
                path = "./data/fonts/Font Awesome 6 Free-Solid-900.otf",
                size = 14,
                range = .[0xf000, 0xf2e0],
                config = .{
                    FontDataOwnedByAtlas = true,
                    MergeMode = true,
                    OversampleH = 2,
                    OversampleV = 1,
                    RasterizerMultiply = 1.0,
                    RasterizerDensity = 1.0,
                    GlyphMaxAdvanceX = FLOAT32_MAX,
                    GlyphOffset = .{0, 2}
                }
            }
        ],
    };
    raylib_imgui_init(imgui_config);

    // Init animation editor
    animation=, _: = resource_load(Animation, "./data/animations/test.res");
    resource_save_to_disk(animation, "./data/animations/test.res");
    animation_editor_init(*animation_editor, animation);

    log_verbose("yae initialized.");
}
animation: *Animation;

yae_shutdown :: ()
{
    log_verbose("shutting down yae...");

    resource_unload(animation);

    raylib_imgui_shutdown();
    rl.CloseWindow();
    resource_manager_shutdown();
    serialization_manager_shutdown();

    // Memory leak check
    #if YAE_DEBUG_MEMORY
    {
        report: = make_leak_report();
        if report.sorted_summaries.count
        {
            log_error("\n=========\nMemory Leak!!\n=========");
            log_leak_report(report);
            assert(false);
        }
    }

    log_verbose("yae shut down.");
}

yae_loop :: (update_function: #type (dt: float), draw_function: #type ())
{
    using YAE;

    while !rl.WindowShouldClose()
    {
        reset_temporary_storage();
        dt: = rl.GetFrameTime();
        prev_editor_state: = editor_state;

        console_handle: = get_console_window_handle();

        { success, rect: = get_window_rect(rl.GetWindowHandle());           if success editor_state.app_window_rect = rect; }
        { success, rect: = get_window_rect(get_console_window_handle());    if success editor_state.console_window_rect = rect; }
        { success, rect: = get_window_rect(debugger_handle);                if success editor_state.debugger_window_rect = rect; }
        
        // Update
        {
            resource_manager_update();

            raylib_imgui_new_frame(dt);

            if update_function != null { update_function(dt); }

            if (editor_state.imgui_demo_open)
            {
                ImGui.ShowDemoWindow(*editor_state.imgui_demo_open);
            }

            if (editor_state.imgui_font_open)
            {
                font_atlas: = ImGui.GetIO().Fonts;
                atlas_size: = ImGui.ImVec2.{xx font_atlas.TexWidth, xx font_atlas.TexHeight};

                ImGui.SetNextWindowContentSize(atlas_size);
                if ImGui.Begin("ImGui Font", null, /*.NoResize |*/ .NoTitleBar | .NoScrollbar| .NoScrollWithMouse)
                {
                    ImGui.Image(font_atlas.TexID, atlas_size);
                }
                ImGui.End();
            }

            if ImGui.BeginMainMenuBar()
            {
                if ImGui.BeginMenu("Windows")
                {
                    ImGui.MenuItem("Resources", "", *editor_state.resources_open);
                    ImGui.MenuItem("Animation Editor", "", *editor_state.animation_editor_open);
                    ImGui.MenuItem("ImGui Demo", "", *editor_state.imgui_demo_open);
                    ImGui.MenuItem("ImGui Font", "", *editor_state.imgui_font_open);

                    ImGui.EndMenu();
                }
            }
            ImGui.EndMainMenuBar();

            prev_resources_open: = editor_state.resources_open;
            if editor_state.resources_open
            {
                if ImGui.Begin("Resources", *editor_state.resources_open)
                {
                    resource_browser_update();
                }
                ImGui.End();
            }

            if editor_state.animation_editor_open
            {
                if ImGui.Begin("Animation Editor", *editor_state.animation_editor_open)
                {
                    animation_editor_update(*animation_editor, dt);
                }
                ImGui.End();
            }
        }

        // Draw
        {
            rl.BeginDrawing();
            defer rl.EndDrawing();

            rl.ClearBackground(rl.BLACK);

            if draw_function != null { draw_function(); }

            raylib_imgui_render();
            rl.DrawFPS(rl.GetScreenWidth() - 90, 10);
        }

        editor_settings_save_requested = memcmp(*prev_editor_state, *editor_state, size_of(EditorState)) != 0;
        if editor_settings_save_requested
        {
            editor_settings_save_requested = false;
            make_directory_if_it_does_not_exist(get_directory(EDITOR_SETTINGS_PATH), true);
            write_json_file(EDITOR_SETTINGS_PATH, *editor_state, DEFAULT_SERIALIZATION_PARAMS);
        }
    }
}

#scope_file

EDITOR_SETTINGS_PATH :: "temp/editor_settings.json";
DEFAULT_SERIALIZATION_PARAMS :: SerializationParams.{ filters = .[.{ .IN, type_info(EditorState), "serialize" }]};

#import "System";
rl :: #import "raylib";
