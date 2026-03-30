extends Node2D

const SCROLL_X: float = 8.0
const SCROLL_Y: float = 4.0

var _offset_x: float = 0.0
var _offset_y: float = 0.0

func _ready() -> void:
	if $Sprite2D.texture == null:
		var img = Image.create(1280, 720, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.04, 0.04, 0.08))
		$Sprite2D.texture = ImageTexture.create_from_image(img)
		return
	$Sprite2D.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	$Sprite2D.region_enabled = true
	$Sprite2D.region_rect = Rect2(0.0, 0.0, 1280.0, 720.0)

func _process(delta: float) -> void:
	if not $Sprite2D.region_enabled:
		return
	_offset_x += SCROLL_X * delta
	_offset_y += SCROLL_Y * delta
	$Sprite2D.region_rect = Rect2(_offset_x, _offset_y, 1280.0, 720.0)
