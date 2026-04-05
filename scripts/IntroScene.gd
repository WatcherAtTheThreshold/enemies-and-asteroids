extends Node2D

const SCROLL_X: float = 8.0
const SCROLL_Y: float = 4.0
var _offset_x: float = 0.0
var _offset_y: float = 0.0

const SLIDE_DURATION: float = 1.2    # slow and cinematic
const PILOT_PAUSE: float = 0.6       # beat after pilot enters before line appears
const LINE_DURATION: float = 3.5     # how long each line shows before advancing
const FADE_DURATION: float = 0.6     # fade to black before game starts
const EYE_FADE_IN: float = 1.2       # symbol fade in
const EYE_HOLD: float = 3.0          # symbol hold duration
const EYE_FADE_OUT: float = 1.2      # symbol fade out

const DIALOGUE: Array = [
	{"speaker": "Pilot",     "text": "Moonbase, come in!"},
	{"speaker": "Moonbase",  "text": "We're in trouble! Please stop the meteor storm!"},
	{"speaker": "Pilot",     "text": "Can do, hang in there Moonbase!"},
]

func _ready() -> void:
	$Background.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	$Background.region_enabled = true
	$Background.region_rect = Rect2(0.0, 0.0, 1280.0, 720.0)
	$EyeSprite.modulate = Color(1, 1, 1, 0)
	$PilotSprite.position = Vector2(-640, 360)
	$BaseSprite.position  = Vector2(1920, 360)
	$BaseSprite.visible   = false
	$UI/DialoguePanel.visible = false
	$UI/FadeOverlay.color = Color(0, 0, 0, 0)
	_run_sequence()

func _process(delta: float) -> void:
	_offset_x += SCROLL_X * delta
	_offset_y += SCROLL_Y * delta
	$Background.region_rect = Rect2(_offset_x, _offset_y, 1280.0, 720.0)

func _run_sequence() -> void:
	# Eye of Shoggoth — fade in, hold, fade out
	var eye_in = create_tween()
	eye_in.tween_property($EyeSprite, "modulate", Color(1, 1, 1, 1), EYE_FADE_IN)
	await eye_in.finished
	await get_tree().create_timer(EYE_HOLD).timeout
	var eye_out = create_tween()
	eye_out.tween_property($EyeSprite, "modulate", Color(1, 1, 1, 0), EYE_FADE_OUT)
	await eye_out.finished

	# Pilot snaps in
	_slide($PilotSprite, Vector2(640, 360))
	await get_tree().create_timer(SLIDE_DURATION).timeout
	await get_tree().create_timer(PILOT_PAUSE).timeout

	# Pilot line
	_show_line(DIALOGUE[0])
	await get_tree().create_timer(LINE_DURATION).timeout

	# Base snaps in over pilot
	$BaseSprite.visible = true
	_slide($BaseSprite, Vector2(640, 360))
	await get_tree().create_timer(SLIDE_DURATION).timeout

	# Base line
	_show_line(DIALOGUE[1])
	await get_tree().create_timer(LINE_DURATION).timeout
	
	# Pilot line
	_show_line(DIALOGUE[2])
	await get_tree().create_timer(LINE_DURATION).timeout
	
	# Fade to black then start game
	var tween = create_tween()
	tween.tween_property($UI/FadeOverlay, "color", Color(0, 0, 0, 1), FADE_DURATION)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _slide(sprite: Sprite2D, target: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "position", target, SLIDE_DURATION)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func _show_line(entry: Dictionary) -> void:
	$UI/DialoguePanel.visible = true
	$UI/DialoguePanel/SpeakerLabel.text = entry["speaker"]
	$UI/DialoguePanel/LineLabel.text    = entry["text"]
