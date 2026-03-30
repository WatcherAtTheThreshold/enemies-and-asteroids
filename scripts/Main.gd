extends Node2D

# Assign these in the inspector after adding scenes to Main
@export var asteroid_spawner: AsteroidSpawner
@export var enemy_spawner: EnemySpawner
@export var player: Player
@export var base: Base
@export var game_over_scene: PackedScene
@export var upgrade_screen_scene: PackedScene

# Seconds to wait after a day ends before the next one starts (no enemy)
@export var day_transition_delay: float = 0.5
# Seconds to wait after enemy defeat before the upgrade screen appears
@export var upgrade_delay: float = 2.5

var _day_running: bool = false
var _waiting_for_enemy: bool = false

func _ready() -> void:
	# Pass player/base references to the enemy spawner
	if enemy_spawner:
		enemy_spawner.player = player
		enemy_spawner.base = base

	# Base exiting the screen is what ends the day
	if base:
		base.base_exited_screen.connect(end_day)

	# Listen for enemy defeated so we can advance the day after an enemy wave
	GameManager.enemy_defeated.connect(_on_enemy_defeated)
	GameManager.game_over.connect(_on_game_over)

	start_day(1)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_F11 and event.pressed):
		var mode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _process(_delta: float) -> void:
	pass  # day end is driven by base_exited_screen signal

# --- Day Cycle ---

func start_day(day: int) -> void:
	_day_running = true
	_waiting_for_enemy = false

	if asteroid_spawner:
		asteroid_spawner.start_day(day)

	# Late-game: enemies can also appear mid-day (day 10+)
	if enemy_spawner and day >= 10:
		enemy_spawner.try_midday_spawn(day)

	GameManager.start_day(day)

func end_day() -> void:
	_day_running = false

	if asteroid_spawner:
		asteroid_spawner.stop_spawning()

	GameManager.end_day()

	# Check if this is an enemy day — if so, hold upgrades until enemy is defeated
	if enemy_spawner and GameManager.day_number % enemy_spawner.enemy_day_cycle == 0:
		_waiting_for_enemy = true
		enemy_spawner.check_for_enemy_day(GameManager.day_number)
	else:
		_show_upgrades()

func _on_enemy_defeated() -> void:
	if _waiting_for_enemy:
		_waiting_for_enemy = false
		_show_upgrades()

func _show_upgrades() -> void:
	if upgrade_screen_scene == null:
		_begin_next_day_after_delay()
		return
	await get_tree().create_timer(upgrade_delay).timeout
	get_tree().paused = true
	var overlay = upgrade_screen_scene.instantiate()
	add_child(overlay)
	overlay.upgrade_chosen.connect(_on_upgrade_chosen.bind(overlay))
	overlay.show_upgrades(player, base, asteroid_spawner)

func _on_upgrade_chosen(overlay: Node) -> void:
	overlay.queue_free()
	get_tree().paused = false
	_begin_next_day_after_delay()

func _begin_next_day_after_delay() -> void:
	await get_tree().create_timer(day_transition_delay).timeout
	start_day(GameManager.day_number + 1)

func _on_game_over(cause: String) -> void:
	# Stop asteroid spawning (enemy spawner is event-driven, nothing to stop)
	if asteroid_spawner:
		asteroid_spawner.stop_spawning()
	# Show overlay
	if game_over_scene:
		var overlay = game_over_scene.instantiate()
		add_child(overlay)
		overlay.show_game_over(cause)
