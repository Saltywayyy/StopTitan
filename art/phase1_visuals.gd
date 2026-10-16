@warning_ignore("integer_division")
class_name Phase1Visuals
extends RefCounted

static var ground_noise: FastNoiseLite
static var macro_patch_noise: FastNoiseLite
static var tuft_noise: FastNoiseLite
static var forest_noise: FastNoiseLite
static var shadow_blob_tex: ImageTexture
static var warm_torch_falloff_tex: ImageTexture

static func ensure_initialized() -> void:
	if ground_noise == null:
		ground_noise = FastNoiseLite.new()
		ground_noise.seed = 4091
		ground_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		ground_noise.frequency = 0.055
		ground_noise.fractal_octaves = 2

	if macro_patch_noise == null:
		macro_patch_noise = FastNoiseLite.new()
		macro_patch_noise.seed = 6153
		macro_patch_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		macro_patch_noise.frequency = 0.032
		macro_patch_noise.fractal_octaves = 2

	if tuft_noise == null:
		tuft_noise = FastNoiseLite.new()
		tuft_noise.seed = 8821
		tuft_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
		tuft_noise.frequency = 0.14

	if forest_noise == null:
		forest_noise = FastNoiseLite.new()
		forest_noise.seed = 1773
		forest_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		forest_noise.frequency = 0.095
		forest_noise.fractal_octaves = 2

	if shadow_blob_tex == null:
		shadow_blob_tex = _build_shadow_blob_texture()

	if warm_torch_falloff_tex == null:
		warm_torch_falloff_tex = build_natural_torch_light_texture()

static func _build_shadow_blob_texture() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var center := Vector2(16.0, 16.0)
	for x in range(32):
		for y in range(32):
			var d: float = Vector2(x, y).distance_to(center) / 15.5
			var a: float = pow(clampf(1.0 - d, 0.0, 1.0), 1.95)
			img.set_pixel(x, y, Color(0.02, 0.03, 0.06, a))
	return ImageTexture.create_from_image(img)

static func build_natural_torch_light_texture() -> ImageTexture:
	var sz: int = 256
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var center := Vector2(sz * 0.5, sz * 0.5)
	var max_r: float = sz * 0.5
	for x in range(sz):
		for y in range(sz):
			var d: float = clampf(Vector2(x, y).distance_to(center) / max_r, 0.0, 1.0)
			if d >= 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var window: float = pow(1.0 - d * d, 2.2)
			var gauss: float = exp(-d * d * 3.6) * window
			var core: float = exp(-d * d * 18.0) * 0.32
			var a: float = clampf(gauss * 0.85 + core, 0.0, 1.0)
			var r_c: float = 1.0
			var g_c: float = lerpf(0.92, 0.54, pow(d, 0.85))
			var b_c: float = lerpf(0.68, 0.20, pow(d, 0.75))
			img.set_pixel(x, y, Color(r_c, g_c, b_c, a))
	return ImageTexture.create_from_image(img)

# Атмосферная смена суток: выразительная тёмная ночь (#101729) и морозная синева зимой
static func sample_sky_color(hour: float, is_winter: bool) -> Color:
	var h: float = fposmod(hour, 24.0)
	var c_night := Color("#101729")
	var c_dawn := Color("#d99c72")
	var c_day := Color("#f0e9dc")
	var c_late := Color("#e0d2ba")
	var c_dusk := Color("#8f5a48")

	var col: Color = c_day
	if h < 4.5:
		col = c_night
	elif h < 5.8:
		col = c_night.lerp(c_dawn, smoothstep(4.5, 5.8, h))
	elif h < 7.2:
		col = c_dawn.lerp(c_day, smoothstep(5.8, 7.2, h))
	elif h < 17.5:
		col = c_day.lerp(c_late, smoothstep(15.0, 17.5, h))
	elif h < 19.2:
		col = c_late.lerp(c_dusk, smoothstep(17.5, 19.2, h))
	elif h < 20.5:
		col = c_dusk.lerp(c_night, smoothstep(19.2, 20.5, h))
	else:
		col = c_night

	if is_winter:
		col = col.lerp(Color("#cfe0f2"), 0.28)
	return col

static func get_light_night_factor(hour: float) -> float:
	var h: float = fposmod(hour, 24.0)
	if h >= 20.5 or h < 4.5:
		return 1.35
	elif h >= 16.0 and h < 20.5:
		return lerpf(0.48, 1.35, smoothstep(16.0, 20.5, h))
	elif h >= 4.5 and h < 7.2:
		return lerpf(1.35, 0.48, smoothstep(4.5, 7.2, h))
	return 0.48

