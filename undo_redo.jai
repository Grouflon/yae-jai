UndoRedoManager :: struct
{
    command_list: [..]UndoRedoCommand;
    last_command_index: s32 = -1;
}
undo_redo_manager: UndoRedoManager;

UndoRedoCommand :: struct
{
    name: string;
    undo_function: #type (*void);
    redo_function: #type (*void);
    deinit_data:   #type (*void);
    user_data: *void;
}

add_data_change_command :: (data_ptr:*void, ti: *Type_Info, before_data: string, after_data: string, on_apply_callback: #type(data_ptr: *void) = null)
{
    CommandData :: struct
    {
        ptr: *void;
        ti: *Type_Info;
        before_data: string;
        after_data: string;
        on_apply_callback: #type (*void);
    }
    command_data: = New(CommandData);
    command_data.ptr = data_ptr;
    command_data.ti = ti;
    command_data.before_data = copy_string(before_data);
    command_data.after_data = copy_string(after_data);
    command_data.on_apply_callback = on_apply_callback;

    command: = UndoRedoCommand.{
        name = "",
        undo_function = (user_data: *void)
        {
            command_data: *CommandData = xx user_data;

            serializer: JsonSerializer;
            json_serializer_set_json_string(*serializer, command_data.before_data);
            serializer_begin(*serializer, .READ);
            serialize(*serializer, command_data.ptr, command_data.ti);
            serializer_end(*serializer);


            if command_data.on_apply_callback != null
            {
                command_data.on_apply_callback(command_data.ptr);
            }
        },
        redo_function = (user_data: *void)
        {
            command_data: *CommandData = xx user_data;

            serializer: JsonSerializer;
            json_serializer_set_json_string(*serializer, command_data.after_data);
            serializer_begin(*serializer, .READ);
            serialize(*serializer, command_data.ptr, command_data.ti);
            serializer_end(*serializer);

            if command_data.on_apply_callback != null
            {
                command_data.on_apply_callback(command_data.ptr);
            }
        },
        deinit_data = (user_data: *void)
        {
            command_data: *CommandData = xx user_data;

            free(command_data.before_data);
            free(command_data.after_data);
        },
        user_data = command_data
    };
    add_undo_redo_command(command);
}

undo_redo_manager_init :: ()
{
    using undo_redo_manager;

}

undo_redo_manager_shutdown :: ()
{
    using undo_redo_manager;

    crop_command_list(0);
}

get_next_undo :: () -> bool, UndoRedoCommand
{
    using undo_redo_manager;
    if last_command_index < 0 return false, .{};
    return true, command_list[last_command_index];
}

get_next_redo :: () -> bool, UndoRedoCommand
{
    using undo_redo_manager;

    if last_command_index >= command_list.count-1 return false, .{};
    return true, command_list[last_command_index+1];
}

undo :: ()
{
    using undo_redo_manager;

    is_valid, command: = get_next_undo();
    if !is_valid return;

    if command.undo_function != null
    {
        command.undo_function(command.user_data);
    }
    last_command_index -= 1;
}

redo :: ()
{
    using undo_redo_manager;

    is_valid, command: = get_next_redo();
    if !is_valid return;

    if command.redo_function != null
    {
        command.redo_function(command.user_data);
    }
    last_command_index += 1;
}

add_undo_redo_command :: (command: UndoRedoCommand)
{
    using undo_redo_manager;

    crop_command_list(last_command_index + 1);
    array_add(*command_list, command);
    last_command_index += 1;
}

#scope_file

crop_command_list :: (new_size: s32)
{
    using undo_redo_manager;

    for i: new_size..command_list.count-1
    {
        deinit(command_list[i]);
    }
    command_list.count = new_size;
    last_command_index = min(last_command_index, new_size-1);
}

deinit :: (command: UndoRedoCommand)
{
    free(command.name);

    if command.deinit_data != null
    {
        command.deinit_data(command.user_data);
    }
    free(command.user_data);
}