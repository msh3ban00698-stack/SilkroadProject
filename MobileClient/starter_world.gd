class_name StarterWorld
extends Node3D

var protocol: SROProtocol
var player: MobilePlayer
var hud: MobileHUD
var movement_cooldown := 0.0
var character_data: Dictionary = {}
var monsters: Dictionary = {}
var drops: Dictionary = {}
var selected_target_id := 0
var inventory_ui: InventoryUI

func _ready() -> void:
    _build_environment()
    _build_city()
    _spawn_player()
    _spawn_hud()
    _spawn_demo_monsters()

func set_protocol(value: SROProtocol) -> void:
    protocol = value
    protocol.entity_spawned.connect(_on_entity_spawned)
    protocol.entity_despawned.connect(_on_entity_despawned)
    protocol.entity_moved.connect(_on_entity_moved)
    protocol.target_info_received.connect(_on_target_info_received)
    protocol.action_result_received.connect(_on_action_result_received)
    protocol.item_picked_up.connect(_on_item_picked_up)

func set_character(data: Dictionary) -> void:
    character_data = data
    if hud:
        hud.set_status("Welcome %s — explore the Jangan outskirts" % data.get("name", "Traveler"))
        var hp := int(data.get("hp", 100))
        var mp := int(data.get("mp", 100))
        hud.set_stats(hp, mp, max(100, hp), max(100, mp))

func _process(delta: float) -> void:
    movement_cooldown = max(0.0, movement_cooldown - delta)
    if player and hud:
        hud.set_world_position(player.global_position)
    if player and protocol and movement_cooldown <= 0.0 and player.velocity.length() > 0.2:
        var p := player.global_position
        protocol.send_move_to(0, int(p.x), int(p.y), int(p.z))
        movement_cooldown = 0.25

func _build_environment() -> void:
    var world_environment := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#9fc7df")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#a9c9e5")
    environment.ambient_light_energy = 0.72
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.glow_enabled = true
    world_environment.environment = environment
    add_child(world_environment)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -32, 0)
    sun.light_color = Color("#ffe2b5")
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    add_child(sun)

    var moon_fill := DirectionalLight3D.new()
    moon_fill.rotation_degrees = Vector3(-20, 148, 0)
    moon_fill.light_color = Color("#75a9e8")
    moon_fill.light_energy = 0.22
    add_child(moon_fill)

func _build_city() -> void:
    var ground := StaticBody3D.new()
    ground.name = "Ground"
    var floor := MeshInstance3D.new()
    var floor_mesh := BoxMesh.new()
    floor_mesh.size = Vector3(90, 0.25, 90)
    floor.mesh = floor_mesh
    floor.position.y = -0.16
    floor.material_override = _material(Color("#b99468"), 0.0, 0.95)
    ground.add_child(floor)
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(90, 0.25, 90)
    collider.shape = shape
    collider.position.y = -0.16
    ground.add_child(collider)
    add_child(ground)

    var road := MeshInstance3D.new()
    var road_mesh := BoxMesh.new()
    road_mesh.size = Vector3(13, 0.03, 90)
    road.mesh = road_mesh
    road.position.y = 0.01
    road.material_override = _material(Color("#6d5b55"), 0.0, 1.0)
    add_child(road)
    var road_cross := MeshInstance3D.new()
    var cross_mesh := BoxMesh.new()
    cross_mesh.size = Vector3(90, 0.035, 10)
    road_cross.mesh = cross_mesh
    road_cross.position.y = 0.015
    road_cross.material_override = _material(Color("#6d5b55"), 0.0, 1.0)
    add_child(road_cross)

    var water := MeshInstance3D.new()
    var water_mesh := BoxMesh.new()
    water_mesh.size = Vector3(90, 0.05, 5.5)
    water.mesh = water_mesh
    water.position = Vector3(0, 0.08, -24)
    water.material_override = _material(Color("#2c91ad"), 0.35, 0.15)
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
    base.material_override = _material(Color("#d6b081"), 0.0, 0.82)
    house.add_child(base)
    var roof := MeshInstance3D.new()
    var roof_mesh := PrismMesh.new()
    roof_mesh.size = Vector3(11.2, 2.0, 8.2)
    roof.mesh = roof_mesh
    roof.position.y = 4.25
    roof.rotation_degrees.y = 90
    roof.material_override = _material(Color("#7a2935"), 0.05, 0.68)
    house.add_child(roof)
    for z in [-3.55, 3.55]:
        var trim := MeshInstance3D.new()
        var trim_mesh := BoxMesh.new()
        trim_mesh.size = Vector3(10.8, 0.22, 0.22)
        trim.mesh = trim_mesh
        trim.position = Vector3(0, 3.25, z)
        trim.material_override = _material(Color("#e6c978"), 0.25, 0.42)
        house.add_child(trim)
    for x in [-2.8, 0, 2.8]:
        var window := MeshInstance3D.new()
        var window_mesh := BoxMesh.new()
        window_mesh.size = Vector3(1.2, 1.25, 0.08)
        window.mesh = window_mesh
        window.position = Vector3(x, 1.9, -3.56)
        window.material_override = _material(Color("#4db3c2"), 0.35, 0.18)
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
        pillar.material_override = _material(Color("#a63f42"), 0.0, 0.72)
        add_child(pillar)
    var beam := MeshInstance3D.new()
    var beam_mesh := BoxMesh.new()
    beam_mesh.size = Vector3(13, 1.35, 1.5)
    beam.mesh = beam_mesh
    beam.position = position + Vector3(0, 6.8, 0)
    beam.material_override = _material(Color("#8b2d36"), 0.05, 0.68)
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
        plank.material_override = _material(Color("#8d5c3f"), 0.0, 0.88)
        add_child(plank)

