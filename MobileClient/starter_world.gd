class_name StarterWorld
extends Node3D

var protocol: SROProtocol
var offline_mode := false
var player: MobilePlayer
var hud: MobileHUD
var movement_cooldown := 0.0
var character_data: Dictionary = {}
var monsters: Dictionary = {}
var drops: Dictionary = {}
var selected_target_id := 0
var inventory_ui: InventoryUI
var skill_system
var skill_tree_ui
var offline_exp := 0
var offline_level := 1
var offline_gold := 0
var offline_kills := 0
var offline_time := 0.0

func _ready() -> void:
    _build_environment()
    _build_city()
    _spawn_player()
    _spawn_hud()
    _spawn_skill_system()
    if offline_mode:
        _spawn_demo_monsters()

func set_offline_mode(value: bool) -> void:
    offline_mode = value
    if hud:
        hud.set_offline_mode(offline_mode)

func set_protocol(value: SROProtocol) -> void:
    protocol = value
    protocol.entity_spawned.connect(_on_entity_spawned)
    protocol.entity_despawned.connect(_on_entity_despawned)
    protocol.entity_moved.connect(_on_entity_moved)
    protocol.target_info_received.connect(_on_target_info_received)
    protocol.action_result_received.connect(_on_action_result_received)
    protocol.item_picked_up.connect(_on_item_picked_up)

func _spawn_skill_system() -> void:
    skill_system = load("res://skill_system.gd").new()
    skill_tree_ui = load("res://skill_tree_ui.gd").new()
    hud.add_child(skill_tree_ui)
    skill_tree_ui.configure(skill_system)
    skill_tree_ui.skill_use_requested.connect(_on_skill_use_requested)
    skill_tree_ui.skill_upgrade_requested.connect(_on_skill_upgrade_requested)

func set_character(data: Dictionary) -> void:
    character_data = data
    if hud:
        hud.set_status("Welcome %s — explore the Jangan outskirts" % data.get("name", "Traveler"))
        var hp := int(data.get("hp", 100))
        var mp := int(data.get("mp", 100))
        offline_level = int(data.get("level", offline_level))
        offline_exp = int(data.get("exp", offline_exp))
        offline_gold = int(data.get("gold", offline_gold))
        if player:
            player.configure_build(data)
        if skill_system:
            skill_system.configure(data)
        hud.set_stats(hp, mp, max(100, hp), max(100, mp))
        if skill_system:
            hud.set_mana(skill_system.mana, skill_system.max_mana)
        hud.set_exp(offline_exp, _exp_to_next(), offline_level)
        hud.set_offline_mode(offline_mode)

func _process(delta: float) -> void:
    movement_cooldown = max(0.0, movement_cooldown - delta)
    if player and hud:
        hud.set_world_position(player.global_position)
    if offline_mode:
        offline_time += delta
        _simulate_offline(delta)
    if skill_system:
        skill_system.tick(delta)
    if player and protocol and not offline_mode and movement_cooldown <= 0.0 and player.velocity.length() > 0.2:
        var p := player.global_position
        protocol.send_move_to(0, int(p.x), int(p.y), int(p.z))
        movement_cooldown = 0.25

