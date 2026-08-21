class_name HumanoidModel
extends Node3D

var build_id := "spear"
var weapon_style := "spear"
var race_name := "Chinese"
var outfit_name := "Jade War Robe"
var skeleton: Skeleton3D
var bones: Dictionary = {}
var imported_model: Node3D
var weapon_mount: Node3D
var imported_mode := false
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
    if imported_mode:
        _animate_imported_model(delta)
        return
    if attack_time > 0.0:
        attack_time = max(0.0, attack_time - delta)
        _pose_attack(1.0 - attack_time / 0.62)
    elif animation_state == "walk":
        _pose_walk()
    else:
        _pose_idle()

func set_animation_state(state: String) -> void:
    animation_state = state
    if imported_mode:
        _play_imported_animation("run" if state == "walk" else "idle")

func play_attack() -> void:
    if imported_mode:
        _play_imported_animation("attack")
    attack_time = 0.62

func _build_rig() -> void:
    if _build_imported_model():
        return
    _build_procedural_rig()

func _build_imported_model() -> bool:
    var loader_script = load("res://asset_loader.gd")
    if loader_script == null:
        return false
    imported_model = loader_script.instantiate_humanoid()
    if imported_model == null:
        return false
    imported_mode = true
    imported_model.name = "ImportedHumanoid"
    imported_model.scale = Vector3.ONE * 2.0
    add_child(imported_model)
    _tint_imported_model()
    weapon_mount = Node3D.new()
    weapon_mount.name = "WeaponMount"
    weapon_mount.position = Vector3(0.34, 0.64, -0.15)
    weapon_mount.rotation_degrees = Vector3(0, 0, -10)
    imported_model.add_child(weapon_mount)
    var weapon = loader_script.instantiate_weapon(weapon_style)
    weapon.name = "ImportedWeapon"
    weapon.scale = Vector3.ONE * (2.2 if weapon_style == "spear" else 2.0)
    weapon.position = Vector3(0, -0.1, 0)
    weapon_mount.add_child(weapon)
    _tint_weapon(weapon)
    if weapon_style == "wizard":
        var orb := MeshInstance3D.new()
        var orb_mesh := SphereMesh.new()
        orb_mesh.radius = 0.11
        orb_mesh.height = 0.22
        orb.mesh = orb_mesh
        orb.position = Vector3(0, 0.62, 0)
        orb.material_override = _material(Color("#8edbff"), 0.05, 0.16, true)
        weapon_mount.add_child(orb)
    _play_imported_animation("idle")
    return true

func _build_procedural_rig() -> void:
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
    var cloth := Color("#172c58") if weapon_style == "wizard" else Color("#173d3d")
    var trim := Color("#e6c477")
    var dark := Color("#0a1228")
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
    _build_celestial_regalia(cloth, trim, dark)

