// cow 3 State
old_layout : Editor_State.Layout = .None;
old_zoom: float;
old_editor: s64;
Cow_Camera :: struct {
    position : Vector2 = .{20, 100};
    zoom : float;
    move_speed: float = 20;
}
cow_camera : Cow_Camera;

Cow_Box :: struct {
    id: int;
    name: string;
    file_path: string;
    start_line: int;
    end_line: int;
    rect: Rect;
    editor_id: s64;
}
cow_boxes: [..] Cow_Box;
inited := false;
// cow 3

cow_boxes_filepath :: "cow_boxes.txt";
cow_camera_filepath :: "cow_camera.txt";

// cow 1 Serializing and Scanning
cow_save :: () {
    { // boxes
        builder: String_Builder;
        builder.allocator = temp;
        init_string_builder(*builder);
        for cow_boxes print_to_builder(*builder, "% % %\n", it.id, cast(int)it.rect.x, cast(int)it.rect.y);
        write_entire_file(cow_boxes_filepath, builder_to_string(*builder));
    }

    { // camera
        builder: String_Builder;
        builder.allocator = temp;
        init_string_builder(*builder);
        print_to_builder(*builder, "% % %", cast(int)cow_camera.position.x, cast(int)cow_camera.position.y, cast(int)cow_camera.zoom);
        write_entire_file(cow_camera_filepath, builder_to_string(*builder));
    }
}

cow_load :: () {
    { // boxes
        boxes_text := read_entire_file(cow_boxes_filepath,, temp);
        lines := split(boxes_text, "\n",, allocator = temp);
        for lines {
            id, x, y: int;
            ok := scan2(it, "% % %", *id, *x, *y);
            if ok == false break;
            for *cow_boxes {
                if it.id == id {
                    it.rect.x = xx x;
                    it.rect.y = xx y;
                }
            }
        }
    }

    { // camera
        camera_text := read_entire_file(cow_camera_filepath,, temp);
        x, y, zoom : int;
        ok := scan2(camera_text, "% % %", *x, *y, *zoom);
        if ok {
            cow_camera.position = .{xx x, xx y};
            cow_camera.zoom = xx zoom;
        }
    }
}

cow_scan :: () {
    file_paths := open_buffers;

    for file_path :file_paths {
        cow_code_file := read_entire_file(file_path.file.full_path,, temp);
        lines := split(cow_code_file, "\n",, allocator = temp);
        for line: lines {
            trimmed := trim_left(line);
            if begins_with(trimmed, "// cow") advance(*trimmed, 6);
            else if begins_with(trimmed, "# cow") advance(*trimmed, 5);
            else continue;

            id, ok, rem := to_integer(trimmed);
            if ok == false continue;
            line_number := it_index;
            found: bool = false;
            for *box: cow_boxes {
                if box.id != id continue;
                found = true;
                // if it.end_line == -1 there is something wrong
                box.end_line = line_number-1;
                box.rect.h = xx ((box.end_line-box.start_line+1));
                for box.start_line..box.end_line {
                    box.rect.w = max(box.rect.w, xx (lines[it].count+3)); // +3 to not have last char exactly on edge
                }
                // do we need this?
                box.rect.w = min(box.rect.w, 100);

                break;
            }
            if found == false {
                box : Cow_Box;
                box.id = id;
                box.rect.w = 50;
                box.name = copy_string(rem);
                box.start_line = line_number+1;
                box.file_path = file_path.file.full_path;
                array_add(*cow_boxes, box);
            }
        }
    }
}
// cow 1

