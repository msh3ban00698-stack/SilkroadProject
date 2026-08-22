class_name VirtualJoystick
extends Control

@export var radius := 140.0
@export var knob_radius := 52.0
var finger_id := -1
var value := Vector2.ZERO
var base_center := Vector2.ZERO
var knob_center := Vector2.ZERO

func _ready() -> void:
    custom_minimum_size = Vector2(radius * 2.6, radius * 2.6)
    mouse_filter = Control.MOUSE_FILTER_STOP
    queue_redraw()

func get_value() -> Vector2:
    return value

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and finger_id == -1:
            finger_id = event.index
            base_center = event.position
            knob_center = event.position
            value = Vector2.ZERO
            queue_redraw()
        elif not event.pressed and event.index == finger_id:
            finger_id = -1
            value = Vector2.ZERO
            queue_redraw()
    elif event is InputEventScreenDrag and event.index == finger_id:
        var delta: Vector2 = event.position - base_center
        value = delta.limit_length(radius) / radius
        knob_center = base_center + value * radius
        queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    if finger_id == -1:
        base_center = center
        knob_center = center
    draw_circle(base_center, radius + 8.0, Color(0.04, 0.07, 0.14, 0.42))
    draw_arc(base_center, radius, 0, TAU, 48, Color(0.43, 0.67, 0.92, 0.65), 3.0)
    draw_circle(knob_center, knob_radius + 5.0, Color(0.08, 0.16, 0.29, 0.8))
    draw_circle(knob_center, knob_radius, Color(0.36, 0.68, 0.95, 0.92))
