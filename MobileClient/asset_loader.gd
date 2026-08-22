extends RefCounted

## Phase 9 visual policy.
## Runtime visuals come from real skeletal glTF/GLB assets generated in
## tools/generate_glb_models.py (celestial jade-teal/gold palette). No
## procedural capsule/cylinder character geometry is shipped anymore.

const GROUND_ALBEDO := "res://assets/ambientcg/PavingStones036/PavingStones036_Color.png"
const GROUND_NORMAL := "res://assets/ambientcg/PavingStones036/PavingStones036_NormalGL.png"
const GROUND_ROUGHNESS := "res://assets/ambientcg/PavingStones036/PavingStones036_Roughness.png"
const GROUND_AO := "res://assets/ambientcg/PavingStones036/PavingStones036_AmbientOcclusion.png"

const HUMAN_WIZARD_GLB := "res://assets/models/humanoid_wizard.glb"
const HUMAN_SPEAR_GLB := "res://assets/models/humanoid_spear.glb"
const MONSTER_GLB := "res://assets/models/monster_mangyang.glb"
const WEAPON_STAFF_GLB := "res://assets/models/weapon_staff.glb"
const WEAPON_SPEAR_GLB := "res://assets/models/weapon_spear.glb"

static var _cache := {}

static func _scene(path: String) -> PackedScene:
    if _cache.has(path):
        return _cache[path]
    var packed: PackedScene = load(path)
    if packed == null:
        return null
    _cache[path] = packed
    return packed

static func instantiate_humanoid(build_id := "") -> Node3D:
    var path := HUMAN_WIZARD_GLB
    if str(build_id).to_lower() not in ["wizard", "european_wizard", "staff"]:
        path = HUMAN_SPEAR_GLB
    var packed := _scene(path)
    if packed == null:
        return null
    var instance := packed.instantiate()
    instance.name = "CelestialHumanoid"
    return instance

static func instantiate_monster() -> Node3D:
    var packed := _scene(MONSTER_GLB)
    if packed == null:
        return null
    var instance := packed.instantiate()
    instance.name = "Mangyang"
    return instance

static func instantiate_weapon(build_id: String) -> Node3D:
    var path := WEAPON_SPEAR_GLB
    if str(build_id).to_lower() in ["wizard", "european_wizard", "staff"]:
        path = WEAPON_STAFF_GLB
    var packed := _scene(path)
    if packed == null:
        return null
    var instance := packed.instantiate()
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
