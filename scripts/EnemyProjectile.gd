class_name EnemyProjectile
extends Area2D

# Set by EnemyShip at spawn time
var direction: Vector2 = Vector2.DOWN

var SPEED: float = 300.0
const DAMAGE: int = 1

func _ready() -> void:
	Placeholder.rect($Sprite2D, Color(1.0, 0.3, 0.1), 8, 16)
	body_entered.connect(_on_body_entered)
	# Rotate sprite to face travel direction
	rotation = direction.angle() + PI / 2.0

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	# Cull once off screen
	var vp = get_viewport_rect()
	if (position.x < -100.0 or position.x > vp.size.x + 100.0
			or position.y < -100.0 or position.y > vp.size.y + 100.0):
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(DAMAGE)
		queue_free()
