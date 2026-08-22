class_name MonsterMob
extends Area3D

signal targeted(unique_id: int)

var unique_id := 0
var model_id := 0
var monster_name := "Mangyang"
var hp := 100
var max_hp := 100
var rarity := 0
var selected := false
var local_demo := false
var body_visual
var target_ring: MeshInstance3D
var health_bar: ProgressBar
var health_label: Label
var destination := Vector3.ZERO
var moving := false
var move_tween: Tween
var defeated := false
var ai_phase := 0.0
var home_position := Vector3.ZERO

func _ready() -> void:
    input_ray_pickable = true
    input_event.connect(_on_input_event)
    _build_visual()

func configure(data: Dictionary) -> void:
    unique_id = int(data.get("unique_id", 0))
    model_id = int(data.get("model", 0))
    monster_name = str(data.get("name", "Mangyang"))
    hp = int(data.get("hp", 100))
    max_hp = max(1, int(data.get("max_hp", max(hp, 100))))
    rarity = int(data.get("rarity", 0))
    var spawn_position: Vector3 = data.get("position", Vector3.ZERO)
    if is_inside_tree():
        global_position = spawn_position
        _refresh_hp()
    else:
        position = spawn_position

func configure_demo(demo_id: int, position: Vector3) -> void:
    unique_id = demo_id
    model_id = 1
    monster_name = "Mangyang Scout"
    hp = 120
    max_hp = 120
    local_demo = true
    home_position = position
    ai_phase = float(demo_id % 17) * 0.37
    if is_inside_tree():
        global_position = position
    else:
        self.position = position

func _build_visual() -> void:
    var collider := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.72
    shape.height = 1.9
    collider.shape = shape
    collider.position.y = 0.9
    add_child(collider)

    body_visual = load("res://animal_mob_model.gd").new()
    body_visual.configure_animal(rarity)
    add_child(body_visual)

    target_ring = MeshInstance3D.new()
    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = 0.82
    ring_mesh.outer_radius = 0.9
    ring_mesh.rings = 32
    target_ring.mesh = ring_mesh
    target_ring.position.y = 0.04
    target_ring.material_override = _material(Color("#f2c66d"), 0.15, 0.22)
    target_ring.visible = false
    add_child(target_ring)

    var bar_root := Control.new()
    bar_root.position = Vector2(-78, -116)
    bar_root.custom_minimum_size = Vector2(156, 42)
    bar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bar_root)
    health_bar = ProgressBar.new()
    health_bar.max_value = max_hp
    health_bar.value = hp
    health_bar.show_percentage = false
    health_bar.custom_minimum_size = Vector2(156, 17)
    health_bar.add_theme_stylebox_override("background", _bar_style(Color("#2a1520")))
    health_bar.add_theme_stylebox_override("fill", _bar_style(Color("#d94f5c")))
    bar_root.add_child(health_bar)
    health_label = Label.new()
    health_label.text = monster_name
    health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    health_label.position = Vector2(0, -25)
    health_label.size = Vector2(156, 24)
    health_label.add_theme_font_size_override("font_size", 12)
    health_label.add_theme_color_override("font_color", Color("#f3d6a2"))
    bar_root.add_child(health_label)

func play_defeat() -> void:
    if defeated:
        return
    defeated = true
    input_ray_pickable = false
    if move_tween:
        move_tween.kill()
    var tween := create_tween().set_parallel(true)
    tween.tween_property(self, "scale", Vector3(0.18, 0.08, 0.18), 0.78).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
    tween.tween_property(self, "rotation:y", rotation.y + PI * 1.8, 0.78).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tween.tween_property(target_ring, "scale", Vector3.ONE * 2.4, 0.5)

func set_targeted(value: bool) -> void:
    selected = value
    if target_ring:
        target_ring.visible = value

func set_hp(current: int, maximum: int = -1) -> void:
    hp = max(0, current)
    if maximum > 0:
        max_hp = maximum
    _refresh_hp()

func _process(_delta: float) -> void:
    if body_visual and body_visual.has_method("set_animation_state"):
        if defeated:
            body_visual.set_animation_state("idle")
        elif moving or local_demo:
            body_visual.set_animation_state("walk")
        else:
            body_visual.set_animation_state("idle")

func apply_damage(damage: int) -> void:
    set_hp(hp - damage)
    if body_visual and body_visual.has_method("play_attack"):
        body_visual.play_attack()

func simulate_local_ai(delta: float, elapsed: float) -> void:
    if not local_demo or defeated:
        return
    ai_phase += delta * (0.45 + float(rarity) * 0.08)
    var patrol := Vector3(sin(elapsed * 0.55 + ai_phase) * 1.8, 0, cos(elapsed * 0.42 + ai_phase) * 1.2)
    var next_position := home_position + patrol
    global_position = global_position.lerp(next_position, clamp(delta * 2.4, 0.0, 1.0))
    rotation.y = lerp_angle(rotation.y, atan2(patrol.x, patrol.z), clamp(delta * 3.0, 0.0, 1.0))

func apply_movement(movement: Dictionary) -> void:
    if movement.get("mode", 0) == 1:
        destination = movement.get("destination", global_position)
        moving = true
        if move_tween:
            move_tween.kill()
        var distance := global_position.distance_to(destination)
        move_tween = create_tween()
        move_tween.tween_property(self, "global_position", destination, max(0.2, distance / 3.5))
        move_tween.finished.connect(func(): moving = false)
    else:
        global_position = movement.get("position", global_position)
        rotation.y = float(movement.get("angle", 0)) / 182.0 * PI / 180.0

func _refresh_hp() -> void:
    if health_bar:
        health_bar.max_value = max_hp
        health_bar.value = hp
    if health_label:
        health_label.text = "%s  %d/%d" % [monster_name, hp, max_hp]

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
    if event is InputEventScreenTouch and event.pressed:
        targeted.emit(unique_id)
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        targeted.emit(unique_id)

func _bar_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(5)
    return style

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    return material
