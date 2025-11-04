// Jai foreign functions
const jai_exports =
{
    wasm_write_string: (s_count, s_data, to_standard_error) =>
    {
        const s = read_string(s_data, s_count);
        write_to_console_log(s, to_standard_error);
    },

    wasm_debug_break: () =>
    {
        debugger;
    },

    memcmp: (a, b, size) =>
    {
        return memcmp(a, b, size);
    }
}

const gl_exports =
{
    create_opengl_context: () =>
    {
        gl = canvas.getContext("webgl2");

        // Resources containers since webgl does not use indices
        gl.vaos = new Array();
        gl.vaos.push(null);
        gl.get_vao = (array_index) =>
        {
            array_index = Number(array_index);
            let vao = gl.vaos[array_index];
            console.assert(vao, "undefined vertex array %d", array_index);
            return vao;
        }

        gl.vbos = new Array();
        gl.vbos.push(null);
        gl.get_vbo = (buffer_index) =>
        {
            buffer_index = Number(buffer_index);
            let vbo = gl.vbos[buffer_index];
            console.assert(vbo, "undefined buffer %d", buffer_index);
            return vbo;
        }

        gl.shaders = new Array();
        gl.shaders.push(null);
        gl.get_shader = (shader_index) =>
        {
            shader_index = Number(shader_index);
            let shader = gl.shaders[shader_index];
            console.assert(shader, "undefined shader %d", shader_index);
            return shader;
        }

        gl.programs = new Array();
        gl.programs.push(null);
        gl.get_program = (program_index) =>
        {
            program_index = Number(program_index);
            let program = gl.programs[program_index];
            console.assert(program, "undefined program %d", program_index);
            return program;
        }
        gl.current_program = null;

        gl.textures = new Array();
        gl.textures.push(null);
        gl.get_texture = (texture_index) =>
        {
            texture_index = Number(texture_index);
            let texture = gl.textures[texture_index];
            console.assert(texture, "undefined texture %d", texture_index);
            return texture;
        }

        gl.locations = new Array();
        gl.locations_map = new Object();
        gl.get_location = (location_index) =>
        {
            location_index = Number(location_index);
            let location = gl.locations[location_index];
            console.assert(location, "undefined location %d", location_index);
            return location;
        }
    },

    _glGetString: (pname) =>
    {
        // TODO: might be better to just use the temp allocator to do that
        return return_cstring(gl.getParameter(pname));
    },

    _glGetIntegeri_v: (target, size, data) =>
    {
        data = Number(data);
        const param = gl.getParameter(target);
        console.assert(typeof param == "object");
        for (i = 0; i < size; ++i)
        {
            write_u32(data+i*4, param[i]);
        }
    },

    _glGenVertexArrays: (n, arrays) =>
    {
        for (i = 0; i < n; ++i)
        {
            gl.vaos.push(gl.createVertexArray());
            write_u32(Number(arrays) + i, gl.vaos.length - 1);
        }
    },

    _glBindVertexArray: (array_index)  =>
    {
        gl.bindVertexArray(gl.get_vao(array_index));
    },

    _glVertexAttribPointer : (index, size, type, normalized, stride, pointer) =>
    {
        gl.vertexAttribPointer(index, size, type, normalized, Number(stride), Number(pointer));
    },

    _glEnableVertexAttribArray : (index) =>
    {
        gl.enableVertexAttribArray(index);
    },

    _glGenBuffers: (n, buffers) =>
    {
        for (i = 0; i < n; ++i)
        {
            gl.vbos.push(gl.createBuffer());
            write_u32(Number(buffers) + i, gl.vbos.length - 1);
        }
    },

    _glBindBuffer(target, buffer_index)
    {
        gl.bindBuffer(target, gl.get_vbo(buffer_index));
    },

    _glBufferData : (target, size, data, usage) =>
    {
        const buffer = exports.memory.buffer;
        const bytes = new Uint8Array(buffer, Number(data), Number(size));
        gl.bufferData(target, bytes, usage);
    },

    _glClearColor: (r, g, b, a) =>
    {
        gl.clearColor(r, g, b, a);
    },

    _glClear: (mask) =>
    {
        gl.clear(mask);
    },

    _glViewport: (x, y, width, height) =>
    {
        gl.viewport(x, y, width, height);
    },

    _glScissor: (x, y, width, height) =>
    {
        gl.scissor(x, y, width, height);
    },

    _glCreateShader: (type) =>
    {
        gl.shaders.push(gl.createShader(type));
        return gl.shaders.length - 1;
    },

    _glShaderSource: (shader_index, count, str_array, length_array) =>
    {
        let final_source = "";
        for (i = 0; i < count; ++i)
        {
            const str = read_u64(Number(str_array) + i);
            const len = read_u32(Number(length_array) + i);
            const source = read_string(str, len);
            final_source += source;
        }

        gl.shaderSource(gl.get_shader(shader_index), final_source);
    },

    _glCompileShader: (shader_index) =>
    {
        gl.compileShader(gl.get_shader(shader_index));
    },

    _glGetShaderiv: (shader_index, pname, params) =>
    {
        let param = gl.getShaderParameter(gl.get_shader(shader_index), pname);
        if (typeof param == "boolean")
        {
            param = param ? 1 : 0;
        }
        write_u32(params, param);
    },

    _glGetShaderInfoLog: (shader_index, buf_size, length, info_log_ptr) =>
    {
        let info_log = gl.getShaderInfoLog(gl.get_shader(shader_index));

        info_log = info_log.substring(0, Math.min(info_log.length, buf_size - 1));
        write_cstring(info_log_ptr, info_log);
        write_u32(length, info_log.length);
    },

    _glDeleteShader: (shader_index) =>
    {
        gl.deleteShader(gl.get_shader(shader_index));
    },

    _glCreateProgram: () =>
    {
        gl.programs.push(gl.createProgram());
        return gl.programs.length - 1;
    },

    _glAttachShader: (program_index, shader_index) =>
    {
        gl.attachShader(gl.get_program(program_index), gl.get_shader(shader_index));
    },

    _glLinkProgram: (program_index) =>
    {
        gl.linkProgram(gl.get_program(program_index));
    },

    _glGetProgramiv: (program_index, pname, params) =>
    {
        let param = gl.getProgramParameter(gl.get_program(program_index), pname);
        if (typeof param == "boolean")
        {
            param = param ? 1 : 0;
        }
        write_u32(params, param);
    },

    _glGetProgramInfoLog: (program_index, buf_size, length, info_log_ptr) =>
    {
        let info_log = gl.getProgramInfoLog(gl.get_program(program_index));

        info_log = info_log.substring(0, Math.min(info_log.length, buf_size - 1));
        write_cstring(info_log_ptr, info_log);
        write_u32(length, info_log.length);
    },

    _glUseProgram: (program_index) =>
    {
        const program = gl.get_program(program_index)
        gl.useProgram(program);
    },

    _glDrawArrays: (mode, first, count) =>
    {
        gl.drawArrays(mode, first, count);
    },

    _glDrawElements: (mode, count, type, offset) =>
    {
        gl.drawElements(mode, count, type, Number(offset));
    },

    _glActiveTexture: (texture) =>
    {
        gl.activeTexture(texture);
    },

    _glGenTextures: (n, textures) =>
    {
        for (i = 0; i < n; ++i)
        {
            gl.textures.push(gl.createTexture());
            write_u32(Number(textures) + i, gl.textures.length - 1);
        }
    },

    _glBindTexture: (target, texture_index) =>
    {
        gl.bindTexture(target, gl.get_texture(texture_index));
    },

    _glTexParameteri: (target, pname, param) =>
    {
        gl.texParameteri(target, pname, param);
    },

    _glTexImage2D: (target, level, internalformat, width, height, border, format, type, pixels) =>
    {
        console.assert(internalformat == gl.RGBA8, "only RGBA8 internal format supported so far");
        console.assert(format == gl.RGBA, "only RGBA format supported so far");

        const buffer = exports.memory.buffer;
        pixel_data = new Uint8Array(buffer, Number(pixels), width * height * 4);
        gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixel_data);
    },

    _glGetUniformLocation: (program_index, name) =>
    {
        name = read_cstring(name);
        const key = program_index + "_" + name;
        let location_index = gl.locations_map[key];
        if (location_index == null)
        {
            const program = gl.get_program(program_index);
            const location = gl.getUniformLocation(program, name);

            if (location == null) return -1;

            gl.locations.push(location);
            location_index = gl.locations.length - 1;
            gl.locations_map[key] = location_index;
        }

        return location_index;
    },

    _glUniform1i: (location_index, v0) =>
    {
        gl.uniform1i(gl.get_location(location_index), v0);
    },

    _glUniformMatrix4fv: (location_index, count, transpose, value) =>
    {
        console.assert(count == 1, "only 1 matrix at a time supported so far");
        matrix = new Float32Array(exports.memory.buffer, Number(value), 16);
        gl.uniformMatrix4fv(gl.get_location(location_index), transpose, matrix);
    },

    _glEnable: (cap) =>
    {
        gl.enable(cap);
    },

    _glDisable: (cap) =>
    {
        gl.disable(cap);
    },

    _glBlendEquation: (mode) =>
    {
        gl.blendEquation(mode);
    },

    _glBlendFuncSeparate: (srcRGB, dstRGB, srcAlpha, dstAlpha) =>
    {
        gl.blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
    },
}

