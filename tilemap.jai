TileMapCell :: struct
{
    position: Vector2;
    id: int;
    flip_x: bool;
    flip_y: bool;
}

TileMap :: struct
{
    texture: Texture2D;
    map_size: [2]int;
    cell_size: [2]int;
    map: []TileMapCell;
}

tilemap_init :: (_tilemap: *TileMap, _texture: Texture2D, _cell_width: int, _cell_height: int, _map_width: int, _map_height: int)
{
    assert(_tilemap != null);

    _tilemap.texture = _texture;
    _tilemap.map_size[0] = _map_width;
    _tilemap.map_size[1] = _map_height;
    _tilemap.cell_size[0] = _cell_width;
    _tilemap.cell_size[1] = _cell_height;
    array_resize(*_tilemap.map, _map_width * _map_height);

    for i : 0.._tilemap.map.count-1
    {
        _tilemap.map[i] = .{
            position = .{},
            id = -1,
            flip_x = false,
            flip_y = false
        };
    }
}

tilemap_shutdown :: (_tilemap: *TileMap)
{
    assert(_tilemap != null);

    array_free(_tilemap.map);
}

tilemap_set_cell :: (_tilemap: *TileMap, _x: int, _y: int, _sprite_id: int, _flip_x: bool = false, _flip_y: bool = false)
{
    assert(_tilemap != null);

    index: = _y * _tilemap.map_size[0] + _x;
    if index >= _tilemap.map.count { return; }

    _tilemap.map[index] = .{
        id = _sprite_id,
        flip_x = _flip_x,
        flip_y = _flip_y
    };
}

tilemap_draw :: (_tilemap: *TileMap, _position: Vector2)
{
    if _tilemap.texture.id == 0 { return; }

    for y: 0.._tilemap.map_size[1]-1
    {
        for x: 0.._tilemap.map_size[0]-1
        {
            tile: = _tilemap.map[y * _tilemap.map_size[0] + x];
            if tile.id < 0 { continue; }

            source_rectangle: = Rectangle.{
                cast(float) (tile.id % _tilemap.texture.width) * _tilemap.cell_size[0],
                cast(float) (tile.id / _tilemap.texture.width) * _tilemap.cell_size[1],
                (ifx tile.flip_x then -1.0 else 1.0) * (_tilemap.cell_size[0]),
                (ifx tile.flip_y then -1.0 else 1.0) * (_tilemap.cell_size[1]),
            };

            dest_rectangle: = Rectangle.{
                _position.x + x * _tilemap.cell_size[0], 
                _position.y + y * _tilemap.cell_size[1], 
                cast(float) _tilemap.cell_size[0],
                cast(float) _tilemap.cell_size[1],
            };

            DrawTexturePro(_tilemap.texture, source_rectangle, dest_rectangle, .{}, 0.0, WHITE);
        }
    }
}
