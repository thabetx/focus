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
        end_line = 271,
        rect = .{650, 0, 500, 500},
    };
    b2 : Cow_Box = .{
        name = "Cow Init",
        file_path = "c:/dev/focus/src/cow.jai",
        start_line = 36,
        end_line = 74,
        rect = .{100, 200, 500, 500},
    };
    b3 : Cow_Box = .{
        name = "Cow Input",
        file_path = "c:/dev/focus/src/cow.jai",
        start_line = 76,
        end_line = 109,
        rect = .{650, 620, 500, 500},
    };

    array_add(*cow_boxes, b1);
    array_add(*cow_boxes, b2);
    array_add(*cow_boxes, b3);
    
    for *cow_boxes {
        buffer_id := find_or_create_buffer(it.file_path);
        created: bool;
        it.editor_id, created = find_or_create_editor2(buffer_id);
        it.rect.h = xx ((it.end_line-it.start_line+2) * 20);

        editor := *open_editors[it.editor_id];

        viewport := *editor.viewport;
        start_animation(*viewport.scroll_y, viewport.top, xx ((it.start_line-1) * 20));
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