func _build_environment() -> void:
    var world_environment := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color("#070f26")
    sky_material.sky_horizon_color = Color("#d99566")
    sky_material.ground_bottom_color = Color("#0c1424")
    sky_material.ground_horizon_color = Color("#54404c")
    sky_material.sun_angle_max = 18.0
    sky_material.sun_curve = 0.08
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#a9c9e5")
    environment.ambient_light_energy = 0.48
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.tonemap_exposure = 0.78
    environment.tonemap_white = 1.6
    environment.fog_enabled = true
    environment.fog_light_color = Color("#b98a83")
    environment.fog_light_energy = 0.42
    environment.fog_density = 0.0065
    environment.fog_sky_affect = 0.38
    environment.fog_height = 1.2
    environment.fog_height_density = 0.035
    environment.ssao_enabled = true
    environment.ssao_radius = 2.1
    environment.ssao_intensity = 1.35
    environment.ssao_power = 1.18
    environment.adjustment_enabled = true
    environment.adjustment_contrast = 1.08
    environment.adjustment_saturation = 1.05
    environment.adjustment_brightness = 0.98
    environment.glow_enabled = true
    environment.glow_intensity = 0.92
    environment.glow_strength = 0.86
    environment.glow_bloom = 0.12
    environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
    environment.glow_hdr_threshold = 0.72
    environment.glow_hdr_scale = 2.0
    world_environment.environment = environment
    add_child(world_environment)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -32, 0)
    sun.light_color = Color("#ffe2b5")
    sun.light_energy = 0.92
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 70.0
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
    sun.shadow_blur = 1.65
    sun.light_angular_distance = 2.1
    add_child(sun)

    var moon_fill := DirectionalLight3D.new()
    moon_fill.rotation_degrees = Vector3(-20, 148, 0)
    moon_fill.light_color = Color("#75a9e8")
    moon_fill.light_energy = 0.18
    moon_fill.shadow_enabled = false
    add_child(moon_fill)

    var golden_fill := OmniLight3D.new()
    golden_fill.position = Vector3(0, 6, 8)
    golden_fill.light_color = Color("#e7a85d")
    golden_fill.light_energy = 0.55
    golden_fill.omni_range = 18.0
    add_child(golden_fill)

func _build_city() -> void:
    var ground := StaticBody3D.new()
    ground.name = "Ground"
    var floor := MeshInstance3D.new()
    var floor_mesh := PlaneMesh.new()
    floor_mesh.size = Vector2(90, 90)
    floor.mesh = floor_mesh
    floor.position.y = -0.16
    floor.material_override = _terrain_material(Color("#6f5147"), 0.86)
    ground.add_child(floor)
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(90, 0.25, 90)
    collider.shape = shape
    collider.position.y = -0.16
    ground.add_child(collider)
    add_child(ground)

    var road := MeshInstance3D.new()
    var road_mesh := PlaneMesh.new()
    road_mesh.size = Vector2(13, 90)
    road.mesh = road_mesh
    road.position.y = 0.01
    road.material_override = _pbr_stone_material(Color("#5b4a4c"), 10.0)
    add_child(road)
    var road_cross := MeshInstance3D.new()
    var cross_mesh := PlaneMesh.new()
    cross_mesh.size = Vector2(90, 10)
    road_cross.mesh = cross_mesh
    road_cross.position.y = 0.015
    road_cross.material_override = _terrain_material(Color("#3f353d"), 0.76)
    add_child(road_cross)

    var water := MeshInstance3D.new()
    var water_mesh := PlaneMesh.new()
    water_mesh.size = Vector2(90, 5.5)
    water.mesh = water_mesh
    water.position = Vector3(0, 0.08, -24)
    water.material_override = _water_shader()
    add_child(water)

    for x in [-18.0, 18.0]:
        for z in [-15.0, 2.0, 19.0]:
            _build_house(Vector3(x, 0, z), 1.0 if x < 0 else 0.86)
    for x in [-28.0, 28.0]:
        for z in [-10.0, 10.0, 29.0]:
            _build_tree(Vector3(x, 0, z), 1.0 + fmod(abs(z), 4.0) * 0.04)
    for z in [-17.0, -8.0, 1.0, 10.0, 19.0]:
        _build_lantern(Vector3(-7.2, 0, z))
        _build_lantern(Vector3(7.2, 0, z))
    _build_gate(Vector3(0, 0, 28))
    _build_bridge(Vector3(0, 0, -24))
    _build_market(Vector3(0, 0, 10))

func _add_glb_asset(path: String, position: Vector3, scale_value: Vector3) -> Node3D:
    var scene: PackedScene = load(path)
    if scene == null:
        return null
    var instance := scene.instantiate()
    instance.position = position
    instance.scale = scale_value
    add_child(instance)
    return instance

