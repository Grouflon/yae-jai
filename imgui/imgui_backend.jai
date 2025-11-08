ImGuiFont :: struct
{
    path: string;
    size: float;
    range: [2]ImGui.ImWchar;
    config: ImGui.ImFontConfig;
}

ImGuiConfig :: struct
{
    theme: ImGuiTheme = .CLASSIC;

    load_default_font: bool = true;
    fonts: []ImGuiFont;

    user_data: *void;
    show_cursor_callback: #type (user_data: *void);
    hide_cursor_callback: #type (user_data: *void);
    // change_cursor_callback: #type (cursor: MouseCursor, user_data: *void);
}

ImGuiTheme :: enum
{
    CLASSIC;
    DARK;
    LIGHT;
}

imgui_init :: (config: ImGuiConfig = .{})
{
    // Setup Mappings
    setup_keymap();
    // setup_mouse_cursors();

    // // Init base state
    backend_data.last_frame_focused = is_window_focused();

    backend_data.config = config;

    // Create context
    backend_data.imgui_context = ImGui.CreateContext(null);
    ImGui.SetCurrentContext(backend_data.imgui_context);

    // Setup Fonts
    io: = ImGui.GetIO();
    io.DisplayFramebufferScale = get_window_scale_dpi();
    io.DisplayFramebufferScale = .{1,1};
    update_scale(io, io.DisplayFramebufferScale.x); // This loads the font

    // // Setup Backend
    io.BackendPlatformName = "yae";
    io.BackendFlags_ |= .ImGuiBackendFlags_HasGamepad;
    io.BackendFlags_ |= .ImGuiBackendFlags_HasSetMousePos;
    io.BackendFlags_ |= .ImGuiBackendFlags_HasMouseCursors;
    io.MousePos = .{};

    io.ConfigFlags_ |= .ImGuiConfigFlags_DockingEnable;

    // Setup clipboard functions
    io.GetClipboardTextFn = (_user_data: *void) -> *u8 #c_call
    {
        push_context
        {
            return temp_c_string(get_clipboard_text());
        }
    };
    io.SetClipboardTextFn = (user_data: *void, text: *u8) #c_call
    {
        push_context
        {
            set_clipboard_text(to_string(text));
        }
    };
    io.ClipboardUserData = null;
}

imgui_shutdown :: ()
{
    ImGui.DestroyContext(backend_data.imgui_context);
    backend_data.imgui_context = null;
}

imgui_new_frame :: (dt: float)
{
    io: = ImGui.GetIO();

    io.DeltaTime = dt;

    update_display_size(io);

    update_events(io);

    // update_mouse_cursor(io);

    ImGui.NewFrame();
}

imgui_render :: ()
{
    ImGui.Render();
    draw_imgui_drawdata(ImGui.GetDrawData());
}

#scope_file
ImGuiBackendData :: struct
{
    config: ImGuiConfig;
    imgui_context: *ImGui.ImGuiContext;
    last_frame_focused: bool;
    last_control_down: bool;
    last_shift_down: bool;
    last_alt_down: bool;
    last_super_down: bool;
}
backend_data: ImGuiBackendData;

