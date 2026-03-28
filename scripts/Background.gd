extends Sprite2D

func _ready() -> void:
	if texture != null:
		return
	# Dark space placeholder until real background art is assigned
	var img = Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.04, 0.04, 0.08))
	texture = ImageTexture.create_from_image(img)
