class_name HumanoidModel
extends Node3D

var build_id := "spear"
var weapon_style := "spear"
var race_name := "Chinese"
var outfit_name := "Jade War Robe"
var skeleton: Skeleton3D
var bones: Dictionary = {}
var animation_state := "idle"
var animation_time := 0.0
var attack_time := 0.0

func configure_build(data: Dictionary) -> void:
    build_id = str(data.get("class_id", data.get("build", "spear"))).to_lower()
    weapon_style = "wizard" if build_id in ["wizard", "european_wizard", "staff"] else "spear"
    race_name = str(data.get("race", "Chinese"))
    outfit_name = str(data.get("outfit", "Jade War Robe"))
    for child in get_children():
        remove_child(child)
        child.free()
    bones.clear()
    _build_rig()

func _process(delta: float) -> void:
    animation_time += delta
    if attack_time > 0.0:
        attack_time = max(0.0, attack_time - delta)
        _pose_attack(1.0 - attack_time / 0.62)
    elif animation_state == "walk":
        _pose_walk()
    else:
        _pose_idle()

func set_animation_state(state: String) -> void:
    animation_state = state

func play_attack() -> void:
    attack_time = 0.62

func _build_rig() -> void:
    skeleton = Skeleton3D.new()
    skeleton.name = "HumanoidSkeleton"
    add_child(skeleton)
    _bone("root", -1, Vector3(0, 0, 0))
    _bone("pelvis", bones["root"], Vector3(0, 0.78, 0))
    _bone("spine", bones["pelvis"], Vector3(0, 0.42, 0))
    _bone("chest", bones["spine"], Vector3(0, 0.42, 0))
    _bone("neck", bones["chest"], Vector3(0, 0.38, 0))
    _bone("head", bones["neck"], Vector3(0, 0.2, 0))
    _bone("upper_arm_l", bones["chest"], Vector3(-0.46, 0.28, 0))
    _bone("lower_arm_l", bones["upper_arm_l"], Vector3(0, -0.42, 0))
    _bone("hand_l", bones["lower_arm_l"], Vector3(0, -0.38, 0))
    _bone("upper_arm_r", bones["chest"], Vector3(0.46, 0.28, 0))
    _bone("lower_arm_r", bones["upper_arm_r"], Vector3(0, -0.42, 0))
    _bone("hand_r", bones["lower_arm_r"], Vector3(0, -0.38, 0))
    _bone("thigh_l", bones["pelvis"], Vector3(-0.2, -0.03, 0))
    _bone("shin_l", bones["thigh_l"], Vector3(0, -0.48, 0))
    _bone("foot_l", bones["shin_l"], Vector3(0, -0.42, -0.12))
    _bone("thigh_r", bones["pelvis"], Vector3(0.2, -0.03, 0))
    _bone("shin_r", bones["thigh_r"], Vector3(0, -0.48, 0))
    _bone("foot_r", bones["shin_r"], Vector3(0, -0.42, -0.12))

    var skin := Color("#c98968") if race_name.to_lower().contains("european") else Color("#d49a75")
    var cloth := Color("#4b70b5") if weapon_style == "wizard" else Color("#2f8a75")
    var trim := Color("#d9b05e")
    var dark := Color("#1b263f")
    _attach_box("pelvis", Vector3(0.58, 0.32, 0.42), Vector3(0, -0.14, 0), cloth)
    if weapon_style == "wizard":
        _attach_robe("spine", cloth, trim)
    else:
        _attach_box("chest", Vector3(0.78, 0.78, 0.48), Vector3(0, -0.22, 0), cloth)
        _attach_box("chest", Vector3(0.82, 0.08, 0.52), Vector3(0, -0.47, -0.01), trim)
        _attach_box("chest", Vector3(0.08, 0.7, 0.06), Vector3(0, -0.22, -0.27), trim)
    _attach_limb("upper_arm_l", skin)
    _attach_limb("lower_arm_l", skin)
    _attach_limb("upper_arm_r", skin)
    _attach_limb("lower_arm_r", skin)
    _attach_limb("thigh_l", dark if weapon_style == "wizard" else Color("#5a3c32"))
    _attach_limb("shin_l", dark if weapon_style == "wizard" else Color("#5a3c32"))
    _attach_limb("thigh_r", dark if weapon_style == "wizard" else Color("#5a3c32"))
    _attach_limb("shin_r", dark if weapon_style == "wizard" else Color("#5a3c32"))
    _attach_box("foot_l", Vector3(0.32, 0.14, 0.46), Vector3(0, -0.06, -0.12), dark)
    _attach_box("foot_r", Vector3(0.32, 0.14, 0.46), Vector3(0, -0.06, -0.12), dark)
    _attach_sphere("head", 0.34, 0.68, Vector3(0, 0.05, 0), skin, Vector3(1.0, 1.08, 0.92))
    _attach_sphere("head", 0.36, 0.22, Vector3(0, 0.31, 0.02), dark if weapon_style == "wizard" else Color("#2d1f22"), Vector3(1.0, 0.55, 1.0))
    _attach_sphere("head", 0.045, 0.09, Vector3(-0.13, 0.08, -0.31), Color("#f6d889"), Vector3.ONE, true)
    _attach_sphere("head", 0.045, 0.09, Vector3(0.13, 0.08, -0.31), Color("#f6d889"), Vector3.ONE, true)
    if weapon_style == "wizard":
        _build_staff(trim)
    else:
        _build_spear(trim)

