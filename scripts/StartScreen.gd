extends Node2D

const SCROLL_X: float = 8.0
const SCROLL_Y: float = 4.0

var _offset_x: float = 0.0
var _offset_y: float = 0.0

func _ready() -> void:
	$Background.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	$Background.region_enabled = true
	$Background.region_rect = Rect2(0.0, 0.0, 1280.0, 720.0)

func _process(delta: float) -> void:
	_offset_x += SCROLL_X * delta
	_offset_y += SCROLL_Y * delta
	$Background.region_rect = Rect2(_offset_x, _offset_y, 1280.0, 720.0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_start_game()
	elif event is InputEventKey and event.keycode == KEY_F11 and event.pressed:
		var mode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_start_button_pressed() -> void:
	_start_game()

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
