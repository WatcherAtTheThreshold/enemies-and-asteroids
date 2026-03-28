class_name HUD
extends CanvasLayer

@export var player: Player
@export var base: Base

func _ready() -> void:
	# Day tracking
	GameManager.day_started.connect(_on_day_started)
	$Screen/DayLabel.text = "Day %d" % GameManager.day_number

	# Resource tracking
	GameManager.resource_collected.connect(_on_resource_collected)
	_refresh_resources()

	# Base HP
	if base:
		var base_hp = base.get_node("HealthComponent") as HealthComponent
		$Screen/BaseHP/Bar.max_value = base_hp.max_hp
		$Screen/BaseHP/Bar.value = base_hp.current_hp
		base_hp.health_changed.connect(_on_base_health_changed)

	# Player HP
	if player:
		var player_hp = player.get_node("HealthComponent") as HealthComponent
		$Screen/PlayerHP/Bar.max_value = player_hp.max_hp
		$Screen/PlayerHP/Bar.value = player_hp.current_hp
		player_hp.health_changed.connect(_on_player_health_changed)

func _on_day_started(day: int) -> void:
	$Screen/DayLabel.text = "Day %d" % day

func _on_resource_collected(_type: String) -> void:
	_refresh_resources()

func _on_base_health_changed(current_hp: int, max_hp: int) -> void:
	$Screen/BaseHP/Bar.max_value = max_hp
	$Screen/BaseHP/Bar.value = current_hp

func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	$Screen/PlayerHP/Bar.max_value = max_hp
	$Screen/PlayerHP/Bar.value = current_hp

func _refresh_resources() -> void:
	$Screen/Resources/General.text  = "General:  %d" % GameManager.get_resource("general")
	$Screen/Resources/Shield.text   = "Shield:   %d" % GameManager.get_resource("shield")
	$Screen/Resources/Weapon.text   = "Weapon:   %d" % GameManager.get_resource("weapon")
	$Screen/Resources/Physical.text = "Physical: %d" % GameManager.get_resource("physical")
