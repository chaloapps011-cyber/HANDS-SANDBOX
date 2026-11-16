extends RefCounted
## Small generated plate/stud texture; no external asset or runtime download required.
static func make(tint: Color, roughness: float = 0.8) -> StandardMaterial3D:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var base := tint.darkened(0.16)
	var groove := tint.darkened(0.32)
	for y in range(128):
		for x in range(128):
			var local_x := x % 32
			var local_y := y % 32
			var color := base
			if local_x < 2 or local_y < 2:
				color = groove
			else:
				var dx := local_x - 16
				var dy := local_y - 16
				var distance := sqrt(float(dx * dx + dy * dy))
				if distance < 8:
					color = tint.lightened(0.12 if distance < 6 else 0.04)
				elif distance < 10:
					color = groove
			image.set_pixel(x, y, color)
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.roughness = roughness
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return material
