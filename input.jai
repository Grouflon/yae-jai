is_pressed :: (key: Key_Code) -> bool
{
    if !is_valid_game_input(key) return false;
    return is_pressed_raw(key);
}

is_down :: (key: Key_Code) -> bool
{
    if !is_valid_game_input(key) return false;
    return is_down_raw(key);
}

is_released :: (key: Key_Code) -> bool
{
    if !is_valid_game_input(key) return false;
    return is_released_raw(key);
}

is_pressed_raw :: (key: Key_Code) -> bool
{
    return (input_button_states[sanitize_key_code(key)] & .START) != 0;
}

is_down_raw :: (key: Key_Code) -> bool
{
    return (input_button_states[sanitize_key_code(key)] & .DOWN) != 0;
}

is_released_raw :: (key: Key_Code) -> bool
{
    return (input_button_states[sanitize_key_code(key)] & .END) != 0;
}

get_characters_pressed :: () -> string
{
    push_allocator(temporary_allocator);
    builder: String_Builder;
    init_string_builder(*builder);

    for e: events_this_frame
    {
        if e.type != .TEXT_INPUT continue;

        // Need to support more than utf8 at some point
        append(*builder, cast(u8) e.utf32);
    }
    return builder_to_string(*builder);
}

is_mouse_key :: (key: Key_Code) -> bool
{
    if key ==
    {
        case .MOUSE_BUTTON_LEFT; return true;
        case .MOUSE_BUTTON_MIDDLE; return true;
        case .MOUSE_BUTTON_RIGHT; return true;
        case; return false;
    }
}

is_keyboard_key :: (key: Key_Code) -> bool
{
    if key >= .GAMEPAD_0_BEGIN && key <= .GAMEPAD_3_BEGIN return false;
    if key ==
    {
        case .MOUSE_BUTTON_LEFT; return false;
        case .MOUSE_BUTTON_MIDDLE; return false;
        case .MOUSE_BUTTON_RIGHT; return false;
        case .TOUCH; return false;
        case; return true;
    }
}

is_gamepad_pressed :: (button: Gamepad_Code) -> bool
{
    return is_gamepad_pressed(gamepad, button);
}

is_gamepad_pressed :: (gamepad: *Gamepad, button: Gamepad_Code) -> bool
{
    if gamepad == null return false;
    return (gamepad.buttons[button] & .START) != 0;
}

is_gamepad_down :: (button: Gamepad_Code) -> bool
{
    return is_gamepad_down(gamepad, button);
}

is_gamepad_down :: (gamepad: *Gamepad, button: Gamepad_Code) -> bool
{
    if gamepad == null return false;
    return (gamepad.buttons[button] & .DOWN) != 0;
}

is_gamepad_released :: (button: Gamepad_Code) -> bool
{
    return is_gamepad_released(gamepad, button);
}

is_gamepad_released :: (gamepad: *Gamepad, button: Gamepad_Code) -> bool
{
    if gamepad == null return false;
    return (gamepad.buttons[button] & .END) != 0;
}

#scope_file

sanitize_key_code :: (key: Key_Code) -> Key_Code
{
    local_key: = key;
    if local_key >= #char "a" && local_key <= #char "z" local_key = xx to_upper(xx local_key);
    return local_key;
}

is_valid_game_input :: (key: Key_Code) -> bool
{
    #if IMGUI_SUPPORTED
    {
        io: = ImGui.GetIO();
        if io.WantCaptureMouse && is_mouse_key(key) return false;
        if io.WantCaptureKeyboard && is_keyboard_key(key) return false;
    }
    return true;
}