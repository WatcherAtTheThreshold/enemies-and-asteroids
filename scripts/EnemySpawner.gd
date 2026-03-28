class_name EnemySpawner
extends Node2D

@export var enemy_scene: PackedScene
@export var resource_drop_scene: PackedScene
@export var projectile_scene: PackedScene
@export var missile_scene: PackedScene

# Every Nth day triggers an enemy wave at end of day
@export var enemy_day_cycle: int = 5

# Set by Main/GameManager so the enemy knows what to target
var player: Node2D = null
var base: Node2D = null

var day_number: int = 1

# --- Called by GameManager at end of each day ---

func check_for_enemy_day(day: int) -> void:
	day_number = day
	if day % enemy_day_cycle == 0:
		GameManager.enemy_day_started.emit(day_number)
		spawn_enemy()

# --- Called mid-day by GameManager once day >= 10 ---

func try_midday_spawn(day: int) -> void:
	day_number = day
	if day >= 10:
		spawn_enemy()

# --- Spawn ---

func spawn_enemy() -> void:
	if enemy_scene == null:
		push_warning("EnemySpawner: enemy_scene not assigned")
		return

	var enemy = enemy_scene.instantiate()

	# Enter from top-center
	enemy.position = Vector2(get_viewport_rect().size.x / 2.0, -100.0)

	# Pass combat targets (null-safe — enemy checks before firing)
	enemy.player = player
	enemy.base = base

	# Pass weapon and drop scenes
	enemy.resource_drop_scene = resource_drop_scene
	enemy.projectile_scene = projectile_scene
	enemy.missile_scene = missile_scene

	# enemy_destroyed signal: EnemyShip already calls GameManager.on_enemy_defeated()
	# directly in _die(), so no additional connection is needed here.
	# Connect here only if other systems need to react (e.g. UI, cutscenes).

	get_parent().add_child(enemy)
