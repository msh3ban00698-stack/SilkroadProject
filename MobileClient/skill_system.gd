extends RefCounted

signal changed()

var build_id := "spear"
var level := 1
var skill_points := 3
var mana := 100
var max_mana := 100
var cooldowns: Dictionary = {}
var skills: Dictionary = {}

const TREES := {
    "wizard": [
        {"id": "arcane_bolt", "name": "Arcane Bolt", "description": "A fast ranged arcane projectile.", "required_level": 1, "cost": 0, "mana": 12, "cooldown": 0.9, "damage": 1.35, "color": Color("#8edbff")},
        {"id": "frost_nova", "name": "Frost Nova", "description": "Ice rings burst around the target.", "required_level": 2, "cost": 1, "mana": 30, "cooldown": 4.5, "damage": 2.1, "color": Color("#9fe9ff")},
        {"id": "meteor_lance", "name": "Meteor Lance", "description": "A heavy falling star strikes the target.", "required_level": 3, "cost": 2, "mana": 52, "cooldown": 7.0, "damage": 3.4, "color": Color("#ffb35f")}
    ],
    "spear": [
        {"id": "piercing_thrust", "name": "Piercing Thrust", "description": "A focused physical stab.", "required_level": 1, "cost": 0, "mana": 8, "cooldown": 0.8, "damage": 1.45, "color": Color("#f2c66d")},
        {"id": "whirlwind_sweep", "name": "Whirlwind Sweep", "description": "A circular spear sweep around the target.", "required_level": 2, "cost": 1, "mana": 24, "cooldown": 3.5, "damage": 2.25, "color": Color("#ffdf8a")},
        {"id": "dragon_impale", "name": "Dragon Impale", "description": "A devastating forward spear strike.", "required_level": 3, "cost": 2, "mana": 44, "cooldown": 6.0, "damage": 3.6, "color": Color("#e87961")}
    ]
}

func configure(data: Dictionary) -> void:
    build_id = str(data.get("class_id", "spear")).to_lower()
    if build_id not in TREES:
        build_id = "spear"
    level = max(1, int(data.get("level", 1)))
    skill_points = max(0, int(data.get("skill_points", 3)))
    max_mana = max(1, int(data.get("mp", 100)))
    mana = max_mana
    skills.clear()
    for definition in TREES[build_id]:
        skills[definition.id] = 0
        cooldowns[definition.id] = 0.0
    changed.emit()

func tick(delta: float) -> void:
    for skill_id in cooldowns.keys():
        cooldowns[skill_id] = max(0.0, float(cooldowns[skill_id]) - delta)

func get_definitions() -> Array:
    return TREES.get(build_id, [])

func get_definition(skill_id: String) -> Dictionary:
    for definition in get_definitions():
        if definition.id == skill_id:
            return definition
    return {}

func get_rank(skill_id: String) -> int:
    return int(skills.get(skill_id, 0))

func can_upgrade(skill_id: String) -> bool:
    var definition := get_definition(skill_id)
    if definition.is_empty():
        return false
    return skill_points >= int(definition.cost) and get_rank(skill_id) < 5 and level >= int(definition.required_level)

func upgrade(skill_id: String) -> bool:
    if not can_upgrade(skill_id):
        return false
    skill_points -= int(get_definition(skill_id).cost)
    skills[skill_id] = get_rank(skill_id) + 1
    changed.emit()
    return true

func can_use(skill_id: String) -> bool:
    var definition := get_definition(skill_id)
    if definition.is_empty():
        return false
    if level < int(definition.required_level):
        return false
    if mana < int(definition.mana):
        return false
    if float(cooldowns.get(skill_id, 0.0)) > 0.0:
        return false
    return true

func use(skill_id: String) -> Dictionary:
    if not can_use(skill_id):
        return {}
    var definition := get_definition(skill_id)
    var rank: int = maxi(1, get_rank(skill_id))
    mana -= int(definition.mana)
    cooldowns[skill_id] = float(definition.cooldown)
    changed.emit()
    return {
        "id": skill_id,
        "name": definition.name,
        "damage_multiplier": float(definition.damage) + (rank - 1) * 0.18,
        "mana": int(definition.mana),
        "rank": rank,
        "color": definition.color
    }

func restore_mana(amount: int) -> void:
    mana = min(max_mana, mana + amount)
    changed.emit()

func add_skill_points(amount: int) -> void:
    skill_points = max(0, skill_points + amount)
    changed.emit()
