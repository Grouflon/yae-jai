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
    name_to_frame: Table(StringHash, *AsepriteFrame);

    // Tags
    frame_tags: []AsepriteFrameTag;
    name_to_tag: Table(StringHash, *AsepriteFrameTag);

    // Layers
    layers: []AsepriteLayer;
    name_to_layer: Table(StringHash, *AsepriteLayer);

    // Slices
    slices: []AsepriteSlice;
    name_to_slice: Table(StringHash, *AsepriteSlice);
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

AsepriteSlice :: struct
{
    name: string;
    color: u32;
    keys: []AsepriteSliceKey;
}

AsepriteSliceKey :: struct
{
    bounds: AsepriteBox;
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

aseprite_load_data :: (aseprite: *AsepriteData, json_file_path: string) -> bool
{
    assert(aseprite != null);

    json_data: JSON_Value;
    {
        push_allocator(temporary_allocator);
        content, success: = read_entire_file(json_file_path);
        if !success
        {
            log_error("Failed to open aseprite data file \"%\"", json_file_path);
            return false;
        }
        
        success=, json_data = json_parse_string(content);
        if !success
        {
            log_error("Failed to parse aseprite data \"%\"", json_file_path);
            return false;
        }
    }

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
            // If it is object, frames will come out unordered. We sort them alphabetically to at least handle the most general case
            bubble_sort(aseprite.frames, (a: AsepriteFrame, b: AsepriteFrame) -> s64
            {
                return compare(a.name, b.name);
            });
        }
    }
    
    // Meta
    {
        meta: = json_get(json_data, "meta", .OBJECT);
        aseprite.app = copy_string(json_get(meta, "app", .STRING).str);
        aseprite.version = copy_string(json_get(meta, "version", .STRING).str);

        {
            found, value: = json_try_get(meta, "image");
            if found
            {
                aseprite.image_path = sprint("%1%2", path_strip_filename(json_file_path), value.str);
                if !file_exists(aseprite.image_path)
                {
                    log_warning("Failed to find referenced image file %", aseprite.image_path);
                }
            }
        }

        aseprite.format = enum_name_to_value(AsepriteImageFormat, json_get(meta, "format", .STRING).str);
        aseprite.size = parse_box(json_get(meta, "size"));
        aseprite.scale = string_to_float(json_get(meta, "scale", .STRING).str);

        // Tags
        {
            found, json_tags: = table_find_new(meta.object, "frameTags");
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
            found, json_layers: = table_find_new(meta.object, "layers");
            if found
            {
                array_resize(*aseprite.layers, json_layers.array.count);
                for json_layer, i : json_layers.array
                {
                    aseprite.layers[i] = parse_layer(json_layer);
                }
            }
        }

        // Layers
        {
            found, json_slices: = table_find_new(meta.object, "slices");
            if found
            {
                array_resize(*aseprite.slices, json_slices.array.count);
                for json_slice, i : json_slices.array
                {
                    aseprite.slices[i] = parse_slice(json_slice, aseprite.frames.count);
                }
            }
        }
    }

    // Build tables
    for *frame, i : aseprite.frames
    {
        table_set(*aseprite.name_to_frame, string_hash(frame.name), frame);
    }

    for *tag, i : aseprite.frame_tags
    {
        table_set(*aseprite.name_to_tag, string_hash(tag.name), tag);
    }

    for *layer, i : aseprite.layers
    {
        table_set(*aseprite.name_to_layer, string_hash(layer.name), layer);
    }

    for *slice, i : aseprite.slices
    {
        table_set(*aseprite.name_to_slice, string_hash(slice.name), slice);
    }

    return true;
}

aseprite_release_data :: (_data: *AsepriteData)
{
    assert(_data != null);
    
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

    for slice : _data.slices
    {
        free(slice.name);
        array_free(slice.keys);
    }
    array_free(_data.slices);
    deinit(*_data.name_to_slice);

    <<_data = .{};
}

