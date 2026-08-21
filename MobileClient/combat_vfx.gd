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
