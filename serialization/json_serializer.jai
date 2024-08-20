JsonSerializer :: struct
{
    #as using serializer: Serializer;

    Context :: struct
    {
        value: *JSON_Value;
        current_index: int = -1;
    }

    root_value: JSON_Value;
    context_stack: [..]Context;
    context_stack.allocator = temporary_allocator;

    begin = (serializer: *Serializer) { json_serializer_begin(cast(*JsonSerializer)serializer); };
    end =   (serializer: *Serializer) { json_serializer_end(cast(*JsonSerializer)serializer); };

    begin_array = (serializer: *Serializer, size: *u32, key: string) -> bool { return json_serializer_begin_array(cast(*JsonSerializer)serializer, size, key); };
    end_array =   (serializer: *Serializer) -> bool                          { return json_serializer_end_array(cast(*JsonSerializer)serializer); };

    begin_object = (serializer: *Serializer, keys: *[]string, key: string) -> bool { return json_serializer_begin_object(cast(*JsonSerializer)serializer, keys, key); };
    end_object   = (serializer: *Serializer) -> bool                               { return json_serializer_end_object(cast(*JsonSerializer)serializer); };

    serialize_bool =    (serializer: *Serializer, value: *bool, key: string) -> bool    { return serialize(cast(*JsonSerializer)serializer, value, key); };
    serialize_u8 =      (serializer: *Serializer, value: *u8, key: string) -> bool      { return serialize(cast(*JsonSerializer)serializer, value, key); };
    serialize_u16 =     (serializer: *Serializer, value: *u16, key: string) -> bool     { return serialize(cast(*JsonSerializer)serializer, value, key); };
    serialize_u32 =     (serializer: *Serializer, value: *u32, key: string) -> bool     { return serialize(cast(*JsonSerializer)serializer, value, key); };
    serialize_u64 =     (serializer: *Serializer, value: *u64, key: string) -> bool     { return serialize(cast(*JsonSerializer)serializer, value, key); };
    serialize_s8 =      (serializer: *Serializer, value: *s8, key: string) -> bool      { return serialize(cast(*JsonSerializer)serializer, value, key); };
    serialize_s16 =     (serializer: *Serializer, value: *s16, key: string) -> bool     { return serialize(cast(*JsonSerializer)serializer, value, key); };
    serialize_s32 =     (serializer: *Serializer, value: *s32, key: string) -> bool     { return serialize(cast(*JsonSerializer)serializer, value, key); };
    serialize_s64 =     (serializer: *Serializer, value: *s64, key: string) -> bool     { return serialize(cast(*JsonSerializer)serializer, value, key); };
    serialize_s64 =     (serializer: *Serializer, value: *s64, key: string) -> bool     { return serialize(cast(*JsonSerializer)serializer, value, key); };
    serialize_float32 = (serializer: *Serializer, value: *float32, key: string) -> bool { return serialize(cast(*JsonSerializer)serializer, value, key); };
    serialize_float64 = (serializer: *Serializer, value: *float64, key: string) -> bool { return serialize(cast(*JsonSerializer)serializer, value, key); };
    serialize_string =  (serializer: *Serializer, value: *string, key: string) -> bool  { return serialize(cast(*JsonSerializer)serializer, value, key); };
}

json_serializer_set_read_data :: (serializer: *JsonSerializer, json_string :string)
{
    assert(serializer.mode == .NONE);
    assert(false); // @TODO
}

json_serializer_set_read_data :: (serializer: *JsonSerializer, root :JSON_Value)
{
    assert(serializer.mode == .NONE);
    root_value = root;
}

#scope_file

json_serializer_begin :: (using s: *JsonSerializer)
{
    if mode == .WRITE
    {
        root_value = .{};
    }
}

json_serializer_end :: (using s: *JsonSerializer)
{
    assert(context_stack.count == 0);
}

serialize :: (using s: *JsonSerializer, value: *bool, key: string = "") -> bool
{
    assert(s != null);
    assert(mode != .NONE);

    success, next_value: = select_next_value(s, key);
    if !success { return false; }

    if mode == {
        case .READ;
        {
            if next_value.type != .BOOLEAN
            {
                last_error = "Read value is not of type bool";
                return false;
            }

            <<value = next_value.boolean;
        }
        case .WRITE;
        {
            next_value.type = .BOOLEAN;
            next_value.boolean = <<value;
        }
    }
    return true;
}

serialize_number :: inline (using s: *JsonSerializer, value: *$T, key: string = "") -> bool
{
    assert(s != null);
    assert(mode != .NONE);

    success, next_value: = select_next_value(s, key);
    if !success { return false; }

    if mode == {
        case .READ;
        {
            if next_value.type != .NUMBER
            {
                last_error = "Read value is not of type number";
                return false;
            }

            <<value = cast(T) next_value.number;
        }
        case .WRITE;
        {
            next_value.type = .NUMBER;
            next_value.number = cast(float64) <<value;
        }
    }
    return true;
}

serialize :: (serializer: *JsonSerializer, value: *u8, key: string = "") -> bool
{
    return serialize_number(serializer, value, key);
}

