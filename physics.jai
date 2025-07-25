PhysicsManager :: struct
{
    colliders: Pool(Collider);
}
physics: PhysicsManager;

Collider :: struct
{
    parent: *Entity;
    rect: Rect;
    layer: u8;
    enabled: bool;
}

physics_init :: ()
{
    using physics;

    pool_init(*colliders, 512, false);
}

physics_shutdown :: ()
{
    using physics;

    pool_shutdown(*colliders);
}

physics_update :: (dt: float)
{
    using physics;
}

physics_draw :: ()
{
    using physics;

    for collider: colliders
    {
        if !collider.enabled continue;

        color: = DARKGRAY;
        if collider.layer ==
        {
            case 0; color = BLUE;
            case 1; color = GREEN;
            case 2; color = RED;
        }
        position: = ifx collider.parent != null then collider.parent.position else Vector3.{};

        draw_outlined_rect(position.xy + collider.rect, color);
    }
}

physics_add_collider :: (parent: *Entity, layer: u8) -> PoolID(Collider)
{
    using physics;

    id, collider: = pool_add(*colliders);

    collider.parent = parent;
    collider.layer = layer;

    return id;
}

physics_remove_collider :: (collider: PoolID(Collider))
{
    using physics;
    
    pool_remove(*colliders, collider);
}
