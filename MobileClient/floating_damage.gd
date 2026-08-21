class_name FloatingDamage
extends Node3D

func show_damage(amount: int, critical: bool = false) -> void:
    var label := Label3D.new()
    label.text = "-%d" % amount
    label.font_size = 58 if critical else 46
    label.outline_size = 12
    label.modulate = Color("#ffe27e") if critical else Color("#ff8f76")
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(label)
    var start := global_position
    var tween := create_tween().set_parallel(true)
    tween.tween_property(self, "global_position", start + Vector3(0, 1.8, 0), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.35)
    tween.finished.connect(queue_free)

static func spawn_hit_effect(parent: Node3D, position: Vector3) -> void:
    var flash := OmniLight3D.new()
    flash.position = position + Vector3(0, 0.8, 0)
    flash.light_color = Color("#ffe18a")
    flash.light_energy = 5.0
    flash.omni_range = 3.2
    parent.add_child(flash)
    var pulse := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.22
    mesh.height = 0.44
    pulse.mesh = mesh
    pulse.position = flash.position
    pulse.material_override = _effect_material()
    parent.add_child(pulse)
    var tween := parent.create_tween().set_parallel(true)
    tween.tween_property(flash, "light_energy", 0.0, 0.28)
    tween.tween_property(pulse, "scale", Vector3.ONE * 4.0, 0.28)
    tween.tween_property(pulse, "transparency", 1.0, 0.28)
    tween.finished.connect(func():
        flash.queue_free()
        pulse.queue_free()
    )

static func _effect_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#ffcc66")
    material.emission_enabled = true
    material.emission = Color("#ff7a45")
    material.emission_energy_multiplier = 4.0
    return material
