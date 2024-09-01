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

init_cow_editors_hardcoded :: () {
    b1 : Cow_Box = .{
        name = "Cow Rendering",
        file_path = "c:/dev/focus/src/draw.jai",
        start_line = 245,
        end_line = 264,
        rect = .{100, 100, 500, 1000},
        editor_id = 0, // TODO: actually open an editor for each box
    };
    b2 : Cow_Box = .{
        name = "Welcome Screen Rendeing ",
        file_path = "c:/dev/focus/src/draw.jai",
        start_line = 98,
        end_line = 243,
        rect = .{700, 100, 500, 1000},
        editor_id = 1, // TODO: actually open an editor for each box
    };    
    array_add(*cow_boxes, b1);
    array_add(*cow_boxes, b2);
}

toggle_cow :: () {
    if editors.layout != .Cow {
        old_layout = editors.layout;
        editors.layout = .Cow;
    } else {
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