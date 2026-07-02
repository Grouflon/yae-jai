Entity :: struct
{
    id: ID(Entity);
    first_component: *EntityComponent;
}

EntityComponent :: struct
{
    id_base: IDBase;
    type: *Type_Info;
    owner: *Entity;
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
    component.owner = entity;

    slot: **T = xx *entity.first_component;

    while slot.* != null
    {
        slot = xx *slot.*.next_component;
    }

    slot.* = component;

    return component;
}

entity_get_component :: (entity: *Entity, $T: Type) -> *T
{
    #assert is_subclass_of(T, EntityComponent);
    assert(entity != null);

    component: = entity.first_component;
    while component != null
    {
        assert(component.owner == entity);

        if component.type == T return component;
        component = component.next_component;
    }
    return null;
}

get_id :: (entity: *$T/EntityComponent) -> ID(T)
{
    return .{entity.id_base.index, entity.id_base.generation};
}