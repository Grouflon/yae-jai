is_key_pressed :: (key: Key_Code) -> bool
{
    return (input_button_states[key] & .START) != 0;
}

is_key_down :: (key: Key_Code) -> bool
{
    return (input_button_states[key] & .DOWN) != 0;
}

is_key_released :: (key: Key_Code) -> bool
{
    return (input_button_states[key] & .END) != 0;
}
