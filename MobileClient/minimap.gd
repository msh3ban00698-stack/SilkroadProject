class_name MinimapView
extends Control

var player_position := Vector3.ZERO
var landmarks: Array[Vector2] = [Vector2(0.62, 0.26), Vector2(0.35, 0.66), Vector2(0.76, 0.72)]

func set_player_position(position: Vector3) -> void:
    player_position = position
    queue_redraw()

func _draw() -> void:
    var r := Rect2(Vector2(8, 8), size - Vector2(16, 16))
    draw_style_box(_box(Color(0.03, 0.06, 0.13, 0.88), Color(0.38, 0.62, 0.88, 0.8), 14), r)
    var inner := r.grow(-12)
    draw_rect(inner, Color(0.08, 0.18, 0.21, 0.75), true)
    for i in range(1, 5):
        var x: float = lerpf(inner.position.x, inner.end.x, float(i) / 5.0)
        var y: float = lerpf(inner.position.y, inner.end.y, float(i) / 5.0)
        draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), Color(0.35, 0.62, 0.55, 0.22), 1.0)
        draw_line(Vector2(inner.position.x, y), Vector2(inner.end.x, y), Color(0.35, 0.62, 0.55, 0.22), 1.0)
    for landmark in landmarks:
        var p := Vector2(lerpf(inner.position.x, inner.end.x, landmark.x), lerpf(inner.position.y, inner.end.y, landmark.y))
        draw_circle(p, 5.0, Color("#f2c66d"))
    var player_uv := Vector2(0.5 + clamp(player_position.x / 80.0, -0.38, 0.38), 0.5 + clamp(player_position.z / 80.0, -0.38, 0.38))
    var player_p := Vector2(lerpf(inner.position.x, inner.end.x, player_uv.x), lerpf(inner.position.y, inner.end.y, player_uv.y))
    draw_circle(player_p, 8.0, Color("#68d7ff"))
    draw_circle(player_p, 13.0, Color(0.41, 0.84, 1.0, 0.22))

func _box(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = fill
    box.border_color = border
    box.set_border_width_all(2)
    box.set_corner_radius_all(radius)
    return box
