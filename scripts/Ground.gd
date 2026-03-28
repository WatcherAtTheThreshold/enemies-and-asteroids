extends StaticBody2D

var _base: Node2D = null
var _last_base_x: float = 0.0
var _scroll_offset: float = 0.0

func _ready() -> void:
	add_to_group("ground")
	Placeholder.rect($Sprite2D, Color(0.3, 0.28, 0.22), 1280, 80)
	# Enable texture repeat so the region scroll tiles seamlessly
	$Sprite2D.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	$Sprite2D.region_enabled = true
	$Sprite2D.region_rect = Rect2(0.0, 0.0, 1280.0, 80.0)
	await get_tree().process_frame
	var bases = get_tree().get_nodes_in_group("base")
	if bases.size() > 0:
		_base = bases[0]
		_last_base_x = _base.position.x

func _physics_process(_delta: float) -> void:
	if _base == null:
		return
	var delta_x = _base.position.x - _last_base_x
	# Ignore large jumps (base teleport reset) — texture wraps anyway so no snap needed
	if abs(delta_x) < 200.0:
		_scroll_offset -= delta_x
		$Sprite2D.region_rect = Rect2(_scroll_offset, 0.0, 1280.0, 80.0)
	_last_base_x = _base.position.x
