class_name Base
extends CharacterBody2D

signal base_exited_screen

@export var move_speed: float = 50.0  # slow crawl left to right

func _ready() -> void:
	Placeholder.rect($Sprite2D, Color(0.2, 0.7, 0.9), 96, 40)
	add_to_group("base")
	$HealthComponent.died.connect(_on_died)
	$HealthComponent.health_changed.connect(_on_health_changed)

func _physics_process(delta: float) -> void:
	velocity = Vector2(move_speed, 0.0)
	move_and_slide()

	# When the base fully exits the right edge, the day ends
	if position.x > get_viewport_rect().size.x + 150.0:
		base_exited_screen.emit()
		# Reposition off the left edge ready for the next day
		position.x = -150.0

func take_damage(amount: int) -> void:
	if position.x < 0.0 or position.x > get_viewport_rect().size.x:
		return
	$HealthComponent.take_damage(amount)

func _on_health_changed(current_hp: int, max_hp_val: int) -> void:
	_flash_damage()

func _flash_damage() -> void:
	$Sprite2D.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.25)

func _on_died() -> void:
	SoundManager.base_explode()
	GameManager.trigger_game_over("base")
