IM_COL32 :: (r: u8, g: u8, b: u8, a: u8) -> u32 #expand
{
    return ((cast(u32)r) << IM_COL32_R_SHIFT) | ((cast(u32)g) << IM_COL32_G_SHIFT) | ((cast(u32)b) << IM_COL32_B_SHIFT) | ((cast(u32)a) << IM_COL32_A_SHIFT);
}

IM_COL32 :: (c: Color) -> u32 #expand
{
    return IM_COL32(c.r, c.g, c.b, c.a);
}

IM_COL32_R_SHIFT :: 0;
IM_COL32_G_SHIFT :: 8;
IM_COL32_B_SHIFT :: 16;
IM_COL32_A_SHIFT :: 24;

ImGui_ColumnDefinition :: struct
{
    name: *u8;
    flags: ImGui.TableColumnFlags;
    base_width: float;
}

ImGui_TableSetupColumns :: (columns: []ImGui_ColumnDefinition)
{
    for column: columns
    {
        ImGui.TableSetupColumn(column.name, column.flags, column.base_width);
    }
}

ImGui_InputText :: (label: string, str: *string, flags: ImGui.InputTextFlags = .None, callback: ImGui.InputTextCallback = null, user_data: *void = null, allocator: *Allocator = null) -> bool
{
    InputTextCallback_UserData :: struct
    {
        str: *string;
        ctx: #Context;
        allocator: *Allocator;
        chain_callback: ImGui.InputTextCallback;
        chain_callback_userdata: *void;
    };

    InputText_Callback :: (data: *ImGui.InputTextCallbackData) -> s32 #c_call
    {
        user_data: = cast(*InputTextCallback_UserData) data.UserData;

        push_context user_data.ctx {

            if data.EventFlag == .ImGuiInputTextFlags_CallbackResize
            {
                new_buffer: *u8 = talloc(data.BufSize);
                memset(new_buffer, 0, data.BufSize);
                memcpy(new_buffer, data.Buf, min(data.BufTextLen, cast(s32)user_data.str.count));
                data.Buf = new_buffer;
            }
            else if data.EventFlag == .CallbackEdit
            {
                push_allocator(user_data.allocator);
                user_data.str.data = realloc(user_data.str.data, data.BufTextLen, user_data.str.count);
                user_data.str.count = data.BufTextLen;
                memcpy(user_data.str.data, data.Buf, data.BufTextLen);
            }
            else if (user_data.chain_callback != null)
            {
                // Forward to user callback, if any
                data.UserData = user_data.chain_callback_userdata;
                return user_data.chain_callback(data);
            }
            return 0;
        }
    }

    assert((flags & .ImGuiInputTextFlags_CallbackResize) == 0);
    assert((flags & .ImGuiInputTextFlags_CallbackEdit) == 0);
    flags |= .CallbackResize;
    flags |= .CallbackEdit;

    cb_user_data: InputTextCallback_UserData;
    cb_user_data.str = str;
    cb_user_data.ctx = context;
    cb_user_data.allocator = ifx allocator != null then allocator else *default_allocator;
    cb_user_data.chain_callback = callback;
    cb_user_data.chain_callback_userdata = user_data;

    buffer: *u8 = talloc(str.count+1);
    memcpy(buffer, str.data, str.count);
    buffer[str.count] = 0;

    modified: = ImGui.InputText(temp_c_string(label), buffer, xx (str.count+1), flags, InputText_Callback, *cb_user_data);
    return modified;
}

ImGui_EditStructMembers :: (value: *$T) -> bool
{
    info: = type_info(T);
    if info.type != .STRUCT return false;

    return ImGui_EditStructMembers(value, cast(*Type_Info_Struct)info);
}

ImGui_EditStructMembers :: (value: *void, info_struct: *Type_Info_Struct) -> bool
{
    custom_editor_function: = get_custom_editor_function(info_struct);
    if custom_editor_function != null
    {
        // @NOTE(remi): We may want a way to be able to call the default editor even when a custom editor is set.
        // Let's wait for an actual use case to do it though
        return custom_editor_function(value, info_struct);
    }

    keys, key_to_member_info, notes: = get_flattened_struct_members(info_struct, "serialize");
    serialize_filter_function: = get_serialize_filter_function(info_struct);

    modified: = false;
    for key: keys
    {
        success, member_info: = table_find(*key_to_member_info, key);
        if !success { continue; }

        if serialize_filter_function != null && !serialize_filter_function(value, info_struct, member_info.tis_member) { continue; }

        member_value: = value + member_info.offset;
        modified = ImGui_EditValue(key, member_value, member_info.tis_member.type, member_info.tis_member.notes) || modified;
    }
    return modified;
}

