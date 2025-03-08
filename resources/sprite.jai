Sprite :: struct
{
    #as using base: Resource;

    texture: *TextureFile; @serialize
    bounds: Bounds; @serialize
}