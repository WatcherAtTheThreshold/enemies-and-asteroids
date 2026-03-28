class_name HealthComponent
extends Node

# Emitted when HP reaches zero. Parent node is responsible for death logic.
signal died

# Emitted on any HP change — useful for driving HP bars.
signal health_changed(current_hp: int, max_hp: int)

@export var max_hp: int = 10

var current_hp: int

func _ready() -> void:
	current_hp = max_hp

func take_damage(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		died.emit()

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)

func get_health_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return float(current_hp) / float(max_hp)

func is_dead() -> bool:
	return current_hp <= 0