let image_data = null;
let file_exists = false;
let read_file_buffer = null;
// Backend foreign functions
const backend_exports =
{
    create_window: (width, height, window_name, background_color) =>
    {
        canvas = document.createElement("canvas");
        canvas.id = "window";
        canvas.style.cssText += "aspect-ratio:" + width + "/" + height + ";";
        canvas.style.cssText += "max-width:" + width + "px;";
        canvas.style.cssText += "max-height:" + height + "px;";

        background_color = read_color(background_color);
        canvas.style.cssText += "background-color: rgb("+background_color.r+","+background_color.g+","+background_color.b+");";

        document.title = read_jstring(window_name);

        content.append(canvas);

        canvas.width = Number(width);
        canvas.height = Number(height);
        return 1n;
    },

    read_and_decode_image: (filename, allocator, out_data) =>
    {
        filename = read_jstring(filename);

        if (asyncify_get_state() == 0)
        {
            const img = new Image();
            img.src = filename;
            img.decode().then(() =>
            {
                const canvas = document.createElement('canvas');
                const ctx = canvas.getContext('2d');
                canvas.width = img.width;
                canvas.height = img.height;
                ctx.drawImage(img, 0, 0);
                image_data = ctx.getImageData(0, 0, img.width, img.height);
                
                asyncify_start_rewind(asyncify_data_ptr);
                main();
            });

            asyncify_start_unwind(asyncify_data_ptr);
        }
        else
        {
            console.assert(asyncify_get_state() == 2);
            asyncify_stop_rewind();

            if (image_data != null)
            {
                const data_ptr = alloc(BigInt(image_data.data.byteLength), allocator);

                const buffer = exports.memory.buffer;
                const data = new Uint8Array(buffer, Number(data_ptr), image_data.data.byteLength);
                data.set(image_data.data);

                // return struct:
                // TextureData :: struct
                // {
                //     data: *u8;
                //     width: u32;
                //     height: u32;
                //     channels: u32;
                // }
                write_u64(out_data, data_ptr);
                write_u32(out_data + 8n, image_data.width);
                write_u32(out_data + 12n, image_data.height);
                write_u32(out_data + 16n, 4);

                image_data = null;
            }
            else
            {
                write_u64(out_data, 0n);
            }
        }
    },

    sleep: (time_ms) =>
    {
        if (asyncify_get_state() == 0)
        {
            setTimeout(() =>
            {
                asyncify_start_rewind(asyncify_data_ptr);
                main();
            },
            time_ms);

            asyncify_start_unwind(asyncify_data_ptr);
        }
        else
        {
            console.assert(asyncify_get_state() == 2);
            asyncify_stop_rewind();
        }
    },

    _get_path_of_running_executable: () =>
    {
        return return_cstring(executable_path);
    },

    get_absolute_path: (str) =>
    {
        // Do nothing
        return false;
    },

    set_working_directory: (str) =>
    {
        // Do nothing
    },

    get_time: () =>
    {
        return performance.now() / 1000.0;
        // return return_float32(0);
    },

    get_canvas_width: () =>
    {
        return canvas.width;
    },

    get_canvas_height: () =>
    {
        return canvas.height;
    },

    file_exists: (path) =>
    {
        if (asyncify_get_state() == 0)
        {
            path = read_jstring(path)
            fetch(path).then((response) => {
                file_exists = response.ok;

                asyncify_start_rewind(asyncify_data_ptr);
                main();
            });

            asyncify_start_unwind(asyncify_data_ptr);
        }
        else
        {
            console.assert(asyncify_get_state() == 2);
            asyncify_stop_rewind();

            return file_exists;
        }
    },

    read_entire_file: (path, out_data, out_size) =>
    {
        if (asyncify_get_state() == 0)
        {
            path = read_jstring(path)
            read_file_buffer = null;
            fetch(path).then((response) =>
            {
                if (!response.ok)
                {
                    asyncify_start_rewind(asyncify_data_ptr);
                    main();
                }
                else
                {
                    response.arrayBuffer().then((buffer) =>
                    {
                        read_file_buffer = buffer;
                        asyncify_start_rewind(asyncify_data_ptr);
                        main();
                    });
                }
            });

            asyncify_start_unwind(asyncify_data_ptr);
        }
        else
        {
            console.assert(asyncify_get_state() == 2);
            asyncify_stop_rewind();

            if (read_file_buffer == null) return false;

            let src = new Uint8Array(read_file_buffer);
            let dest_ptr = temp_alloc(BigInt(src.length));
            let dest = new Uint8Array(exports.memory.buffer, Number(dest_ptr), src.length);
            dest.set(src);

            write_u64(out_data, dest_ptr);
            write_u64(out_size, BigInt(src.length));

            return true;
        }
    },
}

