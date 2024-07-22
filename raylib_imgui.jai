RaylibImGuiConfig :: struct
{
    theme: ImGuiTheme = .CLASSIC;
    font_file: string = "";
    font_size: float = 10.0;

    user_data: *void;
    show_cursor_callback: #type (user_data: *void);
    hide_cursor_callback: #type (user_data: *void);
    change_cursor_callback: #type (cursor: MouseCursor, user_data: *void);
}

ImGuiTheme :: enum
{
    CLASSIC;
    DARK;
    LIGHT;
}

raylib_imgui_init :: (config: RaylibImGuiConfig = .{})
{
    // Setup Mappings
    setup_keymap();
    setup_mouse_cursors();

    // Init base state
    global_state.last_frame_focused = IsWindowFocused();

    global_state.config = config;
    global_state.config.font_file = copy_string(config.font_file);

    // Create context
    global_state.imgui_context = ImGui.CreateContext(null);
    ImGui.SetCurrentContext(global_state.imgui_context);

    // Setup Fonts
    io: = ImGui.GetIO();
    io.DisplayFramebufferScale = GetWindowScaleDPI();
    update_scale(io, io.DisplayFramebufferScale.x); // This loads the font

    // Setup Backend
    io.BackendPlatformName = "raylib";
    io.BackendFlags_ |= .ImGuiBackendFlags_HasGamepad;
    io.BackendFlags_ |= .ImGuiBackendFlags_HasSetMousePos;
    io.BackendFlags_ |= .ImGuiBackendFlags_HasMouseCursors;
    io.MousePos = .{};

    // Setup clipboard functions
    io.GetClipboardTextFn = (_user_data: *void) -> *u8 #c_call { return GetClipboardText(); };
    io.SetClipboardTextFn = (user_data: *void, text: *u8) #c_call { SetClipboardText(text); };
    io.ClipboardUserData = null;
}

raylib_imgui_shutdown :: ()
{
    ImGui.DestroyContext(global_state.imgui_context);
    global_state.imgui_context = null;
}

raylib_imgui_new_frame :: (dt: float)
{
    io: = ImGui.GetIO();

    io.DeltaTime = dt;

    update_display_size(io);

    update_events(io);

    update_mouse_cursor(io);

    ImGui.NewFrame();
}

raylib_imgui_render :: ()
{
    ImGui.Render();

    io: = ImGui.GetIO();

    fb_width := (io.DisplaySize.x * io.DisplayFramebufferScale.x);
    fb_height := (io.DisplaySize.y * io.DisplayFramebufferScale.y);
    if fb_width == 0 || fb_height == 0 return;

    draw_data: = ImGui.GetDrawData();

    DrawRenderBatchActive();
    DisableBackfaceCulling();
    EnableScissorTest();

    for i: 0..draw_data.CmdListsCount-1
    {
        command_list: = draw_data.CmdLists[i];

        for j: 0..command_list.CmdBuffer.Size-1
        {
            cmd: = command_list.CmdBuffer.Data[j];

            Scissor(
                xx (cmd.ClipRect.x),
                xx (io.DisplaySize.y - cmd.ClipRect.w),
                xx (cmd.ClipRect.z - cmd.ClipRect.x),
                xx (cmd.ClipRect.w - cmd.ClipRect.y)
            );

            if cmd.UserCallback != null
            {
                cmd.UserCallback(command_list, *cmd);
                continue;
            }

            render_triangles(cmd.ElemCount, cmd.IdxOffset, command_list.IdxBuffer.Data, command_list.VtxBuffer.Data, cmd.TextureId);
            DrawRenderBatchActive();
        }
    }

    SetTexture(0);
    DisableScissorTest();
    EnableBackfaceCulling();
}

#scope_file

RaylibImgGuiState :: struct
{
    config: RaylibImGuiConfig;

    last_frame_focused: bool;
    last_control_down: bool;
    last_shift_down: bool;
    last_alt_down: bool;
    last_super_down: bool;
    current_mouse_cursor: ImGui.MouseCursor;

    imgui_context: *ImGui.ImGuiContext;
}
global_state: RaylibImgGuiState;


