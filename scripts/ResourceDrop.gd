class_name ResourceDrop
extends Area2D

# Assign in the spawning code or inspector: "general" | "shield" | "weapon" | "physical"
@export var resource_type: String = "general"

const DRIFT_SPEED: float = 30.0

const TEXTURES: Dictionary = {
	"general":     "res://assets/pickups/general-resource.png",
	"shield":      "res://assets/pickups/shield-resource.png",
	"weapon":      "res://assets/pickups/weapon-resource.png",
	"physical":    "res://assets/pickups/structure-resource.png",
	"ship-health": "res://assets/pickups/ship-health.png",
	"base-health": "res://assets/pickups/base-health.png",
}

const PLACEHOLDER_COLORS: Dictionary = {
	"general":     Color.YELLOW,
	"shield":      Color.CYAN,
	"weapon":      Color.ORANGE,
	"physical":    Color.MAGENTA,
	"ship-health": Color.GREEN,
	"base-health": Color.BLUE,
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
		if resource_type == "base-health":
			SoundManager.pickup_resource("base-health")
			body.get_node("HealthComponent").heal(5)
		else:
			SoundManager.resource_hit_base()
			body.take_damage(1)
		queue_free()
	elif body.is_in_group("ground"):
		queue_free()
	elif body.is_in_group("player"):
		if resource_type == "ship-health":
			SoundManager.pickup_resource("ship-health")
			body.get_node("HealthComponent").heal(3)
		elif resource_type == "base-health":
			SoundManager.pickup_resource("base-health")
			var bases = body.get_tree().get_nodes_in_group("base")
			if bases.size() > 0:
				bases[0].get_node("HealthComponent").heal(5)
		else:
			SoundManager.pickup_resource(resource_type)
			GameManager.add_resource(resource_type)
		queue_free()