// Library

// data
let executable_path;
let exports;
let canvas;
let gl;
let return_buffer_ptr;
let asyncify_data_ptr;

// functions
let alloc;
let temp_alloc;
let memcmp;
let asyncify_start_rewind;
let asyncify_stop_rewind;
let asyncify_start_unwind;
let asyncify_stop_unwind;
let asyncify_get_state;
let main;

// consts
const RETURN_BUFFER_SIZE = 1024n;
const ASYNCIFY_DATA_SIZE = 1024n * 4n;

// Load the WASM file we compiled and run its main.
function instantiate_yae(wasm_path, content_element)
{
    WebAssembly.instantiateStreaming(
        fetch(wasm_path),
        { "env": make_environment(jai_exports, gl_exports, backend_exports) }
    ).then(
        (obj) => {
            exports = obj.instance.exports;
            console.log(exports, exports.memory);
            executable_path = wasm_path;

            alloc = find_name_by_regexp(exports, "wasm_alloc");
            temp_alloc = find_name_by_regexp(exports, "wasm_temp_alloc");
            memcmp = find_name_by_regexp(exports, "wasm_memcmp");
            asyncify_start_rewind = exports.asyncify_start_rewind;
            asyncify_stop_rewind = exports.asyncify_stop_rewind;
            asyncify_start_unwind = exports.asyncify_start_unwind;
            asyncify_stop_unwind = exports.asyncify_stop_unwind;
            asyncify_get_state = exports.asyncify_get_state;
            main = () => {
                exports.main(0, 0n);

                // We always need to catch asyncify calls when we exit main
                if (asyncify_get_state() == 1)
                {
                    asyncify_stop_unwind();
                }
                else
                {
                    console.assert(asyncify_get_state() == 0);
                    window.requestAnimationFrame(first_frame);
                }
            };

            return_buffer_ptr = alloc(RETURN_BUFFER_SIZE, 0n);

            asyncify_data_ptr = alloc(ASYNCIFY_DATA_SIZE, 0n);
            write_u64(asyncify_data_ptr, asyncify_data_ptr+16n);
            write_u64(asyncify_data_ptr+8n, asyncify_data_ptr+ASYNCIFY_DATA_SIZE-1n);

            let _on_update = find_name_by_regexp(exports, "wasm_on_update");
            let _on_keydown = find_name_by_regexp(exports, "wasm_on_keydown");
            let _on_keyup = find_name_by_regexp(exports, "wasm_on_keyup");

            let _previous_timestamp = null;

            function first_frame(timestamp)
            {
                _previous_timestamp = timestamp;
                window.requestAnimationFrame(update_frame);
            }

            function update_frame(timestamp)
            {
                var dt = (timestamp - _previous_timestamp) * 0.001;
                _previous_timestamp = timestamp;

                _on_update(dt);
                // @NOTE(remi): We also need to do the asyncify catch all here

                window.requestAnimationFrame(update_frame);
            }

            document.addEventListener('keydown', (e) =>
            {
                _on_keydown(e.keyCode);
            });

            document.addEventListener('keyup', (e) =>
            {
                _on_keyup(e.keyCode);
            });

            main();
        }
    );
}

