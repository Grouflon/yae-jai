LAYER_COUNT :: 32; // If we ever want more, we will need to make layer_response more generic, like making it something like [LAYER_COUNT][LAYER_COUNT/32]u64
SOLVING_ITERATIONS :: 5;

PhysicsManager :: struct
{
    colliders: Pool(Collider);

    colliders_by_layer: [LAYER_COUNT][..]*Collider;
    layers_response: [LAYER_COUNT]u64;
}
physics: PhysicsManager;

PhysicsShapeType :: enum
{
    BOX;
    CIRCLE; // NOT IMPLEMENTED YET
}

PhysicsShape :: struct
{
    type: PhysicsShapeType;
    union {
        box: Rect;
        circle: struct {
            center: Vector2;
            radius: float;
        }
    }
}

Collider :: struct
{
    id: ID(Collider);
    parent: *Entity;
    shape: PhysicsShape;
    static: bool = true;
    enabled: bool = true;

    frame_collisions: [..]*Collider;
    frame_overlaps: [..]*Collider;

    _previous_center: Vector2;
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

    pool_init(*colliders);
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

    for *collider: colliders
    {
        array_clear(*collider.frame_collisions);
        array_clear(*collider.frame_overlaps);
    }

    for i: 0..SOLVING_ITERATIONS-1
    {
        solve_collisions();
    }

    for *collider: colliders
    {
        collider._previous_center = center(collider_get_bounds(collider));
    }
}

physics_draw_colliders :: ()
{
    using physics;

    for collider: colliders
    {
        if !collider.enabled continue;

        color: = physics_layer_to_color(collider._layer);
        position: = ifx collider.parent != null then collider.parent.position else Vector3.{};

        if collider.shape.type ==
        {
            case .BOX; draw_rectangle(position, collider.shape.box, color);
        }
    }
}

physics_add_collider :: (parent: *Entity, layer: u8) -> *Collider
{
    using physics;

    collider, id: = pool_add(*colliders);

    collider.id = id;
    collider.parent = parent;
    collider._layer = layer;

    array_add(*colliders_by_layer[layer], collider);

    return collider;
}

physics_remove_collider :: (collider: *Collider)
{
    using physics;

    assert(collider != null);

    // Not sure unordered can cause determinism issues. If this function is not called in parallel, I don't think so, and I don't think it ever should be
    found: = array_ordered_remove_by_value(*colliders_by_layer[collider._layer], collider);
    assert(found);

    array_free(collider.frame_collisions);
    array_free(collider.frame_overlaps);
    
    pool_remove(*colliders, collider);
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

physics_get_layer_response :: (layer1: u8, layer2: u8) -> CollisionResponse
{
    using physics;

    mask: u64 = (cast(u64)0b11) << cast(u64)(layer2 * 2);
    return xx((layers_response[layer1] & mask) >> cast(u64)(layer2 * 2));
}

physics_cast :: (position: Vector2, shape: PhysicsShape, target_layers: []u8) -> []*Collider
{
    using physics;

    result: [..]*Collider;
    result.allocator = temporary_allocator;

    for i: target_layers
    {
        for b: colliders_by_layer[i]
        {
            if !b.enabled continue;
            b_position: = b.parent.position.xy;

            if !collision_shape_shape(position, shape, b_position, b.shape) continue;

            array_add(*result, b);
        }
    }

    return result;
}

collider_get_bounds :: (using collider: *Collider) -> Bounds
{
    assert(collider != null);

    pos: = ifx collider.parent != null then collider.parent.position.xy else Vector2.{};

    return pos + shape_get_bounds(collider.shape);
}

shape_get_bounds :: (using shape: PhysicsShape) -> Bounds
{
    if type ==
    {
        case .BOX; return make_bounds(Vector2.{box.x, box.y}, Vector2.{box.x + box.w, box.y + box.h});
        case; assert(false);
    }
     return .{};
}

physics_layer_to_color :: (layer: u8) -> Color
{
    if layer ==
    {
        case 0; return BLUE;
        case 1; return GREEN;
        case 2; return RED;
    }
    return DARKGRAY;
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
            response: = physics_get_layer_response(xx i, xx j);

            // Skip layer if response is 0
            if response == .NONE { continue; }

            for a: colliders_by_layer[i]
            {
                if !a.enabled continue;
                a_position: = a.parent.position.xy;
                a_bounds: = collider_get_bounds(a);

                for b: colliders_by_layer[j]
                {
                    if a == b continue;
                    if !b.enabled continue;
                    if a.parent == b.parent continue;

                    b_position: = b.parent.position.xy;
                    b_bounds: = collider_get_bounds(b);

                    if !collision_shape_shape(a_position, a.shape, b_position, b.shape) continue;

                    if (response == .COLLIDE)
                    {
                        a_factor: float = 0.0;
                        b_factor: float = 0.0;
                        if a.static == b.static
                        {
                            a_factor = 0.5;
                            b_factor = 0.5;
                        }
                        else if a.static
                        {
                            a_factor = 0.0;
                            b_factor = 1.0;
                        }
                        else
                        {
                            a_factor = 1.0;
                            b_factor = 0.0;
                        }
                        a_push: = compute_push(a._previous_center, a_bounds, b_bounds) * a_factor;
                        b_push: = compute_push(b._previous_center, b_bounds, a_bounds) * b_factor;

                        a.parent.position += .{a_push.x, a_push.y, 0};
                        b.parent.position += .{b_push.x, b_push.y, 0};

                        array_add_if_unique(*a.frame_collisions, b);
                        array_add_if_unique(*b.frame_collisions, a);
                    }
                    else if (response == .OVERLAP)
                    {
                        array_add_if_unique(*a.frame_overlaps, b);
                        array_add_if_unique(*b.frame_overlaps, a);
                        // solve_overlap(collider_a, collider_b);
                    }
                }   
            }
        }
    }
}

