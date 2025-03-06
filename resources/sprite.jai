Sprite :: struct
{
    #as using base: Resource;

    texture: ResourceID(TextureFile); @serialize
    bounds: Bounds; @serialize
}