function find_name_by_regexp(exports, prefix)
{
    const re = new RegExp('^'+prefix+'_[0-9a-z]+$');
    for (let name in exports) {
        if (re.test(name)) {
            return exports[name];
        }
    }
    return null;
}

function make_environment(...envs)
{
    return new Proxy(envs, {
        get(target, prop, receiver) {
            for (let env of envs) {
                if (env.hasOwnProperty(prop)) {
                    return env[prop];
                }
            }
            return (...args) => {console.error("NOT IMPLEMENTED: "+prop, args)}
        }
    });
}

function read_float32(ptr)
{
    ptr = Number(ptr);
    const buffer = exports.memory.buffer;
    return new Float32Array(buffer)[ptr/4];
}

function read_u8(ptr)
{
    ptr = Number(ptr);
    const buffer = exports.memory.buffer;
    return new Uint8Array(buffer)[ptr];
}

function read_u32(ptr)
{
    ptr = Number(ptr);
    const buffer = exports.memory.buffer;
    return new Uint32Array(buffer, ptr, 4)[0];
}

function read_u64(ptr)
{
    ptr = Number(ptr);
    const buffer = exports.memory.buffer;
    return Number(new BigUint64Array(buffer, ptr, 8)[0]);
}

function read_s64(ptr)
{
    ptr = Number(ptr);
    const buffer = exports.memory.buffer;
    return Number(new BigInt64Array(buffer, ptr, 8)[0]);
}

