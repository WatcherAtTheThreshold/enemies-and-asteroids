class_name Asteroid
extends CharacterBody2D

signal asteroid_destroyed(position: Vector2, size_category: String)

@export var move_speed: float = 60.0
@export var rotation_speed: float = 0.5
@export var resource_drop_count: int = 2
@export var resource_drop_scene: PackedScene
@export var size_category: String = "small"
@export var impact_damage: int = 5

var _move_direction: Vector2

func _ready() -> void:
	var sizes = {"small": 24, "medium": 40, "large": 64}
	Placeholder.circle($Sprite2D, Color(0.6, 0.5, 0.35), sizes.get(size_category, 24))
	add_to_group("asteroid")
	# Random downward angle with left/right spread (60–120 deg)
	# In Godot Y increases downward, so 90° = straight down
	var angle = randf_range(deg_to_rad(60), deg_to_rad(120))
	_move_direction = Vector2(cos(angle), sin(angle))
	$HealthComponent.died.connect(_on_health_component_died)

func _physics_process(delta: float) -> void:
	rotation += rotation_speed * delta
	velocity = _move_direction * move_speed
	move_and_slide()
	_check_impact_collisions()

func _check_impact_collisions() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("base"):
			SoundManager.asteroid_hit_base()
			collider.take_damage(impact_damage)
			_die(false)  # base hit: no score signal
			return
		elif collider.is_in_group("ground"):
			SoundManager.asteroid_hit_ground()
			_break_apart()
			return
		elif collider.is_in_group("player"):
			collider.take_damage(impact_damage)
			_die(false)  # player hit: no score signal
			return

# Called by weapons via the HitboxArea2D
func take_damage(amount: int) -> void:
	$HealthComponent.take_damage(amount)

func _on_health_component_died() -> void:
	_die(true)

# Destroyed by player — emits signal for scoring
func _die(emit_signal_flag: bool) -> void:
	if emit_signal_flag:
		asteroid_destroyed.emit(global_position, size_category)
		GameManager.on_asteroid_destroyed(global_position, size_category)
	_spawn_resources()
	queue_free()

# Hit the ground — scatter resources, no score
func _break_apart() -> void:
	_spawn_resources()
	queue_free()

const ASTEROID_DROP_POOL: Array = ["general", "general", "general", "physical", "physical", "shield"]

func _spawn_resources() -> void:
	if resource_drop_scene == null:
		return
	for i in resource_drop_count:
		var res = resource_drop_scene.instantiate()
		res.resource_type = ASTEROID_DROP_POOL.pick_random()
		res.global_position = global_position + Vector2(
			randf_range(-20.0, 20.0),
			randf_range(-20.0, 20.0)
		)
		get_parent().add_child(res)