load_fonts :: (fonts: *ImGui.ImFontAtlas)
{
    fonts.ClearFonts(fonts);

    if global_state.config.font_file.count > 0
    {
        fonts.AddFontFromFileTTF(fonts, temp_c_string(global_state.config.font_file), global_state.config.font_size);
    }
    else
    {
        fonts.AddFontDefault(fonts);
    }

    pixels: *u8;
    width: s32;
    height: s32;

    fonts.GetTexDataAsRGBA32(fonts, *pixels, *width, *height);
    image: = GenImageColor(width, height, BLANK);
    memcpy(image.data, pixels, width * height * 4);

    font_texture: = Texture2D.{ id = cast(u32) fonts.TexID };
    if font_texture.id != 0
    {
        UnloadTexture(font_texture);
    }

    font_texture = LoadTextureFromImage(image);
    UnloadImage(image);

    fonts.TexID = cast(ImGui.ImTextureID) font_texture.id;
}

update_display_size :: (io: *ImGui.IO)
{
    if IsWindowFullscreen()
    {
        monitor: = GetCurrentMonitor();
        io.DisplaySize.x = cast(float) GetMonitorWidth(monitor);
        io.DisplaySize.y = cast(float) GetMonitorHeight(monitor);
    }
    else
    {
        io.DisplaySize.x = cast(float) GetScreenWidth();
        io.DisplaySize.y = cast(float) GetScreenHeight();
    }


    resolution_scale: = GetWindowScaleDPI();
    if resolution_scale != io.DisplayFramebufferScale
    {
        io.DisplayFramebufferScale = resolution_scale;
        update_scale(io, io.DisplayFramebufferScale.x);
    }
}

update_scale :: (io: *ImGui.IO, scale: float)
{
    // Setup Font
    io.FontGlobalScale = scale;
    load_fonts(io.Fonts);

    // Setup Theme
    if global_state.config.theme ==
    {
        case .CLASSIC; ImGui.StyleColorsClassic();
        case .DARK; ImGui.StyleColorsDark();
        case .LIGHT; ImGui.StyleColorsLight();
    }
    style: = ImGui.GetStyle();
    style.WindowRounding = 4.0;
    style.FrameRounding = 2.0;
    style.ScaleAllSizes(style, scale);
}

update_mouse_cursor :: (io: *ImGui.IO)
{
    hide_cursor :: ()
    {
        if global_state.config.hide_cursor_callback != null
        {
            global_state.config.hide_cursor_callback(global_state.config.user_data);
        }
        else
        {
            HideCursor();
        }
    }

    show_cursor :: ()
    {
        if global_state.config.show_cursor_callback != null
        {
            global_state.config.show_cursor_callback(global_state.config.user_data);
        }
        else
        {
            ShowCursor();
        }
    }

    change_cursor :: (cursor: ImGui.MouseCursor)
    {
        raylib_cursor, found: = table_find(*imgui_raylib_cursors, cursor);
        if !found { raylib_cursor = .MOUSE_CURSOR_DEFAULT; }

        if global_state.config.change_cursor_callback != null
        {
            global_state.config.change_cursor_callback(raylib_cursor, global_state.config.user_data);
        }
        else
        {
            SetMouseCursor(cast(s32) raylib_cursor);
        }
    }

    if io.BackendFlags_ & ImGui.BackendFlags.ImGuiBackendFlags_HasMouseCursors == 0 { return; }
    if io.ConfigFlags_ & ImGui.ConfigFlags.ImGuiConfigFlags_NoMouseCursorChange != 0 { return; }

    wanted_cursor: = ImGui.GetMouseCursor();
    previous_cursor: = global_state.current_mouse_cursor;
    if wanted_cursor == previous_cursor { return; }

    // Cursor has changed
    global_state.current_mouse_cursor = wanted_cursor;
    if wanted_cursor ==
    {
        case ImGui.MouseCursor.ImGuiMouseCursor_None;
        {
            hide_cursor();
        }

        case;
        {
            if previous_cursor == ImGui.MouseCursor.ImGuiMouseCursor_None
            {
                show_cursor();
            }

            if io.ConfigFlags_ & ImGui.ConfigFlags.ImGuiConfigFlags_NoMouseCursorChange == 0
            {
                change_cursor(wanted_cursor);
            }
        }
    }
}

update_events :: (io: *ImGui.IO)
{
    // Window Focus
    focused: = IsWindowFocused();
    if focused != global_state.last_frame_focused
    {
        io.AddFocusEvent(io, focused);
    }
    global_state.last_frame_focused = focused;

    // Input Devices
    update_mouse_events(io);
    update_keyboard_events(io);
    update_gamepad_events(io);
}

