OBJECT_LOG_SECTION :: Log_Section.{ "Object" };

// Object
ObjectIDBase :: u32;

ID :: struct($ObjectType: Type)
{
    #as base: ObjectIDBase;
}

Object :: struct
{
    name: string;
    type: *Type_Info_Struct;
    id: ObjectIDBase;
}

get :: (id: ID($T)) -> *T
{
    object: = get(id);
    assert(object.type == T);
    return cast(*T) object;
}

get :: (id: ObjectIDBase) -> *Object
{
    using registry: = *object_registry;

    success, object: = table_find_new(*object_by_id, id);
    if !success { return null; }
    return object;
}

get_id :: (object: *$T/Object) -> ID(T)
{
    if object == null return .{};
    return .{object.id};
}


get_objects_by_type :: ($T: Type) -> []*T
{
    using registry: = *object_registry;
    if !is_subclass_of(T, Object) return .[];

    ti: = cast(*Type_Info_Struct) type_info(T);
    type_array: = find_or_add(*objects_by_type, ti);
    return cast,force([]*T)<<type_array;
}

object_rename :: (object: *Object, name: string)
{
    assert(object != null);
    using registry: = *object_registry;

    if name == object.name return;

    if object.name.count > 0
    {
        object_unregister_name(object, name);
        free(object.name);
        object.name = .{};
    }
    
    object.name = copy_string(name);

    if object.name.count > 0
    {
        object_register_name(object, object.name);
    }
}

object_create :: ($T: Type, id: ObjectIDBase = 0) -> *T
{
    object: = object_create(type_info(T), id);
    assert(object.type == type_info(T));
    return cast(*T)object;
}

object_create :: (ti: *Type_Info_Struct, id: ObjectIDBase = 0) -> *Object
{
    assert(ti != null);
    assert(is_subclass_of(ti, Object));
    using registry: = *object_registry;

    actual_id: = id;
    // If it is undefined, generate one
    if actual_id == 0
    {
        actual_id = generate_object_id();
        while table_contains(*object_by_id, id)
        {
            // If there is an id collision, just pick a new one
            actual_id = generate_object_id();
        }
    }

    if (table_contains(*object_by_id, actual_id))
    {
        log_error("Object id collision (%)", actual_id, section= *OBJECT_LOG_SECTION);
        return null;
    }

    object: *Object = alloc(ti.runtime_size);
    if ti.initializer != null
    {
        ti.initializer(object);
    }
    else
    {
        memset(object, 0, ti.runtime_size);
    }

    object.id = actual_id;
    object.type = ti;

    object_register(object);

    return object;
}

object_get_or_create :: (ti: *Type_Info_Struct, id: ObjectIDBase = 0) -> object: *Object, created: bool
{
    assert(ti != null);
    using registry: = *object_registry;

    found, object: = table_find_new(*object_by_id, id);
    if !found
    {
        object = object_create(ti, id);
        assert(object != null);
    }
    return object, !found;
}

object_get_or_create :: ($T: Type, name: string) -> object: *T, created: bool
{
    assert(is_subclass_of(T, Object));
    using registry: = *object_registry;

    if name.count == 0
    {
        log_warning("Can't get object with empty name.", section= *OBJECT_LOG_SECTION);
        return null, false;
    }

    ti: = cast(*Type_Info_Struct) type_info(T);
    found, object: = table_find_new(*object_by_name, string_hash(name));
    if !found
    {
        object = object_create(ti);
    }
    assert(object != null);
    if object.type != type_info(T)
    {
        log_error("Can't get Object \"%\": Does not match the requested type (is %, expects %).", name, object.type.name, ti.name, section= *OBJECT_LOG_SECTION);
        return null, false;
    }
    object_rename(object, name);
    return xx object, !found;
}

object_serialize :: (serializer: *Serializer, object_ptr: **Object, key: string = "") -> bool
{
    assert(serializer != null);

    if serializer.mode == .WRITE && <<object_ptr == null
    {
        serialize_null(serializer, key);
        return true;
    }

    if !serializer_begin_object(serializer, null, key) { <<object_ptr = null; return true; }
    defer serializer_end_object(serializer);

    if !object_serialize_header(serializer, object_ptr) return false;

    object: = <<object_ptr;
    assert(object != null);

    return object_serialize_body(serializer, object);
}

