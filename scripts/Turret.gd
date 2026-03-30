class_name Turret
extends Node2D

const PROJECTILE_SCENE = preload("res://scenes/TurretProjectile.tscn")

@export var fire_rate: float = 2.0
@export var detection_range: float = 500.0
var projectile_damage: int = 1

var _fire_timer: float = 0.0
var _target: Node2D = null

func _ready() -> void:
	Placeholder.rect($Sprite2D, Color(0.8, 0.8, 0.2), 16, 24)
	add_to_group("turret")

func _physics_process(delta: float) -> void:
	_find_nearest_target()
	if _target == null:
		return
	rotation = (_target.global_position - global_position).normalized().angle() + PI / 2.0
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_rate
		_fire()

func _find_nearest_target() -> void:
	if not is_instance_valid(_target):
		_target = null
	var candidates = get_tree().get_nodes_in_group("asteroid") + get_tree().get_nodes_in_group("enemy")
	var nearest: Node2D = null
	var nearest_dist: float = detection_range
	for t in candidates:
		if not is_instance_valid(t):
			continue
		var d = global_position.distance_to(t.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = t
	_target = nearest

func _fire() -> void:
	if not is_instance_valid(_target):
		return
	var proj = PROJECTILE_SCENE.instantiate()
	proj.global_position = $WeaponMount.global_position
	proj.direction = (_target.global_position - $WeaponMount.global_position).normalized()
	proj.DAMAGE = projectile_damage
	get_tree().current_scene.add_child(proj)
