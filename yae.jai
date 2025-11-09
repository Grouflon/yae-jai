RAYLIB_LOG_SECTION :: Log_Section.{ "Raylib" };

YAE :: struct
{
    app_window_rect: IntRect = .{0, 30, 800, 600}; @serialize
    console_window_rect: IntRect = .{50, 80, 800, 600}; @serialize
    debugger_window_rect: IntRect = .{50, 80, 800, 600}; @serialize

    engine_resources: [..]*Resource;

    window_handle: *void;
    debugger_handle: *void;
    settings: Settings;
    renderer: Renderer;

#if WITH_EDITOR
{
    editor: Editor;
}

    root_directory: string;
    yae_directory: string;

    time: float64;
    should_close: bool;

    update_function: #type (dt: float);
    draw_function: #type ();
};
yae: YAE;

// note: can we remove the compile time argument with a macro ?
yae_init :: (compile_time_info: *YaeCompileTimeInfo, width: s32, height: s32, title: string)
{
    using yae;
    context.logger = yae_logger;

    log_verbose("Initializing yae...");
    log_indent();

    debugger_handle = find_window_by_title_containing("RemedyBG");

    // Normalize working directory
    exe_directory: = path_strip_filename(get_path_of_running_executable());
    set_working_directory(tprint("%/..", exe_directory));
    root_directory = copy_string(normalize_path(get_working_directory()));
    yae_directory = sprint("%/modules/yae", root_directory);
    log_verbose("working directory: %", root_directory);
    log_verbose("yae directory: %", yae_directory);

    // Init core stuff
    register_resources(*yae_resources, *engine_resources);
    compile_time_registry_init(compile_time_info);

    time = get_time();
    undo_redo_manager_init();
    resource_manager_init(compile_time_info.resource_types);

    // Init Window
    window_handle = create_window(width, height, title);
    renderer_init();
    // window_flags: rl.ConfigFlags;
    // window_flags |= .FLAG_WINDOW_RESIZABLE;
    // rl.InitWindow(width, height, temp_c_string(title));
    // rl.SetWindowState(xx window_flags);
    // rl.SetTargetFPS(60);
    // rl.SetExitKey(.KEY_NULL);

    // ImGui
    #if IMGUI_SUPPORTED
    {
        imgui_config: ImGuiConfig = .{
            theme = .DARK,
            fonts = .[
                .{
                    path = "yae_data://fonts/Font Awesome 6 Free-Solid-900.otf",
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
        imgui_init(imgui_config);
    }

    // Init Settings
    register_settings_section("app", *yae, null, (data: *void)
    {
        using t: *YAE = xx data;
        if debugger_window_rect != IntRect.{} { set_window_rect(debugger_handle, debugger_window_rect); }
        if console_window_rect != IntRect.{} { set_window_rect(get_console_window_handle(), console_window_rect); }
        if app_window_rect != IntRect.{} { set_window_rect(window_handle, app_window_rect); }
    });
    #if WITH_EDITOR
    {
        editor_register_settings_section();
    }
    settings_init(); // also loads settings

    // Init stuff
    draw_init();
    #if WITH_EDITOR
    {
        editor_init();
    }

    load_resources(engine_resources);

    log_unindent();
    log_verbose("yae initialized.");
}

yae_shutdown :: ()
{
    using yae;

    log_verbose("shutting down yae...");
    log_indent();

    unload_resources(engine_resources);

    #if WITH_EDITOR
    {
        editor_shutdown();
    }
    draw_shutdown();

    #if IMGUI_SUPPORTED
    {
        imgui_shutdown();
    }

    renderer_shutdown();
    destroy_window(window_handle);

    resource_manager_shutdown();
    undo_redo_manager_shutdown();
    compile_time_registry_shutdown();
    // No need to unregister resources, resource_manager clears everything
    array_reset(*engine_resources);

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

    log_unindent();
    log_verbose("yae shut down.");
}

yae_loop :: (update_function: #type (dt: float), draw_function: #type ())
{
    yae.update_function = update_function;
    yae.draw_function = draw_function;

    #if OS == .WASM { return; }

    while !yae.should_close
    {
        previous_time: = yae.time;
        yae.time = get_time();
        dt: = yae.time - previous_time;

        yae_frame(xx dt);
    }
}

yae_frame :: (dt: float)
{
    using yae;

    reset_temporary_storage();
    // time += dt;

    // Update Windows rects
    { success, rect: = get_window_rect(debugger_handle);                if success yae.debugger_window_rect = rect; }
    { success, rect: = get_window_rect(get_console_window_handle());    if success yae.console_window_rect = rect; }
    { success, rect: = get_window_rect(window_handle);           if success yae.app_window_rect = rect; }
    
    // Update
    {
        update_input_events();
        resource_manager_update();

        #if IMGUI_SUPPORTED
        {
            imgui_new_frame(dt);
        }

        for events_this_frame
        {
            if it.type == .QUIT then should_close = true;
        }

        if update_function != null { update_function(dt); }

        #if WITH_EDITOR
        {
            editor_update(dt);
        }
    }

    // Draw
    {
        begin_draw();

        if draw_function != null { draw_function(); }

        end_draw();

        #if IMGUI_SUPPORTED
        {
            imgui_render();
        }

        swap_buffers(yae.window_handle);
    }

    settings_update();
}

yae_resolve_path :: (path: string) -> string
{
    push_allocator(temporary_allocator);

    resolved_path: = path;
    if begins_with(path, "data://")
    {
        resolved_path = replace(resolved_path, "data://", "./data/");
    }
    else if begins_with(path, "yae_data://")
    {
        resolved_path = replace(resolved_path, "yae_data://", tprint("%/data/", yae.yae_directory));
    }
    return normalize_path(resolved_path);
}

#scope_file

// tracelog_callback :: (log_level: s32, text: *u8, args: *void) #c_call
// {
//     ctx: #Context;
//     ctx.logger = yae_logger;
//     push_context ctx
//     {
//         trace_log_level: rl.TraceLogLevel = xx log_level;
//         t: = c_format_string(text, args);

//         if trace_log_level == 
//         {
//             case .RL_LOG_TRACE; #through;
//             case .RL_LOG_DEBUG;
//             {
//                 log_verbose(t, section = *RAYLIB_LOG_SECTION);
//             }
//             case;
//             {
//                 log(t);
//             }
//             case .RL_LOG_WARNING;
//             {
//                 log_warning(t, section = *RAYLIB_LOG_SECTION);
//             }
//             case .RL_LOG_ERROR;
//             case .RL_LOG_FATAL;
//             {
//                 log_error(t, section = *RAYLIB_LOG_SECTION);
//             }
//         }
//     }
// }


#import "System";
#import "Input";

// rl :: #import "raylib";
