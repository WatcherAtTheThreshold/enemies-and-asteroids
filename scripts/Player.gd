class_name Player
extends CharacterBody2D

@export var move_speed: float = 200.0
@export var fire_rate: float = 0.15
@export var projectile_scene: PackedScene
var projectile_damage: int = 1

var _fire_timer: float = 0.0
var _last_shoot_dir: Vector2 = Vector2.UP  # default aim upward
var _thruster_timer: float = 0.0
const THRUSTER_FRAME_TIME: float = 0.08

func _ready() -> void:
	Placeholder.rect($Sprite2D, Color(0.2, 0.9, 0.3), 32, 32)
	add_to_group("player")
	$HealthComponent.died.connect(_on_died)
	$HealthComponent.health_changed.connect(_on_health_changed)

func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_shooting(delta)

# --- Movement (WASD + Left Stick) ---

func _handle_movement() -> void:
	var dir = Vector2.ZERO

	if Input.is_key_pressed(KEY_W): dir.y -= 1.0
	if Input.is_key_pressed(KEY_S): dir.y += 1.0
	if Input.is_key_pressed(KEY_A): dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): dir.x += 1.0

	# Left stick
	dir.x += Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	dir.y += Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)

	velocity = dir.limit_length(1.0) * move_speed
	move_and_slide()
	_update_thruster(dir.length())

# --- Shooting (Arrow Keys + Right Stick) ---

func _handle_shooting(delta: float) -> void:
	_fire_timer -= delta

	var shoot_dir = Vector2.ZERO

	if Input.is_key_pressed(KEY_UP):    shoot_dir.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN):  shoot_dir.y += 1.0
	if Input.is_key_pressed(KEY_LEFT):  shoot_dir.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT): shoot_dir.x += 1.0

	# Right stick (deadzone applied manually)
	var stick = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	if stick.length() > 0.2:
		shoot_dir += stick

	if shoot_dir.length() > 0.0:
		_last_shoot_dir = shoot_dir.normalized()

	# Rotate ship to face shoot direction (holds last direction when stick is neutral)
	rotation = _last_shoot_dir.angle() + PI / 2.0

	# Fire if a direction is held and timer is ready
	if shoot_dir.length() > 0.0 and _fire_timer <= 0.0:
		_fire_timer = fire_rate
		_spawn_projectile(_last_shoot_dir)

func _update_thruster(input_length: float) -> void:
	var thruster = $Thruster
	if input_length < 0.1:
		thruster.visible = false
		return
	thruster.visible = true
	_thruster_timer -= get_physics_process_delta_time()
	if _thruster_timer <= 0.0:
		_thruster_timer = THRUSTER_FRAME_TIME
		thruster.frame = (thruster.frame + 1) % 3

func _spawn_projectile(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var proj = projectile_scene.instantiate()
	proj.global_position = $WeaponMount.global_position
	proj.direction = dir
	proj.DAMAGE = projectile_damage
	get_parent().add_child(proj)

# --- Damage ---

func take_damage(amount: int) -> void:
	$HealthComponent.take_damage(amount)

func _on_health_changed(current_hp: int, max_hp_val: int) -> void:
	_flash_damage()
	_screen_shake(current_hp, max_hp_val)

func _flash_damage() -> void:
	$Sprite2D.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.25)

func _screen_shake(current_hp: int, max_hp: int) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return
	var intensity = lerp(4.0, 14.0, 1.0 - float(current_hp) / float(max_hp))
	var tween = create_tween()
	for i in 6:
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", offset, 0.03)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)

func _on_died() -> void:
	GameManager.trigger_game_over("ship")
