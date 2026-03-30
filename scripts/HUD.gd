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
	_tint_bar($Screen/BaseHP/Bar, float(current_hp) / float(max_hp))

func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	$Screen/PlayerHP/Bar.max_value = max_hp
	$Screen/PlayerHP/Bar.value = current_hp
	_tint_bar($Screen/PlayerHP/Bar, float(current_hp) / float(max_hp))

func _tint_bar(bar: ProgressBar, pct: float) -> void:
	var color: Color
	if pct > 0.6:
		color = Color(0.2, 0.8, 0.2)       # green
	elif pct > 0.4:
		color = Color(0.9, 0.85, 0.1)      # yellow
	elif pct > 0.2:
		color = Color(0.95, 0.5, 0.05)     # orange
	else:
		color = Color(0.9, 0.1, 0.1)       # red
	var style = StyleBoxFlat.new()
	style.bg_color = color
	bar.add_theme_stylebox_override("fill", style)

func _refresh_resources() -> void:
	$Screen/Resources/General.text  = "General:  %d" % GameManager.get_resource("general")
	$Screen/Resources/Shield.text   = "Shield:   %d" % GameManager.get_resource("shield")
	$Screen/Resources/Weapon.text   = "Weapon:   %d" % GameManager.get_resource("weapon")
	$Screen/Resources/Physical.text = "Physical: %d" % GameManager.get_resource("physical")
