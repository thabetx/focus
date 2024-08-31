old_layout : Editor_State.Layout = .None;
Cow_Camera :: struct {
    position : Vector2 = .{20, 100};
    zoom: float;
    move_speed: float = 20;
    zoom_speed: float = 20;
}
cow_camera : Cow_Camera;

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