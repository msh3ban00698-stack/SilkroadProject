class_name AnimalMobModel
extends Node3D

## Phase 10.2 compatibility wrapper. Owns a MonsterVisualAdapter child and keeps
## the exact public surface that monster_mob.gd relies on
## (configure_animal / set_animation_state / play_attack).

var rarity := 0

var adapter: MonsterVisualAdapter

func configure_animal(value: int = 0) -> void:
	rarity = value
	if adapter == null:
		adapter = MonsterVisualAdapter.new()
		adapter.name = "VisualAdapter"
		add_child(adapter)
	adapter.configure_animal(value)

func set_animation_state(state: String) -> void:
	if adapter:
		adapter.set_animation_state(state)

func play_attack() -> void:
	if adapter:
		adapter.play_attack()
