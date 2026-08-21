extends RefCounted

## Phase 8 visual policy.
## Legacy low-poly assets are intentionally not part of the default runtime.
## The current production-safe path uses the procedural humanoid/animal rigs
## with upgraded PBR-style materials and ambientCG CC0 surface maps.

const GROUND_ALBEDO := "res://assets/ambientcg/PavingStones036/PavingStones036_Color.png"
const GROUND_NORMAL := "res://assets/ambientcg/PavingStones036/PavingStones036_NormalGL.png"
const GROUND_ROUGHNESS := "res://assets/ambientcg/PavingStones036/PavingStones036_Roughness.png"
const GROUND_AO := "res://assets/ambientcg/PavingStones036/PavingStones036_AmbientOcclusion.png"

static func instantiate_humanoid() -> Node3D:
    return null

static func instantiate_monster() -> Node3D:
    return null

static func instantiate_weapon(_build_id: String) -> Node3D:
    return null

static func source_manifest() -> Dictionary:
    return {
        "provider": "ambientCG",
        "license": "CC0 1.0 Universal",
        "ground_albedo": GROUND_ALBEDO,
        "ground_normal": GROUND_NORMAL,
        "ground_roughness": GROUND_ROUGHNESS,
        "ground_ao": GROUND_AO,
        "character_policy": "Use the built-in proportional humanoid rig with fabric/armor PBR-style materials; no low-poly placeholder GLB is shipped.",
        "monster_policy": "Use the built-in Mangyang animal rig with matte fur/skin response; no low-poly placeholder GLB is shipped."
    }