// cow 2 Commands
cow_open :: () {
    if inited == false {
        cow_scan();
        cow_load();
    }
    if editors.layout != .Cow {
        old_editor = editors.active;
        make_editor_active(-1);
        old_layout = editors.layout;
        editors.layout = .Cow;
        old_zoom = xx font_size;
        font_size = xx cow_camera.zoom;
        init_fonts_and_dependent_things();
    }

    // This could be done when loading, but the font size won't be correct
    if inited == false {
        for *cow_boxes {
            buffer_id := find_or_create_buffer(it.file_path);
            it.editor_id = find_or_create_editor_for_cow(buffer_id);
            editor := *open_editors[it.editor_id];
            viewport := *editor.viewport;
            // the 0.5 is to hide any part of the start-1 line
            start_animation(*viewport.scroll_y, viewport.top, xx ((it.start_line+.5) * line_height));
        }
    }
    inited = true;

}
cow_rescan ::() {
    for *cow_boxes free(it.name);
    array_reset_keeping_memory(*cow_boxes);
    cow_scan();
    cow_load();
}
cow_close :: () {
    if editors.layout == .Cow {
        make_editor_active(old_editor);
        editors.layout = old_layout;
        cow_camera.zoom = xx font_size;
        font_size = xx old_zoom;
        init_fonts_and_dependent_things();
    }
    cow_save();
}
cow_left :: () {
    cow_camera.position.x -= cow_camera.move_speed;
}
cow_right :: () {
    cow_camera.position.x += cow_camera.move_speed;
}
cow_up :: () {
    cow_camera.position.y += cow_camera.move_speed;
}
cow_down :: () {
    cow_camera.position.y -= cow_camera.move_speed;
}
// cow 2

Cow_State :: enum {
    NONE;
    HOVERING_EDITOR;
    DRAGGING_CAMERA;
    DRAGGING_EDITOR;
    EDITING;
}

// cow 6 Input
cow_x_scale : float;
cow_y_scale : float;
hovering_header : bool = false;

cow_state: Cow_State = .NONE;

hovered_box_index : s64 = -1;
held_box_index : s64 = -1;
edited_box_index : s64 = -1;

// @NOTE maybe move this to draw.jai
cow_input :: () {
    if #complete cow_state == {
        case .NONE;
            if hovered_box_index != -1 {
                cow_state = .HOVERING_EDITOR;
                cow_input();
            } else if mouse.middle.just_pressed || mouse.left.just_pressed {
                cow_state = .DRAGGING_CAMERA;
                cow_input();
            }
        case .HOVERING_EDITOR;
            if hovered_box_index == -1 {
                cow_state = .NONE;
                cow_input();
            } else {
                // make the clicked box last in array so it gets rendered on top of others
                if mouse.left.just_pressed {
                    box := cow_boxes[hovered_box_index];
                    array_ordered_remove_by_index(*cow_boxes, hovered_box_index);
                    array_add(*cow_boxes, box);
                    hovered_box_index = cow_boxes.count - 1;
                }
                if mouse.left.just_double_clicked {
                    if hovering_header == false {
                        make_editor_active(cow_boxes[hovered_box_index].editor_id);
                        edited_box_index = hovered_box_index;
                        cow_state = .EDITING;
                        cow_input();
                    } else {
                        cow_close();
                        editors_open_file(cow_boxes[hovered_box_index].file_path, .in_place);
                        editor := *open_editors[editors.active];
                        viewport := *editor.viewport;
                        // the 0.5 is to hide any part of the start-1 line
                        start_animation(*viewport.scroll_y, viewport.top, xx ((cow_boxes[hovered_box_index].start_line+.5) * line_height));
                    }
                } else if mouse.left.just_pressed {
                    held_box_index = hovered_box_index;
                    cow_state = .DRAGGING_EDITOR;
                    cow_input();
                } else if mouse.middle.just_pressed {
                    cow_state = .DRAGGING_CAMERA;
                    cow_input();
                }
            }
        case .DRAGGING_CAMERA;
            if mouse.middle.just_released || mouse.left.just_released {
                cow_state = .NONE;
                cow_input();
            } else if mouse.left.is_dragging || mouse.middle.is_dragging {
                cow_camera.position.x -= mouse.delta.x;
                cow_camera.position.y -= mouse.delta.y;
            }
        case .DRAGGING_EDITOR;
            if mouse.left.just_released {
                cow_state = .NONE;
                cow_input();
            } else if mouse.left.is_dragging {
                cow_boxes[held_box_index].rect.x += mouse.delta.x / cow_x_scale;
                cow_boxes[held_box_index].rect.y += mouse.delta.y / cow_y_scale;
            }
        case .EDITING;
            if hovered_box_index != edited_box_index {
                if mouse.left.just_pressed {
                    make_editor_active(-1);
                    cow_state = .NONE;
                    cow_input();
                }
            }
    }
}
// cow 6
