class_name HumanoidModel
extends Node3D

## Phase 10.2 compatibility wrapper. Owns a CharacterVisualAdapter child and
## keeps the exact public surface that character_select.gd and player_controller.gd
## rely on (configure_build / set_animation_state / play_attack plus the legacy
## read-only handle fields).

var build_id := "spear"
var weapon_style := "spear"
var race_name := "Chinese"
var outfit_name := "Jade War Robe"
var skeleton: Skeleton3D
var bones: Dictionary = {}
var imported_model: Node3D
var weapon_mount: Node3D
var animation_state := "idle"

var adapter: CharacterVisualAdapter

func configure_build(data: Dictionary) -> void:
	build_id = str(data.get("class_id", data.get("build", "spear"))).to_lower()
	weapon_style = "wizard" if build_id in ["wizard", "european_wizard", "staff"] else "spear"
	race_name = str(data.get("race", "Chinese"))
	outfit_name = str(data.get("outfit", "Jade War Robe"))
	if adapter == null:
		adapter = CharacterVisualAdapter.new()
		adapter.name = "VisualAdapter"
		add_child(adapter)
	adapter.configure(data)
	_mirror_adapter()
	_attach_default_weapon()

func _mirror_adapter() -> void:
	skeleton = adapter.skeleton
	bones.clear()
	if skeleton:
		for index in range(skeleton.get_bone_count()):
			bones[skeleton.get_bone_name(index)] = index
	imported_model = adapter.rig_root
	weapon_mount = adapter.socket("weapon_r")

func _attach_default_weapon() -> void:
	var weapon_key := "weapons/staff/western_staff_01"
	var accent := Color("#8edbff")
	if weapon_style != "wizard":
		weapon_key = "weapons/spear/eastern_spear_01"
		accent = Color("#e5bb5f")
	adapter.attach_weapon(weapon_key, accent)
	weapon_mount = adapter.socket("weapon_r")

func set_animation_state(state: String) -> void:
	animation_state = state
	if adapter:
		adapter.set_animation_state(state)

func play_attack() -> void:
	if adapter:
		adapter.play_attack()