update_mouse_events :: (io: *ImGui.IO)
{
    // Buttons
    handle_mouse_event :: (io: *ImGui.IO, ray_mouse: MouseButton, imgui_mouse: ImGui.MouseButton)
    {
        if IsMouseButtonPressed(xx ray_mouse)
        {
            io.AddMouseButtonEvent(io, xx imgui_mouse, true);
        }
        else if IsMouseButtonReleased(xx ray_mouse)
        {
            io.AddMouseButtonEvent(io, xx imgui_mouse, false);
        }
    }
    handle_mouse_event(io, xx .MOUSE_BUTTON_LEFT, ImGui.MouseButton.ImGuiMouseButton_Left);
    handle_mouse_event(io, xx .MOUSE_BUTTON_RIGHT, ImGui.MouseButton.ImGuiMouseButton_Right);
    handle_mouse_event(io, xx .MOUSE_BUTTON_MIDDLE, ImGui.MouseButton.ImGuiMouseButton_Middle);

    // Position
    if io.WantSetMousePos
    {
        SetMousePosition(cast(s32) io.MousePos.x, cast(s32) io.MousePos.y);
    }
    else
    {
        io.AddMousePosEvent(io, cast(float) GetMouseX(), cast(float) GetMouseY());
    }

    // Wheel
    mouse_wheel: = GetMouseWheelMove();
    io.AddMouseWheelEvent(io, 0.0, mouse_wheel);
}

update_keyboard_events :: (io: *ImGui.IO)
{
    // Modifer Keys
    ctrl_down: = IsKeyDown(xx KeyboardKey.KEY_RIGHT_CONTROL) || IsKeyDown(xx KeyboardKey.KEY_LEFT_CONTROL);
    if ctrl_down != global_state.last_control_down
    {
        io.AddKeyEvent(io, ImGui.Key.ImGuiMod_Ctrl, ctrl_down);
        global_state.last_control_down = ctrl_down;
    }

    shift_down: = IsKeyDown(xx KeyboardKey.KEY_RIGHT_SHIFT) || IsKeyDown(xx KeyboardKey.KEY_LEFT_SHIFT);
    if shift_down != global_state.last_shift_down
    {
        io.AddKeyEvent(io, ImGui.Key.ImGuiMod_Shift, shift_down);
        global_state.last_shift_down = shift_down;
    }

    alt_down: = IsKeyDown(xx KeyboardKey.KEY_RIGHT_ALT) || IsKeyDown(xx KeyboardKey.KEY_LEFT_ALT);
    if alt_down != global_state.last_alt_down
    {
        io.AddKeyEvent(io, ImGui.Key.ImGuiMod_Alt, alt_down);
        global_state.last_alt_down = alt_down;
    }

    super_down: = IsKeyDown(xx KeyboardKey.KEY_RIGHT_SUPER) || IsKeyDown(xx KeyboardKey.KEY_LEFT_SUPER);
    if super_down != global_state.last_super_down
    {
        io.AddKeyEvent(io, ImGui.Key.ImGuiMod_Super, super_down);
        global_state.last_super_down = super_down;
    }

    // Key Pressed/Released
    for raylib_key: KeyboardKey.KEY_NULL..KeyboardKey.KEY_KP_EQUAL
    {
        imgui_key, found: = table_find(*raylib_imgui_keymap, raylib_key);
        if !found { continue; }

        if IsKeyPressed(xx raylib_key)
        {
            io.AddKeyEvent(io, imgui_key, true);
        }
        if IsKeyReleased(xx raylib_key)
        {
            io.AddKeyEvent(io, imgui_key, false);
        }
    }

    // Key Capture
    if io.WantCaptureKeyboard
    {
        // add the text input in order
        pressed: = GetCharPressed();
        while pressed != 0
        {
            io.AddInputCharacter(io, cast(u32) pressed);
            pressed = GetCharPressed();
        }
    }
}

