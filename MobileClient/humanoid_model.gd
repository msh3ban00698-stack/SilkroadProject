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
var animation_state := "idle"

var _animation_player: AnimationPlayer
var _base_animation := "idle"
var _attack_timer := 0.0
var _attack_duration := 0.62

func configure_build(data: Dictionary) -> void:
    build_id = str(data.get("class_id", data.get("build", "spear"))).to_lower()
    weapon_style = "wizard" if build_id in ["wizard", "european_wizard", "staff"] else "spear"
    race_name = str(data.get("race", "Chinese"))
    outfit_name = str(data.get("outfit", "Jade War Robe"))
    for child in get_children():
        remove_child(child)
        child.free()
    _build_imported_model()

func _process(delta: float) -> void:
    if _attack_timer > 0.0:
        _attack_timer = max(0.0, _attack_timer - delta)
        if _attack_timer <= 0.0:
            _play_base_animation()

func set_animation_state(state: String) -> void:
    animation_state = state
    if _attack_timer <= 0.0:
        _base_animation = "walk" if state == "walk" else "idle"
        _play_base_animation()

func play_attack() -> void:
    _attack_timer = _attack_duration
    if _animation_player and _animation_player.has_animation("attack"):
        _animation_player.play("attack")

func _build_imported_model() -> void:
    var loader_script := load("res://asset_loader.gd")
    if loader_script == null:
        return
    imported_model = loader_script.instantiate_humanoid(weapon_style)
    if imported_model == null:
        return
    imported_model.name = "ImportedHumanoid"
    add_child(imported_model)

    _animation_player = imported_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
    if _animation_player:
        for animation_name in ["idle", "walk"]:
            if _animation_player.has_animation(animation_name):
                var anim: Animation = _animation_player.get_animation(animation_name)
                anim.loop_mode = Animation.LOOP_LINEAR
        _animation_player.play("idle")

    skeleton = imported_model.find_child("Skeleton3D", true, false) as Skeleton3D
    for index in range(skeleton.get_bone_count()):
        bones[skeleton.get_bone_name(index)] = index

    weapon_mount = BoneAttachment3D.new()
    weapon_mount.name = "WeaponMount"
    weapon_mount.bone_name = "hand_r"
    skeleton.add_child(weapon_mount)

    var weapon: Node3D = loader_script.instantiate_weapon(weapon_style)
    if weapon:
        weapon.name = "ImportedWeapon"
        weapon.position = Vector3(0, 0, 0)
        weapon.rotation_degrees = Vector3(0, 0, -8)
        weapon_mount.add_child(weapon)
        _tint_weapon(weapon)

func _play_base_animation() -> void:
    if _animation_player and _animation_player.has_animation(_base_animation):
        _animation_player.play(_base_animation)

func _tint_weapon(weapon: Node3D) -> void:
    var accent := Color("#8edbff") if weapon_style == "wizard" else Color("#e5bb5f")
    for mesh in weapon.find_children("*", "MeshInstance3D", true, false):
        var material := mesh.get_active_material(0) as StandardMaterial3D
        if material == null:
            continue
        var tinted: StandardMaterial3D = material.duplicate()
        var albedo := tinted.albedo_color as Color
        albedo = albedo.lerp(accent, 0.18)
        tinted.albedo_color = albedo
        tinted.metallic = 0.35
        tinted.roughness = 0.3
        tinted.emission_enabled = false
        mesh.material_override = tinted
