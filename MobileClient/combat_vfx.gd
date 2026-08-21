extends Node

static func spawn_weapon_slash(parent: Node3D, origin: Vector3, facing: float) -> void:
    var effect := Node3D.new()
    effect.name = "CelestialWeaponSlash"
    effect.position = origin + Vector3(0, 1.05, 0)
    effect.rotation.y = facing
    parent.add_child(effect)
    for index in range(3):
        var slash := MeshInstance3D.new()
        var mesh := QuadMesh.new()
        mesh.size = Vector2(2.8 - index * 0.32, 0.72 - index * 0.08)
        slash.mesh = mesh
        slash.rotation_degrees = Vector3(-14 + index * 14, 0, -32 + index * 13)
        slash.position = Vector3(0, index * 0.12, -0.32 - index * 0.11)
        slash.material_override = _arc_material(Color("#f7d27c") if index == 0 else Color("#66d9ff"), 5.0 - index * 0.6)
        effect.add_child(slash)
        var tween := effect.create_tween().set_parallel(true)
        tween.tween_property(slash, "scale", Vector3(1.85, 1.85, 1.85), 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tween.tween_property(slash, "material_override:shader_parameter/fade", 0.0, 0.36).set_trans(Tween.TRANS_SINE)
    _add_spark_burst(effect, Color("#f7d27c"), 22, 0.42)
    _add_flash_light(effect, Color("#ffd98a"), 5.0, 4.5, 0.42)
    _finish_after(effect, 0.52)

static func spawn_magic_projectile(parent: Node3D, origin: Vector3, target: Vector3) -> void:
    var effect := Node3D.new()
    effect.name = "CelestialCastProjectile"
    effect.position = origin
    parent.add_child(effect)
    var orb := MeshInstance3D.new()
    var orb_mesh := SphereMesh.new()
    orb_mesh.radius = 0.24
    orb_mesh.height = 0.48
    orb_mesh.radial_segments = 32
    orb_mesh.rings = 16
    orb.mesh = orb_mesh
    orb.material_override = _orb_material(Color("#65d9ff"), 7.0)
    effect.add_child(orb)
    for index in range(2):
        var orbit := MeshInstance3D.new()
        var orbit_mesh := TorusMesh.new()
        orbit_mesh.inner_radius = 0.31 + index * 0.1
        orbit_mesh.outer_radius = 0.34 + index * 0.1
        orbit_mesh.rings = 32
        orbit_mesh.ring_segments = 18
        orbit.mesh = orbit_mesh
        orbit.rotation_degrees = Vector3(25 + index * 58, 20, index * 33)
        orbit.material_override = _arc_material(Color("#9df2ff"), 4.0)
        effect.add_child(orbit)
        var orbit_tween := effect.create_tween().set_loops(4)
        orbit_tween.tween_property(orbit, "rotation_degrees:y", 380.0 + index * 120.0, 0.8 + index * 0.16)
    _add_spark_burst(effect, Color("#8defff"), 18, 0.32)
    _add_flash_light(effect, Color("#63d9ff"), 7.0, 4.8, 0.7)
    var distance := origin.distance_to(target)
    var duration: float = clampf(distance / 13.0, 0.2, 0.78)
    var tween := effect.create_tween()
    tween.tween_property(effect, "global_position", target + Vector3(0, 1.0, 0), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tween.finished.connect(func():
        _spawn_ring_burst(parent, target + Vector3(0, 0.35, 0), Color("#75e5ff"), 3, 1.55)
        FloatingDamage.spawn_hit_effect(parent, target + Vector3(0, 1.0, 0))
        effect.queue_free()
    )

static func spawn_skill_vfx(parent: Node3D, skill_id: String, origin: Vector3, target: Vector3, color: Color) -> void:
    match skill_id:
        "arcane_bolt":
            spawn_magic_projectile(parent, origin, target)
        "frost_nova":
            _spawn_ring_burst(parent, target + Vector3(0, 0.1, 0), color, 4, 1.65)
            spawn_magic_projectile(parent, origin, target)
        "meteor_lance":
            _spawn_meteor(parent, target, color)
        "piercing_thrust":
            _spawn_thrust_wave(parent, origin, target, color, 1.1)
        "whirlwind_sweep":
            _spawn_ring_burst(parent, target + Vector3(0, 0.2, 0), color, 3, 2.0)
        "dragon_impale":
            _spawn_thrust_wave(parent, origin, target, color, 2.5)
        _:
            spawn_weapon_slash(parent, origin, 0.0)

static func _spawn_ring_burst(parent: Node3D, origin: Vector3, color: Color, ring_count: int, scale_factor: float) -> void:
    var effect := Node3D.new()
    effect.name = "CelestialShockwave"
    effect.position = origin
    parent.add_child(effect)
    for index in range(ring_count):
        var ring := MeshInstance3D.new()
        var mesh := TorusMesh.new()
        mesh.inner_radius = 0.25 + index * 0.18
        mesh.outer_radius = 0.29 + index * 0.18
        mesh.rings = 40
        mesh.ring_segments = 20
        ring.mesh = mesh
        ring.rotation_degrees = Vector3(0, index * 37.0, 0)
        ring.material_override = _arc_material(color.lightened(index * 0.05), 4.8)
        effect.add_child(ring)
        var tween := effect.create_tween().set_parallel(true)
        var duration := 0.72 + index * 0.08
        tween.tween_property(ring, "scale", Vector3.ONE * scale_factor, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tween.tween_property(ring, "material_override:shader_parameter/fade", 0.0, duration)
    _add_spark_burst(effect, color, 32, 0.7)
    _add_flash_light(effect, color, 6.0, 5.0, 0.85)
    _finish_after(effect, 1.02)

static func _spawn_meteor(parent: Node3D, target: Vector3, color: Color) -> void:
    var effect := Node3D.new()
    effect.name = "CelestialMeteorLance"
    effect.position = target + Vector3(0, 8.0, 0)
    parent.add_child(effect)
    var meteor := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.42
    mesh.height = 0.84
    mesh.radial_segments = 32
    mesh.rings = 16
    meteor.mesh = mesh
    meteor.material_override = _orb_material(color, 8.0)
    effect.add_child(meteor)
    var tail := MeshInstance3D.new()
    var tail_mesh := CylinderMesh.new()
    tail_mesh.top_radius = 0.04
    tail_mesh.bottom_radius = 0.34
    tail_mesh.height = 2.4
    tail.mesh = tail_mesh
    tail.position.y = 1.1
    tail.material_override = _arc_material(color.lightened(0.2), 5.5)
    effect.add_child(tail)
    _add_spark_burst(effect, color, 30, 0.8)
    _add_flash_light(effect, color, 9.0, 6.0, 0.8)
    var tween := effect.create_tween()
    tween.tween_property(effect, "global_position", target + Vector3(0, 0.8, 0), 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tween.finished.connect(func():
        _spawn_ring_burst(parent, target, color, 4, 2.35)
        effect.queue_free()
    )

static func _spawn_thrust_wave(parent: Node3D, origin: Vector3, target: Vector3, color: Color, scale_factor: float) -> void:
    var effect := Node3D.new()
    effect.name = "DragonSpearWave"
    effect.position = origin
    effect.look_at(target + Vector3(0, 1.0, 0), Vector3.UP)
    parent.add_child(effect)
    for index in range(2):
        var wave := MeshInstance3D.new()
        var mesh := QuadMesh.new()
        mesh.size = Vector2(1.45 * scale_factor, 0.62 * scale_factor)
        wave.mesh = mesh
        wave.position = Vector3(0, 0.15 * index, -0.28 - index * 0.12)
        wave.rotation_degrees.z = -12 + index * 24
        wave.material_override = _arc_material(color.lightened(index * 0.1), 5.5)
        effect.add_child(wave)
        var wave_tween := effect.create_tween().set_parallel(true)
        wave_tween.tween_property(wave, "scale", Vector3(2.1, 2.1, 2.1), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        wave_tween.tween_property(wave, "material_override:shader_parameter/fade", 0.0, 0.5)
    _add_spark_burst(effect, color, 20, 0.42)
    var distance := origin.distance_to(target)
    var duration: float = clampf(distance / 14.0, 0.15, 0.52)
    var tween := effect.create_tween().set_parallel(true)
    tween.tween_property(effect, "position:z", -distance, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(effect, "scale", Vector3.ONE * 1.2, duration)
    tween.finished.connect(func():
        _spawn_ring_burst(parent, target, color, 2, 1.4)
        effect.queue_free()
    )

static func spawn_death_effect(parent: Node3D, origin: Vector3) -> void:
    var effect := Node3D.new()
    effect.name = "CelestialMonsterDissolve"
    effect.position = origin + Vector3(0, 0.5, 0)
    parent.add_child(effect)
    _spawn_ring_burst(effect, Vector3.ZERO, Color("#c7a1ff"), 3, 1.9)
    _add_spark_burst(effect, Color("#d7c1ff"), 38, 0.9)
    _add_flash_light(effect, Color("#e4c8ff"), 7.5, 5.0, 0.7)
    _finish_after(effect, 1.0)

static func _arc_material(color: Color, emission_energy: float) -> ShaderMaterial:
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;
uniform vec4 tint : source_color;
uniform float intensity = 4.0;
uniform float fade = 1.0;
void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float edge = smoothstep(1.0, 0.12, length(p));
    float filament = smoothstep(0.24, 0.0, abs(p.y + p.x * 0.18));
    float alpha = edge * filament * fade;
    ALBEDO = tint.rgb;
    EMISSION = tint.rgb * intensity;
    ALPHA = alpha;
}
"""
    var material := ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("tint", color)
    material.set_shader_parameter("intensity", emission_energy)
    material.set_shader_parameter("fade", 1.0)
    return material

static func _orb_material(color: Color, emission_energy: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = emission_energy
    material.metallic = 0.22
    material.roughness = 0.1
    material.clearcoat_enabled = true
    material.clearcoat = 0.55
    return material

static func _add_spark_burst(parent: Node3D, color: Color, amount: int, lifetime: float) -> void:
    var particles := GPUParticles3D.new()
    particles.amount = amount
    particles.lifetime = lifetime
    particles.one_shot = true
    particles.explosiveness = 1.0
    particles.local_coords = true
    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    process.emission_sphere_radius = 0.22
    process.direction = Vector3(0, 1, 0)
    process.spread = 180.0
    process.initial_velocity_min = 1.0
    process.initial_velocity_max = 3.2
    process.gravity = Vector3(0, -2.4, 0)
    process.scale_min = 0.04
    process.scale_max = 0.11
    particles.process_material = process
    var spark_mesh := SphereMesh.new()
    spark_mesh.radius = 0.06
    spark_mesh.height = 0.12
    spark_mesh.radial_segments = 10
    particles.draw_pass_1 = spark_mesh
    particles.draw_pass_1.material = _orb_material(color, 4.5)
    parent.add_child(particles)

static func _add_flash_light(parent: Node3D, color: Color, energy: float, radius: float, duration: float) -> void:
    var light := OmniLight3D.new()
    light.light_color = color
    light.light_energy = energy
    light.omni_range = radius
    parent.add_child(light)
    var tween := parent.create_tween()
    tween.tween_property(light, "light_energy", 0.0, duration)
    tween.finished.connect(light.queue_free)

static func _finish_after(parent: Node3D, duration: float) -> void:
    var timer := parent.get_tree().create_timer(duration)
    timer.timeout.connect(parent.queue_free)
