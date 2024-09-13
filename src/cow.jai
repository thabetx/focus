// cow 3 The COW State
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

cow_canvas_filepath :: "cow.txt";
cow_state_filepath :: "cow_state.txt";

// cow 1 Serializing and scanning the boxes
cow_save :: () {
    builder: String_Builder;
    builder.allocator = temp;
    init_string_builder(*builder);
    for cow_boxes print_to_builder(*builder, "% % %\n", it.id, cast(int)it.rect.x, cast(int)it.rect.y);
    write_entire_file(cow_canvas_filepath, builder_to_string(*builder));
    
    {
        builder: String_Builder;
        builder.allocator = temp;
        init_string_builder(*builder);
        print_to_builder(*builder, "% % %", cast(int)cow_camera.position.x, cast(int)cow_camera.position.y, cast(int)cow_camera.zoom);
        write_entire_file(cow_state_filepath, builder_to_string(*builder));
    }
}

cow_load :: () {
    canvas_text := read_entire_file(cow_canvas_filepath,, temp);
    lines := split(canvas_text, "\n",, allocator = temp);
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

    {
        state_text := read_entire_file(cow_state_filepath,, temp);
        x, y, zoom : int;
        ok := scan2(state_text, "% % %", *x, *y, *zoom);
        if ok {
            cow_camera.position = .{xx x, xx y};
            cow_camera.zoom = xx zoom;
        }
    }
}

cow_scan :: () {
    file_paths := string.[
        "c:/dev/focus/src/cow.jai",
        "c:/dev/focus/src/draw.jai",
    ];
    
    for file_path :file_paths {
        cow_code_file := read_entire_file(file_path,, temp);
        lines := split(cow_code_file, "\n",, allocator = temp);
        for line: lines {
            trimmed := trim_left(line);
            if begins_with(trimmed, "// cow") == false continue;
            advance(*trimmed, 6);
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
                box.file_path = file_path;
                array_add(*cow_boxes, box);
            }
        }
    }
}
// cow 1

// cow 2 COW Commands
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
            it.editor_id = find_or_create_editor2(buffer_id);
            editor := *open_editors[it.editor_id];
            viewport := *editor.viewport;
            // the 0.5 is to hide any part of the start-1 line
            start_animation(*viewport.scroll_y, viewport.top, xx ((it.start_line+.5) * line_height));
        }
    }
    inited = true;

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

state: Cow_State = .NONE;

hovered_box_index : s64 = -1;
held_box_index : s64 = -1;
edited_box_index : s64 = -1;
hovering_header : bool = false;

y_scale : float;
x_scale : float;

// cow 5 Rendering
draw_cow :: (main_area: Rect) {
    // @hack
    cow_camera.zoom = xx font_size;
    
    draw_rect(main_area, Color.BACKGROUND_4);
    y_scale = line_height;
    x_scale = char_size;
    expanded_rect_padding_x : float = .6*x_scale;
    expanded_rect_padding_y : float = .6*y_scale;
    text_padding := x_scale;

    hovering_header = false;
    hovered_box_index = -1;

    for *cow_boxes {
        world_rect := it.rect;
        world_rect.x *= x_scale;
        world_rect.y *= y_scale;
        world_rect.w *= x_scale;
        world_rect.h *= y_scale;
        world_rect.x -= cow_camera.position.x;
        world_rect.y -= cow_camera.position.y;
        
        header_rect := world_rect;
        header_rect.h = 2*y_scale;
        header_rect.y = world_rect.y + world_rect.h;
        
        expanded_rect := world_rect;
        expanded_rect.w += expanded_rect_padding_x;
        expanded_rect.h = world_rect.h + header_rect.h + expanded_rect_padding_y;
        expanded_rect.x -= expanded_rect_padding_x/2;
        expanded_rect.y -= expanded_rect_padding_y/2;
        
        all_rect := world_rect;
        all_rect.h = world_rect.h + header_rect.h;
        
        if mouse_pointer_is_within(header_rect) hovering_header = true;
        if mouse_pointer_is_within(expanded_rect) hovered_box_index = it_index;

        draw_rounded_rect_with_shadow(all_rect, Color.BACKGROUND_4);
        if editors.active == it.editor_id draw_rounded_rect(expanded_rect, Color.UI_WARNING);
        draw_rect(header_rect, Color.SELECTION_ACTIVE);
        draw_editor(it.editor_id, world_rect, 0, xx it.editor_id, .{}, editors.active != it.editor_id);
        {
            editor := *open_editors[it.editor_id];
            buffer := *open_buffers[editor.buffer_id];
            width := Simp.prepare_text(font_ui_medium, it.name);
            Simp.draw_prepared_text(font_ui_medium, xx (header_rect.x + text_padding), xx (header_rect.y + text_padding), color = xx Color.UI_DEFAULT);
            Simp.prepare_text(font_ui_small, get_buffer_name(buffer));
            Simp.draw_prepared_text(font_ui_small, xx (header_rect.x + width + 2 * text_padding), xx (header_rect.y + text_padding), color = xx Color.UI_DEFAULT);
            // draw_file_info(buffer, 0, 0, .{header_rect.x+width+20, header_rect.y + 10});
        }
    }
    
    Simp.prepare_text(font_ui_big, tprint("state: %", state));
    Simp.draw_prepared_text(font_ui_big, 10, 10, color = xx Color.UI_DIM);
    
    do_input :: () {
        if #complete state == {
            case .NONE;
                if hovered_box_index != -1 {
                    state = .HOVERING_EDITOR;
                    do_input();
                } else if mouse.middle.just_pressed || mouse.left.just_pressed {
                    state = .DRAGGING_CAMERA;
                    do_input();
                }
            case .HOVERING_EDITOR;
                if hovered_box_index == -1 {
                    state = .NONE;
                    do_input();
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
                        state = .EDITING;
                        do_input();
                    } else {
                        cow_close();
                        // buffer_id := find_or_create_buffer(cow_boxes[hovered_box_index].file_path);
                        // editor_id := find_or_create_editor(buffer_id);
                        // editor := *open_editors[editor_id];
                        // viewport := *editor.viewport;
                        // // the 0.5 is to hide any part of the start-1 line
                            // start_animation(*viewport.scroll_y, viewport.top, xx ((cow_boxes[hovered_box_index].start_line+.5) * line_height));
                            // make_editor_active(editor_id);
                        }                    
                    } else if mouse.left.just_pressed {
                        held_box_index = hovered_box_index;
                        state = .DRAGGING_EDITOR;
                        do_input();
                    } else if mouse.middle.just_pressed {
                        state = .DRAGGING_CAMERA;
                        do_input();
                    }
                }
            case .DRAGGING_CAMERA;
                if mouse.middle.just_released || mouse.left.just_released {
                    state = .NONE;
                    do_input();
                } else if mouse.left.is_dragging || mouse.middle.is_dragging {
                    cow_camera.position.x -= mouse.delta.x;
                    cow_camera.position.y -= mouse.delta.y;
                }
            case .DRAGGING_EDITOR;
                if mouse.left.just_released {
                    state = .NONE;
                    do_input();
                } else if mouse.left.is_dragging {
                    cow_boxes[held_box_index].rect.x += mouse.delta.x / x_scale;
                    cow_boxes[held_box_index].rect.y += mouse.delta.y / y_scale;
                }
            case .EDITING;
                if hovered_box_index != edited_box_index {
                    if mouse.left.just_pressed {
                        make_editor_active(-1);
                        state = .NONE;
                        do_input();
                    }
                }
        }
    }
    do_input();
}
// cow 5

