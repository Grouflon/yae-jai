YAE_DEBUG_MEMORY :: (OS != .WASM);
RAYLIB_LOG_SECTION :: Log_Section.{ "Raylib" };

YAE :: struct
{
    app_window_rect: IntRect = .{0, 30, 800, 600}; @serialize
    console_window_rect: IntRect = .{50, 80, 800, 600}; @serialize
    debugger_window_rect: IntRect = .{50, 80, 800, 600}; @serialize

    debugger_handle: *void;
    settings: Settings;
    editor: Editor;

    root_directory: string;
    yae_directory: string;

    time: float;
};
yae: YAE;

yae_init :: (compile_time_info: *YaeCompileTimeInfo, width: s32, height: s32, title: string)
{
    using yae;
    context.logger = yae_logger;
    rl.SetTraceLogCallback(tracelog_callback);

    log_verbose("Initializing yae...");
    log_indent();

    debugger_handle = find_window_by_title_containing("RemedyBG");

    // Normalize working directory
    exe_directory: = path_strip_filename(get_path_of_running_executable());
    root_directory = copy_string(normalize_path(tprint("%/..", exe_directory)));
    set_working_directory(root_directory);
    yae_directory = sprint("%/modules/yae", root_directory);
    log_verbose("working directory: %", root_directory);
    log_verbose("yae directory: %", yae_directory);

    // Init core stuff
    compile_time_registry_init(compile_time_info);

    time = 0;
    undo_redo_manager_init();
    resource_manager_init(compile_time_info.resource_types);
    physics_init();

    // Init Window
    window_flags: rl.ConfigFlags;
    window_flags |= .FLAG_WINDOW_RESIZABLE;
    rl.InitWindow(width, height, temp_c_string(title));
    rl.SetWindowState(xx window_flags);
    rl.SetTargetFPS(60);
    rl.SetExitKey(.KEY_NULL);

    // Init Settings
    register_settings_section("app", *yae, null, (data: *void)
    {
        using t: *YAE = xx data;
        if debugger_window_rect != IntRect.{} { set_window_rect(debugger_handle, debugger_window_rect); }
        if console_window_rect != IntRect.{} { set_window_rect(get_console_window_handle(), console_window_rect); }
        if app_window_rect != IntRect.{} { set_window_rect(rl.GetWindowHandle(), app_window_rect); }
    });
    editor_register_settings_section();
    settings_init(); // also loads settings

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

    log_verbose("yae initialized.");
    log_unindent();
}

yae_shutdown :: ()
{
    using yae;

    log_verbose("shutting down yae...");
    log_indent();

    raylib_imgui_shutdown();

    editor_shutdown();

    rl.CloseWindow();

    physics_shutdown();
    resource_manager_shutdown();
    undo_redo_manager_shutdown();
    compile_time_registry_shutdown();

    settings_shutdown();

    free(yae_directory);
    free(root_directory);
    yae_directory = .{};
    root_directory = .{};

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
    log_unindent();
}

get_time :: () -> float64
{
    return rl.GetTime();
}

yae_loop :: (update_function: #type (dt: float), draw_function: #type ())
{
    using yae;

    while !rl.WindowShouldClose()
    {
        reset_temporary_storage();
        dt: = rl.GetFrameTime();
        time += dt;

        // Update Windows rects
        { success, rect: = get_window_rect(debugger_handle);                if success yae.debugger_window_rect = rect; }
        { success, rect: = get_window_rect(get_console_window_handle());    if success yae.console_window_rect = rect; }
        { success, rect: = get_window_rect(rl.GetWindowHandle());           if success yae.app_window_rect = rect; }
        
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
        }

        settings_update();
    }
}

#scope_file

tracelog_callback :: (log_level: s32, text: *u8, args: *void) #c_call
{
    ctx: #Context;
    ctx.logger = yae_logger;
    push_context ctx
    {
        trace_log_level: rl.TraceLogLevel = xx log_level;
        t: = c_format_string(text, args);

        if trace_log_level == 
        {
            case .RL_LOG_TRACE; #through;
            case .RL_LOG_DEBUG;
            {
                log_verbose(t, section = *RAYLIB_LOG_SECTION);
            }
            case;
            {
                log(t);
            }
            case .RL_LOG_WARNING;
            {
                log_warning(t, section = *RAYLIB_LOG_SECTION);
            }
            case .RL_LOG_ERROR;
            case .RL_LOG_FATAL;
            {
                log_error(t, section = *RAYLIB_LOG_SECTION);
            }
        }
    }
}


#import "System";
rl :: #import "raylib";