func _build_house(position: Vector3, scale_factor: float) -> void:
    var house := Node3D.new()
    house.position = position
    house.scale = Vector3.ONE * scale_factor
    add_child(house)
    var base := MeshInstance3D.new()
    var base_mesh := BoxMesh.new()
    base_mesh.size = Vector3(10, 3.3, 7)
    base.mesh = base_mesh
    base.position.y = 1.65
    base.material_override = _plaster_shader(Color("#b99b7c"))
    house.add_child(base)
    var roof := MeshInstance3D.new()
    var roof_mesh := PrismMesh.new()
    roof_mesh.size = Vector3(11.2, 2.0, 8.2)
    roof.mesh = roof_mesh
    roof.position.y = 4.25
    roof.rotation_degrees.y = 90
    roof.material_override = _asian_roof_shader(Color("#6e2535"))
    house.add_child(roof)
    for z in [-3.55, 3.55]:
        var trim := MeshInstance3D.new()
        var trim_mesh := BoxMesh.new()
        trim_mesh.size = Vector3(10.8, 0.22, 0.22)
        trim.mesh = trim_mesh
        trim.position = Vector3(0, 3.25, z)
        trim.material_override = _asian_wood_shader(Color("#9c6b3c"))
        house.add_child(trim)
    for x in [-2.8, 0, 2.8]:
        var window := MeshInstance3D.new()
        var window_mesh := BoxMesh.new()
        window_mesh.size = Vector3(1.2, 1.25, 0.08)
        window.mesh = window_mesh
        window.position = Vector3(x, 1.9, -3.56)
        window.material_override = _material(Color("#315a68"), 0.38, 0.16)
        house.add_child(window)

func _build_tree(position: Vector3, scale_factor: float) -> void:
    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.25
    trunk_mesh.bottom_radius = 0.38
    trunk_mesh.height = 2.7
    trunk.mesh = trunk_mesh
    trunk.position = position + Vector3(0, 1.35, 0)
    trunk.scale = Vector3.ONE * scale_factor
    trunk.material_override = _material(Color("#69452f"), 0.0, 0.95)
    add_child(trunk)
    for offset in [Vector3(0, 2.9, 0), Vector3(-0.8, 2.55, 0), Vector3(0.8, 2.55, 0)]:
        var crown := MeshInstance3D.new()
        var crown_mesh := SphereMesh.new()
        crown_mesh.radius = 1.25
        crown_mesh.height = 2.2
        crown.mesh = crown_mesh
        crown.position = position + offset * scale_factor
        crown.scale = Vector3.ONE * scale_factor
        crown.material_override = _material(Color("#447c5c"), 0.0, 0.92)
        add_child(crown)

func _build_lantern(position: Vector3) -> void:
    var pole := MeshInstance3D.new()
    var pole_mesh := CylinderMesh.new()
    pole_mesh.top_radius = 0.08
    pole_mesh.bottom_radius = 0.11
    pole_mesh.height = 2.8
    pole.mesh = pole_mesh
    pole.position = position + Vector3(0, 1.4, 0)
    pole.material_override = _material(Color("#3b2930"), 0.55, 0.3)
    add_child(pole)
    var lamp := MeshInstance3D.new()
    var lamp_mesh := SphereMesh.new()
    lamp_mesh.radius = 0.32
    lamp_mesh.height = 0.64
    lamp.mesh = lamp_mesh
    lamp.position = position + Vector3(0, 2.65, 0)
    lamp.material_override = _material(Color("#ffd76b"), 0.2, 0.16)
    add_child(lamp)
    var glow := OmniLight3D.new()
    glow.position = lamp.position
    glow.light_color = Color("#ffc85e")
    glow.light_energy = 1.2
    glow.omni_range = 5.0
    add_child(glow)

func _build_gate(position: Vector3) -> void:
    for x in [-5.0, 5.0]:
        var pillar := MeshInstance3D.new()
        var pillar_mesh := BoxMesh.new()
        pillar_mesh.size = Vector3(1.4, 7.0, 1.4)
        pillar.mesh = pillar_mesh
        pillar.position = position + Vector3(x, 3.5, 0)
        pillar.material_override = _asian_wood_shader(Color("#7e2e39"))
        add_child(pillar)
    var beam := MeshInstance3D.new()
    var beam_mesh := BoxMesh.new()
    beam_mesh.size = Vector3(13, 1.35, 1.5)
    beam.mesh = beam_mesh
    beam.position = position + Vector3(0, 6.8, 0)
    beam.material_override = _asian_wood_shader(Color("#632432"))
    add_child(beam)
    var sign := Label3D.new()
    sign.text = "長安  JANGAN"
    sign.font_size = 48
    sign.outline_size = 10
    sign.modulate = Color("#ffe18a")
    sign.position = position + Vector3(0, 5.75, -0.82)
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(sign)