# Бесшовные тайлы травы и земли (края каждого тайла сведены к единому базовому тону — никакой «вафельной сетки»!)
static func generate_ground_textures() -> Dictionary:
	ensure_initialized()
	var grass_palette: Array = [
		Color("#24341e"),
		Color("#2b3e24"),
		Color("#31462a"),
		Color("#385030"),
		Color("#405a37")
	]
	var dirt_palette: Array = [
		Color("#593f2b"),
		Color("#664932"),
		Color("#735339"),
		Color("#805d40"),
		Color("#8c6747")
	]

	var grass_list: Array[ImageTexture] = []
	for v in range(8):
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for x in range(16):
			for y in range(16):
				var is_edge: bool = (x == 0 or x == 15 or y == 0 or y == 15)
				if is_edge:
					img.set_pixel(x, y, grass_palette[2])
				else:
					var n_val: float = ground_noise.get_noise_2d(float(x + v * 16) * 1.15, float(y + v * 16) * 1.15)
					var tone: int = 2
					if n_val > 0.20:
						tone = 3
					elif n_val < -0.20:
						tone = 1
					img.set_pixel(x, y, grass_palette[tone])

		if v in [1, 4, 6]:
			var tx: int = 4 + (v * 3) % 8
			var ty: int = 6 + (v * 2) % 6
			img.set_pixel(tx, ty, grass_palette[0])
			img.set_pixel(tx, ty - 1, grass_palette[3])
			img.set_pixel(tx + 1, ty, grass_palette[3])
			img.set_pixel(tx + 1, ty - 1, grass_palette[4])

		if v == 5:
			img.set_pixel(7, 8, Color("#cbbba0"))
			img.set_pixel(7, 9, grass_palette[0])

		grass_list.append(ImageTexture.create_from_image(img))

	var dirt_list: Array[ImageTexture] = []
	for v in range(6):
		var d_img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for x in range(16):
			for y in range(16):
				var is_edge: bool = (x <= 1 or x >= 14 or y <= 1 or y >= 14)
				if is_edge:
					d_img.set_pixel(x, y, dirt_palette[2])
				else:
					var n_val: float = ground_noise.get_noise_2d(float(x + v * 24) * 1.2, float(y + v * 20) * 1.2)
					var d_tone: int = 2
					if n_val > 0.22:
						d_tone = 3
					elif n_val < -0.22:
						d_tone = 1
					d_img.set_pixel(x, y, dirt_palette[d_tone])

		if v % 2 == 0:
			var px: int = 4 + (v * 3) % 7
			var py: int = 5 + (v * 4) % 6
			d_img.set_pixel(px, py, dirt_palette[4])
			d_img.set_pixel(px + 1, py, dirt_palette[1])
		dirt_list.append(ImageTexture.create_from_image(d_img))

	# 16 масок органического перехода без горизонтальных зубьев на вертикальных стыках
	var blend_list: Array[ImageTexture] = []
	for mask in range(16):
		var b_img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		var has_n: bool = (mask & 1) != 0
		var has_e: bool = (mask & 2) != 0
		var has_s: bool = (mask & 4) != 0
		var has_w: bool = (mask & 8) != 0

		for x in range(16):
			for y in range(16):
				var u: float = float(x) / 15.0
				var v_c: float = float(y) / 15.0
				var pull: float = 0.0
				if has_n:
					pull = maxf(pull, 1.0 - v_c * 1.65)
				if has_s:
					pull = maxf(pull, (v_c - 0.38) * 1.65)
				if has_w:
					pull = maxf(pull, 1.0 - u * 1.65)
				if has_e:
					pull = maxf(pull, (u - 0.38) * 1.65)

				# Мягкий изгиб, который равен 0 на самых краях тайла (u=0,1 и v_c=0,1), чтобы соседние клетки сходились пиксель-в-пиксель!
				var edge_curve: float = sin(u * PI) * sin(v_c * PI) * 0.14
				if pull + edge_curve > 0.42:
					b_img.set_pixel(x, y, dirt_palette[2])
				elif pull + edge_curve > 0.28:
					b_img.set_pixel(x, y, dirt_palette[1])
				else:
					b_img.set_pixel(x, y, grass_palette[2])
		blend_list.append(ImageTexture.create_from_image(b_img))

	return {
		"grass": grass_list,
		"dirt": dirt_list,
		"blend": blend_list
	}

static func sample_grass_variant(cell: Vector2i, count: int) -> int:
	if count <= 1:
		return 0
	ensure_initialized()
	var n: float = macro_patch_noise.get_noise_2d(float(cell.x) * 4.2, float(cell.y) * 4.2) * 0.5 + 0.5
	var patch_idx: int = clampi(int(floor(n * float(count))), 0, count - 1)
	if ArtLoader.cell_hash(cell, 17) % 5 == 0:
		patch_idx = (patch_idx + 1) % count
	return patch_idx

static func is_dirt_like(g_type: int) -> bool:
	return g_type == 1 or g_type == 4

