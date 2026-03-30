class_name AsteroidSpawner
extends Node2D

@export var small_asteroid_scene: PackedScene
@export var medium_asteroid_scene: PackedScene
@export var large_asteroid_scene: PackedScene
@export var resource_drop_scene: PackedScene

@export var base_spawn_interval: float = 2.5
@export var min_spawn_interval: float = 0.6

var day_number: int = 1

# Horizontal spawn positions as a fraction of viewport width
const SPAWN_X_FRACTIONS: Array = [0.15, 0.5, 0.85]
const SPAWN_Y_OFFSET: float = -60.0  # above top edge of screen

func _ready() -> void:
	$SpawnTimer.timeout.connect(_on_spawn_timer_timeout)

func start_day(day: int) -> void:
	day_number = day
	$SpawnTimer.wait_time = _interval_for_day(day)
	$SpawnTimer.start()

func stop_spawning() -> void:
	$SpawnTimer.stop()

func _on_spawn_timer_timeout() -> void:
	spawn_asteroid()
	# Re-set wait_time each tick so interval changes mid-day if needed
	$SpawnTimer.wait_time = _interval_for_day(day_number)

func spawn_asteroid() -> void:
	var scene = _pick_scene_for_day()
	if scene == null:
		push_warning("AsteroidSpawner: no scene available for day %d" % day_number)
		return

	var asteroid = scene.instantiate()

	# Wire in scenes so the asteroid can spawn pickups and split on death
	asteroid.resource_drop_scene = resource_drop_scene
	asteroid.split_scene_small = small_asteroid_scene
	asteroid.split_scene_medium = medium_asteroid_scene

	# Scale HP for difficulty — must happen before add_child so _ready() picks it up
	var mult: float = _hp_multiplier_for_day(day_number)
	asteroid._day_hp_multiplier = mult
	var health: Node = asteroid.get_node("HealthComponent")
	health.max_hp = int(health.max_hp * mult)

	# Position: one of three horizontal zones, randomised within each zone
	var vp_size = get_viewport_rect().size
	var zone_x = SPAWN_X_FRACTIONS[randi() % SPAWN_X_FRACTIONS.size()]
	asteroid.position = Vector2(
		vp_size.x * zone_x + randf_range(-120.0, 120.0),
		SPAWN_Y_OFFSET
	)

	# Connect destroyed signal to GameManager
	asteroid.asteroid_destroyed.connect(GameManager.on_asteroid_destroyed)

	get_parent().add_child(asteroid)

# --- Difficulty helpers ---

func _pick_scene_for_day() -> PackedScene:
	var s = small_asteroid_scene
	var m = medium_asteroid_scene
	var l = large_asteroid_scene
	# Pool sizes are tuned accounting for the split mechanic —
	# large/medium are much more dangerous than raw HP suggests.
	var pool: Array
	if day_number <= 2:
		pool = [s, s, s, s, s]
	elif day_number <= 4:
		pool = [s, s, s, s, m]
	elif day_number <= 6:
		pool = [s, s, s, m, m]
	elif day_number <= 8:
		pool = [s, s, m, m, l]
	elif day_number <= 11:
		pool = [s, m, m, l, l]
	else:
		pool = [s, m, l, l, l, l]
	return pool.pick_random()

func _interval_for_day(day: int) -> float:
	return maxf(min_spawn_interval, base_spawn_interval - (day * 0.1))

func _hp_multiplier_for_day(day: int) -> float:
	if day <= 3:
		return 1.0
	elif day <= 6:
		return 1.3
	elif day <= 9:
		return 1.6
	elif day <= 13:
		return 2.0
	else:
		return 2.5