func _build_bridge(position: Vector3) -> void:
    for i in range(8):
        var plank := MeshInstance3D.new()
        var plank_mesh := BoxMesh.new()
        plank_mesh.size = Vector3(10.0, 0.32, 0.85)
        plank.mesh = plank_mesh
        plank.position = position + Vector3(0, 0.4 + sin(float(i) / 7.0 * PI) * 0.5, -3.0 + i * 0.85)
        plank.rotation_degrees.x = -sin(float(i) / 7.0 * PI) * 7.0
        plank.material_override = _asian_wood_shader(Color("#72452f"))
        add_child(plank)

func _build_market(position: Vector3) -> void:
    var table := MeshInstance3D.new()
    var table_mesh := BoxMesh.new()
    table_mesh.size = Vector3(8, 0.35, 3)
    table.mesh = table_mesh
    table.position = position + Vector3(0, 1.1, 0)
    table.material_override = _asian_wood_shader(Color("#68402e"))
    add_child(table)
    for x in [-3.5, 3.5]:
        var leg := MeshInstance3D.new()
        var leg_mesh := CylinderMesh.new()
        leg_mesh.top_radius = 0.1
        leg_mesh.bottom_radius = 0.1
        leg_mesh.height = 2.2
        leg.mesh = leg_mesh
        leg.position = position + Vector3(x, 0.1, 0)
        leg.material_override = _asian_wood_shader(Color("#553329"))
        add_child(leg)
    var canopy := MeshInstance3D.new()
    var canopy_mesh := BoxMesh.new()
    canopy_mesh.size = Vector3(9, 0.22, 4)
    canopy.mesh = canopy_mesh
    canopy.position = position + Vector3(0, 3.7, 0)
    canopy.material_override = _fabric_shader(Color("#8f3340"), Color("#c37a54"))
    add_child(canopy)

func _spawn_player() -> void:
    player = MobilePlayer.new()
    player.position = Vector3(0, 0.35, 5)
    player.movement_changed.connect(func(_position): pass)
    add_child(player)

func _spawn_hud() -> void:
    hud = MobileHUD.new()
    add_child(hud)
    player.set_joystick(hud.joystick)
    hud.action_requested.connect(_on_action)
    inventory_ui = InventoryUI.new()
    hud.add_child(inventory_ui)
    hud.inventory_requested.connect(func(): inventory_ui.visible = not inventory_ui.visible)

func _spawn_demo_monsters() -> void:
    _spawn_monster({"unique_id": 900001, "model": 1, "kind": "monster", "name": "Mangyang Scout", "position": Vector3(-3, 0, -2), "hp": 120, "max_hp": 120, "rarity": 0}, true)
    _spawn_monster({"unique_id": 900002, "model": 1, "kind": "monster", "name": "Mangyang Scout", "position": Vector3(4, 0, -6), "hp": 120, "max_hp": 120, "rarity": 1}, true)
    _spawn_monster({"unique_id": 900003, "model": 1, "kind": "monster", "name": "Mangyang Brute", "position": Vector3(8, 0, 2), "hp": 180, "max_hp": 180, "rarity": 2}, true)

func _simulate_offline(delta: float) -> void:
    for uid in monsters.keys():
        var monster: MonsterMob = monsters[uid]
        if is_instance_valid(monster) and monster.local_demo and not monster.defeated:
            monster.simulate_local_ai(delta, offline_time)

func _exp_to_next() -> int:
    return 100 + (offline_level - 1) * 60