func _build_market(position: Vector3) -> void:
    var table := MeshInstance3D.new()
    var table_mesh := BoxMesh.new()
    table_mesh.size = Vector3(8, 0.35, 3)
    table.mesh = table_mesh
    table.position = position + Vector3(0, 1.1, 0)
    table.material_override = _material(Color("#75432e"), 0.0, 0.9)
    add_child(table)
    for x in [-3.5, 3.5]:
        var leg := MeshInstance3D.new()
        var leg_mesh := CylinderMesh.new()
        leg_mesh.top_radius = 0.1
        leg_mesh.bottom_radius = 0.1
        leg_mesh.height = 2.2
        leg.mesh = leg_mesh
        leg.position = position + Vector3(x, 0.1, 0)
        leg.material_override = _material(Color("#5d382a"), 0.0, 0.95)
        add_child(leg)
    var canopy := MeshInstance3D.new()
    var canopy_mesh := BoxMesh.new()
    canopy_mesh.size = Vector3(9, 0.22, 4)
    canopy.mesh = canopy_mesh
    canopy.position = position + Vector3(0, 3.7, 0)
    canopy.material_override = _material(Color("#d65d52"), 0.0, 0.78)
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
        if protocol:
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
        if protocol:
            protocol.attack_target(selected_target_id)
        if monsters.has(selected_target_id) and monsters[selected_target_id].local_demo:
            _apply_local_demo_attack()
    elif action == "pickup":
        _collect_nearest_drop()
    elif action == "potion":
        hud.set_status("Potion ready — inventory consumables are server-driven")

func _apply_local_demo_attack() -> void:
    if not monsters.has(selected_target_id):
        return
    var monster: MonsterMob = monsters[selected_target_id]
    var damage := randi_range(18, 32)
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
            _kill_local_demo(monster)

func _show_damage(monster: MonsterMob, damage: int) -> void:
    if damage <= 0:
        return
    FloatingDamage.spawn_hit_effect(self, monster.global_position)
    var popup := FloatingDamage.new()
    popup.position = monster.global_position + Vector3(0, 1.8, 0)
    add_child(popup)
    popup.show_damage(damage)

func _kill_local_demo(monster: MonsterMob) -> void:
    var drop_data := {"unique_id": monster.unique_id + 1000000, "model": 9001, "position": monster.global_position, "name": "Mangyang Hide"}
    _spawn_drop(drop_data)
    _on_entity_despawned(monster.unique_id)
    selected_target_id = 0
    hud.clear_target()
    hud.set_status("Mangyang defeated — loot dropped")

func _on_drop_requested(unique_id: int) -> void:
    if protocol:
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

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    return material
