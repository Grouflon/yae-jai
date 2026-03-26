pools_inspector_update :: ()
{
    table_flags: ImGui.TableFlags = .ScrollX | .ScrollY | .BordersV | .BordersOuterV | .BordersH | .Resizable | .RowBg | .Sortable | .Hideable;

    COLUMNS :: ImGui_ColumnDefinition.[
        .{"Name", .NoHide, 0},
        .{"Items", 0, 0},
        .{"Memory", 0, 0},
    ];

    if ImGui.BeginTable("pools", COLUMNS.count, table_flags, .{0, 0})
    {
        defer ImGui.EndTable();

        ImGui_TableSetupColumns(COLUMNS);
        ImGui.TableSetupScrollFreeze(0, 1);

        ImGui.TableHeadersRow();

        // current_sort_specs = ImGui.TableGetSortSpecs();
        // if current_sort_specs != null && current_sort_specs.SpecsCount > 0
        // {
        //     if first_update
        //     {
        //         first_update = false;
        //         ImGui.TableSetColumnSortDirection(1, .Ascending, false);
        //     }

        //     quick_sort(resources, (a: *Resource, b: *Resource) -> s64
        //     {
        //         sort_spec: = current_sort_specs.Specs[0];
        //         delta: s64 = 0;
        //         if sort_spec.ColumnIndex ==
        //         {
        //             case 0; delta = compare_strings(a.name, b.name);
        //             case 1; delta = compare_strings(a.type.name, b.type.name);
        //             case 2; delta = cast(s64)a.load_count - cast(s64)b.load_count;
        //         }

        //         if sort_spec.SortDirection_ == .Descending { delta *= -1; }
        //         return delta;
        //     });
        // }

        for *pool : pool_collection.pools
        {
            ImGui.TableNextRow();

            ImGui.TableNextColumn();

            name: string;
            if pool.type.type != .STRUCT
            {
                name = "non-struct (name not supported yet)";
            }
            else
            {
                name = pool.type.(*Type_Info_Struct).name;
            }

            used: = pool.used_count;
            total: = pool.items_per_page * pool.pages.count;
            item_size: = get_item_size(pool);

            ImGui.Selectable(temp_c_string(name), false, .SpanAllColumns | .AllowOverlap);

            ImGui.TableNextColumn();
            ImGui.Text("% / %", used, total-1); // we remove null item from total for clarity

            ImGui.TableNextColumn();
            used_size: = (used+1) * item_size;
            total_size: = total * item_size;
            ImGui.Text("% / %", prettify_byte_count(used_size, "%%"), prettify_byte_count(total_size, "%%"));
        }
    }
}