func _grant_offline_exp(amount: int) -> void:
    offline_exp += amount
    while offline_exp >= _exp_to_next():
        offline_exp -= _exp_to_next()
        offline_level += 1
        if skill_system:
            skill_system.level = offline_level
            skill_system.add_skill_points(1)
        hud.set_status("LEVEL UP! You reached level %d" % offline_level)
    hud.set_exp(offline_exp, _exp_to_next(), offline_level)

func _spawn_monster(data: Dictionary, demo: bool = false) -> void:
    var uid := int(data.get("unique_id", 0))
    if monsters.has(uid):
        return
    var monster := MonsterMob.new()
    monster.configure(data)
    if demo:
        monster.configure_demo(uid, data.get("position", Vector3.ZERO))
    monster.targeted.connect(_on_monster_targeted)
    monsters[uid] = monster
    add_child(monster)
    if selected_target_id == 0 and demo:
        _on_monster_targeted(uid)

func _spawn_drop(data: Dictionary) -> void:
    var uid := int(data.get("unique_id", 0))
    if drops.has(uid):
        return
    var drop := DropItem3D.new()
    drop.configure(data)
    drop.pickup_requested.connect(_on_drop_requested)
    drops[uid] = drop
    add_child(drop)

func _on_entity_spawned(entity: Dictionary) -> void:
    if entity.get("kind", "monster") == "item":
        _spawn_drop(entity)
    else:
        _spawn_monster(entity)

func _on_entity_despawned(unique_id: int) -> void:
    if monsters.has(unique_id):
        monsters[unique_id].queue_free()
        monsters.erase(unique_id)
    if drops.has(unique_id):
        drops[unique_id].queue_free()
        drops.erase(unique_id)
    if selected_target_id == unique_id:
        selected_target_id = 0
        hud.clear_target()

func _on_entity_moved(unique_id: int, movement: Dictionary) -> void:
    if monsters.has(unique_id):
        monsters[unique_id].apply_movement(movement)

func _on_monster_targeted(unique_id: int) -> void:
    if selected_target_id != 0 and monsters.has(selected_target_id):
        monsters[selected_target_id].set_targeted(false)
    selected_target_id = unique_id
    if monsters.has(unique_id):
        var monster: MonsterMob = monsters[unique_id]
        monster.set_targeted(true)
        hud.set_target(monster.monster_name, monster.hp, monster.max_hp)
        if protocol and not offline_mode:
            protocol.select_entity(unique_id)
        hud.set_status("Target locked: %s" % monster.monster_name)

func _on_target_info_received(target: Dictionary) -> void:
    if not target.get("accepted", false):
        hud.clear_target()
        return
    if monsters.has(int(target.unique_id)):
        var monster: MonsterMob = monsters[int(target.unique_id)]
        monster.set_hp(int(target.hp), int(target.max_hp))
        hud.set_target(monster.monster_name, monster.hp, monster.max_hp)

func _on_action(action: String) -> void:
    if hud:
        hud.set_status("Action: %s" % action.to_upper())
    if action == "attack":
        if selected_target_id == 0:
            hud.set_status("Select a Mangyang first")
            return
        var target_position := player.global_position + Vector3(0, 0, -2.0)
        if monsters.has(selected_target_id):
            target_position = monsters[selected_target_id].global_position
        player.play_attack()
        if player.get_attack_style() == "wizard":
            CombatVFX.spawn_magic_projectile(self, player.get_attack_origin(), target_position)
            hud.set_status("Arcane bolt cast — ranged magic attack")
        else:
            CombatVFX.spawn_weapon_slash(self, player.global_position, player.rotation.y)
            hud.set_status("Spear stance — close-range physical attack")
        if selected_target_id == 0:
            hud.set_status("Select a Mangyang first")
            return
        if protocol and not offline_mode:
            protocol.attack_target(selected_target_id)
        if monsters.has(selected_target_id) and monsters[selected_target_id].local_demo:
            _apply_local_demo_attack()
    elif action == "skill":
        if skill_tree_ui:
            skill_tree_ui.open_for_build()
            hud.set_status("Choose an active skill for %s" % ("Wizard" if player.get_attack_style() == "wizard" else "Spear"))
    elif action == "pickup":
        _collect_nearest_drop()
    elif action == "potion":
        hud.set_status("Potion ready — inventory consumables are server-driven")

