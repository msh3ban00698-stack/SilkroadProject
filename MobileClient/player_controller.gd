class_name MobilePlayer
extends CharacterBody3D

signal movement_changed(position: Vector3)

var input_vector := Vector2.ZERO
var move_speed := 4.6
var joystick: Control
var camera_rig: SpringArm3D
var visual
var weapon_style := "spear"
var build_id := "spear"
var yaw := 0.0

func _ready() -> void:
    _build_body()
    _build_camera()
    floor_snap_length = 0.35
    motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED

func _build_body() -> void:
    var collider := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.38
    shape.height = 1.65
    collider.shape = shape
    collider.position.y = 0.86
    add_child(collider)

    visual = load("res://humanoid_model.gd").new()
    visual.configure_build({"class_id": "spear", "race": "Chinese", "outfit": "Jade Armor"})
    add_child(visual)

func _build_camera() -> void:
    camera_rig = SpringArm3D.new()
    camera_rig.name = "CameraRig"
    camera_rig.spring_length = 6.5
    camera_rig.position = Vector3(0, 3.5, 0)
    camera_rig.rotation_degrees.x = -18
    camera_rig.collision_mask = 1
    add_child(camera_rig)
    var camera := Camera3D.new()
    camera.current = true
    camera.fov = 58.0
    camera_rig.add_child(camera)

func configure_build(data: Dictionary) -> void:
    build_id = str(data.get("class_id", data.get("build", "spear"))).to_lower()
    weapon_style = "wizard" if build_id in ["wizard", "european_wizard", "staff"] else "spear"
    if visual:
        visual.configure_build(data)
    move_speed = 4.2 if weapon_style == "wizard" else 4.6

func get_attack_style() -> String:
    return weapon_style

func get_attack_origin() -> Vector3:
    return global_position + Vector3(0, 1.35, -0.55).rotated(Vector3.UP, rotation.y)

func play_attack() -> void:
    if visual:
        visual.play_attack()

func set_joystick(value: Control) -> void:
    joystick = value

func set_input(value: Vector2) -> void:
    input_vector = value.limit_length(1.0)

func _physics_process(_delta: float) -> void:
    if joystick and joystick.has_method("get_value"):
        input_vector = joystick.get_value()
    var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if keyboard.length() > 0.05:
        input_vector = keyboard
    var direction := Vector3(input_vector.x, 0, input_vector.y)
    if direction.length() > 0.05:
        if visual:
            visual.set_animation_state("walk")
        direction = direction.normalized()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        yaw = lerp_angle(yaw, atan2(direction.x, direction.z), 0.18)
        rotation.y = yaw
        movement_changed.emit(global_position)
    else:
        if visual:
            visual.set_animation_state("idle")
        velocity.x = move_toward(velocity.x, 0, move_speed * 8.0 * _delta)
        velocity.z = move_toward(velocity.z, 0, move_speed * 8.0 * _delta)
    if not is_on_floor():
        velocity.y -= 18.0 * _delta
    else:
        velocity.y = -0.2
    move_and_slide()