function read_color(ptr)
{
    ptr = Number(ptr);
    const buffer = exports.memory.buffer;
    const bytes = new Uint8Array(buffer);
    return {
        r: bytes[ptr],
        g: bytes[ptr+1],
        b: bytes[ptr+2],
        a: bytes[ptr+3],
    }
}


const text_decoder = new TextDecoder();
function read_string(ptr, length)
{
    ptr = Number(ptr);
    length = Number(length);
    const buffer = exports.memory.buffer;
    const bytes = new Uint8Array(buffer, ptr, length);
    return text_decoder.decode(bytes);
}

function read_jstring(ptr)
{
    ptr = Number(ptr);
    const buffer = exports.memory.buffer;
    const count = read_s64(ptr);
    const str_ptr = read_u64(ptr+8);
    return read_string(str_ptr, count);
}

function read_cstring(ptr)
{
    ptr = Number(ptr);
    return read_string(ptr, strlen(ptr));
}

const text_encoder = new TextEncoder();
function write_cstring(ptr, str)
{
    console.assert(typeof str == "string", "str is not a string", str);
    const str_bytes = text_encoder.encode(str);
    const buffer = exports.memory.buffer;
    var bytes = new Uint8Array(buffer);
    bytes.set(str_bytes, Number(ptr));
    bytes.set([0], Number(ptr) + str_bytes.byteLength);
}