func _on_skill_upgrade_requested(skill_id: String) -> void:
    if not skill_system:
        return
    if skill_system.upgrade(skill_id):
        hud.set_status("Skill upgraded: %s" % skill_system.get_definition(skill_id).name)
    else:
        hud.set_status("Not enough skill points or level requirement not met")

func _on_skill_use_requested(skill_id: String) -> void:
    if selected_target_id == 0 or not monsters.has(selected_target_id):
        hud.set_status("Select a target before using a skill")
        return
    var result: Dictionary = skill_system.use(skill_id)
    if result.is_empty():
        hud.set_status("Skill unavailable: cooldown, Mana, or level requirement")
        return
    var monster: MonsterMob = monsters[selected_target_id]
    var target_position := monster.global_position
    player.play_attack()
    CombatVFX.spawn_skill_vfx(self, skill_id, player.get_attack_origin(), target_position, result.color)
    hud.set_mana(skill_system.mana, skill_system.max_mana)
    hud.set_status("%s used — Mana %d" % [result.name, result.mana])
    if offline_mode and monster.local_demo:
        var damage := int(24.0 * float(result.damage_multiplier))
        if player.get_attack_style() == "wizard":
            damage += 10
        monster.apply_damage(damage)
        _show_damage(monster, damage)
        if monster.hp <= 0:
            _kill_local_demo(monster)
        else:
            hud.set_target_hp(monster.hp, monster.max_hp)

func _apply_local_demo_attack() -> void:
    if not monsters.has(selected_target_id):
        return
    var monster: MonsterMob = monsters[selected_target_id]
    var style := player.get_attack_style()
    if style == "spear" and player.global_position.distance_to(monster.global_position) > 4.2:
        hud.set_status("Spear attack out of range — move closer")
        return
    var damage := randi_range(28, 46) if style == "wizard" else randi_range(18, 32)
    monster.apply_damage(damage)
    _show_damage(monster, damage)
    if monster.hp <= 0:
        _kill_local_demo(monster)
    else:
        hud.set_target_hp(monster.hp, monster.max_hp)

func _on_action_result_received(result: Dictionary) -> void:
    var uid := int(result.get("target_id", 0))
    if monsters.has(uid):
        var monster: MonsterMob = monsters[uid]
        var damage := int(result.get("damage", 0))
        monster.set_hp(int(result.get("hp", monster.hp)), monster.max_hp)
        _show_damage(monster, damage)
        hud.set_target_hp(monster.hp, monster.max_hp)
        if result.get("dead", false):
            _finish_monster(monster)

func _show_damage(monster: MonsterMob, damage: int) -> void:
    if damage <= 0:
        return
    FloatingDamage.spawn_hit_effect(self, monster.global_position)
    var popup := FloatingDamage.new()
    popup.position = monster.global_position + Vector3(0, 1.8, 0)
    add_child(popup)
    popup.show_damage(damage)

func _kill_local_demo(monster: MonsterMob) -> void:
    _finish_monster(monster)

func _finish_monster(monster: MonsterMob) -> void:
    if monster.defeated:
        return
    var defeated_position := monster.global_position
    monster.play_defeat()
    CombatVFX.spawn_death_effect(self, defeated_position)
    if monster.local_demo:
        offline_kills += 1
        offline_gold += 12 + monster.rarity * 8
        _grant_offline_exp(35 + monster.rarity * 15)
        var drop_data := {"unique_id": monster.unique_id + 1000000, "model": 9001, "position": defeated_position, "name": "Mangyang Hide"}
        _spawn_drop(drop_data)
    selected_target_id = 0
    hud.clear_target()
    hud.set_status("Mangyang defeated — loot dropped")
    await get_tree().create_timer(0.82).timeout
    if is_instance_valid(monster):
        var respawn_id := monster.unique_id
        var respawn_position := defeated_position
        _on_entity_despawned(respawn_id)
        if offline_mode:
            await get_tree().create_timer(1.8).timeout
            _spawn_monster({"unique_id": respawn_id, "model": 1, "kind": "monster", "name": "Mangyang Scout", "position": respawn_position, "hp": 120, "max_hp": 120, "rarity": 0}, true)

