class_name AnimalMobModel
extends Node3D

var rarity := 0

var _animation_player: AnimationPlayer
var _base_animation := "idle"
var _attack_timer := 0.0
var _attack_duration := 0.8

func configure_animal(value: int = 0) -> void:
    rarity = value
    for child in get_children():
        remove_child(child)
        child.free()
    _build_imported_animal()

func _process(delta: float) -> void:
    if _attack_timer > 0.0:
        _attack_timer = max(0.0, _attack_timer - delta)
        if _attack_timer <= 0.0:
            _play_base_animation()

func set_animation_state(state: String) -> void:
    if _attack_timer <= 0.0:
        _base_animation = "walk" if state == "walk" else "idle"
        _play_base_animation()

func play_attack() -> void:
    _attack_timer = _attack_duration
    if _animation_player and _animation_player.has_animation("attack"):
        _animation_player.play("attack")

func _build_imported_animal() -> void:
    var loader_script := load("res://asset_loader.gd")
    if loader_script == null:
        return
    var imported: Node3D = loader_script.instantiate_monster()
    if imported == null:
        return
    imported.name = "MangyangVisual"
    imported.scale = Vector3.ONE * 2.6
    imported.position = Vector3(0, 0.02, 0)
    add_child(imported)

    _animation_player = imported.find_child("AnimationPlayer", true, false) as AnimationPlayer
    if _animation_player:
        for animation_name in ["idle", "walk"]:
            if _animation_player.has_animation(animation_name):
                var anim: Animation = _animation_player.get_animation(animation_name)
                anim.loop_mode = Animation.LOOP_LINEAR
        _animation_player.play("idle")

func _play_base_animation() -> void:
    if _animation_player and _animation_player.has_animation(_base_animation):
        _animation_player.play(_base_animation)
