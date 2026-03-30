class_name TurretProjectile
extends Area2D

# Set by Turret at spawn time
var direction: Vector2 = Vector2.UP

const SPEED: float = 450.0
var DAMAGE: int = 1

func _ready() -> void:
	Placeholder.rect($Sprite2D, Color(1.0, 0.9, 0.2), 6, 12)
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
	var parent = area.get_parent()
	if parent.has_method("take_damage"):
		parent.take_damage(DAMAGE)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		queue_free()
