extends Node

# --- Signals ---
signal day_started(day_number: int)
signal day_ended(day_number: int)
signal enemy_day_started(day_number: int)
signal enemy_defeated()
signal asteroid_destroyed(position: Vector2, size: String)
signal resource_collected(type: String)
signal game_over(cause: String)

# --- State ---
var day_number: int = 1
var is_day_active: bool = false

var resources: Dictionary = {
	"general":  0,
	"shield":   0,
	"weapon":   0,
	"physical": 0,
}

# --- Day Management ---

func start_day(day: int) -> void:
	day_number = day
	is_day_active = true
	day_started.emit(day_number)

func end_day() -> void:
	is_day_active = false
	day_ended.emit(day_number)

# --- Resource Management ---

func add_resource(type: String) -> void:
	if resources.has(type):
		resources[type] += 1
		resource_collected.emit(type)
	else:
		push_warning("GameManager: unknown resource type '%s'" % type)

func get_resource(type: String) -> int:
	return resources.get(type, 0)

func spend_resource(type: String, amount: int) -> bool:
	if get_resource(type) >= amount:
		resources[type] -= amount
		resource_collected.emit(type)
		return true
	return false

# --- Event Receivers ---
# Connect asteroid/enemy signals here so GameManager stays in the loop.

func on_asteroid_destroyed(pos: Vector2, size: String) -> void:
	asteroid_destroyed.emit(pos, size)

func on_enemy_defeated() -> void:
	enemy_defeated.emit()

func trigger_game_over(cause: String) -> void:
	is_day_active = false
	game_over.emit(cause)