static func compute_dirt_blend_mask(cell: Vector2i, ground_map: Dictionary) -> int:
	var g_type: int = int(ground_map.get(cell, 0))
	if g_type != 0 and g_type != 6:
		return 0
	var mask: int = 0
	if is_dirt_like(int(ground_map.get(cell + Vector2i(0, -1), 0))):
		mask |= 1
	if is_dirt_like(int(ground_map.get(cell + Vector2i(1, 0), 0))):
		mask |= 2
	if is_dirt_like(int(ground_map.get(cell + Vector2i(0, 1), 0))):
		mask |= 4
	if is_dirt_like(int(ground_map.get(cell + Vector2i(-1, 0), 0))):
		mask |= 8
	return mask

static func should_blend_dirt_into_grass(cell: Vector2i, ground_map: Dictionary) -> bool:
	return compute_dirt_blend_mask(cell, ground_map) != 0

static func draw_soft_shadow(canvas: CanvasItem, center_pos: Vector2, size: Vector2, alpha: float = 0.34) -> void:
	ensure_initialized()
	var rect := Rect2(center_pos - size * 0.5, size)
	canvas.draw_texture_rect(shadow_blob_tex, rect, false, Color(1, 1, 1, alpha))

static func draw_outside_atmosphere(canvas: CanvasItem, fort_rect_px: Rect2) -> void:
	ensure_initialized()
	var steps: int = 12
	for i in range(steps):
		var t0: float = float(i) / float(steps)
		var expand: float = 24.0 + t0 * 320.0
		var r := fort_rect_px.grow(expand)
		var ring_w: float = 28.0
		var alpha: float = lerpf(0.008, 0.028, t0)
		var col := Color(0.03, 0.05, 0.09, alpha)
		canvas.draw_rect(Rect2(r.position.x, r.position.y - ring_w, r.size.x, ring_w), col, true)
		canvas.draw_rect(Rect2(r.position.x, r.end.y, r.size.x, ring_w), col, true)
		canvas.draw_rect(Rect2(r.position.x - ring_w, r.position.y, ring_w, r.size.y), col, true)
		canvas.draw_rect(Rect2(r.end.x, r.position.y, ring_w, r.size.y), col, true)

static func create_atmosphere_vignette_layer() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 0

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;

void fragment() {
	vec2 uv = UV;
	vec2 centered = uv * 2.0 - 1.0;
	centered.x *= 1.12;
	float dist = length(centered);
	float vig = smoothstep(0.82, 1.52, dist);
	vec3 col = vec3(0.03, 0.05, 0.10);
	float alpha = clamp(vig * 0.20, 0.0, 0.24);
	COLOR = vec4(col, alpha);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	rect.material = mat
	layer.add_child(rect)
	return layer

static func populate_dense_forest(world: Node2D, map_radius: int) -> void:
	ensure_initialized()
	for x in range(-map_radius + 3, map_radius - 2, 2):
		for y in range(-map_radius + 3, map_radius - 2, 2):
			if x >= -16 and x <= 15 and y >= -14 and y <= 8:
				continue
			if x >= -4 and x <= 12 and y >= -20 and y <= -14:
				continue

			var h_jit: int = ArtLoader.cell_hash(Vector2i(x, y), 33)
			var jx: int = x + ((h_jit % 3) - 1)
			var jy: int = y + (((h_jit >> 3) % 3) - 1)
			var cell := Vector2i(jx, jy)
			if cell.x >= -16 and cell.x <= 15 and cell.y >= -14 and cell.y <= 8:
				continue
			if cell.x >= -4 and cell.x <= 12 and cell.y >= -20 and cell.y <= -14:
				continue

			var n_val: float = forest_noise.get_noise_2d(float(cell.x) * 2.2, float(cell.y) * 2.2)
			var dist_fort: float = maxf(maxf(-16.0 - float(cell.x), float(cell.x) - 15.0), maxf(-14.0 - float(cell.y), float(cell.y) - 8.0))
			var density_threshold: float = -0.34 if dist_fort > 3.0 else -0.08

			if n_val > density_threshold:
				world._set_block(cell, 8, false)
				world.decor_map.erase(cell)
				var u_cell := cell + Vector2i(1 if (cell.y % 2 == 0) else -1, 1)
				if not world.wall_map.has(u_cell) and (u_cell.x < -16 or u_cell.x > 15 or u_cell.y < -14 or u_cell.y > 8):
					var h: int = ArtLoader.cell_hash(u_cell, 55) % 10
					if h < 4:
						world.decor_map[u_cell] = "bush"
					elif h < 6:
						world.decor_map[u_cell] = "flowers"
					elif h < 8:
						world.decor_map[u_cell] = "rock"
					elif h == 8:
						world.decor_map[u_cell] = "log"
					else:
						world.decor_map[u_cell] = "stump"
