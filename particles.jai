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
    size: RangeFloat = .{5.0, 5.0};
    color: Color = WHITE;

    auto_emit: bool;
} 

particle_emitter_emit :: (using _emitter: *ParticleEmitter, _count: int)
{
    particles_to_emit += _count;
}

particle_emitter_update :: (using _emitter: *ParticleEmitter, _position: Vector3, _dt: float)
{
    for p: particles
    {
        particle_update(_emitter, p, _dt);
    }

    particles_per_frame: = ceil_to_s32(settings.emission_rate * _dt);
    if settings.auto_emit && particles_to_emit < particles_per_frame
    {
        particles_to_emit += particles_per_frame;
    }

    if particles_to_emit == 0
    {
        next_particle_in = 0.0;
        return;
    }

    previous_position: = position;
    position = _position;
    next_particle_in -= _dt;

    particle_interval: = 1.0 / settings.emission_rate;
    while next_particle_in < 0.0 && particles_to_emit > 0
    {
        new_particle: = pool_add(*particles);

        ratio: = (_dt + next_particle_in) / _dt;
        new_particle.position = lerp(previous_position, position, ratio);
        new_particle.size = random_range(settings.size);
        new_particle.remaining_life = random_range(settings.duration);
        new_particle.color = settings.color;
        new_particle.velocity = xyz(rotate(.{1,0}, D2R * random_range(settings.angle)) * random_range(settings.speed), 0);

        particle_update(_emitter, new_particle, -next_particle_in);
        next_particle_in += particle_interval;

        particles_to_emit -= 1;
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

#scope_file

particle_update :: (using _emitter: *ParticleEmitter, _particle: *Particle, _dt: float)
{
    _particle.remaining_life -= _dt;

    if _particle.remaining_life <= 0
    {
        pool_remove(*particles, _particle);
        return;
    }

    _particle.position += _particle.velocity * _dt;
}