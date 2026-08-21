class_name CombatVFX
extends Node

static func spawn_weapon_slash(parent: Node3D, origin: Vector3, facing: float) -> void:
    var effect := Node3D.new()
    effect.name = "WeaponSlashTrail"
    effect.position = origin + Vector3(0, 1.05, 0)
    effect.rotation.y = facing
    parent.add_child(effect)
    for index in range(3):
        var slash := MeshInstance3D.new()
        var mesh := QuadMesh.new()
        mesh.size = Vector2(2.3 - index * 0.25, 0.38 - index * 0.05)
        slash.mesh = mesh
        slash.rotation_degrees = Vector3(-18 + index * 18, 0, -25 + index * 9)
        slash.position = Vector3(0, index * 0.12, -0.25 - index * 0.12)
        slash.material_override = _slash_material(Color("#f4c968"), 3.2 - index * 0.6)
        effect.add_child(slash)
        var tween := effect.create_tween().set_parallel(true)
        tween.tween_property(slash, "scale", Vector3(1.65, 1.65, 1.65), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tween.tween_property(slash, "material_override:albedo_color:a", 0.0, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    var light := OmniLight3D.new()
    light.light_color = Color("#ffd86c")
    light.light_energy = 4.0
    light.omni_range = 4.0
    effect.add_child(light)
    var light_tween := effect.create_tween()
    light_tween.tween_property(light, "light_energy", 0.0, 0.35)
    light_tween.finished.connect(effect.queue_free)

static func spawn_magic_projectile(parent: Node3D, origin: Vector3, target: Vector3) -> void:
    var effect := Node3D.new()
    effect.name = "ArcaneBolt"
    effect.position = origin
    parent.add_child(effect)
    var orb := MeshInstance3D.new()
    var orb_mesh := SphereMesh.new()
    orb_mesh.radius = 0.2
    orb_mesh.height = 0.4
    orb.mesh = orb_mesh
    orb.material_override = _slash_material(Color("#8edbff"), 5.5)
    effect.add_child(orb)
    var light := OmniLight3D.new()
    light.light_color = Color("#65cfff")
    light.light_energy = 5.5
    light.omni_range = 4.2
    effect.add_child(light)
    var distance := origin.distance_to(target)
    var duration: float = clampf(distance / 11.0, 0.18, 0.72)
    var tween := effect.create_tween()
    tween.tween_property(effect, "global_position", target + Vector3(0, 1.0, 0), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tween.finished.connect(func():
        FloatingDamage.spawn_hit_effect(parent, target + Vector3(0, 1.0, 0))
        effect.queue_free()
    )

static func spawn_skill_vfx(parent: Node3D, skill_id: String, origin: Vector3, target: Vector3, color: Color) -> void:
    match skill_id:
        "arcane_bolt":
            spawn_magic_projectile(parent, origin, target)
        "frost_nova":
            _spawn_ring_burst(parent, target + Vector3(0, 0.1, 0), color, 3, 1.4)
            spawn_magic_projectile(parent, origin, target)
        "meteor_lance":
            _spawn_meteor(parent, target, color)
        "piercing_thrust":
            _spawn_thrust_wave(parent, origin, target, color, 1.0)
        "whirlwind_sweep":
            _spawn_ring_burst(parent, target + Vector3(0, 0.2, 0), color, 2, 1.8)
        "dragon_impale":
            _spawn_thrust_wave(parent, origin, target, color, 2.2)
        _:
            spawn_weapon_slash(parent, origin, 0.0)

static func _spawn_ring_burst(parent: Node3D, origin: Vector3, color: Color, ring_count: int, scale_factor: float) -> void:
    var effect := Node3D.new()
    effect.name = "SkillRingBurst"
    effect.position = origin
    parent.add_child(effect)
    var light := OmniLight3D.new()
    light.light_color = color
    light.light_energy = 4.5
    light.omni_range = 4.0
    effect.add_child(light)
    for index in range(ring_count):
        var ring := MeshInstance3D.new()
        var mesh := TorusMesh.new()
        mesh.inner_radius = 0.38 + index * 0.18
        mesh.outer_radius = 0.43 + index * 0.18
        mesh.rings = 32
        ring.mesh = mesh
        ring.rotation_degrees = Vector3(0, index * 42.0, 0)
        ring.material_override = _slash_material(color, 4.0)
        effect.add_child(ring)
        var tween := effect.create_tween().set_parallel(true)
        tween.tween_property(ring, "scale", Vector3.ONE * scale_factor, 0.72 + index * 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tween.tween_property(ring, "material_override:albedo_color:a", 0.0, 0.72 + index * 0.08)
    var cleanup := effect.create_tween()
    cleanup.tween_property(light, "light_energy", 0.0, 0.85)
    cleanup.finished.connect(effect.queue_free)

static func _spawn_meteor(parent: Node3D, target: Vector3, color: Color) -> void:
    var effect := Node3D.new()
    effect.name = "MeteorLance"
    effect.position = target + Vector3(0, 7.0, 0)
    parent.add_child(effect)
    var meteor := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.34
    mesh.height = 0.68
    meteor.mesh = mesh
    meteor.material_override = _slash_material(color, 6.0)
    effect.add_child(meteor)
    var light := OmniLight3D.new()
    light.light_color = color
    light.light_energy = 8.0
    light.omni_range = 5.0
    effect.add_child(light)
    var tween := effect.create_tween()
    tween.tween_property(effect, "global_position", target + Vector3(0, 0.8, 0), 0.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tween.finished.connect(func():
        _spawn_ring_burst(parent, target, color, 3, 2.2)
        effect.queue_free()
    )

static func _spawn_thrust_wave(parent: Node3D, origin: Vector3, target: Vector3, color: Color, scale_factor: float) -> void:
    var effect := Node3D.new()
    effect.name = "SpearSkillWave"
    effect.position = origin
    effect.look_at(target + Vector3(0, 1.0, 0), Vector3.UP)
    parent.add_child(effect)
    var wave := MeshInstance3D.new()
    var mesh := QuadMesh.new()
    mesh.size = Vector2(1.2 * scale_factor, 0.46 * scale_factor)
    wave.mesh = mesh
    wave.material_override = _slash_material(color, 4.6)
    effect.add_child(wave)
    var distance := origin.distance_to(target)
    var duration: float = clampf(distance / 14.0, 0.15, 0.48)
    var tween := effect.create_tween().set_parallel(true)
    tween.tween_property(effect, "position:z", -distance, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(wave, "scale", Vector3(1.8, 1.8, 1.8), duration)
    tween.tween_property(wave, "material_override:albedo_color:a", 0.0, duration)
    tween.finished.connect(effect.queue_free)

static func spawn_death_effect(parent: Node3D, origin: Vector3) -> void:
    var effect := Node3D.new()
    effect.name = "MonsterDeathVFX"
    effect.position = origin + Vector3(0, 0.5, 0)
    parent.add_child(effect)
    var light := OmniLight3D.new()
    light.light_color = Color("#e6a8ff")
    light.light_energy = 5.0
    light.omni_range = 4.5
    effect.add_child(light)
    for index in range(3):
        var ring := MeshInstance3D.new()
        var mesh := TorusMesh.new()
        mesh.inner_radius = 0.2 + index * 0.12
        mesh.outer_radius = 0.34 + index * 0.16
        ring.mesh = mesh
        ring.position.y = 0.45 + index * 0.2
        ring.rotation_degrees = Vector3(0, index * 48.0, 0)
        ring.material_override = _slash_material(Color("#d8a5ff"), 2.5)
        effect.add_child(ring)
        var tween := effect.create_tween().set_parallel(true)
        tween.tween_property(ring, "scale", Vector3.ONE * (2.6 + index * 0.35), 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tween.tween_property(ring, "material_override:albedo_color:a", 0.0, 0.72).set_delay(index * 0.05)
    var flash := MeshInstance3D.new()
    var flash_mesh := SphereMesh.new()
    flash_mesh.radius = 0.35
    flash_mesh.height = 0.7
    flash.mesh = flash_mesh
    flash.material_override = _slash_material(Color("#fff1bd"), 4.0)
    effect.add_child(flash)
    var flash_tween := effect.create_tween().set_parallel(true)
    flash_tween.tween_property(flash, "scale", Vector3.ONE * 3.8, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    flash_tween.tween_property(flash, "material_override:albedo_color:a", 0.0, 0.55)
    var light_tween := effect.create_tween()
    light_tween.tween_property(light, "light_energy", 0.0, 0.8)
    light_tween.finished.connect(effect.queue_free)

static func _slash_material(color: Color, emission_energy: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = emission_energy
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material
