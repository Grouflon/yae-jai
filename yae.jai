YAE_DEBUG_MEMORY :: (OS != .WASM);

YAE : struct @serialize_optin
{
    debugger_handle : *void;
    
    app_window_rect: IntRect = .{0, 30, 800, 600}; @serialize
    console_window_rect: IntRect = .{50, 80, 800, 600}; @serialize
    debugger_window_rect: IntRect = .{50, 80, 800, 600}; @serialize

    editor: Editor; @serialize
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
    log_indent();

    debugger_handle = find_window_by_title_containing("RemedyBG");

    // Normalize working directory
    exe_directory: = path_strip_filename(get_path_of_running_executable());
    root_directory: = tprint("%/..", exe_directory);
    set_working_directory(root_directory);
    log_verbose("working directory: %", get_working_directory());

    // Init Window
    window_flags: rl.ConfigFlags;
    window_flags |= .FLAG_WINDOW_RESIZABLE;
    rl.InitWindow(width, height, temp_c_string(title));
    rl.SetWindowState(xx window_flags);
    rl.SetTargetFPS(60);
    rl.SetExitKey(.KEY_NULL);

    // Init serialization
    serialization_manager_init(compile_time_info.custom_serialize_types); // custom_serialize_types is generated at build time. See build.jai

    // Init & gather resources
    resource_manager_init(compile_time_info.resource_types, "data"); // resource_types is generated at build time. See build.jai

    // Read settings
    if read_json_file(YAE_SETTINGS_PATH, *YAE)
    {
        console_handle: = get_console_window_handle();

        if YAE.app_window_rect != IntRect.{} { set_window_rect(rl.GetWindowHandle(), YAE.app_window_rect); }
        if YAE.console_window_rect != IntRect.{} { set_window_rect(get_console_window_handle(), YAE.console_window_rect); }
        if YAE.debugger_window_rect != IntRect.{} { set_window_rect(debugger_handle, YAE.debugger_window_rect); }
    }

    // Init stuff
    editor_init();

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

    log_unindent();
    log_verbose("yae initialized.");
}

yae_shutdown :: ()
{
    using YAE;

    log_verbose("shutting down yae...");
    log_indent();

    raylib_imgui_shutdown();

    editor_shutdown();
    resource_manager_shutdown();
    serialization_manager_shutdown();

    rl.CloseWindow();

    free_string_hash_repository();

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

    log_unindent();
    log_verbose("yae shut down.");
}

yae_loop :: (update_function: #type (dt: float), draw_function: #type ())
{
    using YAE;

    while !rl.WindowShouldClose()
    {
        reset_temporary_storage();
        dt: = rl.GetFrameTime();

        // Settings cache & update
        prev_yae_state: = YAE;
        { success, rect: = get_window_rect(rl.GetWindowHandle());           if success YAE.app_window_rect = rect; }
        { success, rect: = get_window_rect(get_console_window_handle());    if success YAE.console_window_rect = rect; }
        { success, rect: = get_window_rect(debugger_handle);                if success YAE.debugger_window_rect = rect; }
        
        // Update
        {
            resource_manager_update();
            raylib_imgui_new_frame(dt);

            if update_function != null { update_function(dt); }

            editor_update(dt);
        }

        // Draw
        {
            rl.BeginDrawing();
            defer rl.EndDrawing();

            rl.ClearBackground(rl.BLACK);

            if draw_function != null { draw_function(); }

            raylib_imgui_render();
            rl.DrawFPS(rl.GetScreenWidth() - 90, 25);
        }

        // Settings compare & save
        settings_save_requested: = memcmp(*prev_yae_state, *YAE, size_of(type_of(YAE))) != 0;
        if settings_save_requested
        {
            settings_save_requested = false;
            make_directory_if_it_does_not_exist(get_directory(YAE_SETTINGS_PATH), true);
            write_json_file(YAE_SETTINGS_PATH, *YAE);
        }
    }
}

#scope_file

YAE_SETTINGS_PATH :: "temp/yae_settings.json";

#import "System";
rl :: #import "raylib";