serialize :: (serializer: *JsonSerializer, value: *u16, key: string = "") -> bool
{
    return serialize_number(serializer, value, key);
}

serialize :: (serializer: *JsonSerializer, value: *u32, key: string = "") -> bool
{
    return serialize_number(serializer, value, key);
}

serialize :: (serializer: *JsonSerializer, value: *u64, key: string = "") -> bool
{
    return serialize_number(serializer, value, key);
}

serialize :: (serializer: *JsonSerializer, value: *s8, key: string = "") -> bool
{
    return serialize_number(serializer, value, key);
}

serialize :: (serializer: *JsonSerializer, value: *s16, key: string = "") -> bool
{
    return serialize_number(serializer, value, key);
}

serialize :: (serializer: *JsonSerializer, value: *s32, key: string = "") -> bool
{
    return serialize_number(serializer, value, key);
}

serialize :: (serializer: *JsonSerializer, value: *s64, key: string = "") -> bool
{
    return serialize_number(serializer, value, key);
}

serialize :: (serializer: *JsonSerializer, value: *float32, key: string = "") -> bool
{
    return serialize_number(serializer, value, key);
}

serialize :: (serializer: *JsonSerializer, value: *float64, key: string = "") -> bool
{
    return serialize_number(serializer, value, key);
}

serialize :: (using s: *JsonSerializer, value: *string, key: string = "") -> bool
{
    assert(s != null);
    assert(mode != .NONE);

    success, next_value: = select_next_value(s, key);
    if !success { return false; }

    if mode == {
        case .READ;
        {
            if next_value.type != .STRING
            {
                last_error = "Read value is not of type string";
                return false;
            }

            <<value = copy_string(next_value.str);
        }
        case .WRITE;
        {
            next_value.type = .STRING;
            next_value.str = copy_temporary_string(<<value);
        }
    }
    return true;
}

json_serializer_begin_array :: (serializer: *JsonSerializer, size: *u32, keys: string) -> bool
{
    return true;
}

json_serializer_end_array :: (serializer: *JsonSerializer) -> bool
{
    return true;
}

json_serializer_begin_object :: (using s: *JsonSerializer, keys: *[]string, key: string) -> bool
{
    assert(s != null);
    assert(mode != .NONE);

    success, next_value: = select_next_value(s, key);
    if !success { return false; }

    if mode ==
    {
        case .READ;
        {
            if (next_value.type != .OBJECT)
            {
                last_error = "Read value is not of type object";
                return false;
            }
        }
        case .WRITE;
        {
            next_value.type = .OBJECT;
            next_value.object = talloc(size_of(JSON_Object));
            Initialize(next_value.object);
            next_value.object.allocator = temporary_allocator;
        }
    }
    array_add(*context_stack, .{ value = next_value });

    return true;
}

json_serializer_end_object :: (using s: *JsonSerializer) -> bool
{
    assert(s != null);
    assert(mode != .NONE);

    if context_stack.count == 0 || array_back(context_stack).value.type != .OBJECT
    {
        last_error = "Ending an object that was never began";
        return false;
    }
    pop(*context_stack);

    return true;
}

select_next_value :: (using s: *JsonSerializer, key: string) -> bool, *JSON_Value
{
    assert(s != null);
    assert(mode != .NONE);

    top_context: = array_back(context_stack);

    if key.count != 0 && (top_context == null || top_context.value.type != .OBJECT)
    {
        last_error = "Cannot serialize item with id outside of any object scope.";
        return false, null;
    }

    // First value
    if top_context == null
    {
        // @NOTE: we currently do not allow the serializer to write a .NULL type, so we can assume this means uninitialized.
        // We will need to change that code if this becomes false, but maybe the safeguard isn't even needed.
        if mode == .WRITE && root_value.type != .NULL
        {
            last_error = "Cant write the root value twice.";
            return false, null;
        }

        return true, *root_value;
    }

    // Nested values
    if top_context.value.type == {
        case .ARRAY;
        {
            top_context.current_index += 1;
            if top_context.current_index >= top_context.value.array.count
            {
                last_error = tprint("Cannot serialize more items than the size of the array (size=%).", top_context.value.array.count);
                return false, null;
            }

            return true, top_context.value.array.data + top_context.current_index;
        }

        case .OBJECT;
        {
            if key.count == 0
            {
                last_error = "Cannot serialize into an object without a key";
                return false, null;
            }

            if mode == {
                case .WRITE;
                {
                    new_value: *JSON_Value = table_add(top_context.value.object, key, .{});
                    return true, new_value;
                }
                case .READ;
                {
                    value: = table_find_pointer(top_context.value.object, key);
                    if value == null
                    {
                        last_error = tprint("Failed to read key \"%\".", key);
                        return false, null;
                    }
                    return true, value;
                }
            }
        }

        case;
        {
            if mode == {
                case .WRITE;
                {
                    last_error = "Cannot serialize nested item outside of an array, an object, or the root of the json document.";
                    return false, null;
                }

                case .READ;
                {
                    return true, top_context.value;
                }
            }
            
        }
    }
    return false, null;
}

#import "jaison";