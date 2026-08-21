class_name DropItem3D
extends Area3D

signal pickup_requested(unique_id: int)

var unique_id := 0
var item_id := 0
var item_name := "Loot"
var mesh_visual: MeshInstance3D
var glow: OmniLight3D

func _ready() -> void:
    input_ray_pickable = true
    input_event.connect(_on_input_event)
    _build_visual()

func configure(data: Dictionary) -> void:
    unique_id = int(data.get("unique_id", 0))
    item_id = int(data.get("model", 0))
    item_name = str(data.get("name", "Loot"))
    var spawn_position: Vector3 = data.get("position", Vector3.ZERO) + Vector3(0, 0.3, 0)
    if is_inside_tree():
        global_position = spawn_position
    else:
        position = spawn_position

func _process(delta: float) -> void:
    if mesh_visual:
        mesh_visual.rotation.y += delta * 1.8
        mesh_visual.position.y = 0.28 + sin(Time.get_ticks_msec() / 220.0) * 0.06
    if glow:
        glow.light_energy = 1.1 + sin(Time.get_ticks_msec() / 180.0) * 0.35

func _build_visual() -> void:
    var collider := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = 0.45
    collider.shape = shape
    collider.position.y = 0.28
    add_child(collider)
    mesh_visual = MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.42, 0.42, 0.42)
    mesh_visual.mesh = mesh
    mesh_visual.position.y = 0.28
    mesh_visual.material_override = _material(Color("#f2c66d"), 0.78, 0.16)
    add_child(mesh_visual)
    glow = OmniLight3D.new()
    glow.position.y = 0.3
    glow.light_color = Color("#ffd36b")
    glow.light_energy = 1.2
    glow.omni_range = 3.5
    add_child(glow)

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
    if event is InputEventScreenTouch and event.pressed:
        pickup_requested.emit(unique_id)
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        pickup_requested.emit(unique_id)

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    return material