func _build_celestial_regalia(cloth: Color, trim: Color, dark: Color) -> void:
    var chest_attachment := _attachment("chest")
    for side in [-1.0, 1.0]:
        var pauldron := MeshInstance3D.new()
        var pauldron_mesh := SphereMesh.new()
        pauldron_mesh.radius = 0.24
        pauldron_mesh.height = 0.32
        pauldron_mesh.radial_segments = 24
        pauldron_mesh.rings = 12
        pauldron.mesh = pauldron_mesh
        pauldron.position = Vector3(0.47 * side, -0.02, 0.02)
        pauldron.scale = Vector3(1.3, 0.72, 1.08)
        pauldron.material_override = _material(trim if weapon_style == "spear" else cloth.lightened(0.12), 0.48, 0.22, true)
        chest_attachment.add_child(pauldron)
    var crest := MeshInstance3D.new()
    var crest_mesh := TorusMesh.new()
    crest_mesh.inner_radius = 0.11
    crest_mesh.outer_radius = 0.16
    crest_mesh.rings = 28
    crest_mesh.ring_segments = 14
    crest.mesh = crest_mesh
    crest.position = Vector3(0, -0.08, -0.31)
    crest.rotation_degrees = Vector3(90, 0, 0)
    crest.material_override = _material(trim, 0.62, 0.16, true)
    chest_attachment.add_child(crest)
    var halo := MeshInstance3D.new()
    var halo_mesh := TorusMesh.new()
    halo_mesh.inner_radius = 0.52
    halo_mesh.outer_radius = 0.555
    halo_mesh.rings = 36
    halo_mesh.ring_segments = 18
    halo.mesh = halo_mesh
    halo.position = Vector3(0, 2.22, 0.12)
    halo.rotation_degrees = Vector3(18, 0, 0)
    halo.material_override = _material(Color("#70dfff") if weapon_style == "wizard" else Color("#f0a45e"), 0.38, 0.18, true)
    add_child(halo)
    var aura := GPUParticles3D.new()
    aura.name = "CelestialAura"
    aura.amount = 18
    aura.lifetime = 1.8
    aura.local_coords = true
    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    process.emission_sphere_radius = 0.48
    process.direction = Vector3(0, 1, 0)
    process.spread = 25.0
    process.initial_velocity_min = 0.08
    process.initial_velocity_max = 0.22
    process.gravity = Vector3.ZERO
    process.scale_min = 0.025
    process.scale_max = 0.07
    aura.process_material = process
    var spark_mesh := SphereMesh.new()
    spark_mesh.radius = 0.045
    spark_mesh.height = 0.09
    spark_mesh.radial_segments = 10
    aura.draw_pass_1 = spark_mesh
    aura.draw_pass_1.material = _material(Color("#8defff") if weapon_style == "wizard" else Color("#f2b86d"), 0.2, 0.18, true)
    aura.position.y = 0.8
    add_child(aura)
    if weapon_style == "wizard":
        for side in [-1.0, 1.0]:
            var talisman := MeshInstance3D.new()
            var talisman_mesh := BoxMesh.new()
            talisman_mesh.size = Vector3(0.16, 0.38, 0.025)
            talisman.mesh = talisman_mesh
            talisman.position = Vector3(0.74 * side, 1.72, 0.0)
            talisman.rotation_degrees = Vector3(0, 0, -14.0 * side)
            talisman.material_override = _material(Color("#74e8ff"), 0.1, 0.2, true)
            add_child(talisman)
            var talisman_tween := create_tween().set_loops(6)
            talisman_tween.tween_property(talisman, "position:y", talisman.position.y + 0.12, 1.1).set_trans(Tween.TRANS_SINE)
            talisman_tween.tween_property(talisman, "position:y", talisman.position.y - 0.12, 1.1).set_trans(Tween.TRANS_SINE)
    else:
        var sash := MeshInstance3D.new()
        var sash_mesh := TorusMesh.new()
        sash_mesh.inner_radius = 0.36
        sash_mesh.outer_radius = 0.42
        sash_mesh.rings = 32
        sash_mesh.ring_segments = 16
        sash.mesh = sash_mesh
        sash.position = Vector3(0, 0.75, 0)
        sash.rotation_degrees.x = 90
        sash.material_override = _material(Color("#d46a4f"), 0.14, 0.32, true)
        add_child(sash)

func _tint_imported_model() -> void:
    var skin := Color("#c98968") if race_name.to_lower().contains("european") else Color("#d49a75")
    var cloth := Color("#172c58") if weapon_style == "wizard" else Color("#173d3d")
    for mesh in imported_model.find_children("*", "MeshInstance3D", true, false):
        var source_material = mesh.get_active_material(0)
        if source_material is StandardMaterial3D:
            var material: StandardMaterial3D = source_material.duplicate()
            material.roughness = 0.58 if str(mesh.name).to_lower().contains("cloth") else 0.68
            material.metallic = 0.12 if str(mesh.name).to_lower().contains("armor") else 0.025
            material.clearcoat_enabled = true
            material.clearcoat = 0.18
            material.clearcoat_roughness = 0.32
            mesh.material_override = material
        else:
            var color := skin if str(mesh.name).to_lower().contains("head") else cloth
            mesh.material_override = _material(color, 0.025, 0.68)

func _tint_weapon(weapon: Node3D) -> void:
    var accent := Color("#8edbff") if weapon_style == "wizard" else Color("#e5bb5f")
    for mesh in weapon.find_children("*", "MeshInstance3D", true, false):
        mesh.material_override = _material(accent, 0.55, 0.24, true)

func _animate_imported_model(_delta: float) -> void:
    if not imported_model:
        return
    if attack_time > 0.0:
        attack_time = max(0.0, attack_time - _delta)
        var attack_progress := 1.0 - attack_time / 0.62
        imported_model.rotation.y = sin(attack_progress * PI) * 0.18
        weapon_mount.rotation.z = -0.25 + sin(attack_progress * PI) * 0.9
    else:
        var sway := sin(animation_time * (7.0 if animation_state == "walk" else 1.6)) * (0.07 if animation_state == "walk" else 0.018)
        imported_model.rotation.y = sway
        weapon_mount.rotation.z = -0.18

func _play_imported_animation(preferred: String) -> void:
    if not imported_model:
        return
    var animation_player := imported_model.find_child("AnimationPlayer", true, false)
    if not animation_player:
        return
    for animation_name in animation_player.get_animation_list():
        if str(animation_name).to_lower().contains(preferred):
            animation_player.play(animation_name)
            return

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
    mesh.top_radius = 0.26
    mesh.bottom_radius = 0.72
    mesh.height = 1.45
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
    material.clearcoat_enabled = true
    material.clearcoat = 0.24 if metallic < 0.4 else 0.58
    material.clearcoat_roughness = 0.22
    material.anisotropy_enabled = metallic < 0.25
    material.anisotropy = 0.26 if metallic < 0.25 else 0.0
    if glow:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 3.6
    return material