func _on_drop_requested(unique_id: int) -> void:
    if protocol and not offline_mode:
        protocol.pickup_item(unique_id)
    if drops.has(unique_id) and int(unique_id) >= 1000000:
        var drop: DropItem3D = drops[unique_id]
        inventory_ui.add_item(drop.item_id, drop.item_name)
        drop.queue_free()
        drops.erase(unique_id)
        hud.set_status("Picked up %s" % drop.item_name)

func _on_item_picked_up(result: Dictionary) -> void:
    var uid := int(result.get("unique_id", 0))
    if not result.get("success", false):
        hud.set_status("Server rejected pickup")
        return
    if drops.has(uid):
        var drop: DropItem3D = drops[uid]
        inventory_ui.add_item(int(result.get("item_id", drop.item_id)), drop.item_name)
        drop.queue_free()
        drops.erase(uid)
        hud.set_status("Picked up %s" % drop.item_name)

func _collect_nearest_drop() -> void:
    var nearest := -1
    var distance := 9999.0
    for uid in drops:
        var drop: DropItem3D = drops[uid]
        var current := player.global_position.distance_to(drop.global_position)
        if current < distance:
            distance = current
            nearest = int(uid)
    if nearest >= 0 and distance < 5.0:
        _on_drop_requested(nearest)
    else:
        hud.set_status("No loot nearby")

func _ground_shader() -> Material:
    return _material(Color("#6f5147"), 0.02, 0.86)

func _road_shader() -> Material:
    return _terrain_material(Color("#51434a"), 0.76)

