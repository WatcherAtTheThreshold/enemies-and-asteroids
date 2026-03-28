class_name ResourceDrop
extends Area2D

# Assign in the spawning code or inspector: "general" | "shield" | "weapon" | "physical"
@export var resource_type: String = "general"

const DRIFT_SPEED: float = 30.0

const TEXTURES: Dictionary = {
	"general":  "res://assets/pickups/general-resource.png",
	"shield":   "res://assets/pickups/shield-resource.png",
	"weapon":   "res://assets/pickups/weapon-resource.png",
	"physical": "res://assets/pickups/structure-resource.png",
}

const PLACEHOLDER_COLORS: Dictionary = {
	"general":  Color.YELLOW,
	"shield":   Color.CYAN,
	"weapon":   Color.ORANGE,
	"physical": Color.MAGENTA,
}

func _ready() -> void:
	if TEXTURES.has(resource_type):
		$Sprite2D.texture = load(TEXTURES[resource_type])
	else:
		Placeholder.rect($Sprite2D, PLACEHOLDER_COLORS.get(resource_type, Color.WHITE), 16, 16)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position.y += DRIFT_SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("base"):
		SoundManager.resource_hit_base()
		body.take_damage(1)
		queue_free()
	elif body.is_in_group("ground"):
		queue_free()
	elif body.is_in_group("player"):
		SoundManager.pickup_resource(resource_type)
		GameManager.add_resource(resource_type)
		queue_free()