update_gamepad_events :: (io: *ImGui.IO)
{
    handle_gamepad_button_event :: (io: *ImGui.IO, button: GamepadButton, key: ImGui.Key)
    {
        if IsGamepadButtonPressed(0, xx button)
        {
            io.AddKeyEvent(io, key, true);
        }
        if IsGamepadButtonReleased(0, xx button)
        {
            io.AddKeyEvent(io, key, false);
        }
    }

    handle_gamepad_stick_event :: (io: *ImGui.IO, axis: GamepadAxis, neg_key: ImGui.Key, pos_key: ImGui.Key)
    {
        DEAD_ZONE :: 0.20;

        axis_value: = GetGamepadAxisMovement(0, cast(s32) axis);

        io.AddKeyAnalogEvent(io, pos_key, axis_value > DEAD_ZONE, (ifx axis_value > DEAD_ZONE then axis_value else 0));
        io.AddKeyAnalogEvent(io, neg_key, axis_value < -DEAD_ZONE, (ifx axis_value < -DEAD_ZONE then axis_value else 0));
    }

    if io.ConfigFlags_ & ImGui.ConfigFlags.ImGuiConfigFlags_NavEnableGamepad != 0 { return; }
    if IsGamepadAvailable(0) { return; }

    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_LEFT_FACE_UP, ImGui.Key.ImGuiKey_GamepadDpadUp);
    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_LEFT_FACE_RIGHT, ImGui.Key.ImGuiKey_GamepadDpadRight);
    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_LEFT_FACE_DOWN, ImGui.Key.ImGuiKey_GamepadDpadDown);
    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_LEFT_FACE_LEFT, ImGui.Key.ImGuiKey_GamepadDpadLeft);

    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_RIGHT_FACE_UP, ImGui.Key.ImGuiKey_GamepadFaceUp);
    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_RIGHT_FACE_RIGHT, ImGui.Key.ImGuiKey_GamepadFaceLeft);
    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_RIGHT_FACE_DOWN, ImGui.Key.ImGuiKey_GamepadFaceDown);
    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_RIGHT_FACE_LEFT, ImGui.Key.ImGuiKey_GamepadFaceRight);

    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_LEFT_TRIGGER_1, ImGui.Key.ImGuiKey_GamepadL1);
    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_LEFT_TRIGGER_2, ImGui.Key.ImGuiKey_GamepadL2);
    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_RIGHT_TRIGGER_1, ImGui.Key.ImGuiKey_GamepadR1);
    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_RIGHT_TRIGGER_2, ImGui.Key.ImGuiKey_GamepadR2);
    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_LEFT_THUMB, ImGui.Key.ImGuiKey_GamepadL3);
    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_RIGHT_THUMB, ImGui.Key.ImGuiKey_GamepadR3);

    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_MIDDLE_LEFT, ImGui.Key.ImGuiKey_GamepadStart);
    handle_gamepad_button_event(io, .GAMEPAD_BUTTON_MIDDLE_RIGHT, ImGui.Key.ImGuiKey_GamepadBack);

    // left stick
    handle_gamepad_stick_event(io, .GAMEPAD_AXIS_LEFT_X, ImGui.Key.ImGuiKey_GamepadLStickLeft, ImGui.Key.ImGuiKey_GamepadLStickRight);
    handle_gamepad_stick_event(io, .GAMEPAD_AXIS_LEFT_Y, ImGui.Key.ImGuiKey_GamepadLStickUp, ImGui.Key.ImGuiKey_GamepadLStickDown);

    // right stick
    handle_gamepad_stick_event(io, .GAMEPAD_AXIS_RIGHT_X, ImGui.Key.ImGuiKey_GamepadRStickLeft, ImGui.Key.ImGuiKey_GamepadRStickRight);
    handle_gamepad_stick_event(io, .GAMEPAD_AXIS_RIGHT_Y, ImGui.Key.ImGuiKey_GamepadRStickUp, ImGui.Key.ImGuiKey_GamepadRStickDown);
}

render_triangles :: (count: int, start_index: int, indices: *ImGui.ImDrawIdx, vertices: *ImGui.ImDrawVert, texture_id: ImGui.ImTextureID)
{
    if count < 3 { return; }

    triangle_vertex :: (_vert: ImGui.ImDrawVert)
    {
        c: = cast(*Color)*_vert.col;
        Color4ub(c.r, c.g, c.b, c.a);
        TexCoord2f(_vert.uv.x, _vert.uv.y);
        Vertex2f(_vert.pos.x, _vert.pos.y);
    }

    Begin(RL_TRIANGLES);
    SetTexture(cast(u32)texture_id);

    i: int = 0;
    while i <= (count - 3)
    {
        index_A: = indices[start_index + i];
        index_B: = indices[start_index + i + 1];
        index_C: = indices[start_index + i + 2];

        vertex_A: = vertices[index_A];
        vertex_B: = vertices[index_B];
        vertex_C: = vertices[index_C];

        triangle_vertex(vertex_A);
        triangle_vertex(vertex_B);
        triangle_vertex(vertex_C);

        i += 3;
    }
    End();
}