ImGui_EditResourcePointer :: (label: string, resource_ptr: **$T/Resource) -> bool
{
    return ImGui_EditResourcePointer(label, xx resource_ptr, cast(*Type_Info_Struct) type_info(T));
}

ImGui_EditResourcePointer :: (label: string, resource_ptr: **Resource, info_struct: *Type_Info_Struct, notes: []string = .[]) -> bool
{
    assert(resource_ptr != null);
    assert(info_struct != null);
    assert(is_subclass_of(info_struct, Resource));

    resource: = resource_ptr.*;

    resources: = get_resources_by_type_info(info_struct);
    modified: = false;
    if ImGui.BeginCombo(temp_c_string(unique_label(label, resource_ptr)), ifx resource != null then temp_c_string(resource.name) else "null")
    {
        if ImGui.Selectable("null", resource == null) { resource_ptr.* = null; modified = true; }
        for o: resources
        {
            if ImGui.Selectable(temp_c_string(o.name), resource == o) { resource_ptr.* = o; modified = true; }
        }
        ImGui.EndCombo();
    }
    return modified;
}

ImGui_EditValue :: (label: string, value: *$T, notes: []string = .[]) -> bool
{
    return ImGui_EditValue(label, value, type_info(T), notes);
}

ImGui_EditValue :: (label: string, value: *void, info: *Type_Info, notes: []string = .[]) -> bool
{
    // Labels
    u_label: = unique_label(label, value);
    c_label: = temp_c_string(u_label);

    // Catch Resource pointers
    // *Object
    if info.type == .POINTER && is_subclass_of((cast(*Type_Info_Pointer)info).pointer_to, Resource)
    {
        resource_type: = cast(*Type_Info_Struct) (cast(*Type_Info_Pointer)info).pointer_to;
        resource_ptr: **Resource = value;

        return ImGui_EditResourcePointer(label, resource_ptr, resource_type, notes);
    }

    // Parse metadata
    WidgetType :: enum
    {
        NONE;
        DRAG;
        SLIDER;
    };
    widget_type: WidgetType = .NONE;
    has_step_override: bool;
    step_override: float = 0.0;
    has_min_override: bool;
    min_override: float = 0.0;
    has_max_override: bool;
    max_override: float = 0.0;

    if has_note(notes, "drag") { widget_type = .DRAG; }
    else if has_note(notes, "slider") { widget_type = .SLIDER; }

    found, args: = has_note_with_args(notes, "step");
    if found && args.count > 0
    {
        has_step_override = true;
        step_override = args[0].decimal;
    }

    found, args = has_note_with_args(notes, "min");
    if found && args.count > 0
    {
        has_min_override = true;
        min_override = args[0].decimal;
    }

    found, args = has_note_with_args(notes, "max");
    if found && args.count > 0
    {
        has_max_override = true;
        max_override = args[0].decimal;
    }

    // Common Float settings
    min_float: float = -FLOAT32_MAX;
    max_float: float = FLOAT32_MAX;
    step_float: = 0.1;
    if has_step_override { step_float = step_override; }
    if has_min_override { min_float = max(min_float, min_override); }
    if has_max_override { max_float = min(max_float, max_override); }
    // Slider does not behave well with huge values. We set bounds to something arbitrary to prevent crash
    if widget_type == .SLIDER && !has_min_override { min_float = 0; }
    if widget_type == .SLIDER && !has_max_override { max_float = 100; }

    // Display widget
    modified: bool = false;

    if info.type == {
        case .STRUCT;
        {
            if info ==
            {
                case type_info(Vector2);
                {
                    if widget_type == .NONE { widget_type = .DRAG; } // Vector have drag input by default
                    if widget_type ==
                    {
                        case .DRAG; modified = ImGui.DragFloat2(c_label, value, step_float, min_float, max_float);
                        case .SLIDER; modified = ImGui.SliderFloat2(c_label, value, min_float, max_float);
                        case; modified = ImGui.InputFloat2(c_label, value);
                    }
                }

                case type_info(Vector3);
                {
                    if widget_type == .NONE { widget_type = .DRAG; } // Vector have drag input by default
                    if widget_type ==
                    {
                        case .DRAG; modified = ImGui.DragFloat3(c_label, value, step_float, min_float, max_float);
                        case .SLIDER; modified = ImGui.SliderFloat3(c_label, value, min_float, max_float);
                        case; modified = ImGui.InputFloat3(c_label, value);
                    }
                }

                case type_info(Vector4); #through;
                case type_info(Quaternion);
                {
                    if widget_type == .NONE { widget_type = .DRAG; } // Vector have drag input by default
                    if widget_type ==
                    {
                        case .DRAG; modified = ImGui.DragFloat4(c_label, value, step_float, min_float, max_float);
                        case .SLIDER; modified = ImGui.SliderFloat4(c_label, value, min_float, max_float);
                        case; modified = ImGui.InputFloat4(c_label, value);
                    }
                }

                case type_info(Curve);
                {
                    modified = EditValue(u_label, cast(*Curve)value);
                }

                case type_info(StringHash);
                {
                    hash_ptr: = cast(*StringHash)value;
                    temp_str: = copy_temporary_string(hash_ptr.str); // unnecessary copy probably
                    if ImGui_InputText(u_label, *temp_str, allocator=*temporary_allocator)
                    {
                        hash_ptr.* = string_hash(temp_str);
                        modified = true;
                    }
                }

                case type_info(Bounds);
                {
                    if ImGui.TreeNodeEx(c_label, .DefaultOpen)
                    {
                        defer ImGui.TreePop();

                        bounds_ptr: = cast(*Bounds)value;
                        min: = bounds_ptr.min;
                        max: = bounds_ptr.max;
                        modified = ImGui_EditValue("min", *min) || modified;
                        modified = ImGui_EditValue("max", *max) || modified;
                        bounds_ptr.min = min;
                        bounds_ptr.max = max;
                    }
                }

                case type_info(Color);
                {
                    color_ptr: = value.(*Color);
                    color: = float.[
                        color_ptr.r.(float) / 255.0,
                        color_ptr.g.(float) / 255.0,
                        color_ptr.b.(float) / 255.0,
                        color_ptr.a.(float) / 255.0,
                    ];

                    if ImGui.ColorEdit4(c_label, *color)
                    {
                        color_ptr.r = xx (color[0] * 255.0);
                        color_ptr.g = xx (color[1] * 255.0);
                        color_ptr.b = xx (color[2] * 255.0);
                        color_ptr.a = xx (color[3] * 255.0);
                        modified = true;
                    }
                }

                case; // Generic structs
                {
                    info_struct: = polymorphic_get_type(value, xx info);

                    if label.count == 0
                    {
                        modified = ImGui_EditStructMembers(value, info_struct);                        
                    }
                    else
                    {
                        if ImGui.TreeNodeEx(c_label, .DefaultOpen)
                        {
                            defer ImGui.TreePop();

                            modified = ImGui_EditStructMembers(value, info_struct);
                        }
                    }
                }
            }
        }
        case .BOOL;
        {
            modified = ImGui.Checkbox(c_label, value);
        }
        case .INTEGER;
        {
            info_int: = cast(*Type_Info_Integer) info;

            data_type: ImGui.DataType;
            signed_min: s64;
            signed_max: s64;
            signed_step: s64;
            unsigned_min: u64;
            unsigned_max: u64;
            unsigned_step: u64;
            data_min: *void;
            data_max: *void;
            data_step: *void;

            float_step: float = 1.0;
            if has_step_override { float_step = xx step_override; }

            if info_int.signed
            {
                if info_int.runtime_size == {
                    case 1; { data_type = .S8; signed_min = S8_MIN; signed_max = S8_MAX; }
                    case 2; { data_type = .S16; signed_min = S16_MIN; signed_max = S16_MAX; }
                    case 4; { data_type = .S32; signed_min = S32_MIN; signed_max = S32_MAX; }
                    case 8; { data_type = .S64; signed_min = S64_MIN; signed_max = S64_MAX; }
                }
                if has_min_override { signed_min = max(signed_min, cast(s64)min_override); }
                if has_max_override { signed_max = min(signed_max, cast(s64)max_override); }
                signed_step = xx float_step;
                data_min = *signed_min;
                data_max = *signed_max;
                data_step = *signed_step;
            }
            else
            {
                if info_int.runtime_size == {
                    case 1; { data_type = .U8; unsigned_min = 0; unsigned_max = U8_MAX; }
                    case 2; { data_type = .U16; unsigned_min = 0; unsigned_max = U16_MAX; }
                    case 4; { data_type = .U32; unsigned_min = 0; unsigned_max = U32_MAX; }
                    case 8; { data_type = .U64; unsigned_min = 0; unsigned_max = U64_MAX; }
                }
                if has_min_override { unsigned_min = max(unsigned_min, cast(u64)min_override); }
                if has_max_override { unsigned_max = min(unsigned_max, cast(u64)max_override); }
                unsigned_step = xx float_step;
                data_min = *unsigned_min;
                data_max = *unsigned_max;
                data_step = *unsigned_step;
            }

            if widget_type ==
            {
                case .DRAG;   { modified = ImGui.DragScalar(c_label, data_type, value, float_step, data_min, data_max); }
                case .SLIDER; { modified = ImGui.SliderScalar(c_label, data_type, value, data_min, data_max); }
                case;         { modified = ImGui.InputScalar(c_label, data_type, value, data_step); }
            }
        }
        case .FLOAT;
        {
            value_float: float32;

            if info.runtime_size == {
                case 4; { value_float = value.(*float32).*.(float); }
                case 8; { value_float = value.(*float32).*.(float); }
            }

            if widget_type ==
            {
                case .DRAG;   { modified = ImGui.DragFloat(c_label, *value_float, step_float, min_float, max_float); }
                case .SLIDER; { modified = ImGui.SliderFloat(c_label, *value_float, min_float, max_float); }
                case;         { modified = ImGui.InputFloat(c_label, *value_float, step_float); }
            }

            if modified
            {
                value_float = clamp(value_float, min_float, max_float);

                if info.runtime_size == {
                    case 4; { value.(*float32).* = cast(float32)value_float; }
                    case 8; { value.(*float64).* = cast(float64)value_float; }
                }
            }
        }
        case .STRING;
        {
            str_ptr: = cast(*string)value;
            temp_str: = copy_temporary_string(str_ptr.*);
            if ImGui_InputText(u_label, str_ptr)
            {
                modified = true;
            }
        }
        case .ENUM;
        {
            info_enum: = cast(*Type_Info_Enum) info;

            getter :: (user_data: *void, idx: s32) -> *u8 #c_call
            {
                ctx: #Context;
                push_context ctx
                {
                    info_enum: = cast(*Type_Info_Enum) user_data;
                    if idx < 0 || idx >= info_enum.names.count { return ""; }
                    return temp_c_string(info_enum.names[idx]);
                }
            }

            index: s32 = xx enum_value_to_index(value, info_enum);
            modified = ImGui.Combo(c_label, *index, getter, xx info_enum, xx info_enum.names.count);
            enum_index_to_value(xx index, info_enum, value);
        }
        case .ARRAY;
        {
            info_array: = cast(*Type_Info_Array) info;
            size: s64;
            data: *void;
            array_resizable: *Resizable_Array;
            element_size: = info_array.element_type.runtime_size;

            if info_array.array_type == {
                case .FIXED;
                {
                    size = info_array.array_count;
                    data = value;
                }
                case .VIEW;
                {
                    array_view: *Array_View_64 = value;
                    size = array_view.count;
                    data = array_view.data;
                }
                case .RESIZABLE;
                {
                    array_resizable = value;
                    size = array_resizable.count;
                    data = array_resizable.data;
                }
            }

            add_last :: (array_resizable: *Resizable_Array, info_array: *Type_Info_Array , data_ptr: **void, size_ptr: *s64)
            {
                maybe_grow(array_resizable, array_resizable.count+1);
                element_size: = info_array.element_type.runtime_size;
                element_ptr: = array_resizable.data + array_resizable.count * element_size;
                if info_array.element_type.type == .STRUCT && (cast(*Type_Info_Struct)info_array.element_type).initializer != null
                {
                    (cast(*Type_Info_Struct)info_array.element_type).initializer(element_ptr);
                }
                else
                {
                    memset(element_ptr, 0, element_size);
                }
                array_resizable.count += 1;
                data_ptr.* = array_resizable.data;
                size_ptr.* = array_resizable.count;
            }

            opened: = ImGui.TreeNode(c_label, "%(%)", label, size);

            // Table context menu
            if array_resizable != null
            {
                if ImGui.BeginPopupContextItem()
                {
                    defer ImGui.EndPopup();

                    if ImGui.Selectable("Add First")
                    {
                        add_last(array_resizable, info_array, *data, *size);
                        array_move_item(data, size, info_array.element_type, size-1, 0);
                        modified = true;
                    }

                    if ImGui.Selectable("Add Last")
                    {
                        add_last(array_resizable, info_array, *data, *size);
                        modified = true;
                    }

                    if ImGui.Selectable("Clear")
                    {
                        array_resizable.count = 0;
                        modified = true;
                    }
                }
            }

            if opened
            {
                defer ImGui.TreePop();

                table_flags: ImGui.TableFlags =  .BordersH | .RowBg;

                array_width: = ImGui.GetContentRegionAvail().x;
                row_positions: [..]Vector2;
                row_positions.allocator = temporary_allocator;

                if ImGui.BeginTable(c_label, 2, table_flags, .{0, 0})
                {
                    defer ImGui.EndTable();

                    // Setup Table
                    column_flags: ImGui.TableColumnFlags = .NoResize | .NoReorder | .NoHide;
                    ImGui.TableSetupColumn("index", column_flags | .WidthFixed, 30);
                    ImGui.TableSetupColumn("value", column_flags);

                    for i: 0..(size-1)
                    {
                        // Index column
                        ImGui.TableNextRow();
                        ImGui.TableSetColumnIndex(0);
                        cursor: = ImGui.GetCursorPos();
                        array_add(*row_positions, cursor);
                        ImGui.Text("[%]", i);
                        if ImGui.IsItemHovered()
                        {
                            ImGui.SetMouseCursor(.ResizeAll);
                        }
                        if (ImGui.BeginDragDropSource(.ImGuiDragDropFlags_SourceAllowNullID))
                        {
                            ImGui.SetDragDropPayload(cprint("array_%_%", label, value), *i, size_of(type_of(i)));
                            ImGui.Text("[%]", i);
                            ImGui.SetMouseCursor(.ResizeAll);
                            ImGui.EndDragDropSource();
                        }
                        if array_resizable != null
                        {
                            if ImGui.BeginPopupContextItem(cprint("[%]", i))
                            {
                                defer ImGui.EndPopup();

                                if ImGui.Selectable("Delete")
                                {
                                    array_move_item(data, size, info_array.element_type, i, size-1);
                                    array_resizable.count -= 1;
                                    size -= 1;
                                    modified = true;
                                }

                                if ImGui.Selectable("Duplicate")
                                {
                                    add_last(array_resizable, info_array, *data, *size);
                                    memcpy(data + (size-1) * element_size, data + i * element_size, element_size);
                                    array_move_item(data, size, info_array.element_type, size-1, i+1);
                                    modified = true;
                                }

                                if ImGui.Selectable("Add Before")
                                {
                                    add_last(array_resizable, info_array, *data, *size);
                                    array_move_item(data, size, info_array.element_type, size-1, i);
                                    modified = true;
                                }

                                if ImGui.Selectable("Add After")
                                {
                                    add_last(array_resizable, info_array, *data, *size);
                                    array_move_item(data, size, info_array.element_type, size-1, i+1);
                                    modified = true;
                                }
                            }
                        }

                        // Value Column
                        ImGui.TableNextColumn();
                        element_data: = data + i * element_size;
                        modified = ImGui_EditValue("", element_data, info_array.element_type, notes) || modified;
                    }
                }

                // In between cells drop zones
                array_add(*row_positions, ImGui.GetCursorPos() - .{0, 2});
                for position, i: row_positions
                {
                    ImGui.SetCursorPos(position - .{0, 5});
                    ImGui.InvisibleButton(cprint("drop %", i), .{array_width, 8});
                    if (ImGui.BeginDragDropTarget())
                    {
                        payload: = ImGui.AcceptDragDropPayload(cprint("array_%_%", label, value));
                        if payload != null
                        {
                            assert(payload.DataSize == size_of(type_of(i)));
                            dragged_i: = payload.Data.(*s64).*;
                            target_i: = ifx i > dragged_i then i-1 else i;

                            if dragged_i == target_i continue;

                            array_move_item(data, size, info_array.element_type, dragged_i, target_i);
                        }
                        ImGui.EndDragDropTarget();
                    }
                }
            }
        }
    }
    return modified;
}

#scope_file

unique_label :: (label: string, value: *void) -> string
{
    return tprint("%##%", label, value);
}

#import "String";