func _bone(name: String, parent: int, position: Vector3) -> void:
    var index := skeleton.get_bone_count()
    skeleton.add_bone(name)
    skeleton.set_bone_parent(index, parent)
    skeleton.set_bone_rest(index, Transform3D(Basis.IDENTITY, position))
    bones[name] = index

func _attachment(bone_name: String) -> BoneAttachment3D:
    var attachment := BoneAttachment3D.new()
    attachment.name = "%s_Attachment" % bone_name
    attachment.bone_name = bone_name
    skeleton.add_child(attachment)
    return attachment

func _attach_box(bone_name: String, size: Vector3, position: Vector3, color: Color) -> void:
    var mesh := BoxMesh.new()
    mesh.size = size
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = position
    node.material_override = _material(color, 0.12, 0.68)
    _attachment(bone_name).add_child(node)

func _attach_robe(bone_name: String, color: Color, accent: Color) -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.36
    mesh.bottom_radius = 0.62
    mesh.height = 1.12
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = Vector3(0, -0.32, 0)
    node.material_override = _material(color, 0.1, 0.72)
    var attachment := _attachment(bone_name)
    attachment.add_child(node)
    var belt_mesh := TorusMesh.new()
    belt_mesh.inner_radius = 0.47
    belt_mesh.outer_radius = 0.52
    var belt := MeshInstance3D.new()
    belt.mesh = belt_mesh
    belt.position = Vector3(0, -0.1, 0)
    belt.material_override = _material(accent, 0.5, 0.2, true)
    attachment.add_child(belt)

func _attach_limb(bone_name: String, color: Color) -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.115
    mesh.bottom_radius = 0.14
    mesh.height = 0.42
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position.y = -0.21
    node.material_override = _material(color, 0.05, 0.8)
    _attachment(bone_name).add_child(node)

func _attach_sphere(bone_name: String, radius: float, height: float, position: Vector3, color: Color, scale_value: Vector3, glow := false) -> void:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = height
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = position
    node.scale = scale_value
    node.material_override = _material(color, 0.08, 0.32, glow)
    _attachment(bone_name).add_child(node)