update_scale :: (io: *ImGui.IO, scale: float)
{
    // Setup Font
    load_fonts(io.Fonts, backend_data.config.load_default_font, backend_data.config.fonts, scale);

    // Setup Theme
    if backend_data.config.theme ==
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

load_fonts :: (fonts: *ImGui.ImFontAtlas, load_default_font: bool, fonts_config: []ImGuiFont, scale: float)
{
    fonts.Clear(fonts);

    if load_default_font
    {
        cfg: ImGui.ImFontConfig;
        ImGui.ImFontConfig.Constructor(*cfg);
        cfg.SizePixels = 13 * scale;
        font: = fonts.AddFontDefault(fonts, *cfg);
        assert(font != null);
    }

    for font_config: fonts_config
    {
        path: = yae_resolve_path(font_config.path);
        font: = fonts.AddFontFromFileTTF(fonts, temp_c_string(path), font_config.size * scale, *font_config.config, font_config.range.data);
        assert(font != null);
    }

    pixels: *u8;
    width: s32;
    height: s32;
    bytes_per_pixel: s32;
    fonts.GetTexDataAsRGBA32(fonts, *pixels, *width, *height, *bytes_per_pixel);

    image_data: ImageData;
    image_data.data = pixels;
    image_data.width = xx width;
    image_data.height = xx height;
    image_data.channels = 4;

    font_texture: = Texture.{ handle = cast(u32) fonts.TexID };
    if font_texture.handle != RENDERER_INVALID_HANDLE
    {
        unload_texture(font_texture);
    }
    font_texture = load_texture(image_data);

    fonts.TexID = cast(ImGui.ImTextureID) font_texture.handle;
}

update_display_size :: (io: *ImGui.IO)
{
    w, h: = get_viewport_size();
    io.DisplaySize.x = cast(float) w;
    io.DisplaySize.y = cast(float) h;

    resolution_scale: = get_window_scale_dpi();
    if resolution_scale != io.DisplayFramebufferScale
    {
        io.DisplayFramebufferScale = resolution_scale;
        update_scale(io, io.DisplayFramebufferScale.x);
    }
}

update_events :: (io: *ImGui.IO)
{
    // Window Focus
    focused: = is_window_focused();
    if focused != backend_data.last_frame_focused
    {
        io.AddFocusEvent(io, focused);
    }
    backend_data.last_frame_focused = focused;

    // Input Devices
    update_mouse_events(io);
    update_keyboard_events(io);
    // update_gamepad_events(io);
}

update_mouse_events :: (io: *ImGui.IO)
{
    // Buttons
    handle_mouse_event :: (io: *ImGui.IO, key_code: Key_Code, imgui_mouse: ImGui.MouseButton)
    {
        if is_pressed_raw(key_code)
        {
            io.AddMouseButtonEvent(io, xx imgui_mouse, true);
        }
        else if is_released_raw(key_code)
        {
            io.AddMouseButtonEvent(io, xx imgui_mouse, false);
        }
    }
    handle_mouse_event(io, .MOUSE_BUTTON_LEFT, ImGui.MouseButton.ImGuiMouseButton_Left);
    handle_mouse_event(io, .MOUSE_BUTTON_RIGHT, ImGui.MouseButton.ImGuiMouseButton_Right);
    handle_mouse_event(io, .MOUSE_BUTTON_MIDDLE, ImGui.MouseButton.ImGuiMouseButton_Middle);

    // Position
    if io.WantSetMousePos
    {
        set_mouse_position(.{ io.MousePos.x, io.MousePos.y});
    }
    else
    {
        mouse_position: = get_mouse_position();
        io.AddMousePosEvent(io, mouse_position.x, mouse_position.y);
    }

    // Wheel
    MOUSE_WHEEL_SCALE :: 120;
    mouse_wheel: Vector2 = Vector2.{0, xx mouse_delta_z} / MOUSE_WHEEL_SCALE;
    io.AddMouseWheelEvent(io, mouse_wheel.x, mouse_wheel.y);
}

update_keyboard_events :: (io: *ImGui.IO)
{
    // Modifer Keys
    ctrl_down: = is_down_raw(.CTRL);
    if ctrl_down != backend_data.last_control_down
    {
        io.AddKeyEvent(io, ImGui.Key.ImGuiMod_Ctrl, ctrl_down);
        backend_data.last_control_down = ctrl_down;
    }

    shift_down: = is_down_raw(.SHIFT);
    if shift_down != backend_data.last_shift_down
    {
        io.AddKeyEvent(io, ImGui.Key.ImGuiMod_Shift, shift_down);
        backend_data.last_shift_down = shift_down;
    }

    alt_down: = is_down_raw(.ALT);
    if alt_down != backend_data.last_alt_down
    {
        io.AddKeyEvent(io, ImGui.Key.ImGuiMod_Alt, alt_down);
        backend_data.last_alt_down = alt_down;
    }

    super_down: = is_down_raw(.CMD);
    if super_down != backend_data.last_super_down
    {
        io.AddKeyEvent(io, ImGui.Key.ImGuiMod_Super, super_down);
        backend_data.last_super_down = super_down;
    }

    // Key Pressed/Released
    for key_code: 0..enum_highest_value(Key_Code)
    {
        found, imgui_key: = table_find_new(*imgui_keymap, xx key_code);
        if !found { continue; }

        if is_pressed_raw(xx key_code)
        {
            io.AddKeyEvent(io, imgui_key, true);
        }
        if is_released_raw(xx key_code)
        {
            io.AddKeyEvent(io, imgui_key, false);
        }
    }


    // Key Capture
    if io.WantCaptureKeyboard
    {
        // add the text input in order
        pressed: = get_characters_pressed();
        if pressed.count > 0
        {
            io.AddInputCharactersUTF8(io, temp_c_string(pressed));
        }
    }
}

// update_mouse_cursor :: (io: *ImGui.IO)
// {
//     hide_cursor :: ()
//     {
//         if global_state.config.hide_cursor_callback != null
//         {
//             global_state.config.hide_cursor_callback(global_state.config.user_data);
//         }
//         else
//         {
//             HideCursor();
//         }
//     }

//     show_cursor :: ()
//     {
//         if global_state.config.show_cursor_callback != null
//         {
//             global_state.config.show_cursor_callback(global_state.config.user_data);
//         }
//         else
//         {
//             ShowCursor();
//         }
//     }

//     change_cursor :: (cursor: ImGui.MouseCursor)
//     {
//         found, raylib_cursor: = table_find_new(*imgui_raylib_cursors, cursor);
//         if !found { raylib_cursor = .MOUSE_CURSOR_DEFAULT; }

//         if global_state.config.change_cursor_callback != null
//         {
//             global_state.config.change_cursor_callback(raylib_cursor, global_state.config.user_data);
//         }
//         else
//         {
//             SetMouseCursor(cast(s32) raylib_cursor);
//         }
//     }

//     if io.BackendFlags_ & ImGui.BackendFlags.ImGuiBackendFlags_HasMouseCursors == 0 { return; }
//     if io.ConfigFlags_ & ImGui.ConfigFlags.ImGuiConfigFlags_NoMouseCursorChange != 0 { return; }

//     wanted_cursor: = ImGui.GetMouseCursor();
//     previous_cursor: = global_state.current_mouse_cursor;
//     if wanted_cursor == previous_cursor { return; }

//     // Cursor has changed
//     global_state.current_mouse_cursor = wanted_cursor;
//     if wanted_cursor ==
//     {
//         case ImGui.MouseCursor.ImGuiMouseCursor_None;
//         {
//             hide_cursor();
//         }

//         case;
//         {
//             if previous_cursor == ImGui.MouseCursor.ImGuiMouseCursor_None
//             {
//                 show_cursor();
//             }

//             if io.ConfigFlags_ & ImGui.ConfigFlags.ImGuiConfigFlags_NoMouseCursorChange == 0
//             {
//                 change_cursor(wanted_cursor);
//             }
//         }
//     }
// }

// update_gamepad_events :: (io: *ImGui.IO)
// {
//     handle_gamepad_button_event :: (io: *ImGui.IO, button: GamepadButton, key: ImGui.Key)
//     {
//         if IsGamepadButtonPressed(0, xx button)
//         {
//             io.AddKeyEvent(io, key, true);
//         }
//         if IsGamepadButtonReleased(0, xx button)
//         {
//             io.AddKeyEvent(io, key, false);
//         }
//     }

//     handle_gamepad_stick_event :: (io: *ImGui.IO, axis: GamepadAxis, neg_key: ImGui.Key, pos_key: ImGui.Key)
//     {
//         DEAD_ZONE :: 0.20;

//         axis_value: = GetGamepadAxisMovement(0, cast(s32) axis);

//         io.AddKeyAnalogEvent(io, pos_key, axis_value > DEAD_ZONE, (ifx axis_value > DEAD_ZONE then axis_value else 0));
//         io.AddKeyAnalogEvent(io, neg_key, axis_value < -DEAD_ZONE, (ifx axis_value < -DEAD_ZONE then axis_value else 0));
//     }

//     if io.ConfigFlags_ & ImGui.ConfigFlags.ImGuiConfigFlags_NavEnableGamepad != 0 { return; }
//     if IsGamepadAvailable(0) { return; }

//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_LEFT_FACE_UP, ImGui.Key.ImGuiKey_GamepadDpadUp);
//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_LEFT_FACE_RIGHT, ImGui.Key.ImGuiKey_GamepadDpadRight);
//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_LEFT_FACE_DOWN, ImGui.Key.ImGuiKey_GamepadDpadDown);
//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_LEFT_FACE_LEFT, ImGui.Key.ImGuiKey_GamepadDpadLeft);

//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_RIGHT_FACE_UP, ImGui.Key.ImGuiKey_GamepadFaceUp);
//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_RIGHT_FACE_RIGHT, ImGui.Key.ImGuiKey_GamepadFaceLeft);
//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_RIGHT_FACE_DOWN, ImGui.Key.ImGuiKey_GamepadFaceDown);
//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_RIGHT_FACE_LEFT, ImGui.Key.ImGuiKey_GamepadFaceRight);

//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_LEFT_TRIGGER_1, ImGui.Key.ImGuiKey_GamepadL1);
//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_LEFT_TRIGGER_2, ImGui.Key.ImGuiKey_GamepadL2);
//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_RIGHT_TRIGGER_1, ImGui.Key.ImGuiKey_GamepadR1);
//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_RIGHT_TRIGGER_2, ImGui.Key.ImGuiKey_GamepadR2);
//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_LEFT_THUMB, ImGui.Key.ImGuiKey_GamepadL3);
//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_RIGHT_THUMB, ImGui.Key.ImGuiKey_GamepadR3);

//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_MIDDLE_LEFT, ImGui.Key.ImGuiKey_GamepadStart);
//     handle_gamepad_button_event(io, .GAMEPAD_BUTTON_MIDDLE_RIGHT, ImGui.Key.ImGuiKey_GamepadBack);

//     // left stick
//     handle_gamepad_stick_event(io, .GAMEPAD_AXIS_LEFT_X, ImGui.Key.ImGuiKey_GamepadLStickLeft, ImGui.Key.ImGuiKey_GamepadLStickRight);
//     handle_gamepad_stick_event(io, .GAMEPAD_AXIS_LEFT_Y, ImGui.Key.ImGuiKey_GamepadLStickUp, ImGui.Key.ImGuiKey_GamepadLStickDown);

//     // right stick
//     handle_gamepad_stick_event(io, .GAMEPAD_AXIS_RIGHT_X, ImGui.Key.ImGuiKey_GamepadRStickLeft, ImGui.Key.ImGuiKey_GamepadRStickRight);
//     handle_gamepad_stick_event(io, .GAMEPAD_AXIS_RIGHT_Y, ImGui.Key.ImGuiKey_GamepadRStickUp, ImGui.Key.ImGuiKey_GamepadRStickDown);
// }

imgui_keymap: Table(Key_Code, ImGui.Key);
setup_keymap :: ()
{
    if imgui_keymap.count > 0 { return; }

    // build up a map of raylib keys to ImGuiKeys
    table_set(*imgui_keymap, #char "'", ImGui.Key.ImGuiKey_Apostrophe);
    table_set(*imgui_keymap, #char ",", ImGui.Key.ImGuiKey_Comma);
    table_set(*imgui_keymap, #char "-", ImGui.Key.ImGuiKey_Minus);
    table_set(*imgui_keymap, #char ".", ImGui.Key.ImGuiKey_Period);
    table_set(*imgui_keymap, #char "/", ImGui.Key.ImGuiKey_Slash);
    table_set(*imgui_keymap, #char "0", ImGui.Key.ImGuiKey_0);
    table_set(*imgui_keymap, #char "1", ImGui.Key.ImGuiKey_1);
    table_set(*imgui_keymap, #char "2", ImGui.Key.ImGuiKey_2);
    table_set(*imgui_keymap, #char "3", ImGui.Key.ImGuiKey_3);
    table_set(*imgui_keymap, #char "4", ImGui.Key.ImGuiKey_4);
    table_set(*imgui_keymap, #char "5", ImGui.Key.ImGuiKey_5);
    table_set(*imgui_keymap, #char "6", ImGui.Key.ImGuiKey_6);
    table_set(*imgui_keymap, #char "7", ImGui.Key.ImGuiKey_7);
    table_set(*imgui_keymap, #char "8", ImGui.Key.ImGuiKey_8);
    table_set(*imgui_keymap, #char "9", ImGui.Key.ImGuiKey_9);
    table_set(*imgui_keymap, #char ";", ImGui.Key.ImGuiKey_Semicolon);
    table_set(*imgui_keymap, #char "=", ImGui.Key.ImGuiKey_Equal);
    table_set(*imgui_keymap, #char "a", ImGui.Key.ImGuiKey_A);
    table_set(*imgui_keymap, #char "b", ImGui.Key.ImGuiKey_B);
    table_set(*imgui_keymap, #char "c", ImGui.Key.ImGuiKey_C);
    table_set(*imgui_keymap, #char "d", ImGui.Key.ImGuiKey_D);
    table_set(*imgui_keymap, #char "e", ImGui.Key.ImGuiKey_E);
    table_set(*imgui_keymap, #char "f", ImGui.Key.ImGuiKey_F);
    table_set(*imgui_keymap, #char "g", ImGui.Key.ImGuiKey_G);
    table_set(*imgui_keymap, #char "h", ImGui.Key.ImGuiKey_H);
    table_set(*imgui_keymap, #char "i", ImGui.Key.ImGuiKey_I);
    table_set(*imgui_keymap, #char "j", ImGui.Key.ImGuiKey_J);
    table_set(*imgui_keymap, #char "k", ImGui.Key.ImGuiKey_K);
    table_set(*imgui_keymap, #char "l", ImGui.Key.ImGuiKey_L);
    table_set(*imgui_keymap, #char "m", ImGui.Key.ImGuiKey_M);
    table_set(*imgui_keymap, #char "n", ImGui.Key.ImGuiKey_N);
    table_set(*imgui_keymap, #char "o", ImGui.Key.ImGuiKey_O);
    table_set(*imgui_keymap, #char "p", ImGui.Key.ImGuiKey_P);
    table_set(*imgui_keymap, #char "q", ImGui.Key.ImGuiKey_Q);
    table_set(*imgui_keymap, #char "r", ImGui.Key.ImGuiKey_R);
    table_set(*imgui_keymap, #char "s", ImGui.Key.ImGuiKey_S);
    table_set(*imgui_keymap, #char "t", ImGui.Key.ImGuiKey_T);
    table_set(*imgui_keymap, #char "u", ImGui.Key.ImGuiKey_U);
    table_set(*imgui_keymap, #char "v", ImGui.Key.ImGuiKey_V);
    table_set(*imgui_keymap, #char "w", ImGui.Key.ImGuiKey_W);
    table_set(*imgui_keymap, #char "x", ImGui.Key.ImGuiKey_X);
    table_set(*imgui_keymap, #char "y", ImGui.Key.ImGuiKey_Y);
    table_set(*imgui_keymap, #char "z", ImGui.Key.ImGuiKey_Z);
    table_set(*imgui_keymap, Key_Code.SPACEBAR, ImGui.Key.ImGuiKey_Space);
    table_set(*imgui_keymap, Key_Code.ESCAPE, ImGui.Key.ImGuiKey_Escape);
    table_set(*imgui_keymap, Key_Code.ENTER, ImGui.Key.ImGuiKey_Enter);
    table_set(*imgui_keymap, Key_Code.TAB, ImGui.Key.ImGuiKey_Tab);
    table_set(*imgui_keymap, Key_Code.BACKSPACE, ImGui.Key.ImGuiKey_Backspace);
    table_set(*imgui_keymap, Key_Code.INSERT, ImGui.Key.ImGuiKey_Insert);
    table_set(*imgui_keymap, Key_Code.DELETE, ImGui.Key.ImGuiKey_Delete);
    table_set(*imgui_keymap, Key_Code.ARROW_RIGHT, ImGui.Key.ImGuiKey_RightArrow);
    table_set(*imgui_keymap, Key_Code.ARROW_LEFT, ImGui.Key.ImGuiKey_LeftArrow);
    table_set(*imgui_keymap, Key_Code.ARROW_DOWN, ImGui.Key.ImGuiKey_DownArrow);
    table_set(*imgui_keymap, Key_Code.ARROW_UP, ImGui.Key.ImGuiKey_UpArrow);
    table_set(*imgui_keymap, Key_Code.PAGE_UP, ImGui.Key.ImGuiKey_PageUp);
    table_set(*imgui_keymap, Key_Code.PAGE_DOWN, ImGui.Key.ImGuiKey_PageDown);
    table_set(*imgui_keymap, Key_Code.HOME, ImGui.Key.ImGuiKey_Home);
    table_set(*imgui_keymap, Key_Code.END, ImGui.Key.ImGuiKey_End);
    // table_set(*imgui_keymap, KeyboardKey.KEY_CAPS_LOCK, ImGui.Key.ImGuiKey_CapsLock);
    table_set(*imgui_keymap, Key_Code.SCROLL_LOCK, ImGui.Key.ImGuiKey_ScrollLock);
    // table_set(*imgui_keymap, KeyboardKey.KEY_NUM_LOCK, ImGui.Key.ImGuiKey_NumLock);
    table_set(*imgui_keymap, Key_Code.PRINT_SCREEN, ImGui.Key.ImGuiKey_PrintScreen);
    table_set(*imgui_keymap, Key_Code.PAUSE, ImGui.Key.ImGuiKey_Pause);
    table_set(*imgui_keymap, Key_Code.F1, ImGui.Key.ImGuiKey_F1);
    table_set(*imgui_keymap, Key_Code.F2, ImGui.Key.ImGuiKey_F2);
    table_set(*imgui_keymap, Key_Code.F3, ImGui.Key.ImGuiKey_F3);
    table_set(*imgui_keymap, Key_Code.F4, ImGui.Key.ImGuiKey_F4);
    table_set(*imgui_keymap, Key_Code.F5, ImGui.Key.ImGuiKey_F5);
    table_set(*imgui_keymap, Key_Code.F6, ImGui.Key.ImGuiKey_F6);
    table_set(*imgui_keymap, Key_Code.F7, ImGui.Key.ImGuiKey_F7);
    table_set(*imgui_keymap, Key_Code.F8, ImGui.Key.ImGuiKey_F8);
    table_set(*imgui_keymap, Key_Code.F9, ImGui.Key.ImGuiKey_F9);
    table_set(*imgui_keymap, Key_Code.F10, ImGui.Key.ImGuiKey_F10);
    table_set(*imgui_keymap, Key_Code.F11, ImGui.Key.ImGuiKey_F11);
    table_set(*imgui_keymap, Key_Code.F12, ImGui.Key.ImGuiKey_F12);
    table_set(*imgui_keymap, Key_Code.SHIFT, ImGui.Key.ImGuiKey_LeftShift);
    table_set(*imgui_keymap, Key_Code.CTRL, ImGui.Key.ImGuiKey_LeftCtrl);
    table_set(*imgui_keymap, Key_Code.ALT, ImGui.Key.ImGuiKey_LeftAlt);
    table_set(*imgui_keymap, Key_Code.CMD, ImGui.Key.ImGuiKey_LeftSuper);
    table_set(*imgui_keymap, Key_Code.SHIFT, ImGui.Key.ImGuiKey_RightShift);
    table_set(*imgui_keymap, Key_Code.CTRL, ImGui.Key.ImGuiKey_RightCtrl);
    table_set(*imgui_keymap, Key_Code.ALT, ImGui.Key.ImGuiKey_RightAlt);
    table_set(*imgui_keymap, Key_Code.CMD, ImGui.Key.ImGuiKey_RightSuper);
    // table_set(*imgui_keymap, KeyboardKey.KEY_KB_MENU, ImGui.Key.ImGuiKey_Menu);
    table_set(*imgui_keymap, #char "[", ImGui.Key.ImGuiKey_LeftBracket);
    table_set(*imgui_keymap, #char "\\", ImGui.Key.ImGuiKey_Backslash);
    table_set(*imgui_keymap, #char "]", ImGui.Key.ImGuiKey_RightBracket);
    table_set(*imgui_keymap, #char "`", ImGui.Key.ImGuiKey_GraveAccent);
    table_set(*imgui_keymap, #char "0", ImGui.Key.ImGuiKey_Keypad0);
    table_set(*imgui_keymap, #char "1", ImGui.Key.ImGuiKey_Keypad1);
    table_set(*imgui_keymap, #char "2", ImGui.Key.ImGuiKey_Keypad2);
    table_set(*imgui_keymap, #char "3", ImGui.Key.ImGuiKey_Keypad3);
    table_set(*imgui_keymap, #char "4", ImGui.Key.ImGuiKey_Keypad4);
    table_set(*imgui_keymap, #char "5", ImGui.Key.ImGuiKey_Keypad5);
    table_set(*imgui_keymap, #char "6", ImGui.Key.ImGuiKey_Keypad6);
    table_set(*imgui_keymap, #char "7", ImGui.Key.ImGuiKey_Keypad7);
    table_set(*imgui_keymap, #char "8", ImGui.Key.ImGuiKey_Keypad8);
    table_set(*imgui_keymap, #char "9", ImGui.Key.ImGuiKey_Keypad9);
    table_set(*imgui_keymap, #char ".", ImGui.Key.ImGuiKey_KeypadDecimal);
    table_set(*imgui_keymap, #char "/", ImGui.Key.ImGuiKey_KeypadDivide);
    table_set(*imgui_keymap, #char "*", ImGui.Key.ImGuiKey_KeypadMultiply);
    table_set(*imgui_keymap, #char "-", ImGui.Key.ImGuiKey_KeypadSubtract);
    table_set(*imgui_keymap, #char "+", ImGui.Key.ImGuiKey_KeypadAdd);
    table_set(*imgui_keymap, Key_Code.ENTER, ImGui.Key.ImGuiKey_KeypadEnter);
    table_set(*imgui_keymap, #char "=", ImGui.Key.ImGuiKey_KeypadEqual);
}

// imgui_raylib_cursors: Table(ImGui.MouseCursor, MouseCursor);
// setup_mouse_cursors :: ()
// {
//     if imgui_raylib_cursors.count > 0 { return; }

//     table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_Arrow, MouseCursor.MOUSE_CURSOR_ARROW);
//     table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_TextInput, MouseCursor.MOUSE_CURSOR_IBEAM);
//     table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_Hand, MouseCursor.MOUSE_CURSOR_POINTING_HAND);
//     table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_ResizeAll, MouseCursor.MOUSE_CURSOR_RESIZE_ALL);
//     table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_ResizeEW, MouseCursor.MOUSE_CURSOR_RESIZE_EW);
//     table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_ResizeNESW, MouseCursor.MOUSE_CURSOR_RESIZE_NESW);
//     table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_ResizeNS, MouseCursor.MOUSE_CURSOR_RESIZE_NS);
//     table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_ResizeNWSE, MouseCursor.MOUSE_CURSOR_RESIZE_NWSE);
//     table_set(*imgui_raylib_cursors, ImGui.MouseCursor.ImGuiMouseCursor_NotAllowed, MouseCursor.MOUSE_CURSOR_NOT_ALLOWED);
// }

#import "Hash_Table";
#import "Math";