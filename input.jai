is_pressed :: (key: Key_Code) -> bool
{
    return (input_button_states[sanitize_key_code(key)] & .START) != 0;
}

is_down :: (key: Key_Code) -> bool
{
    return (input_button_states[sanitize_key_code(key)] & .DOWN) != 0;
}

is_released :: (key: Key_Code) -> bool
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

#scope_file

sanitize_key_code :: (key: Key_Code) -> Key_Code
{
    local_key: = key;
    if local_key >= #char "a" && local_key <= #char "z" local_key = xx to_upper(xx local_key);
    return local_key;
}