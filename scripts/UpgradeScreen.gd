extends CanvasLayer

signal upgrade_chosen

const TURRET_SCENE = preload("res://scenes/Turret.tscn")
const TURRET_SLOTS: Array = [Vector2(-55.0, -20.0), Vector2(55.0, -20.0)]

var _player = null
var _base = null
var _spawner = null

const UPGRADES: Array = [
	{
		"name": "Reinforce Hull",
		"desc": "Restore player ship to full HP.",
		"cost_type": "shield",
		"cost": 2,
	},
	{
		"name": "Repair Base",
		"desc": "Restore +20 base HP.",
		"cost_type": "physical",
		"cost": 3,
	},
	{
		"name": "Rapid Fire",
		"desc": "Increase player fire rate by 20%.",
		"cost_type": "weapon",
		"cost": 2,
	},
	{
		"name": "Afterburners",
		"desc": "Increase player move speed by 40.",
		"cost_type": "general",
		"cost": 2,
	},
	{
		"name": "Breathing Room",
		"desc": "Slow asteroid spawns for next day.",
		"cost_type": "general",
		"cost": 2,
	},
	{
		"name": "Deploy Turret",
		"desc": "Place an auto-targeting turret beside the base. Max 2.",
		"cost_type": "weapon",
		"cost": 4,
	},
]

func show_upgrades(player, base, spawner) -> void:
	_player = player
	_base = base
	_spawner = spawner
	_populate_cards()
	visible = true

func _populate_cards() -> void:
	var container = $Screen/Panel/Cards
	for child in container.get_children():
		child.queue_free()
	var pool: Array = UPGRADES.duplicate()
	pool.shuffle()
	for upgrade in pool.slice(0, 3):
		container.add_child(_make_card(upgrade))

func _make_card(upgrade: Dictionary) -> Control:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(200, 140)

	var name_lbl := Label.new()
	name_lbl.text = upgrade["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = upgrade["desc"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	card.add_child(desc_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "Cost: %d %s" % [upgrade["cost"], upgrade["cost_type"]]
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(cost_lbl)

	var btn := Button.new()
	btn.text = "Select"
	btn.disabled = not _is_available(upgrade)
	btn.pressed.connect(_on_card_selected.bind(upgrade))
	card.add_child(btn)

	return card

func _is_available(upgrade: Dictionary) -> bool:
	if GameManager.get_resource(upgrade["cost_type"]) < upgrade["cost"]:
		return false
	if upgrade["name"] == "Deploy Turret":
		return get_tree().get_nodes_in_group("turret").size() < 2
	return true

func _on_card_selected(upgrade: Dictionary) -> void:
	GameManager.spend_resource(upgrade["cost_type"], upgrade["cost"])
	_apply(upgrade["name"])
	_finish()

func _apply(upgrade_name: String) -> void:
	match upgrade_name:
		"Reinforce Hull":
			if _player:
				_player.get_node("HealthComponent").heal(999)
		"Repair Base":
			if _base:
				_base.get_node("HealthComponent").heal(20)
		"Rapid Fire":
			if _player:
				_player.fire_rate *= 0.8
		"Afterburners":
			if _player:
				_player.move_speed += 40.0
		"Breathing Room":
			if _spawner:
				_spawner.base_spawn_interval += 0.5
		"Deploy Turret":
			if _base:
				var slot = get_tree().get_nodes_in_group("turret").size()
				var turret = TURRET_SCENE.instantiate()
				turret.position = TURRET_SLOTS[slot]
				_base.add_child(turret)

func _finish() -> void:
	visible = false
	upgrade_chosen.emit()

func _on_skip_button_pressed() -> void:
	_finish()
