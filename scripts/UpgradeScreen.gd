extends CanvasLayer

signal upgrade_chosen

const TURRET_SCENE = preload("res://scenes/Turret.tscn")
const TURRET_SLOTS: Array = [Vector2(-45.0, -20.0), Vector2(45.0, -20.0)]

var _player = null
var _base   = null
var _spawner = null

const TRACK_COLORS: Dictionary = {
	"weapons":     Color(0.28, 0.10, 0.02),
	"engineering": Color(0.04, 0.20, 0.08),
	"hull":        Color(0.04, 0.08, 0.28),
}
const LOCKED_COLOR:    Color = Color(0.08, 0.08, 0.08)
const DONE_COLOR:      Color = Color(0.08, 0.14, 0.08)
const BORDER_READY:    Color = Color(0.85, 0.75, 0.30, 0.9)
const BORDER_BROKE:    Color = Color(0.45, 0.45, 0.45, 0.55)
const BORDER_DONE:     Color = Color(0.30, 0.60, 0.30, 0.60)

const UPGRADES: Array = [
	# ── WEAPONS track ──────────────────────────────────────────
	{
		"name": "Rapid Fire",
		"desc": "Increase player fire rate by 5%.",
		"cost_type": "weapon", "cost": 1,
		"track": "weapons", "tier": 1,
		"requires": "", "repeatable": true,
	},
	{
		"name": "Overcharge",
		"desc": "Player shots deal +1 damage.",
		"cost_type": "weapon", "cost": 2,
		"track": "weapons", "tier": 1,
		"requires": "", "repeatable": true,
	},
	{
		"name": "Afterburners",
		"desc": "Increase player move speed by 40.",
		"cost_type": "weapon", "cost": 2,
		"track": "weapons", "tier": 2,
		"requires": "Overcharge", "repeatable": false,
	},
	# ── ENGINEERING track ───────────────────────────────────────
	{
		"name": "Repair Base",
		"desc": "Restore +20 base HP.",
		"cost_type": "physical", "cost": 3,
		"track": "engineering", "tier": 1,
		"requires": "", "repeatable": true,
	},
	{
		"name": "Breathing Room",
		"desc": "Slow asteroid spawns for the next day.",
		"cost_type": "general", "cost": 2,
		"track": "engineering", "tier": 1,
		"requires": "", "repeatable": true,
	},
	{
		"name": "Deploy Turret",
		"desc": "Deploy a second turret to defend the base.",
		"cost_type": "weapon", "cost": 4,
		"track": "engineering", "tier": 2,
		"requires": "Repair Base", "repeatable": false,
	},
	{
		"name": "Turret Upgrade",
		"desc": "Turret shots deal +1 damage.",
		"cost_type": "weapon", "cost": 3,
		"track": "engineering", "tier": 3,
		"requires": "Deploy Turret", "repeatable": true,
	},
	# ── HULL track ─────────────────────────────────────────────
	{
		"name": "Reinforce Hull",
		"desc": "Restore player ship to full HP.",
		"cost_type": "shield", "cost": 2,
		"track": "hull", "tier": 1,
		"requires": "", "repeatable": true,
	},
	{
		"name": "Expand Cockpit",
		"desc": "Increase player max HP by 3.",
		"cost_type": "shield", "cost": 3,
		"track": "hull", "tier": 2,
		"requires": "Reinforce Hull", "repeatable": false,
	},
	{
		"name": "Reinforce Base",
		"desc": "Increase base max HP by 10.",
		"cost_type": "physical", "cost": 4,
		"track": "hull", "tier": 2,
		"requires": "Reinforce Hull", "repeatable": false,
	},
]

# ── Public API ──────────────────────────────────────────────────────────────

func show_upgrades(player, base, spawner) -> void:
	_player  = player
	_base    = base
	_spawner = spawner
	$Screen/Panel/DayLabel.text = "Day %d" % GameManager.day_number
	_refresh()
	visible = true

# ── Tree rebuild ────────────────────────────────────────────────────────────

func _refresh() -> void:
	var col_btns: Array = [
		_populate_column($Screen/Panel/Tracks/WeaponsCol/WeaponsNodes,         "weapons"),
		_populate_column($Screen/Panel/Tracks/EngineeringCol/EngineeringNodes, "engineering"),
		_populate_column($Screen/Panel/Tracks/HullCol/HullNodes,               "hull"),
	]
	_wire_focus(col_btns)

func _populate_column(container: VBoxContainer, track: String) -> Array:
	# Safe removal: skip nodes already queued for deletion
	for child in container.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()

	var btns: Array = []
	var track_upgrades = UPGRADES.filter(func(u): return u["track"] == track)
	for upgrade in track_upgrades:
		var pair = _make_node(upgrade)
		container.add_child(pair[0])
		btns.append(pair[1])
	return btns

