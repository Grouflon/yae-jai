first_update: = true;

resource_browser_update :: ()
{
    table_flags: ImGui.TableFlags = .ScrollX | .ScrollY | .BordersV | .BordersOuterV | .BordersH | .Resizable | .RowBg | .Sortable | .Hideable;

    COLUMNS :: ImGui.ColumnDefinition.[
        .{"ID", 0, 0},
        .{"Name", .NoHide, 0},
        .{"Type", 0, 0},
        .{"Load count", 0, 0},
    ];

    resources: = get_objects_by_type(Resource);

    if ImGui.BeginTable("resource_browser", COLUMNS.count, table_flags, .{0, 0})
    {
        defer ImGui.EndTable();

        ImGui.TableSetupColumns(COLUMNS);
        ImGui.TableSetupScrollFreeze(0, 1);

        ImGui.TableHeadersRow();

        current_sort_specs = ImGui.TableGetSortSpecs();
        if current_sort_specs != null && current_sort_specs.SpecsCount > 0
        {
            if first_update
            {
                first_update = false;
                ImGui.TableSetColumnSortDirection(1, .Ascending, false);
            }

            bubble_sort(resources, (a: *Resource, b: *Resource) -> s64
            {
                sort_spec: = current_sort_specs.Specs[0];
                delta: s64 = 0;
                if sort_spec.ColumnIndex ==
                {
                    case 0; delta = cast(s64)a.id - cast(s64)b.id;
                    case 1; delta = compare_strings(a.name, b.name);
                    case 2; delta = compare_strings(a.type.name, b.type.name);
                    case 3; delta = cast(s64)a.load_count - cast(s64)b.load_count;
                }

                if sort_spec.SortDirection_ == .Descending { delta *= -1; }
                return delta;
            });
        }

        for resource : resources
        {
            ImGui.TableNextRow();

            ImGui.TableNextColumn();
            ImGui.Text("%", resource.id);

            ImGui.TableNextColumn();
            ImGui.Selectable(temp_c_string(resource.name), false, .SpanAllColumns | .AllowOverlap);
            if ImGui.IsItemClicked(.Left) && ImGui.IsMouseDoubleClicked(.Left)
            {
                editor_open_resource(resource);
            }

            ImGui.TableNextColumn();
            ImGui.Text("%", resource.type.name);

            ImGui.TableNextColumn();
            ImGui.Text("%", resource.load_count);
        }
    }
}

#scope_file

current_sort_specs: *ImGui.TableSortSpecs;

#import "Sort";
