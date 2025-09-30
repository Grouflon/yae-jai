Shader :: struct
{
    #as using _resource: Resource;
    type = type_info(Shader);
    load_function = shader_load;
    unload_function = shader_unload;

    vs_path: string;
    fs_path: string;

    program: rl.Shader;
}

shader_begin_draw :: (using shader: *Shader)
{
    if !is_loaded_without_errors || program.id == 0
        return;

    rl.BeginShaderMode(program);
}

shader_end_draw :: (using shader: *Shader)
{
    if !is_loaded_without_errors || program.id == 0
        return;

    rl.EndShaderMode();
}

shader_set_uniform :: (using shader: *Shader, uniform_name: string, value: $T)
{
    assert(shader != null);

    location: = rl.GetShaderLocation(program, temp_c_string(uniform_name));
    rl.SetShaderValue(program, location, *value, xx type_to_uniform_type(T));
}

#scope_file

shader_load :: (resource: *Resource) -> bool
{
    using t: *Shader = xx resource;

    c_vs_path: *u8;
    if vs_path.count > 0
    {
        resource_add_file_watch(resource, vs_path);
        c_vs_path = temp_c_string(vs_path);
    }

    c_fs_path: *u8;
    if fs_path.count > 0
    {
        resource_add_file_watch(resource, fs_path);
        c_fs_path = temp_c_string(fs_path);
    }

    program = rl.LoadShader(c_vs_path, c_fs_path);

    return program.id != 0;
}

shader_unload :: (resource: *Resource)
{
    using t: *Shader = xx resource;

    rl.UnloadShader(program);
    program = .{};

    if vs_path.count > 0
    {
        resource_remove_file_watch(resource, vs_path);
    }

    if fs_path.count > 0
    {
        resource_remove_file_watch(resource, fs_path);
    }
}

type_to_uniform_type :: ($T: Type) -> rl.ShaderUniformDataType
{
    info : *Type_Info : type_info(T);
    #if T ==
    {
        case float; return .RL_SHADER_UNIFORM_FLOAT;
        case Vector2; return .RL_SHADER_UNIFORM_VEC2;
        case Vector3; return .RL_SHADER_UNIFORM_VEC2;
        case Vector4; return .RL_SHADER_UNIFORM_VEC2;
        case s32; return .RL_SHADER_UNIFORM_INT;
        case; #assert false;
    }

    // RL_SHADER_UNIFORM_FLOAT     :: 0;
    // RL_SHADER_UNIFORM_VEC2      :: 1;
    // RL_SHADER_UNIFORM_VEC3      :: 2;
    // RL_SHADER_UNIFORM_VEC4      :: 3;
    // RL_SHADER_UNIFORM_INT       :: 4;
    // RL_SHADER_UNIFORM_IVEC2     :: 5;
    // RL_SHADER_UNIFORM_IVEC3     :: 6;
    // RL_SHADER_UNIFORM_IVEC4     :: 7;
    // RL_SHADER_UNIFORM_SAMPLER2D :: 8;
}

rl :: #import "raylib";