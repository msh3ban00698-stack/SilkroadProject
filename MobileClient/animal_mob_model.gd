class_name AnimalMobModel
extends Node3D

var rarity := 0

func configure_animal(value: int = 0) -> void:
    rarity = value
    for child in get_children():
        remove_child(child)
        child.free()
    _build_animal()

func _build_animal() -> void:
    var loader_script = load("res://asset_loader.gd")
    if loader_script:
        var imported_orc = loader_script.instantiate_monster()
        if imported_orc:
            imported_orc.name = "MangyangVisual"
            imported_orc.scale = Vector3.ONE * 3.5
            imported_orc.position = Vector3(0, 0.02, 0)
            add_child(imported_orc)
            return
    _build_procedural_animal()

func _build_procedural_animal() -> void:
    var fur := Color("#214d59") if rarity < 2 else Color("#493d86")
    var belly := Color("#6ca7a4") if rarity < 2 else Color("#a788dc")
    var accent := Color("#e8c777")
    _sphere(0.72, 1.32, Vector3(0, 0.98, 0), fur, Vector3(1.0, 0.9, 1.3))
    _sphere(0.5, 0.86, Vector3(0, 1.18, -0.95), fur, Vector3(1.0, 0.92, 1.0))
    _sphere(0.34, 0.56, Vector3(0, 0.99, -1.28), belly, Vector3(0.95, 0.8, 0.65))
    for x in [-0.44, 0.44]:
        for z in [-0.37, 0.42]:
            _cylinder(0.15, 0.18, 0.8, Vector3(x, 0.43, z), fur)
            _sphere(0.17, 0.2, Vector3(x, 0.08, z - 0.04), Color("#583c38"), Vector3(1.0, 0.55, 1.35))
    for x in [-0.23, 0.23]:
        _sphere(0.07, 0.13, Vector3(x, 1.29, -1.55), Color("#ffe28a"), Vector3.ONE, true)
        _cone(0.12, 0.55, Vector3(x * 1.4, 1.78, -1.0), accent, Vector3(-18 if x < 0 else 18, 0, 0))
    _cone(0.2, 0.72, Vector3(-0.45, 1.78, -0.92), accent, Vector3(0, 0, -18))
    _cone(0.2, 0.72, Vector3(0.45, 1.78, -0.92), accent, Vector3(0, 0, 18))
    _torus(0.84, 0.045, Vector3(0, 0.05, 0), Color("#f2c66d"))
    _build_celestial_details(fur, accent)

func _build_celestial_details(fur: Color, accent: Color) -> void:
    for index in range(3):
        var tail := MeshInstance3D.new()
        var tail_mesh := SphereMesh.new()
        tail_mesh.radius = 0.22 - index * 0.04
        tail_mesh.height = 0.44 - index * 0.08
        tail_mesh.radial_segments = 20
        tail.mesh = tail_mesh
        tail.position = Vector3(0, 0.66 + index * 0.18, 0.78 + index * 0.18)
        tail.rotation_degrees.x = -18.0 + index * 8.0
        tail.material_override = _material(fur.lightened(0.08), 0.12, 0.55, index == 2)
        add_child(tail)
    var collar := MeshInstance3D.new()
    var collar_mesh := TorusMesh.new()
    collar_mesh.inner_radius = 0.36
    collar_mesh.outer_radius = 0.42
    collar_mesh.rings = 32
    collar_mesh.ring_segments = 16
    collar.mesh = collar_mesh
    collar.position = Vector3(0, 1.2, -0.04)
    collar.rotation_degrees.x = 90
    collar.material_override = _material(accent, 0.55, 0.2, true)
    add_child(collar)
    var aura := GPUParticles3D.new()
    aura.amount = 24
    aura.lifetime = 1.5
    aura.local_coords = true
    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    process.emission_sphere_radius = 0.82
    process.direction = Vector3(0, 1, 0)
    process.spread = 90.0
    process.initial_velocity_min = 0.08
    process.initial_velocity_max = 0.32
    process.gravity = Vector3(0, 0.35, 0)
    process.scale_min = 0.025
    process.scale_max = 0.08
    aura.process_material = process
    var spark_mesh := SphereMesh.new()
    spark_mesh.radius = 0.04
    spark_mesh.height = 0.08
    spark_mesh.radial_segments = 10
    aura.draw_pass_1 = spark_mesh
    aura.draw_pass_1.material = _material(accent, 0.2, 0.14, true)
    aura.position.y = 0.8
    add_child(aura)

func _sphere(radius: float, height: float, pos: Vector3, color: Color, scale_value: Vector3, glow := false) -> void:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = height
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    node.scale = scale_value
    node.material_override = _material(color, 0.02, 0.86, glow)
    add_child(node)

func _cylinder(top_radius: float, bottom_radius: float, height: float, pos: Vector3, color: Color) -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = top_radius
    mesh.bottom_radius = bottom_radius
    mesh.height = height
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    node.material_override = _material(color, 0.0, 0.9)
    add_child(node)

func _cone(radius: float, height: float, pos: Vector3, color: Color, rotation_value: Vector3) -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.02
    mesh.bottom_radius = radius
    mesh.height = height
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    node.rotation_degrees = rotation_value
    node.material_override = _material(color, 0.05, 0.7)
    add_child(node)

func _torus(inner_radius: float, outer_radius: float, pos: Vector3, color: Color) -> void:
    var mesh := TorusMesh.new()
    mesh.inner_radius = inner_radius
    mesh.outer_radius = inner_radius + outer_radius
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    node.material_override = _material(color, 0.25, 0.35, true)
    add_child(node)

func _material(color: Color, metallic: float, roughness: float, glow := false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    material.clearcoat_enabled = true
    material.clearcoat = 0.22
    material.clearcoat_roughness = 0.24
    material.anisotropy_enabled = true
    material.anisotropy = 0.2
    if glow:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 2.4
    return material
