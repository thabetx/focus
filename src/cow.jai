old_layout : Editor_State.Layout = .None;
Cow_Camera :: struct {
    position : Vector2 = .{20, 100};
    zoom: float;
    move_speed: float = 20;
    zoom_speed: float = 20;
}
cow_camera : Cow_Camera;

Cow_Box :: struct {
    name: string;
    file_path: string;
    start_line: int;
    end_line: int;
    rect: Rect; // maybe turn this into Vector2; width is max line width, height is line_end-line_start
    editor_id: s64;
}
cow_boxes: [..] Cow_Box;
inited := false;

init_cow_editors_hardcoded :: () #expand {
    b1 : Cow_Box = .{
        name = "Cow Rendering",
        file_path = "c:/dev/focus/src/draw.jai",
        start_line = 244,
        end_line = 261,
        rect = .{100, 100, 500, 500},
        editor_id = 1, // TODO: actually open an editor for each box
    };
    b2 : Cow_Box = .{
        name = "Cow Init",
        file_path = "c:/dev/focus/src/cow.jai",
        start_line = 21,
        end_line = 56,
        rect = .{700, 100, 500, 500},
        editor_id = 2, // TODO: actually open an editor for each box
    };

    editors_open_file(b1.file_path, .floating);
    editors_open_file(b2.file_path, .floating);

    array_add(*cow_boxes, b1);
    array_add(*cow_boxes, b2);
    
    for *cow_boxes {
        editor := *open_editors[it.editor_id];
        it.rect.h = xx ((it.end_line-it.start_line+2) * 20);
        // editor.viewport.top = xx (it.start_line * 20);
        
        // cursor := leave_only_original_cursor(editor);
        // editor.cursor_moved = .jumped;
        // editor.scroll_to_cursor = .yes;
        viewport := *editor.viewport;
        start_animation(*viewport.scroll_y, viewport.top, xx ((it.start_line-1) * 20));
        // @COW move the cursor as well for that editor
    }
}

cow_open :: () {
    if inited == false {
        inited = true;
        init_cow_editors_hardcoded();
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