SETTINGS_PATH :: "temp/settings.json";

Settings :: struct
{
    sections: Table(StringHash, SettingsSection);
    cached_json_settings: string;
    skip_next_reload: bool;

    #if FILE_WATCH_SUPPORTED
    {
        watcher: File_Watcher;
    }
}

LoadSettingsCallback :: #type (data: *void);
SettingsSection :: struct
{
    data: *void;
    type: *Type_Info;
    before_load_callback: LoadSettingsCallback;
    after_load_callback: LoadSettingsCallback;
};

settings_init :: ()
{
    using yae.settings;

    load_settings();

    #if FILE_WATCH_SUPPORTED
    {
        // File watch
        on_file_modified :: (watcher: *File_Watcher(void), change: *File_Change, user_data: *void)
        {
            if change.events != .MODIFIED return;

            path: = normalize_path(change.full_path);
            if path != normalize_path(SETTINGS_PATH) return;

            if !yae.settings.skip_next_reload
            {
                load_settings();
            }
            yae.settings.skip_next_reload = false;
        }
        if !init(*watcher, on_file_modified, events_to_watch = .MODIFIED)
        {
            log_error("Could not initialize watcher");
        }
        directory: = get_directory(SETTINGS_PATH);
        make_directory_if_it_does_not_exist(directory, true);
        if !add_directories(*watcher, directory)
        {
            log_error("Could not watch directory %", directory);
        }
    }
}

settings_shutdown :: ()
{
    using yae.settings;

    #if FILE_WATCH_SUPPORTED
    {
        deinit(*watcher);
    }

    free(cached_json_settings);
    cached_json_settings = .{};
}

register_settings_section :: (name: string, data: *$T, before_load_callback: LoadSettingsCallback = null, after_load_callback: LoadSettingsCallback = null)
{
    register_settings_section(name, data, type_info(T), before_load_callback, after_load_callback);
}

unregister_settings_section :: (name: string)
{
    using yae.settings;

    name_hash: = string_hash(name);

    result: = table_remove(*sections, name_hash);
    assert(result, "unregistering unknown settings section %", name);
}

settings_update :: ()
{
    using yae.settings;

    #if FILE_WATCH_SUPPORTED
    {
        process_changes(*watcher);
    }

    settings_save_if_changed();
}

// @NOTE(remi): This will become inefficient as the size of settings grow. But is very convenient until then (no need to mark settings dirty on the user side)
settings_save_if_changed :: ()
{
    using yae.settings;

    serializer: JsonSerializer;
    serializer_begin(*serializer, .WRITE);
    serialize_settings(*serializer);
    serializer_end(*serializer);

    current_json_settings: = json_serializer_get_json_string(*serializer);

    if current_json_settings != cached_json_settings
    {
        skip_next_reload = true;
        make_directory_if_it_does_not_exist(get_directory(SETTINGS_PATH), true);
        write_entire_file(SETTINGS_PATH, current_json_settings);
        replace_string(*cached_json_settings, current_json_settings);
    }
}

#scope_file

register_settings_section :: (name: string, data: *void, type: *Type_Info, before_load_callback: LoadSettingsCallback = null, after_load_callback: LoadSettingsCallback = null)
{
    using yae.settings;
    assert(data != null);
    assert(type != null);

    name_hash: = string_hash(name);
    assert(!table_contains(*sections, name_hash), "settings section % registered twice.", name);
    table_add(*sections, name_hash, .{
        data = data,
        type = type,
        before_load_callback = before_load_callback,
        after_load_callback = after_load_callback,
    });
}

load_settings :: ()
{
    using yae.settings;

    content: string;
    {
        push_allocator(temporary_allocator);
        content=, success: = read_entire_file(SETTINGS_PATH);
        if !success
            return;
    }

    serializer: JsonSerializer;
    if !json_serializer_set_json_string(*serializer, content)
    {
        log_error("Cannot read settings: Malformed json file \"%\".", SETTINGS_PATH);
        return;
    }
    replace_string(*cached_json_settings, content);

    for section: sections
    {
        if section.before_load_callback != null
        {
            section.before_load_callback(section.data);
        }
    }

    serializer_begin(*serializer, .READ);
    serialize_settings(*serializer);
    serializer_end(*serializer);

    for section: sections
    {
        if section.after_load_callback != null
        {
            section.after_load_callback(section.data);
        }
    }
}

serialize_settings :: (serializer: *Serializer) -> bool
{
    using yae.settings;

    if !serializer_begin_object(serializer) return false;
    defer serializer_end_object(serializer);

    for section, name_hash: sections
    {
        serialize(serializer, section.data, section.type, name_hash.str);
    }
    return true;
}

#if FILE_WATCH_SUPPORTED
{
    #import "File_Watcher";
}