// This is supposed to be called with `serializer_begin_object` already called
object_serialize_header :: (serializer: *Serializer, object_ptr: **Object) -> bool
{
    assert(serializer != null);
    assert(object_ptr != null);
    using registry: = *object_registry;

    if serializer.mode == .READ
    {
        // Read instantiation data
        temp_id: ObjectIDBase;
        if !serialize(serializer, *temp_id, "id")
        {
            return false;
        }

        type: *Type_Info_Struct;
        type_name: string;
        if !serialize(serializer, *type_name, "type", *temporary_allocator)
        {
            return false;
        }

        success, ti: = table_find_new(*object_type_by_name, string_hash(type_name));
        if !success
        {
            return false;
        }
        type = ti;

        // Get or create object
        object: = object_get_or_create(type, temp_id);
        if object == null
        {
            return false;
        }
        << object_ptr = object;
    }
    else
    {
        object: = <<object_ptr;
        if object == null
        {
            return false;
        }

        serialize(serializer, *object.id, "id");
        serialize(serializer, *object.type.name, "type");
    }

    object: = <<object_ptr;
    assert(object != null);

    name: = copy_temporary_string(object.name);
    serialize(serializer, *name, "name", *temporary_allocator);
    if serializer.mode == .READ
    {
        object_rename(object, name);
    }
    return true;
}

object_serialize_body :: (serializer: *Serializer, object: *Object) -> bool
{
    assert(object != null);
    assert(object.id != 0);
    assert(object.type != null);

    return serialize(serializer, object, object.type, "data");
}

// Registry
ObjectRegistry :: struct
{
    objects: [..]*Object;
    object_by_id: Table(ObjectIDBase, *Object);
    object_by_name: Table(StringHash, *Object);
    objects_by_type: Table(*Type_Info_Struct, [..]*Object);

    object_type_by_name: Table(StringHash, *Type_Info_Struct);
};
object_registry: ObjectRegistry;

object_registry_init :: (object_types: []*Type_Info_Struct)
{
    using registry: = *object_registry;

    for info: object_types
    {
        hash: = string_hash(info.name);
        table_add(*object_type_by_name, hash, info);
    }
}

object_registry_shutdown :: ()
{
    using registry: = *object_registry;

    for object: objects
    {
        free(object.name);
        free(object);
    }
    array_reset(*objects);

    table_reset_and_free(*object_by_id);
    table_reset_and_free(*object_by_name);

    for types_objects: objects_by_type
    {
        array_reset(*types_objects);
    }
    table_reset_and_free(*objects_by_type);
}

object_register :: (object: *Object)
{
    assert(object != null);
    using registry: = *object_registry;

    assert(array_find(objects, object) == false);
    assert(table_contains(*object_by_id, object.id) == false);

    table_add(*object_by_id, object.id, object);
    array_add(*objects, object);

    type: = object.type;
    while type != null
    {
        type_array: = find_or_add(*objects_by_type, type);
        array_add(type_array, object);

        t: = get_parent_type(type);
        type = ifx t == null || t.type != .STRUCT then null else cast(*Type_Info_Struct) t;
    }
}

// Unregistering is unused and untested so far
object_unregister :: (object: *Object)
{
    assert(object != null);
    using registry: = *object_registry;

    assert(array_find(*objects, object) == true);
    assert(table_contains(*object_by_id, object.id) == true);
    
    type_array: = table_find_pointer(*objects_by_type, object.type);
    assert(type_array != null);
    array_unordered_remove_by_value(*type_array, object);

    table_remove(*object_by_id, object.id);
    array_unordered_remove_by_value(*objects, object);
}

object_register_name :: (object: *Object, name: string)
{
    assert(object != null);

    using registry: = *object_registry;

    hash: = string_hash(name);
    if table_contains(*object_by_name, hash)
    {
        log_warning("Name \"%\" already registered for object %", name, object);
        return;
    }

    table_add(*object_by_name, hash, object);
}

object_unregister_name :: (object: *Object, name: string)
{
    assert(object != null);

    using registry: = *object_registry;

    hash: = string_hash(name);
    success, o: = table_remove(*object_by_name, hash);
    if !success
    {
        log_warning("Name \"%\" not registered for object %", name, object);
        return;
    }
    assert(o == object);
}

#scope_file

generate_object_id :: () -> ObjectIDBase
{
    // Until we need something more sophisticated, Object id is just a hash of the current time
    current_time: = current_time_consensus();
    date_hash: = sdbm_hash(*current_time, xx size_of(Apollo_Time));
    id: ObjectIDBase = date_hash;
    return id;
}

#import "Hash_Table";
#import "Hash";
