PreloadFunction :: #type ();
InitFunction :: #type ();
UpdateFunction :: #type (dt: float32);
ShutdownFunction :: #type ();

Application :: struct
{
    window: *void;
    stop_requested: bool;

    preload_function: PreloadFunction;
    init_function: InitFunction;
    update_function: UpdateFunction;
    shutdown_function: ShutdownFunction;
}

ApplicationParameters :: struct
{
    width: int;
    height: int;
    name: string;

    preload_function: InitFunction;
    init_function: InitFunction;
    update_function: UpdateFunction;
    shutdown_function: ShutdownFunction;
}

app: Application;

application_run :: (parameters: ApplicationParameters)
{
    app.preload_function = parameters.preload_function;
    app.init_function = parameters.init_function;
    app.update_function = parameters.update_function;
    app.shutdown_function = parameters.shutdown_function;

    app.window = create_window(parameters.width, parameters.height, parameters.name);
    application_preload();

    #if OS == .WASM
    {
        // Nothing to do, window creation will call us back
    }
    else
    {
        application_init();

        t := seconds_since_init();
        while !app.stop_requested
        {
            previous_t: = t;
            t = seconds_since_init();
            dt: float32 = xx (t - previous_t);

            application_update(dt);
        }

        application_shutdown();
    }
}

application_request_stop :: ()
{
    app.stop_requested = true;
}

// Internal
application_preload :: ()
{
    if app.preload_function != null then app.preload_function();
}

application_init :: ()
{
    renderer_init(app.window);

    if app.init_function != null then app.init_function();
}

application_update :: (dt: float32)
{
    reset_temporary_storage();

    update_input_events();

    for events_this_frame
    {
        if it.type == .QUIT then application_request_stop();

        if it.type == .KEYBOARD
        {
            if it.key_pressed == 0 continue;

            if it.key_code == .ESCAPE
            {
                application_request_stop();
            }
        }
    }

    if app.update_function != null then app.update_function(dt);

    swap_buffers(app.window);
}

application_shutdown :: ()
{
    if app.shutdown_function != null then app.shutdown_function();

    renderer_shutdown();
}

#scope_file

#import "Input";
#import "Basic";
#import "Math";
