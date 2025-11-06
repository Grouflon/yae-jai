Shader :: struct
{
    #as using _resource: Resource;
    type = type_info(Shader);
    load_function = shader_load;
    unload_function = shader_unload;

    vs_path: string;
    fs_path: string;

    program: ShaderProgram;
}

// shader_begin_draw :: (using shader: *Shader)
// {
//     if !is_loaded_without_errors || program.id == 0
//         return;

//     rl.BeginShaderMode(program);
// }

// shader_end_draw :: (using shader: *Shader)
// {
//     if !is_loaded_without_errors || program.id == 0
//         return;

//     rl.EndShaderMode();
// }

// // @NOTE(remi): It seems that supporting an array of textures will require raylib modification to support sampler2DArray uniform type
// shader_set_uniform_array :: (using shader: *Shader, uniform_name: string, array: []$T)
// {
//     assert(shader != null);

//     location: = rl.GetShaderLocation(program, temp_c_string(uniform_name));
//     rl.SetShaderValueV(program, location, *array.data, xx type_to_uniform_type(T), xx array.count);
// }

// shader_set_uniform :: (using shader: *Shader, uniform_name: string, value: rl.Texture)
// {
//     assert(shader != null);

//     location: = rl.GetShaderLocation(program, temp_c_string(uniform_name));
//     rl.SetShaderValueTexture(program, location, value);
// }

// shader_set_uniform :: (using shader: *Shader, uniform_name: string, value: $T)
// {
//     assert(shader != null);

//     location: = rl.GetShaderLocation(program, temp_c_string(uniform_name));
//     rl.SetShaderValue(program, location, *value, xx type_to_uniform_type(T));
// }

#scope_file

shader_load :: (resource: *Resource) -> bool
{
    using t: *Shader = xx resource;

    resolved_vs_path: = resolve_vs_path(t);
    if resolved_vs_path.count > 0
    {
        resource_add_file_watch(resource, resolved_vs_path);
    }

    resolved_fs_path: = resolve_fs_path(t);
    if resolved_fs_path.count > 0
    {
        resource_add_file_watch(resource, resolved_fs_path);
    }

    vs_text: string;
    fs_text: string;
    push_allocator(temporary_allocator);
    {
        vs_text = read_entire_file(resolved_vs_path);
        fs_text = read_entire_file(resolved_fs_path);
    }

    program=, success: = load_shader_program(vs_text, fs_text);
    return success;
}

shader_unload :: (resource: *Resource)
{
    using t: *Shader = xx resource;

    unload_shader_program(program);
    program = .{};

    resolved_vs_path: = resolve_vs_path(t);
    if resolved_vs_path.count > 0
    {
        resource_remove_file_watch(resource, resolved_vs_path);
    }

    resolved_fs_path: = resolve_fs_path(t);
    if resolved_fs_path.count > 0
    {
        resource_remove_file_watch(resource, resolved_fs_path);
    }
}

resolve_vs_path :: (using shader: *Shader) -> string
{
    resolved_path: = vs_path;
    if resolved_path.count == 0 resolved_path = yae_resources.generic_shader.vs_path;
    return yae_resolve_path(resolved_path);
}

resolve_fs_path :: (using shader: *Shader) -> string
{
    resolved_path: = fs_path;
    if resolved_path.count == 0 resolved_path = yae_resources.generic_shader.fs_path;
    return yae_resolve_path(resolved_path);
}

// type_to_uniform_type :: ($T: Type) -> rl.ShaderUniformDataType #expand
// {
//     #if T ==
//     {
//         case float; return .RL_SHADER_UNIFORM_FLOAT;
//         case Vector2; return .RL_SHADER_UNIFORM_VEC2;
//         case Vector3; return .RL_SHADER_UNIFORM_VEC2;
//         case Vector4; return .RL_SHADER_UNIFORM_VEC2;
//         case int; return .RL_SHADER_UNIFORM_INT;
//         case s32; return .RL_SHADER_UNIFORM_INT;
//         case; #assert false; // uniform type not supported
//     }

//     // RL_SHADER_UNIFORM_FLOAT     :: 0;
//     // RL_SHADER_UNIFORM_VEC2      :: 1;
//     // RL_SHADER_UNIFORM_VEC3      :: 2;
//     // RL_SHADER_UNIFORM_VEC4      :: 3;
//     // RL_SHADER_UNIFORM_INT       :: 4;
//     // RL_SHADER_UNIFORM_IVEC2     :: 5;
//     // RL_SHADER_UNIFORM_IVEC3     :: 6;
//     // RL_SHADER_UNIFORM_IVEC4     :: 7;
//     // RL_SHADER_UNIFORM_SAMPLER2D :: 8;
// }