function write_float32(ptr, n)
{
    console.log(ptr, n);
    console.assert(typeof n == "number", "n is not a number", n);
    ptr = Number(ptr);
    const buffer = exports.memory.buffer;
    var bytes = new Float32Array(buffer);
    bytes[ptr/4] = n;
}

function write_u32(ptr, n)
{
    console.assert(typeof n == "number", "n is not a number", n);
    console.assert(n >= 0, "%f is not an unsigned number", n);
    ptr = Number(ptr);
    const buffer = exports.memory.buffer;
    const bytes = new Uint8Array(buffer);
    const n_bytes = number_to_ubytes(n).slice(0,4);
    bytes.set(n_bytes, ptr);
}

function write_u64(ptr, n)
{
    console.assert(typeof n == "bigint", "n is not a BigInt", n);
    console.assert(n >= 0, "%f is not an unsigned number", n);
    const buffer = exports.memory.buffer;
    const bytes = new Uint8Array(buffer);
    const n_bytes = number_to_ubytes(Number(n)).slice(0,8);
    bytes.set(n_bytes, Number(ptr));
}

function strlen(ptr, max_size = 256)
{
    ptr = Number(ptr);
    const buffer = exports.memory.buffer;
    const bytes = new Uint8Array(buffer);
    end = ptr;
    while (bytes[end] != 0 && end < ptr + max_size) { ++end; }
    return end - ptr;
}

function number_to_ubytes(x)
{
    // stolen here: https://stackoverflow.com/questions/8482309/converting-javascript-integer-to-byte-array-and-back
    // but reversed endianness
    // Don't know if it is actually robust or not + we surely need a different algorithm for signed and unsigned
    let y= Math.floor(x/2**32);
    return [(x<<24),(x<<16),(x<<8),x,(y<<24),(y<<16),(y<<8),y].map(z=> z>>>24)
}

function return_cstring(str)
{
    console.assert(str.length < RETURN_BUFFER_SIZE, "string \"%s\" is too long for the return buffer of %d bytes", str, RETURN_BUFFER_SIZE);
    write_cstring(return_buffer_ptr, str);
    return return_buffer_ptr;
}

// console.log and console.error always add newlines so we need to buffer the output from write_string
// to simulate a more basic I/O behavior. We’ll flush it after a certain time so that you still
// see the last line if you forget to terminate it with a newline for some reason.
let console_buffer = "";
let console_buffer_is_standard_error;
let console_timeout;
const FLUSH_CONSOLE_AFTER_MS = 3;
function write_to_console_log(str, to_standard_error)
{
    if (console_buffer && console_buffer_is_standard_error != to_standard_error) {
        flush_buffer();
    }

    console_buffer_is_standard_error = to_standard_error;
    const lines = str.split("\n");
    for (let i = 0; i < lines.length - 1; i++) {
        console_buffer += lines[i];
        flush_buffer();
    }

    console_buffer += lines[lines.length - 1];

    clearTimeout(console_timeout);
    if (console_buffer) {
        console_timeout = setTimeout(() => {
            flush_buffer();
        }, FLUSH_CONSOLE_AFTER_MS);
    }

    function flush_buffer() {
        if (!console_buffer) return;

        if (console_buffer_is_standard_error) {
            console.error(console_buffer);
        } else {
            console.log(console_buffer);
        }

        console_buffer = "";
    }
}