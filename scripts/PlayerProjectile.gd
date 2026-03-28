class_name PlayerProjectile
extends Area2D

# Set by Player at spawn time
var direction: Vector2 = Vector2.UP

const SPEED: float = 500.0
const DAMAGE: int = 1

func _ready() -> void:
	Placeholder.rect($Sprite2D, Color(0.6, 1.0, 0.2), 8, 16)
	SoundManager.player_fire()
	add_to_group("player_projectile")
	rotation = direction.angle() + PI / 2.0
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	var vp = get_viewport_rect()
	if (position.x < -100.0 or position.x > vp.size.x + 100.0
			or position.y < -100.0 or position.y > vp.size.y + 100.0):
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Hit an enemy or asteroid via their HitboxArea2D, or intercept a missile
	var parent = area.get_parent()
	if parent.has_method("take_damage"):
		parent.take_damage(DAMAGE)
		queue_free()
	elif area.is_in_group("enemy_missile"):
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		queue_free()
