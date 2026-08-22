class_name CharacterVisualAdapter
extends Node3D

## Phase 10.2 adapter that owns a character rig (Skeleton3D + AnimationPlayer +
## BoneAttachment3D sockets) and maps logical animation states to per-asset clips.
## Mirrors the public surface of humanoid_model.gd so gameplay callers are unchanged.

const WIZARD_ASSET_KEY := "characters/western/western_wizard"
const SPEAR_ASSET_KEY := "characters/eastern/eastern_spear_warrior"

var asset_key := SPEAR_ASSET_KEY
var rig_root: Node3D
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var sockets: Dictionary = {}
var animation_map: Dictionary = {}
var socket_map: Dictionary = {}

var build_id := "spear"
var weapon_style := "spear"

var _attack_timer := 0.0
var _attack_duration := 0.62
var _base_animation := "idle"

func configure(data: Dictionary) -> void:
	build_id = str(data.get("class_id", data.get("build", "spear"))).to_lower()
	weapon_style = "wizard" if build_id in ["wizard", "european_wizard", "staff"] else "spear"
	asset_key = WIZARD_ASSET_KEY if weapon_style == "wizard" else SPEAR_ASSET_KEY
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	rig_root = null
	skeleton = null
	animation_player = null
	sockets.clear()
	animation_map = VisualAssetLoader.animation_map(asset_key)
	socket_map = VisualAssetLoader.socket_map(asset_key)
	rig_root = VisualAssetLoader.instantiate(asset_key)
	if rig_root == null:
		push_error("CharacterVisualAdapter: no visual for %s" % asset_key)
		return
	rig_root.name = "Rig"
	add_child(rig_root)
	animation_player = rig_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player:
		for clip in animation_map.values():
			if animation_player.has_animation(clip):
				var anim: Animation = animation_player.get_animation(clip)
				anim.loop_mode = Animation.LOOP_LINEAR
		_play_clip("idle")
	skeleton = rig_root.find_child("Skeleton3D", true, false) as Skeleton3D
	_build_sockets()

func _build_sockets() -> void:
	if skeleton == null:
		return
	for logical_name in socket_map:
		var bone_name := str(socket_map[logical_name])
		var existing := skeleton.find_child(logical_name, true, false)
		if existing is BoneAttachment3D:
			sockets[logical_name] = existing
			continue
		var index := skeleton.find_bone(bone_name)
		if index == -1:
			index = _find_bone_substring(bone_name)
		if index == -1:
			continue
		var mount := BoneAttachment3D.new()
		mount.name = logical_name
		mount.bone_name = skeleton.get_bone_name(index)
		skeleton.add_child(mount)
		sockets[logical_name] = mount

func _find_bone_substring(needle: String) -> int:
	if skeleton == null:
		return -1
	var lower := needle.to_lower()
	for index in range(skeleton.get_bone_count()):
		var bone := skeleton.get_bone_name(index).to_lower()
		if bone == lower or bone.contains(lower):
			return index
	return -1

func _play_clip(logical: String) -> void:
	var clip := str(animation_map.get(logical, logical))
	if animation_player and animation_player.has_animation(clip):
		animation_player.play(clip)

func set_animation_state(state: String) -> void:
	if _attack_timer > 0.0:
		return
	_base_animation = "walk" if state == "walk" else "idle"
	_play_clip(_base_animation)

func play_attack() -> void:
	_attack_timer = _attack_duration
	_play_clip("attack")

func _process(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer = max(0.0, _attack_timer - delta)
		if _attack_timer <= 0.0:
			_play_clip(_base_animation)

func socket(logical_name: String) -> Node3D:
	return sockets.get(logical_name) as Node3D

func attach_weapon(weapon_key: String, accent := Color("#e5bb5f")) -> void:
	var mount := socket("weapon_r")
	if mount == null:
		return
	var weapon: Node3D = VisualAssetLoader.instantiate(weapon_key)
	if weapon == null:
		return
	weapon.name = "Weapon"
	_tint_weapon(weapon, accent)
	mount.add_child(weapon)

func get_attack_origin() -> Vector3:
	var mount := socket("weapon_r")
	if mount:
		return mount.global_position
	return global_position + Vector3(0, 1.2, 0)

func get_visual_root() -> Node3D:
	return rig_root

func _tint_weapon(weapon: Node3D, accent: Color) -> void:
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
