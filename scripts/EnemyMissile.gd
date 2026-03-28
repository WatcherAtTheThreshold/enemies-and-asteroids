class_name EnemyMissile
extends Area2D

# Set by EnemyShip at spawn time
var target_position: Vector2 = Vector2.ZERO
var is_enemy_missile: bool = true  # flag so player weapons can identify and destroy this

const SPEED: float = 150.0
const DAMAGE: int = 10

var _direction: Vector2

func _ready() -> void:
	Placeholder.rect($Sprite2D, Color(1.0, 0.1, 0.1), 12, 24)
	_direction = (target_position - global_position).normalized()
	rotation = _direction.angle() + PI / 2.0
	add_to_group("enemy_missile")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position += _direction * SPEED * delta
	# Cull once well below screen (missiles travel downward toward the base)
	var vp = get_viewport_rect()
	if position.y > vp.size.y + 150.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("base"):
		body.take_damage(DAMAGE)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Intercepted by a player projectile
	if area.is_in_group("player_projectile"):
		queue_free()