compute_push :: (a_previous_center: Vector2, a_bounds: Bounds, b_bounds: Bounds) -> Vector2
{
    a_center: = center(a_bounds);
    b_center: = center(b_bounds);

    movement: = a_center - a_previous_center;
    a_solving_bounds: = a_bounds - movement;

    x_move :: (a_bounds: *Bounds, b_bounds: Bounds, movement: Vector2)
    {
        a_bounds += Vector2.{movement.x, 0};
        if collision_bounds_bounds(a_bounds, b_bounds)
        {
            if movement.x >= 0 { <<a_bounds += Vector2.{b_bounds.min.x - a_bounds.max.x, 0}; }
            else { <<a_bounds += Vector2.{b_bounds.max.x - a_bounds.min.x, 0}; }
        }
    }

    y_move :: (a_bounds: *Bounds, b_bounds: Bounds, movement: Vector2)
    {
        a_bounds += Vector2.{0, movement.y};
        if collision_bounds_bounds(a_bounds, b_bounds)
        {
            if movement.y >= 0 { <<a_bounds += Vector2.{0, b_bounds.min.y - a_bounds.max.y}; }
            else { <<a_bounds += Vector2.{0, b_bounds.max.y - a_bounds.min.y}; }
        }
    }

    if abs(movement.x) > abs(movement.y)
    {
        x_move(*a_solving_bounds, b_bounds, movement);
        y_move(*a_solving_bounds, b_bounds, movement);
    }
    else
    {
        y_move(*a_solving_bounds, b_bounds, movement);
        x_move(*a_solving_bounds, b_bounds, movement);
    }

    return center(a_solving_bounds) - a_center;
}

collision_shape_shape :: (a_position: Vector2, a_shape: PhysicsShape, b_position: Vector2, b_shape: PhysicsShape) -> bool
{
    if a_shape.type ==
    {
        case .BOX;
        {
            if b_shape.type ==
            {
                case .BOX; return false;
                case .CIRCLE; return false;
            }
        }

        case .CIRCLE;
        {
            if b_shape.type ==
            {
                case .BOX; return false;
                case .CIRCLE; return false;
            }
        }

        case; assert(false);
    }

    return false;
}
