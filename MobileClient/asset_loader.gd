extends RefCounted

const HUMANOID_SCENE: PackedScene = preload("res://assets/kenney/characters/character-human.glb")
const SPEAR_SCENE: PackedScene = preload("res://assets/kenney/dungeon/weapon-spear.glb")
const ORC_SCENE: PackedScene = preload("res://assets/kenney/characters/character-orc.glb")
const WIZARD_STAFF_SCENE: PackedScene = preload("res://assets/kenney/dungeon/weapon-spear.glb")

static func instantiate_humanoid() -> Node3D:
    return HUMANOID_SCENE.instantiate()

static func instantiate_monster() -> Node3D:
    return ORC_SCENE.instantiate()

static func instantiate_weapon(build_id: String) -> Node3D:
    if build_id == "wizard":
        return WIZARD_STAFF_SCENE.instantiate()
    return SPEAR_SCENE.instantiate()

static func source_manifest() -> Dictionary:
    return {
        "provider": "Kenney",
        "license": "CC0 1.0",
        "character": "assets/kenney/characters/character-human.glb",
        "monster": "assets/kenney/characters/character-orc.glb",
        "spear": "assets/kenney/dungeon/weapon-spear.glb",
        "wizard_staff": "assets/kenney/dungeon/weapon-spear.glb + ArcaneOrb VFX",
        "fallback_policy": "Use the procedural rig only if the GLB import is unavailable."
    }