func _terrain_material(color: Color, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = 0.0
    material.roughness = clampf(roughness, 0.0, 1.0)
    material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    material.cull_mode = BaseMaterial3D.CULL_BACK
    material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    return material

func _plaster_shader(tint: Color) -> ShaderMaterial:
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 base_color : source_color;
void fragment() {
    float grain = sin(UV.x * 180.0) * sin(UV.y * 160.0);
    float soft = 0.86 + grain * 0.035;
    ALBEDO = base_color.rgb * soft;
    ROUGHNESS = 0.78;
    SPECULAR = 0.24;
}
"""
    var material := ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("base_color", tint)
    return material

func _asian_roof_shader(tint: Color) -> ShaderMaterial:
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 base_color : source_color;
void fragment() {
    float tile = 0.91 + 0.09 * sin(UV.x * 92.0 + sin(UV.y * 11.0));
    float ridge = smoothstep(0.42, 0.5, abs(fract(UV.x * 16.0) - 0.5));
    ALBEDO = base_color.rgb * tile * (0.88 + ridge * 0.12);
    ROUGHNESS = 0.58;
    METALLIC = 0.04;
    SPECULAR = 0.42;
}
"""
    var material := ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("base_color", tint)
    return material

func _asian_wood_shader(tint: Color) -> ShaderMaterial:
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 base_color : source_color;
void fragment() {
    float grain = 0.86 + 0.14 * sin(UV.y * 120.0 + sin(UV.x * 14.0) * 4.0);
    ALBEDO = base_color.rgb * grain;
    ROUGHNESS = 0.64;
    SPECULAR = 0.32;
}
"""
    var material := ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("base_color", tint)
    return material

func _fabric_shader(primary: Color, secondary: Color) -> ShaderMaterial:
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 primary_color : source_color;
uniform vec4 secondary_color : source_color;
void fragment() {
    float warp = step(0.5, fract(UV.x * 80.0));
    float weft = step(0.5, fract(UV.y * 80.0));
    float weave = mix(0.92, 1.08, abs(warp - weft));
    ALBEDO = mix(primary_color.rgb, secondary_color.rgb, weave * 0.18) * weave;
    ROUGHNESS = 0.72;
    SPECULAR = 0.3;
}
"""
    var material := ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("primary_color", primary)
    material.set_shader_parameter("secondary_color", secondary)
    return material

func _pbr_stone_material(tint: Color, uv_scale: float, use_color_texture := true) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    if use_color_texture:
        material.albedo_texture = _texture_or_fallback("res://assets/ambientcg/PavingStones036/PavingStones036_Color.png", Color("#8a6d5d"))
    material.albedo_color = tint
    material.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
    material.normal_enabled = true
    material.normal_texture = _texture_or_fallback("res://assets/ambientcg/PavingStones036/PavingStones036_NormalGL.png", Color("#8080ff"))
    material.normal_scale = 0.52
    material.roughness_texture = _texture_or_fallback("res://assets/ambientcg/PavingStones036/PavingStones036_Roughness.png", Color("#b0b0b0"))
    material.roughness = 0.78
    material.ao_enabled = true
    material.ao_texture = _texture_or_fallback("res://assets/ambientcg/PavingStones036/PavingStones036_AmbientOcclusion.png", Color("#f0f0f0"))
    material.metallic = 0.02
    material.clearcoat_enabled = true
    material.clearcoat = 0.08
    material.clearcoat_roughness = 0.48
    return material

func _texture_or_fallback(path: String, fallback_color: Color) -> Texture2D:
    if ResourceLoader.exists(path, "Texture2D"):
        var loaded = ResourceLoader.load(path)
        if loaded is Texture2D:
            return loaded
    var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
    image.fill(fallback_color)
    return ImageTexture.create_from_image(image)

func _water_shader() -> ShaderMaterial:
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform vec4 deep_color : source_color = vec4(0.018, 0.12, 0.22, 1.0);
uniform vec4 reflected_color : source_color = vec4(0.12, 0.42, 0.48, 1.0);
void fragment() {
    vec2 flow_a = UV * vec2(10.0, 3.0) + vec2(TIME * 0.018, TIME * 0.032);
    vec2 flow_b = UV * vec2(17.0, 5.0) - vec2(TIME * 0.026, TIME * 0.015);
    float wave = sin(flow_a.x + sin(flow_a.y * 2.0)) * 0.055 + cos(flow_b.y + flow_b.x * 0.7) * 0.035;
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
    vec3 water_color = mix(deep_color.rgb, reflected_color.rgb, clamp(UV.y + wave * 2.0, 0.0, 1.0));
    ALBEDO = mix(water_color, reflected_color.rgb * 1.2, fresnel * 0.38);
    NORMAL = normalize(vec3(wave * 1.8, 1.0, wave * 1.2));
    METALLIC = 0.24;
    ROUGHNESS = 0.13;
    SPECULAR = 0.92;
    EMISSION = reflected_color.rgb * (0.045 + abs(wave) * 0.18);
    ALPHA = 0.88;
}
"""
    var material := ShaderMaterial.new()
    material.shader = shader
    return material

func _pattern_shader(primary: Color, secondary: Color, frequency: float, line_width: float) -> ShaderMaterial:
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode diffuse_burley;
uniform vec4 primary : source_color;
uniform vec4 secondary : source_color;
uniform float frequency = 16.0;
uniform float line_width = 0.03;
void fragment() {
    vec2 tiled = fract(UV * frequency);
    float lines = step(tiled.x, line_width) + step(tiled.y, line_width);
    float variation = 0.5 + 0.5 * sin(UV.x * 80.0) * sin(UV.y * 60.0);
    ALBEDO = mix(primary.rgb, secondary.rgb, clamp(variation * 0.22 + lines * 0.18, 0.0, 1.0));
    ROUGHNESS = 0.86;
}
"""
    var material := ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("primary", primary)
    material.set_shader_parameter("secondary", secondary)
    material.set_shader_parameter("frequency", frequency)
    material.set_shader_parameter("line_width", line_width)
    return material

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    material.clearcoat_enabled = true
    material.clearcoat = 0.12 if roughness > 0.55 else 0.28
    material.clearcoat_roughness = 0.34
    material.anisotropy_enabled = roughness > 0.7
    material.anisotropy = 0.08 if roughness > 0.7 else 0.0
    return material
