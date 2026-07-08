ParticleEmitter :: struct
{
    particles: SimplePool(Particle); // maybe we can make it a global pool for all emitters, but that is too complex for now

    settings: ParticleEmitterSettings;
    position: Vector3;
    particles_to_emit: s32;
    next_particle_in: float;
}

Particle :: struct
{
    color: Color;
    position: Vector3;
    velocity: Vector3;    
    size: float;
    remaining_life: float;
}

ParticleType :: enum
{
    GRAIN;
    STRIP;
}

ParticleEmitterSettings :: struct @serialize
{
    type: ParticleType = .GRAIN;

    emission_rate: float = 100.0; // particles per second
    angle: RangeFloat = .{0,360}; @range(0,360)
    duration: RangeFloat = .{1.0, 1.0};
    speed: RangeFloat = .{1.0, 1.0};

    auto_emit: bool;
} 

particle_emitter_emit :: (using _emitter: *ParticleEmitter, _count: int)
{
    particles_to_emit += _count;
}

particle_emitter_update :: (using _emitter: *ParticleEmitter, _position: Vector3, _dt: float)
{
    if settings.auto_emit
    {
        particles_to_emit += xx (settings.emission_rate.(float) * _dt);
    }

    if particles_to_emit == 0
    {
        next_particle_in = 0.0;
        return;
    }

    next_particle_in -= _dt;

    for p: particles
    {
        p.remaining_life -= _dt;

        if p.remaining_life <= 0
        {
            pool_remove(*particles, p);
            continue;
        }

        p.position += p.velocity * _dt;
    }

    while next_particle_in < 0.0
    {
        next_particle_in += 1.0 / settings.emission_rate;

        new_particle: = pool_add(*particles);

    }
}

particle_emitter_draw :: (using _emitter: *ParticleEmitter)
{
    for p: particles
    {
        if settings.type ==
        {
            case .GRAIN;
            {
                draw_circle(p.position, p.size, p.color, 8);
            }
        }
    }
}