AsepriteData :: struct
{
    // Aseprite data
    app: string;
    version: string;

    // Image data
    image_path: string;
    format: AsepriteImageFormat;
    size: AsepriteBox;
    scale: float;

    // Frames
    frames: []AsepriteFrame;
    name_to_frame: Table(string, s32);

    // Tags
    frame_tags: []AsepriteFrameTag;
    name_to_tag: Table(string, s32);

    // Layers
    layers: []AsepriteLayer;
    name_to_layer: Table(string, s32);
}

AsepriteBox :: struct
{
    x: s32;
    y: s32;
    w: s32;
    h: s32;
}

AsepriteFrame :: struct
{
    name: string;
    frame: AsepriteBox;
    rotated: bool;
    trimmed: bool;
    sprite_source_size: AsepriteBox;
    source_size: AsepriteBox;
    duration_in_ms: s32;
}

AsepriteFrameTag :: struct
{
    name: string;
    start_frame: s32;
    end_frame: s32;
    repeat_count: s32; // 0 means loop
    direction: AsepriteDirection;
    color: string;
    duration_in_ms: s32;
}

AsepriteLayer :: struct
{
    name: string;
    opacity: float32;
    blend_mode: AsepriteBlendMode;
}

AsepriteImageFormat :: enum
{
    RGBA8888;
    I8; 
}

AsepriteBlendMode :: enum
{
    normal;
}

AsepriteDirection :: enum
{
    forward;
    backward;
}

aseprite_load_data :: (_json_file_path: string) -> *AsepriteData
{
    success, json_data: = json_parse_file(_json_file_path);
    defer json_free(json_data);

    if !success
    {
        log_error("Failed to load aseprite data \"%\"", _json_file_path);
        return null;
    }

    aseprite: = New(AsepriteData);

    // Frames
    {
        json_frames: = json_get(json_data, "frames");
        

        if json_frames.type == .ARRAY
        {
            array_resize(*aseprite.frames, json_frames.array.count);
            for json_frame, i : json_frames.array
            {
                aseprite.frames[i] = parse_frame(json_frame);
            }
        }
        else if json_frames.type == .OBJECT
        {
            array_resize(*aseprite.frames, json_frames.object.count);
            i: = 0;
            for json_frame, name : json_frames.object
            {
                aseprite.frames[i] = parse_frame(json_frame);
                aseprite.frames[i].name = copy_string(name);
                i += 1;
            }
        }
    }
    
    // Meta
    {
        meta: = json_get(json_data, "meta", .OBJECT);
        aseprite.app = copy_string(json_get(meta, "app", .STRING).str);
        aseprite.version = copy_string(json_get(meta, "version", .STRING).str);
        aseprite.image_path = sprint("%/%", path_strip_filename(_json_file_path), json_get(meta, "image", .STRING).str);
        aseprite.format = enum_name_to_value(AsepriteImageFormat, json_get(meta, "format", .STRING).str);
        aseprite.size = parse_box(json_get(meta, "size"));
        aseprite.scale = cast(float)atof(temp_c_string(json_get(meta, "scale", .STRING).str));

        // Tags
        {
            json_tags, found: = table_find(meta.object, "frameTags");
            if found
            {
                array_resize(*aseprite.frame_tags, json_tags.array.count);
                for json_tag, i : json_tags.array
                {
                    aseprite.frame_tags[i] = parse_tag(json_tag);

                    // Compute duration
                    aseprite.frame_tags[i].duration_in_ms = 0;
                    for j : 0..(aseprite.frame_tags[i].end_frame - aseprite.frame_tags[i].start_frame)
                    {
                        aseprite.frame_tags[i].duration_in_ms += aseprite.frames[aseprite.frame_tags[i].start_frame + j].duration_in_ms;
                    }
                }
            }
        }

        // Layers
        {
            json_layers, found: = table_find(meta.object, "layers");
            if found
            {
                array_resize(*aseprite.layers, json_layers.array.count);
                for json_layer, i : json_layers.array
                {
                    aseprite.layers[i] = parse_layer(json_layer);
                }
            }
        }
    }

    // Build tables
    for frame, i : aseprite.frames
    {
        table_set(*aseprite.name_to_frame, frame.name, cast(s32)i);
    }

    for tag, i : aseprite.frame_tags
    {
        table_set(*aseprite.name_to_tag, tag.name, cast(s32)i);
    }

    for layer, i : aseprite.layers
    {
        table_set(*aseprite.name_to_layer, layer.name, cast(s32)i);
    }

    return aseprite;
}

