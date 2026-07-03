Entity :: struct
{
    id: ID(Entity);
    first_component: *EntityComponent;

    initialized: bool;
}

EntityComponent :: struct
{
    id_base: IDBase;
    type: *Type_Info;
    entity: *Entity;
    next_component: *EntityComponent;
}

add_entity :: () -> *Entity
{
    entity, id: = pool_add(Entity);
    entity.id = id;
    return entity;
}

remove_entity :: (entity: *Entity)
{
    assert(entity != null);

    entity_shutdown(entity);

    component: = entity.first_component;
    while component != null
    {
        c: = component;
        component = component.next_component;
        pool_remove(c, c.type);
    }
    pool_remove(entity);
}

entity_add_component :: (entity: *Entity, $T: Type) -> *T
{
    #assert is_subclass_of(T, EntityComponent);
    assert(entity != null);


    component, id: = pool_add(T);
    component.id_base = id.id;
    component.type = type_info(T);
    component.entity = entity;

    slot: **T = xx *entity.first_component;

    while slot.* != null
    {
        slot = xx *slot.*.next_component;
    }

    slot.* = component;

    return component;
}

entity_initialize :: (entity: *Entity)
{
    if entity.initialized return;

    component: = entity.first_component;
    while component != null
    {
        initialize_function: = get_initialize_function(component.type);
        if initialize_function != null initialize_function(component);

        component = component.next_component;
    }

    entity.initialized = true;
}

entity_shutdown :: (entity: *Entity)
{
    if !entity.initialized return;

    // We need to shutdown in the reverse order of initialize
    components: [..]*EntityComponent;
    components.allocator = temporary_allocator;

    component: = entity.first_component;
    while component != null
    {
        array_add(*components, component);
        
        component = component.next_component;
    }

    for < component: components
    {
        shutdown_function: = get_shutdown_function(component.type);
        if shutdown_function != null shutdown_function(component);
    }

    entity.initialized = false;
}

entity_get_component :: (entity: *Entity, $T: Type) -> *T
{
    #assert is_subclass_of(T, EntityComponent);
    assert(entity != null);

    component: = entity.first_component;
    while component != null
    {
        assert(component.entity == entity);

        if component.type == type_info(T) return xx component;
        component = component.next_component;
    }
    return null;
}

get_component :: (component: *EntityComponent, $T: Type) -> *T
{
    #assert is_subclass_of(T, EntityComponent);
    assert(component != null);
    if component.entity == null return null;
    return entity_get_component(component.entity, T);
}

get_id :: (entity: *$T/EntityComponent) -> ID(T)
{
    return .{entity.id_base.index, entity.id_base.generation};
}