raylib_imgui_keymap: Table(KeyboardKey, ImGui.Key);
setup_keymap :: ()
{
    if raylib_imgui_keymap.count > 0 { return; }

    // build up a map of raylib keys to ImGuiKeys
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_APOSTROPHE, ImGui.Key.ImGuiKey_Apostrophe);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_COMMA, ImGui.Key.ImGuiKey_Comma);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_MINUS, ImGui.Key.ImGuiKey_Minus);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_PERIOD, ImGui.Key.ImGuiKey_Period);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_SLASH, ImGui.Key.ImGuiKey_Slash);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_ZERO, ImGui.Key.ImGuiKey_0);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_ONE, ImGui.Key.ImGuiKey_1);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_TWO, ImGui.Key.ImGuiKey_2);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_THREE, ImGui.Key.ImGuiKey_3);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_FOUR, ImGui.Key.ImGuiKey_4);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_FIVE, ImGui.Key.ImGuiKey_5);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_SIX, ImGui.Key.ImGuiKey_6);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_SEVEN, ImGui.Key.ImGuiKey_7);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_EIGHT, ImGui.Key.ImGuiKey_8);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_NINE, ImGui.Key.ImGuiKey_9);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_SEMICOLON, ImGui.Key.ImGuiKey_Semicolon);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_EQUAL, ImGui.Key.ImGuiKey_Equal);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_A, ImGui.Key.ImGuiKey_A);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_B, ImGui.Key.ImGuiKey_B);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_C, ImGui.Key.ImGuiKey_C);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_D, ImGui.Key.ImGuiKey_D);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_E, ImGui.Key.ImGuiKey_E);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_F, ImGui.Key.ImGuiKey_F);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_G, ImGui.Key.ImGuiKey_G);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_H, ImGui.Key.ImGuiKey_H);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_I, ImGui.Key.ImGuiKey_I);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_J, ImGui.Key.ImGuiKey_J);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_K, ImGui.Key.ImGuiKey_K);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_L, ImGui.Key.ImGuiKey_L);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_M, ImGui.Key.ImGuiKey_M);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_N, ImGui.Key.ImGuiKey_N);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_O, ImGui.Key.ImGuiKey_O);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_P, ImGui.Key.ImGuiKey_P);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_Q, ImGui.Key.ImGuiKey_Q);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_R, ImGui.Key.ImGuiKey_R);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_S, ImGui.Key.ImGuiKey_S);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_T, ImGui.Key.ImGuiKey_T);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_U, ImGui.Key.ImGuiKey_U);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_V, ImGui.Key.ImGuiKey_V);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_W, ImGui.Key.ImGuiKey_W);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_X, ImGui.Key.ImGuiKey_X);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_Y, ImGui.Key.ImGuiKey_Y);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_Z, ImGui.Key.ImGuiKey_Z);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_SPACE, ImGui.Key.ImGuiKey_Space);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_ESCAPE, ImGui.Key.ImGuiKey_Escape);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_ENTER, ImGui.Key.ImGuiKey_Enter);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_TAB, ImGui.Key.ImGuiKey_Tab);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_BACKSPACE, ImGui.Key.ImGuiKey_Backspace);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_INSERT, ImGui.Key.ImGuiKey_Insert);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_DELETE, ImGui.Key.ImGuiKey_Delete);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_RIGHT, ImGui.Key.ImGuiKey_RightArrow);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_LEFT, ImGui.Key.ImGuiKey_LeftArrow);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_DOWN, ImGui.Key.ImGuiKey_DownArrow);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_UP, ImGui.Key.ImGuiKey_UpArrow);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_PAGE_UP, ImGui.Key.ImGuiKey_PageUp);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_PAGE_DOWN, ImGui.Key.ImGuiKey_PageDown);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_HOME, ImGui.Key.ImGuiKey_Home);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_END, ImGui.Key.ImGuiKey_End);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_CAPS_LOCK, ImGui.Key.ImGuiKey_CapsLock);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_SCROLL_LOCK, ImGui.Key.ImGuiKey_ScrollLock);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_NUM_LOCK, ImGui.Key.ImGuiKey_NumLock);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_PRINT_SCREEN, ImGui.Key.ImGuiKey_PrintScreen);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_PAUSE, ImGui.Key.ImGuiKey_Pause);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_F1, ImGui.Key.ImGuiKey_F1);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_F2, ImGui.Key.ImGuiKey_F2);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_F3, ImGui.Key.ImGuiKey_F3);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_F4, ImGui.Key.ImGuiKey_F4);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_F5, ImGui.Key.ImGuiKey_F5);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_F6, ImGui.Key.ImGuiKey_F6);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_F7, ImGui.Key.ImGuiKey_F7);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_F8, ImGui.Key.ImGuiKey_F8);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_F9, ImGui.Key.ImGuiKey_F9);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_F10, ImGui.Key.ImGuiKey_F10);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_F11, ImGui.Key.ImGuiKey_F11);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_F12, ImGui.Key.ImGuiKey_F12);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_LEFT_SHIFT, ImGui.Key.ImGuiKey_LeftShift);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_LEFT_CONTROL, ImGui.Key.ImGuiKey_LeftCtrl);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_LEFT_ALT, ImGui.Key.ImGuiKey_LeftAlt);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_LEFT_SUPER, ImGui.Key.ImGuiKey_LeftSuper);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_RIGHT_SHIFT, ImGui.Key.ImGuiKey_RightShift);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_RIGHT_CONTROL, ImGui.Key.ImGuiKey_RightCtrl);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_RIGHT_ALT, ImGui.Key.ImGuiKey_RightAlt);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_RIGHT_SUPER, ImGui.Key.ImGuiKey_RightSuper);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KB_MENU, ImGui.Key.ImGuiKey_Menu);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_LEFT_BRACKET, ImGui.Key.ImGuiKey_LeftBracket);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_BACKSLASH, ImGui.Key.ImGuiKey_Backslash);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_RIGHT_BRACKET, ImGui.Key.ImGuiKey_RightBracket);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_GRAVE, ImGui.Key.ImGuiKey_GraveAccent);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_0, ImGui.Key.ImGuiKey_Keypad0);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_1, ImGui.Key.ImGuiKey_Keypad1);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_2, ImGui.Key.ImGuiKey_Keypad2);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_3, ImGui.Key.ImGuiKey_Keypad3);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_4, ImGui.Key.ImGuiKey_Keypad4);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_5, ImGui.Key.ImGuiKey_Keypad5);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_6, ImGui.Key.ImGuiKey_Keypad6);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_7, ImGui.Key.ImGuiKey_Keypad7);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_8, ImGui.Key.ImGuiKey_Keypad8);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_9, ImGui.Key.ImGuiKey_Keypad9);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_DECIMAL, ImGui.Key.ImGuiKey_KeypadDecimal);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_DIVIDE, ImGui.Key.ImGuiKey_KeypadDivide);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_MULTIPLY, ImGui.Key.ImGuiKey_KeypadMultiply);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_SUBTRACT, ImGui.Key.ImGuiKey_KeypadSubtract);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_ADD, ImGui.Key.ImGuiKey_KeypadAdd);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_ENTER, ImGui.Key.ImGuiKey_KeypadEnter);
    table_set(*raylib_imgui_keymap, KeyboardKey.KEY_KP_EQUAL, ImGui.Key.ImGuiKey_KeypadEqual);
}

imgui_raylib_cursors: Table(ImGui.MouseCursor, MouseCursor);
setup_mouse_cursors :: ()
{
    if imgui_raylib_cursors.count > 0 { return; }

    table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_Arrow, MouseCursor.MOUSE_CURSOR_ARROW);
    table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_TextInput, MouseCursor.MOUSE_CURSOR_IBEAM);
    table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_Hand, MouseCursor.MOUSE_CURSOR_POINTING_HAND);
    table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_ResizeAll, MouseCursor.MOUSE_CURSOR_RESIZE_ALL);
    table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_ResizeEW, MouseCursor.MOUSE_CURSOR_RESIZE_EW);
    table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_ResizeNESW, MouseCursor.MOUSE_CURSOR_RESIZE_NESW);
    table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_ResizeNS, MouseCursor.MOUSE_CURSOR_RESIZE_NS);
    table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_ResizeNWSE, MouseCursor.MOUSE_CURSOR_RESIZE_NWSE);
    table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_NotAllowed, MouseCursor.MOUSE_CURSOR_NOT_ALLOWED);
}

ImGui :: #import "ImGui";
#import "raylib";
#import "Hash_Table";
#import "Math";