aseprite_release_data :: (_data: *AsepriteData)
{
    for frame : _data.frames
    {
        free(frame.name);
    }
    array_free(_data.frames);
    deinit(*_data.name_to_frame);

    free(_data.app);
    free(_data.version);
    free(_data.image_path);

    for frameTag : _data.frame_tags
    {
        free(frameTag.name);
        free(frameTag.color);
    }
    array_free(_data.frame_tags);
    deinit(*_data.name_to_tag);

    for layer : _data.layers
    {
        free(layer.name);
    }
    array_free(_data.layers);
    deinit(*_data.name_to_layer);
    free(_data);
}

#scope_file

parse_box :: (_value: JSON_Value) -> AsepriteBox
{
    assert(_value.type == .OBJECT);

    box: AsepriteBox;
    {
        value, success: = table_find(_value.object, "x");
        if success { box.x = cast(s32)value.number; }
    }
    {
        value, success: = table_find(_value.object, "y");
        if success { box.y = cast(s32)value.number; }
    }
    {
        value, success: = table_find(_value.object, "w");
        if success { box.w = cast(s32)value.number; }
    }
    {
        value, success: = table_find(_value.object, "h");
        if success { box.h = cast(s32)value.number; }
    }

    return box;
}

parse_frame :: (_value: JSON_Value) -> AsepriteFrame
{
    assert(_value.type == .OBJECT);

    frame: AsepriteFrame;
    json_try_copy_string(_value, "filename", *frame.name);
    frame.frame = parse_box(json_get(_value, "frame"));
    frame.rotated = json_get(_value, "rotated", .BOOLEAN).boolean;
    frame.trimmed = json_get(_value, "trimmed", .BOOLEAN).boolean;
    frame.sprite_source_size = parse_box(json_get(_value, "spriteSourceSize"));
    frame.source_size = parse_box(json_get(_value, "sourceSize"));
    frame.duration_in_ms = cast(s32)json_get(_value, "duration", .NUMBER).number;
    return frame;
}

parse_tag :: (_value: JSON_Value) -> AsepriteFrameTag
{
    tag: AsepriteFrameTag;
    tag.name = copy_string(json_get(_value, "name", .STRING).str);
    tag.start_frame = cast(s32)json_get(_value, "from", .NUMBER).number;
    tag.end_frame = cast(s32)json_get(_value, "to", .NUMBER).number;
    tag.direction = enum_name_to_value(AsepriteDirection, json_get(_value, "direction", .STRING).str);
    {
        val, success: = table_find(_value.object, "repeat");
        if success { tag.repeat_count = cast(s32)atof(temp_c_string(val.str)); } 
    }
    tag.color = copy_string(json_get(_value, "color", .STRING).str); // Would be better to directly convert it to color but fuck it for now

    return tag;
}

parse_layer :: (_value: JSON_Value) -> AsepriteLayer
{
    layer: AsepriteLayer;
    layer.name = copy_string(json_get(_value, "name", .STRING).str);
    layer.opacity = cast(float)(json_get(_value, "opacity", .NUMBER).number / 255.0);
    layer.blend_mode = enum_name_to_value(AsepriteBlendMode, json_get(_value, "blendMode", .STRING).str);
    return layer;
}

#import "Basic";
#import "String";
#import "jaison";
#import "Reflection";