to_bounds :: inline (aseprite_box: AsepriteBox) -> Bounds
{
    return make_bounds(
        Vector2.{xx aseprite_box.x, xx aseprite_box.y },
        Vector2.{xx (aseprite_box.x + aseprite_box.w), xx (aseprite_box.y + aseprite_box.h)}
    );
}

aseprite_get_tag :: (using data: *AsepriteData, name: StringHash) -> *AsepriteFrameTag
{
    assert(data != null);

    found, tag: = table_find_new(*name_to_tag, name);
    if !found return null;
    return tag;
}

aseprite_get_tag :: (data: *AsepriteData, name: string) -> *AsepriteFrameTag
{
    return aseprite_get_tag(data, string_hash(name));
}

aseprite_get_slice :: (data: *AsepriteData, name: string, frame: s32, reverse_y: bool = false) -> bool, Bounds
{
    found, slice: = aseprite_get_slice(data, string_hash(name), frame, reverse_y);
    return found, slice;
}

aseprite_get_slice :: (data: *AsepriteData, name: StringHash, frame: s32, reverse_y: bool = false) -> bool, Bounds
{
    if data == null return false, .{};

    found, slice: = table_find_new(*data.name_to_slice, name);
    if !found return false, .{};

    if frame < 0 || frame >= slice.keys.count return false, .{};

    slice_bounds: = to_bounds(slice.keys[frame].bounds);
    if reverse_y
    {
        h: float = xx data.frames[frame].frame.h;
        slice_bounds = make_bounds(
            Vector2.{slice_bounds.min.x, h-slice_bounds.min.y},
            Vector2.{slice_bounds.max.x, h-slice_bounds.max.y}
        );
    }
    return true, slice_bounds;
}

#scope_file

parse_box :: (_value: JSON_Value) -> AsepriteBox
{
    assert(_value.type == .OBJECT);

    box: AsepriteBox;
    {
        success, value: = table_find_new(_value.object, "x");
        if success { box.x = cast(s32)value.number; }
    }
    {
        success, value: = table_find_new(_value.object, "y");
        if success { box.y = cast(s32)value.number; }
    }
    {
        success, value: = table_find_new(_value.object, "w");
        if success { box.w = cast(s32)value.number; }
    }
    {
        success, value: = table_find_new(_value.object, "h");
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
    frame.duration_in_ms = xx json_get(_value, "duration", .NUMBER).number;
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
        success, val: = table_find_new(_value.object, "repeat");
        if success { tag.repeat_count = cast(s32)string_to_float(val.str); } 
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

parse_slice :: (_value: JSON_Value, frame_count: s64) -> AsepriteSlice
{
    _slice: AsepriteSlice;
    _slice.name = copy_string(json_get(_value, "name", .STRING).str);
    _slice.color = string_to_int(slice(json_get(_value, "color", .STRING).str, 1, 8), 16, u32);

    array_resize(*_slice.keys, frame_count);
    found, json_keys: = table_find_new(_value.object, "keys");
    if found && json_keys.array.count > 0
    {
        previous_frame: s32 = -1;
        previous_bounds: AsepriteBox;
        for i: 0..json_keys.array.count-1
        {
            json_key: = json_keys.array[i];
            frame: s32 = xx json_get(json_key, "frame", .NUMBER).number;
            bounds: = parse_box(json_get(json_key, "bounds", .OBJECT));

            // Everything before first key is set to the first key
            if previous_frame < 0
            {
                previous_frame = 0;
                previous_bounds = bounds;
            }

            for j: previous_frame..frame-1
            {
                _slice.keys[j].bounds = previous_bounds;
            }

            previous_frame = frame;
            previous_bounds = bounds;
        }

        // Everything after last key is set to the last key
        for i: previous_frame..frame_count-1
        {
            _slice.keys[i].bounds = previous_bounds;
        }
    }

    return _slice;
}

#import "Basic";
#import "String";
#import "Reflection";
// #import "File_Utilities";
#import "Sort";
