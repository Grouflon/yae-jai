texture_file_editor_init :: (resource_editor: *ResourceEditor)
{
    assert(resource_editor != null);
}

texture_file_editor_shutdown :: (resource_editor: *ResourceEditor)
{
    assert(resource_editor != null);
}

texture_file_editor_update :: (resource_editor: *ResourceEditor, dt: float) -> bool
{
    assert(resource_editor != null);
    assert(resource_editor.resource != null);

    texture_file: = cast(*TextureFile)resource_editor.resource;

    ImGui.SeparatorText("Full Texture");
    {
        size_available: = ImGui.GetContentRegionAvail();
        ratio: = size_available.x / cast(float)texture_file.texture.width;
        ImGui.Image(texture_file.texture.id, .{size_available.x, ratio * cast(float)texture_file.texture.height});
    }
    
    // Sprites
    ImGui.SeparatorText(temp_c_string(tprint("Sprites (%)", texture_file.sprites.count)));
    {
        size_available: = ImGui.GetContentRegionAvail();

        THUMBNAIL_SIZE: = Vector2.{64, 64};
        SPACING: = 10.0;

        sprites_per_line: s32 = max(cast(s32)floor(size_available.x / (THUMBNAIL_SIZE.x + SPACING)), 1);

        ratio: = size_available.x / cast(float)texture_file.texture.width;

        for sprite_res, i: texture_file.sprites
        {
            if (i % sprites_per_line != 0) ImGui.SameLine(spacing=SPACING);

            texture_size: = Vector2.{ xx sprite_res.texture.texture.width, xx sprite_res.texture.texture.height };
            uv0: = sprite_res.bounds.min / texture_size;
            uv1: = sprite_res.bounds.max / texture_size;

            ImGui.Image(sprite_res.texture.texture.id, THUMBNAIL_SIZE, uv0, uv1);
        }
    }

    return false;
}