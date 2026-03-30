class_name EnemyShip
extends CharacterBody2D

signal enemy_destroyed(position: Vector2)

# Tunable in inspector
@export var move_speed: float = 80.0
@export var fire_rate: float = 1.5
@export var missile_fire_rate: float = 5.0
@export var resource_drop_count: int = 6
@export var resource_drop_scene: PackedScene
@export var missile_scene: PackedScene
@export var projectile_scene: PackedScene

# State machine
enum State { ENTER, COMBAT, RETREAT }
var state: State = State.ENTER

# Combat targets — set by EnemySpawner or GameManager at spawn time
var player: Node2D = null
var base: Node2D = null

var fire_timer: float = 0.0
var missile_timer: float = 0.0

func _ready() -> void:
	Placeholder.rect($Sprite2D, Color(0.8, 0.1, 0.1), 64, 64)
	add_to_group("enemy")
	SoundManager.enemy_appears()
	$HealthComponent.died.connect(_on_health_component_died)
	$HealthComponent.health_changed.connect(_on_health_changed)
	# Initialise HP bar to full
	$HPBar.max_value = $HealthComponent.max_hp
	$HPBar.value = $HealthComponent.max_hp

func _physics_process(delta: float) -> void:
	match state:
		State.ENTER:   _state_enter(delta)
		State.COMBAT:  _state_combat(delta)
		State.RETREAT: _state_retreat(delta)

# --- States ---

func _state_enter(delta: float) -> void:
	# Fly onto screen from the top
	velocity = Vector2(0.0, move_speed)
	move_and_slide()
	if position.y > 150.0:
		state = State.COMBAT

func _state_combat(delta: float) -> void:
	_strafe(delta)
	_shoot_at_player(delta)
	_shoot_missile_at_base(delta)

func _state_retreat(delta: float) -> void:
	# Reserved for future use (e.g. low-HP escape behaviour)
	velocity = Vector2(0.0, -move_speed)
	move_and_slide()
	if position.y < -100.0:
		queue_free()

# --- Weapons ---

func _shoot_at_player(delta: float) -> void:
	if player == null or projectile_scene == null:
		return
	fire_timer -= delta
	if fire_timer > 0.0:
		return
	fire_timer = fire_rate
	SoundManager.enemy_fire_projectile()
	var proj = projectile_scene.instantiate()
	proj.global_position = $WeaponMount.global_position
	proj.direction = (player.global_position - $WeaponMount.global_position).normalized()
	get_parent().add_child(proj)

func _shoot_missile_at_base(delta: float) -> void:
	if base == null or missile_scene == null:
		return
	missile_timer -= delta
	if missile_timer > 0.0:
		return
	missile_timer = missile_fire_rate
	SoundManager.enemy_fire_missile()
	var missile = missile_scene.instantiate()
	missile.global_position = $MissileLauncher.global_position
	missile.target_position = base.global_position
	get_parent().add_child(missile)

# --- Movement ---

func _strafe(delta: float) -> void:
	# Horizontal sine oscillation — feels aggressive without chasing the player yet
	var strafe_x = sin(Time.get_ticks_msec() * 0.001 * 1.5) * move_speed
	velocity = Vector2(strafe_x, 0.0)
	move_and_slide()

# --- Damage & Death ---

func take_damage(amount: int) -> void:
	$HealthComponent.take_damage(amount)

func _on_health_changed(current_hp: int, max_hp_val: int) -> void:
	$HPBar.value = current_hp

func _on_health_component_died() -> void:
	_die()

func _die() -> void:
	enemy_destroyed.emit(global_position)
	GameManager.on_enemy_defeated()
	_spawn_resources()
	queue_free()

const ENEMY_DROP_POOL: Array = ["weapon", "weapon", "shield", "general", "physical"]

func _spawn_resources() -> void:
	if resource_drop_scene == null:
		return
	for i in resource_drop_count:
		var res = resource_drop_scene.instantiate()
		res.resource_type = ENEMY_DROP_POOL.pick_random()
		res.global_position = global_position + Vector2(
			randf_range(-30.0, 30.0),
			randf_range(-30.0, 30.0)
		)
		get_parent().call_deferred("add_child", res)
