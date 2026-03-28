class_name Placeholder

# Fills a Sprite2D with a solid colored rectangle if it has no texture yet.
# Assign a real texture in the inspector and this call becomes a no-op.
static func rect(sprite: Sprite2D, color: Color, w: int, h: int) -> void:
	if sprite.texture != null:
		return
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	sprite.texture = ImageTexture.create_from_image(img)

# Fills a Sprite2D with a solid colored circle (for round objects like asteroids).
static func circle(sprite: Sprite2D, color: Color, size: int) -> void:
	if sprite.texture != null:
		return
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var center = Vector2(size * 0.5, size * 0.5)
	var radius = size * 0.5 - 1.0
	for x in size:
		for y in size:
			if Vector2(x, y).distance_to(center) <= radius:
				img.set_pixel(x, y, color)
	sprite.texture = ImageTexture.create_from_image(img)
