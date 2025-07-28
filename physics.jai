LAYER_COUNT :: 32; // If we ever want more, we will need to make layer_response more generic, like making it something like [LAYER_COUNT][LAYER_COUNT/32]u64
SOLVING_ITERATIONS :: 5;

PhysicsManager :: struct
{
    colliders: Pool(Collider);

    colliders_by_layer: [LAYER_COUNT][..]PoolID(Collider);
    layers_response: [LAYER_COUNT]u64;
}
physics: PhysicsManager;

Collider :: struct
{
    parent: *Entity;
    rect: Rect;
    enabled: bool;

    _layer: u8;
}

CollisionResponse :: enum // this will be encoded on 2 bits, so should never exceed 4 values
{
    NONE :: 0;
    OVERLAP :: 1;
    COLLIDE :: 2;
}

physics_init :: ()
{
    using physics;

    pool_init(*colliders, 512, false);
}

physics_shutdown :: ()
{
    using physics;

    for *colliders: colliders_by_layer
    {
        array_reset(colliders);
    }
    pool_shutdown(*colliders);
}

physics_update :: (dt: float)
{
    using physics;

    for i: 0..SOLVING_ITERATIONS-1
    {
        solve_collisions();
    }
}

physics_draw :: ()
{
    using physics;

    for collider: colliders
    {
        if !collider.enabled continue;

        color: = DARKGRAY;
        if collider._layer ==
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
    collider._layer = layer;

    array_add(*colliders_by_layer[layer], id);

    return id;
}

physics_remove_collider :: (id: PoolID(Collider))
{
    using physics;

    collider: = get(id);
    assert(collider != null);

    found: = false;
    for c, i: colliders_by_layer[collider._layer]
    {
        if c == id
        {
            array_unordered_remove_by_index(*colliders_by_layer[collider._layer], i);
            found = true;
            break;
        }
    }
    assert(found);
    
    // array_unordered_remove_by_value(*colliders_by_layer[collider._layer], id); // Not sure unordered can cause determinism issues. If this function is not called in parallel, I don't think so, and I don't think it ever should be
    pool_remove(*colliders, id);
}

physics_set_layer_response :: (layer1: u8, layer2: u8, response: CollisionResponse)
{
    using physics;

    process_response :: (previous_layer_response: u64, layer1: u8, layer2: u8, response: CollisionResponse) -> u64
    {
        /*
        Ex: 
           10            response
        01 01 00 01      previous_layer_response
        11 00 11 11 and  additive_mask
        00 10 00 00 or   additive_response

        01 10 00 01      result
        */
        additive_mask: = ~(cast(u64)(3) << (cast(u64)(layer2) * 2));
        additive_response: = cast(u64)(response) << (cast(u64)(layer2) * 2);
        return (previous_layer_response & additive_mask) | additive_response;
    }
    
    layers_response[layer1] = process_response(layers_response[layer1], layer1, layer2, response);
    layers_response[layer2] = process_response(layers_response[layer2], layer2, layer1, response);
}

collider_get_bounds :: (using collider: *Collider) -> Bounds
{
    pos: = ifx collider.parent != null then collider.parent.position.xy else Vector2.{};
    pos += .{collider.rect.x, collider.rect.y};
    return make_bounds(pos, pos + .{collider.rect.w, collider.rect.h});
}

#scope_file

solve_collisions :: ()
{
    using physics;

    // Iterate through every pair
    for i: 0..LAYER_COUNT-1
    {
        // Skip layer if total response is 0
        if layers_response[i] == 0 continue;

        for j: i..LAYER_COUNT-1
        {
            // Find collision response
            mask: u64 = (cast(u64)0b11) << cast(u64)(j * 2);
            response: CollisionResponse = xx((layers_response[i] & mask) >> cast(u64)(j * 2));

            // Skip layer if response is 0
            if response == .NONE { continue; }

            for collider_a: colliders_by_layer[i]
            {
                a: = get(collider_a, false);
                if !a.enabled continue;

                a_bounds: = collider_get_bounds(a);

                for collider_b: colliders_by_layer[j]
                {
                    if collider_a == collider_b continue;
                    b: = get(collider_b, false);
                    if !b.enabled continue;

                    b_bounds: = collider_get_bounds(b);

                    if !collision_bounds_bounds(a_bounds, b_bounds) continue;

                    if (response == .COLLIDE)
                    {
                        a_push: = compute_push(a_bounds, b_bounds) * 0.5;
                        b_push: = compute_push(b_bounds, a_bounds) * 0.5;

                        a.parent.position += .{a_push.x, a_push.y, 0};
                        b.parent.position += .{b_push.x, b_push.y, 0};
                    }
                    else if (response == .OVERLAP)
                    {
                        // solve_overlap(collider_a, collider_b);
                    }
                }   
            }
        }
    }
}

compute_push :: (a_bounds: Bounds, b_bounds: Bounds) -> Vector2
{
    a_center: = center(a_bounds);
    b_center: = center(b_bounds);
    bary_0: = b_center;
    bary_1: = b_bounds.max;
    bary_2: = Vector2.{b_bounds.max.x, b_bounds.min.y};

    bary_coords: = barycentric_coordinates(a_center, bary_0, bary_1, bary_2);

    push: Vector2;
    if (bary_coords.y > 0 && bary_coords.z > 0) // push right
    {
        push = .{ b_bounds.max.x - a_bounds.min.x, 0.0 };
    }
    else if (bary_coords.y > 0 && bary_coords.z <= 0) // push down
    {
        push = .{ 0.0,  b_bounds.max.y - a_bounds.min.y };
    }
    else if (bary_coords.y <= 0 && bary_coords.z <= 0) // push left
    {
        push = .{b_bounds.min.x - a_bounds.max.x,  0.0 };
    }
    else if (bary_coords.y <= 0 && bary_coords.z > 0) // push up
    {
        push = .{ 0.0, b_bounds.min.y - a_bounds.max.y };
    }

    return push;
}