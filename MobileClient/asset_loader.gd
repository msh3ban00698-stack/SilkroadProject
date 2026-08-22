extends RefCounted

## Phase 10.2 facade over VisualAssetLoader.
## Keeps the historical public methods (instantiate_humanoid / instantiate_monster /
## instantiate_weapon / source_manifest) so existing callers keep working unchanged.
## Resolution, caching and manifest metadata now live in visual_asset_loader.gd.

const GROUND_ALBEDO := "res://assets/ambientcg/PavingStones036/PavingStones036_Color.png"
const GROUND_NORMAL := "res://assets/ambientcg/PavingStones036/PavingStones036_NormalGL.png"
const GROUND_ROUGHNESS := "res://assets/ambientcg/PavingStones036/PavingStones036_Roughness.png"
const GROUND_AO := "res://assets/ambientcg/PavingStones036/PavingStones036_AmbientOcclusion.png"

static func instantiate_humanoid(build_id := "") -> Node3D:
	var instance := VisualAssetLoader.instantiate_humanoid(build_id)
	if instance != null:
		instance.name = "CelestialHumanoid"
	return instance

static func instantiate_monster() -> Node3D:
	var instance := VisualAssetLoader.instantiate_monster()
	if instance != null:
		instance.name = "Mangyang"
	return instance

static func instantiate_weapon(build_id: String) -> Node3D:
	var instance := VisualAssetLoader.instantiate_weapon(build_id)
	if instance != null:
		instance.name = "CelestialWeapon"
	return instance

static func source_manifest() -> Dictionary:
	return {
		"provider": "self-generated glTF/GLB + ambientCG CC0",
		"license": "GLB models generated in-repo; ambientCG ground maps are CC0 1.0 Universal",
		"ground_albedo": GROUND_ALBEDO,
		"ground_normal": GROUND_NORMAL,
		"ground_roughness": GROUND_ROUGHNESS,
		"ground_ao": GROUND_AO,
		"character_policy": "Skeletal glTF/GLB humanoid rig with baked idle/walk/attack animations; no procedural character meshes.",
		"monster_policy": "Skeletal glTF/GLB Mangyang rig with baked idle/walk/attack animations; no procedural character meshes.",
		"generator": "res://tools/generate_glb_models.py"
	}
