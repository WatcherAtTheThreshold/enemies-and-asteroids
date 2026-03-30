extends CanvasLayer

func show_game_over(cause: String) -> void:
	var cause_text = "Base destroyed" if cause == "base" else "Ship destroyed"
	$Screen/Box/CauseLabel.text = cause_text
	visible = true

func _process(_delta: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")

func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")