func _build_staff(accent: Color) -> void:
    var attachment := _attachment("hand_r")
    var shaft := CylinderMesh.new()
    shaft.top_radius = 0.045
    shaft.bottom_radius = 0.06
    shaft.height = 1.8
    var shaft_node := MeshInstance3D.new()
    shaft_node.mesh = shaft
    shaft_node.position = Vector3(0, 0.84, 0)
    shaft_node.rotation_degrees = Vector3(0, 0, -7)
    shaft_node.material_override = _material(Color("#6e4932"), 0.0, 0.78)
    attachment.add_child(shaft_node)
    _attach_weapon_sphere(attachment, Vector3(-0.13, 1.72, 0), Color("#9be7ff"))
    var ring := TorusMesh.new()
    ring.inner_radius = 0.19
    ring.outer_radius = 0.23
    var ring_node := MeshInstance3D.new()
    ring_node.mesh = ring
    ring_node.position = Vector3(-0.13, 1.72, 0)
    ring_node.material_override = _material(accent, 0.55, 0.18, true)
    attachment.add_child(ring_node)

func _build_spear(accent: Color) -> void:
    var attachment := _attachment("hand_r")
    var shaft := CylinderMesh.new()
    shaft.top_radius = 0.035
    shaft.bottom_radius = 0.05
    shaft.height = 2.35
    var shaft_node := MeshInstance3D.new()
    shaft_node.mesh = shaft
    shaft_node.position = Vector3(0, 1.05, 0)
    shaft_node.rotation_degrees = Vector3(0, 0, -7)
    shaft_node.material_override = _material(Color("#70462f"), 0.0, 0.82)
    attachment.add_child(shaft_node)
    var blade := CylinderMesh.new()
    blade.top_radius = 0.0
    blade.bottom_radius = 0.16
    blade.height = 0.58
    var blade_node := MeshInstance3D.new()
    blade_node.mesh = blade
    blade_node.position = Vector3(-0.2, 2.32, 0)
    blade_node.rotation_degrees = Vector3(180, 0, -5)
    blade_node.material_override = _material(accent, 0.55, 0.18, true)
    attachment.add_child(blade_node)

func _attach_weapon_sphere(attachment: BoneAttachment3D, position: Vector3, color: Color) -> void:
    var mesh := SphereMesh.new()
    mesh.radius = 0.18
    mesh.height = 0.36
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = position
    node.material_override = _material(color, 0.08, 0.2, true)
    attachment.add_child(node)

func _pose_idle() -> void:
    var sway := sin(animation_time * 1.6) * 0.025
    _rotate_bone("spine", Vector3(0, sway, 0))
    _rotate_bone("upper_arm_l", Vector3(0, 0, -0.04))
    _rotate_bone("upper_arm_r", Vector3(0, 0, 0.04))

func _pose_walk() -> void:
    var stride := sin(animation_time * 8.0) * 0.38
    _rotate_bone("thigh_l", Vector3(stride, 0, 0))
    _rotate_bone("thigh_r", Vector3(-stride, 0, 0))
    _rotate_bone("upper_arm_l", Vector3(-stride * 0.55, 0, 0))
    _rotate_bone("upper_arm_r", Vector3(stride * 0.55, 0, 0))

func _pose_attack(progress: float) -> void:
    var swing := sin(progress * PI)
    if weapon_style == "wizard":
        _rotate_bone("upper_arm_r", Vector3(-1.0 - swing * 0.55, 0, -0.18))
        _rotate_bone("lower_arm_r", Vector3(-0.7 - swing * 0.35, 0, 0))
        _rotate_bone("spine", Vector3(-0.1 * swing, 0, 0))
    else:
        _rotate_bone("upper_arm_r", Vector3(-0.65 + swing * 1.1, 0, -0.2))
        _rotate_bone("lower_arm_r", Vector3(-0.55 + swing * 0.75, 0, 0))
        _rotate_bone("spine", Vector3(0, -0.2 * swing, 0))

func _rotate_bone(name: String, euler: Vector3) -> void:
    if bones.has(name):
        skeleton.set_bone_pose_rotation(bones[name], Quaternion.from_euler(euler))

func _material(color: Color, metallic: float, roughness: float, glow := false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    if glow:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 3.6
    return material