func _make_node(upgrade: Dictionary) -> Array:
	var unlocked   = _is_unlocked(upgrade)
	var done       = _is_done(upgrade)
	var affordable = _is_affordable(upgrade)

	# ── Outer panel ──────────────────────────────────────────
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 95)

	var style := StyleBoxFlat.new()
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_width_left   = 1
	style.border_width_right  = 1

	if done:
		style.bg_color     = DONE_COLOR
		style.border_color = BORDER_DONE
	elif unlocked:
		style.bg_color     = TRACK_COLORS[upgrade["track"]]
		style.border_color = BORDER_READY if affordable else BORDER_BROKE
	else:
		style.bg_color     = LOCKED_COLOR
		style.border_color = Color(0.2, 0.2, 0.2, 0.4)

	panel.add_theme_stylebox_override("panel", style)

	# ── Margin → VBox ────────────────────────────────────────
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_bottom",  8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)

	# Name label
	var name_lbl := Label.new()
	name_lbl.text = upgrade["name"]
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.modulate = Color(1, 1, 1, 0.35) if not unlocked else Color(1, 1, 1, 1)
	vbox.add_child(name_lbl)

	# Description / prereq hint
	var desc_lbl := Label.new()
	if unlocked:
		desc_lbl.text = upgrade["desc"]
	else:
		desc_lbl.text = "Requires: %s" % upgrade["requires"]
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.modulate = Color(0.75, 0.75, 0.75, 0.35) if not unlocked else Color(0.85, 0.85, 0.85, 1.0)
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_lbl)

	# Research button
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 13)

	if done:
		btn.text     = "Researched"
		btn.disabled = true
	elif not unlocked:
		btn.text     = "Locked"
		btn.disabled = true
	elif not affordable:
		btn.text     = "Need %d %s" % [upgrade["cost"], upgrade["cost_type"]]
		btn.disabled = true
	else:
		btn.text     = "Research  [%d %s]" % [upgrade["cost"], upgrade["cost_type"]]
		btn.disabled = false
		btn.pressed.connect(_on_research_pressed.bind(upgrade))

	vbox.add_child(btn)

	return [panel, btn]

# ── State helpers ──────────────────────────────────────────────────────────

func _is_unlocked(upgrade: Dictionary) -> bool:
	if upgrade["requires"] == "":
		return true
	return GameManager.get_purchase_count(upgrade["requires"]) > 0

func _is_affordable(upgrade: Dictionary) -> bool:
	return GameManager.get_resource(upgrade["cost_type"]) >= upgrade["cost"]

func _is_done(upgrade: Dictionary) -> bool:
	if upgrade["repeatable"]:
		return false
	return GameManager.get_purchase_count(upgrade["name"]) > 0

# ── Controller focus wiring ─────────────────────────────────────────────────

func _wire_focus(col_btns: Array) -> void:
	var launch: Button = $Screen/Panel/LaunchButton

	for ci in col_btns.size():
		var btns: Array = col_btns[ci]
		for bi in btns.size():
			var btn: Button = btns[bi]
			var left_ci  = (ci - 1 + col_btns.size()) % col_btns.size()
			var right_ci = (ci + 1) % col_btns.size()

			btn.focus_neighbor_top    = btns[bi - 1].get_path()                                                  if bi > 0                          else btn.get_path()
			btn.focus_neighbor_bottom = btns[bi + 1].get_path()                                                  if bi < btns.size() - 1            else launch.get_path()
			btn.focus_neighbor_left   = col_btns[left_ci][mini(bi, col_btns[left_ci].size() - 1)].get_path()    if col_btns[left_ci].size()  > 0   else btn.get_path()
			btn.focus_neighbor_right  = col_btns[right_ci][mini(bi, col_btns[right_ci].size() - 1)].get_path()  if col_btns[right_ci].size() > 0   else btn.get_path()

	# Launch button: up goes to the last row of the middle column (or any available)
	var mid_btns: Array = col_btns[1] if col_btns[1].size() > 0 else col_btns[0]
	launch.focus_neighbor_top    = mid_btns[mid_btns.size() - 1].get_path() if mid_btns.size() > 0 else launch.get_path()
	launch.focus_neighbor_bottom = launch.get_path()

	# Auto-focus first affordable button
	var first_ready: Button = null
	for col in col_btns:
		for btn in col:
			if not btn.disabled:
				first_ready = btn
				break
		if first_ready:
			break

	if first_ready:
		first_ready.call_deferred("grab_focus")
	else:
		launch.call_deferred("grab_focus")

# ── Research handler ────────────────────────────────────────────────────────

func _on_research_pressed(upgrade: Dictionary) -> void:
	GameManager.spend_resource(upgrade["cost_type"], upgrade["cost"])
	GameManager.record_purchase(upgrade["name"])
	_apply(upgrade["name"])
	_refresh()

func _apply(upgrade_name: String) -> void:
	match upgrade_name:
		"Reinforce Hull":
			if _player:
				_player.get_node("HealthComponent").heal(999)
		"Repair Base":
			if _base:
				_base.get_node("HealthComponent").heal(20)
		"Expand Cockpit":
			if _player:
				var hc = _player.get_node("HealthComponent")
				hc.max_hp += 3
				hc.heal(3)
		"Reinforce Base":
			if _base:
				var hc = _base.get_node("HealthComponent")
				hc.max_hp += 10
				hc.heal(10)
		"Rapid Fire":
			if _player:
				_player.fire_rate *= 0.95
		"Overcharge":
			if _player:
				_player.projectile_damage += 1
		"Turret Upgrade":
			for t in get_tree().get_nodes_in_group("turret"):
				t.projectile_damage += 1
		"Afterburners":
			if _player:
				_player.move_speed += 40.0
		"Breathing Room":
			if _spawner:
				_spawner.base_spawn_interval += 0.5
		"Deploy Turret":
			if _base:
				var turrets = get_tree().get_nodes_in_group("turret")
				if turrets.size() < 3:
					var turret = TURRET_SCENE.instantiate()
					turret.position = TURRET_SLOTS[turrets.size() - 1]
					turret.z_index = -1
					_base.add_child(turret)
				else:
					for t in turrets:
						t.fire_rate = maxf(0.3, t.fire_rate * 0.75)

# ── Close ───────────────────────────────────────────────────────────────────

func _finish() -> void:
	visible = false
	upgrade_chosen.emit()

func _on_launch_button_pressed() -> void:
	_finish()
