// cow 3
// cow 3 The COW State
old_layout : Editor_State.Layout = .None;
Cow_Camera :: struct {
    position : Vector2 = .{20, 100};
    zoom: float;
    move_speed: float = 20;
    zoom_speed: float = 20;
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

// cow 1 Serializing and scanning the boxes
cow_save :: () {
    builder: String_Builder;
    builder.allocator = temp;
    init_string_builder(*builder);
    for cow_boxes print_to_builder(*builder, "% % %\n", it.id, cast(int)it.rect.x, cast(int)it.rect.y);
    write_entire_file("cow.txt", builder_to_string(*builder));
}

cow_load :: () {
    state := read_entire_file("cow.txt",, temp);
    lines := split(state, "\n",, allocator = temp);
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
                for box.start_line..box.end_line {
                    box.rect.w = max(box.rect.w, xx (lines[it].count));
                }
                break;
            }
        if found == false {
            box : Cow_Box;
            box.id = id;
            box.rect.w = 100;
            box.name = copy_string(rem);
            box.start_line = line_number+1;
            box.file_path = file_path;
                array_add(*cow_boxes, box);
            }
        }
    }
    for *cow_boxes {
        buffer_id := find_or_create_buffer(it.file_path);
        it.editor_id = find_or_create_editor2(buffer_id);
        it.rect.h = xx ((it.end_line-it.start_line+3));
        editor := *open_editors[it.editor_id];
        viewport := *editor.viewport;
        start_animation(*viewport.scroll_y, viewport.top, xx ((it.start_line+0.5) * 20));
    }
}
// cow 1

// cow 2 COW Commands
cow_open :: () {
    if inited == false {
        inited = true;
        cow_scan();
        cow_load();
        make_editor_active(-1);        
    }
    if editors.layout != .Cow {
        old_layout = editors.layout;
        editors.layout = .Cow;
    }
}
cow_close :: () {
    if editors.layout == .Cow {
        editors.layout = old_layout;
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
cow_zoom_in :: () {
    cow_camera.zoom += cow_camera.zoom_speed;
}
cow_zoom_out :: () {
    cow_camera.zoom -= cow_camera.zoom_speed;
}
// cow 2
