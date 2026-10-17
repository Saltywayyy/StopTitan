@warning_ignore("integer_division")
class_name BuildSystem
extends RefCounted

static var _lmb_was_down: bool = false
static var _rmb_was_down: bool = false
static var _last_built_cell := Vector2i(9999, 9999)
static var _last_removed_cell := Vector2i(9999, 9999)
static var last_touch_world_pos: Vector2 = Vector2.ZERO
static var has_touch_preview: bool = false

static var _autowall_mask_cache: Dictionary = {}
static var _autowall_loaded: bool = false
static var tex_autowall_wood_vars: Array = []
static var tex_autowall_brick_vars: Array = []
static var tex_autowall_stone_vars: Array = []

# ПУНКТ 2.1 и 2.2: 4-кадровые текстуры анимации дверей (фронтальные и боковые) и боковые окна
static var tex_door_front_frames: Array[ImageTexture] = []
static var tex_door_side_frames: Array[ImageTexture] = []
static var tex_window_side_frames: Array[ImageTexture] = []

static var _roof_loaded: bool = false
static var tex_roof_wood_frames: Array[Texture2D] = []
static var tex_chimney_sprite: ImageTexture
static var _rooms_cache: Array[Dictionary] = []
static var _cell_to_room_id: Dictionary = {}
static var _roof_cell_to_room_id: Dictionary = {}
static var _rooms_dirty: bool = true

const HOTBAR_SLOT_W: float = 54.0
const HOTBAR_GAP: float = 5.0
const HOTBAR_HEIGHT: float = 64.0

static func ensure_autowall_textures() -> void:
	if _autowall_loaded:
		return
	_autowall_loaded = true

	tex_autowall_wood_vars.clear()
	tex_autowall_brick_vars.clear()
	tex_autowall_stone_vars.clear()

	for v in range(4):
		var w_arr: Array[Texture2D] = []
		var b_arr: Array[Texture2D] = []
		var s_arr: Array[Texture2D] = []
		for mask in range(16):
			w_arr.append(_create_autowall_tile("wood", mask, v))
			b_arr.append(_create_autowall_tile("brick", mask, v))
			s_arr.append(_create_autowall_tile("stone", mask, v))
		tex_autowall_wood_vars.append(w_arr)
		tex_autowall_brick_vars.append(b_arr)
		tex_autowall_stone_vars.append(s_arr)

	tex_door_front_frames.clear()
	tex_door_side_frames.clear()
	for stage in range(4):
		var openness: float = float(stage) / 3.0
		tex_door_front_frames.append(_create_oriented_door_tile(false, openness))
		tex_door_side_frames.append(_create_oriented_door_tile(true, openness))

	tex_window_side_frames.clear()
	tex_window_side_frames.append(_create_side_window_tile(false))
	tex_window_side_frames.append(_create_side_window_tile(true))

	ensure_roof_textures()

# ПУНКТ 2.1 и 2.2: Генерация 4 фаз открытия для фронтальной и боковой (профильной) двери
static func _create_oriented_door_tile(is_side: bool, openness: float) -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	var c_wood_hi := Color("#9a6b3f")
	var c_wood_mid := Color("#7a5230")
	var c_wood_dark := Color("#5b3a22")
	var c_iron := Color("#9aa1ab")
	var c_sill := Color("#4a4f59")

	if not is_side:
		# Фронтальная дверь (стена идёт слева направо, проход вверх-вниз)
		for x in range(1, 15):
			img.set_pixel(x, 22, c_sill)
			img.set_pixel(x, 23, c_out)
		# Боковые косяки и верхняя перекладина
		for y in range(2, 24):
			for x in [0, 1, 2, 13, 14, 15]:
				var edge: bool = (x == 0 or x == 2 or x == 13 or x == 15 or y == 2 or y == 23)
				img.set_pixel(x, y, c_out if edge else c_wood_hi)
		for x in range(0, 16):
			for y in range(2, 6):
				img.set_pixel(x, y, c_out if (y == 2 or y == 5 or x == 0 or x == 15) else c_wood_hi)

		# Створка двери (плавно распахивается и укорачивается по ширине в 4 кадра)
		var leaf_w: int = int(round(lerpf(10.0, 2.0, openness)))
		for x in range(3, 3 + leaf_w):
			for y in range(6, 23):
				var is_b: bool = (x == 3 + leaf_w - 1 or y == 22)
				var iron_b: bool = (y == 9 or y == 18)
				var seam: bool = ((x - 3) % 3 == 0 and openness < 0.5)
				if is_b or seam:
					img.set_pixel(x, y, c_out)
				elif iron_b:
					img.set_pixel(x, y, c_iron)
				else:
					img.set_pixel(x, y, c_wood_mid if y < 14 else c_wood_dark)
		if leaf_w >= 5:
			img.set_pixel(3 + leaf_w - 2, 14, Color("#ffcc66"))
	else:
		# Боковая дверь в профиль (стена идёт сверху вниз, проход слева направо)
		# Каменный порог на всю глубину клетки
		for y in range(10, 24):
			for x in range(4, 12):
				if x == 4 or x == 11 or y == 10 or y == 23:
					img.set_pixel(x, y, c_out)
				else:
					img.set_pixel(x, y, c_sill if (x + y) % 2 == 0 else c_sill.darkened(0.15))

		# Верхняя и нижняя деревянные стойки коробки в профиль
		for y in range(0, 9):
			for x in range(4, 12):
				var edge_t: bool = (x == 4 or x == 11 or y == 0 or y == 8)
				img.set_pixel(x, y, c_out if edge_t else (c_wood_hi if x < 8 else c_wood_mid))
		for y in range(18, 24):
			for x in range(4, 12):
				var edge_b: bool = (x == 4 or x == 11 or y == 18 or y == 23)
				img.set_pixel(x, y, c_out if edge_b else c_wood_dark)

		# Полотно двери: закрыто — вертикально перекрывает проём (x=6..9, y=4..21);
		# при открытии — поворачивается вбок вправо (до x=15)
		var swing_dx: int = int(round(openness * 6.0))
		for s in range(10):
			var t_s: float = float(s) / 9.0
			var px: int = clampi(int(round(lerpf(7.0, 7.0 + float(swing_dx), t_s))), 2, 15)
			var py_top: int = int(round(lerpf(5.0, 7.0 - openness * 2.0, t_s)))
			for py in range(py_top, py_top + 12):
				if py >= 1 and py < 23:
					img.set_pixel(px, py, c_wood_hi if py < py_top + 3 else c_wood_mid)
					if px + 1 < 16:
						img.set_pixel(px + 1, py, c_out)
					if px - 1 >= 0 and s == 0:
						img.set_pixel(px - 1, py, c_out)
					if py == py_top or py == py_top + 11:
						img.set_pixel(px, py, c_out)
					elif py == py_top + 4 or py == py_top + 9:
						img.set_pixel(px, py, c_iron)

	return ImageTexture.create_from_image(img)

# ПУНКТ 2.2: Боковое окно в профиль для вертикальных стен (день и тёплый свет ночью)
static func _create_side_window_tile(is_lit: bool) -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	var c_stone_hi := Color("#8b929c")
	var c_stone_mid := Color("#656b75")
	var c_stone_front := Color("#4b5059")
	var c_frame := Color("#5b3a22")
	var c_glass := Color("#ffcc66") if is_lit else Color("#3b556e")
	var c_glass_hi := Color("#fff3b0") if is_lit else Color("#5c82a6")

	for y in range(0, 24):
		for x in range(2, 14):
			var is_border: bool = (x == 2 or x == 13 or y == 0 or y == 23 or y == 13)
			if is_border:
				img.set_pixel(x, y, c_out)
			elif y < 13:
				# Верхняя грань стены с врезанной посередине узкой рамой окна
				if y >= 3 and y <= 10 and x >= 5 and x <= 10:
					if x == 5 or x == 10 or y == 3 or y == 10:
						img.set_pixel(x, y, c_frame)
					elif y == 6:
						img.set_pixel(x, y, c_out)
					else:
						img.set_pixel(x, y, c_glass_hi if x <= 7 else c_glass)
				else:
					img.set_pixel(x, y, c_stone_hi if x < 8 else c_stone_mid)
			else:
				# Передний торец стены под окном
				var seam: bool = (y == 18 or x == 8)
				img.set_pixel(x, y, Color("#2b2f36") if seam else c_stone_front)

	return ImageTexture.create_from_image(img)

static func _create_autowall_tile(mat_kind: String, mask: int, variant: int) -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	var c_out := Color("#1f1b18")
	var has_n: bool = (mask & 1) != 0
	var has_e: bool = (mask & 2) != 0
	var has_s: bool = (mask & 4) != 0
	var has_w: bool = (mask & 8) != 0

	var c_stone_hi := Color("#8b929c")
	var c_stone_mid := Color("#656b75")
	var c_stone_front := Color("#4b5059")
	var c_stone_seam := Color("#32363d")
	var c_moss := Color("#364d2c")

	var c_top_hi: Color = c_stone_hi
	var c_top: Color = c_stone_mid
	var c_front: Color = c_stone_front
	var c_seam: Color = c_stone_seam

	if mat_kind == "wood":
		c_top_hi = Color("#8c7055")
		c_top = Color("#735942")
		c_front = Color("#5c4532")
		c_seam = Color("#3d2d20")
	elif mat_kind == "brick":
		c_top_hi = Color("#82644b")
		c_top = Color("#6b503b")
		c_front = Color("#57402f")
		c_seam = Color("#3d2c20")

	var x0: int = 0 if has_w else 2
	var x1: int = 15 if has_e else 13
	var y_top0: int = 0 if has_n else 3
	var y_top1: int = 13 if has_s else 10

	var seam_y: int = 4 + (variant * 3) % 6
	var seam_x: int = 5 + (variant * 3) % 6

	for y in range(y_top0, y_top1 + 1):
		for x in range(x0, x1 + 1):
			var is_border: bool = (
				(not has_w and x == x0) or
				(not has_e and x == x1) or
				(not has_n and y == y_top0) or
				(not has_s and y == y_top1)
			)
			if is_border:
				img.set_pixel(x, y, c_out)
			elif mat_kind == "wood":
				var log_sep: bool = (x % 4 == 0)
				if y == (y_top0 + y_top1) / 2:
					img.set_pixel(x, y, c_stone_mid)
				elif log_sep:
					img.set_pixel(x, y, c_seam)
				else:
					img.set_pixel(x, y, c_top_hi if (y <= y_top0 + 2 and x % 4 == 1) else c_top)
			else:
				var is_joint: bool = (x == seam_x or y == seam_y)
				if is_joint:
					img.set_pixel(x, y, c_seam)
				else:
					var shade_r: bool = (x >= x1 - 2)
					img.set_pixel(x, y, c_front if shade_r else (c_top_hi if y <= y_top0 + 2 else c_top))

	var f_y0: int = y_top1 + 1
	var f_y1: int = 23
	var split_top: int = 4 + (variant * 3) % 7
	var split_bot: int = 8 - (variant * 2) % 6

	for y in range(f_y0, f_y1 + 1):
		for x in range(x0, x1 + 1):
			var edge: bool = ((not has_w and x == x0) or (not has_e and x == x1) or y == f_y1)
			if edge:
				img.set_pixel(x, y, c_out)
			elif y >= 20:
				var base_seam: bool = (y == 20 or x == x0 + 6)
				img.set_pixel(x, y, c_stone_seam if base_seam else c_stone_front)
			elif mat_kind == "wood":
				var v_log: bool = (x % 4 == 0)
				var iron_band: bool = (y == f_y0 + 2)
				if iron_band:
					img.set_pixel(x, y, c_stone_hi if x % 4 == 2 else c_stone_front)
				elif v_log:
					img.set_pixel(x, y, c_seam)
				else:
					var log_col: Color = c_top if (x % 4 == 1) else (c_front if (x % 4 == 2) else c_front.darkened(0.08))
					img.set_pixel(x, y, log_col)
			else:
				var mid_row: int = f_y0 + 4
				var h_seam: bool = (y == mid_row)
				var v_seam: bool = ((y < mid_row and x == x0 + split_top) or (y > mid_row and x == x0 + split_bot))
				if h_seam or v_seam:
					img.set_pixel(x, y, c_seam)
				else:
					var col: Color = c_top if (y == f_y0 or y == mid_row + 1) else c_front
					if (variant == 1 or variant == 3) and y <= f_y0 + 1 and abs(x - (x0 + split_top)) <= 1:
						col = c_moss
					img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

static func ensure_roof_textures() -> void:
	if _roof_loaded:
		return
	_roof_loaded = true
	tex_roof_wood_frames.clear()
	for i in range(8):
		tex_roof_wood_frames.append(_create_procedural_roof_tile(i))
	tex_chimney_sprite = _create_chimney_texture()

static func _create_procedural_roof_tile(variant: int) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c_out := Color("#211610")
	var c_seam := Color("#2e1f16")
	var c_beam := Color("#3d281c")
	var c_beam_hi := Color("#63432e")
	var c_moss := Color("#354a2b")

	var is_north_slope: bool = (variant == 4 or variant == 5)
	var shingles: Array = [
		Color("#663c28"), Color("#593322"), Color("#73452e"), Color("#4d2b1c")
	] if not is_north_slope else [
		Color("#3d2418"), Color("#331e14"), Color("#472b1d"), Color("#2b1810")
	]

	for y in range(16):
		for x in range(16):
			if variant == 6 and y >= 4 and y <= 11:
				if y == 4 or y == 11:
					img.set_pixel(x, y, c_out)
				elif y <= 6:
					img.set_pixel(x, y, Color("#855a3e") if (x % 8 != 0) else c_seam)
				elif y <= 9:
					img.set_pixel(x, y, c_beam_hi if (x % 8 != 0) else Color("#4a4f59"))
				else:
					img.set_pixel(x, y, c_beam)
				continue

			if variant == 7 and y >= 11:
				if y == 11 or y == 15:
					img.set_pixel(x, y, c_out)
				elif y == 12:
					img.set_pixel(x, y, c_beam_hi if (x % 4 != 0) else c_beam)
				else:
					img.set_pixel(x, y, c_beam if y == 13 else Color("#24150c"))
				continue

			var row_h: int = 5
			var row_idx: int = y / row_h
			var dy: int = y % row_h
			var shift: int = (row_idx * 3 + variant * 2) % 6
			var col_idx: int = (x + shift) / 5
			var is_h_seam: bool = (dy == row_h - 1)
			var is_v_seam: bool = ((x + shift) % 5 == 0 and dy >= 1)

			if is_h_seam or is_v_seam:
				img.set_pixel(x, y, c_seam)
			else:
				var h_hash: int = abs(row_idx * 13 + col_idx * 29 + variant * 7)
				var sc: Color = shingles[h_hash % shingles.size()]
				if dy == 0 and not is_north_slope:
					sc = sc.lightened(0.07)
				if (variant == 1 or variant == 2 or variant == 5) and (h_hash % 7 == 0) and dy >= 2:
					sc = c_moss
				img.set_pixel(x, y, sc)

	return ImageTexture.create_from_image(img)

static func _create_chimney_texture() -> ImageTexture:
	var img := Image.create(16, 20, false, Image.FORMAT_RGBA8)
	var c_out := Color("#1f1b18")
	var c_stone_hi := Color("#8a929e")
	var c_stone := Color("#5c636e")
	var c_dark := Color("#353940")
	for x in range(2, 14):
		for y in range(2, 19):
			var edge: bool = (x == 2 or x == 13 or y == 2 or y == 18 or y == 6)
			if edge:
				img.set_pixel(x, y, c_out)
			elif y < 6:
				img.set_pixel(x, y, Color("#14161b") if (x >= 5 and x <= 10 and y >= 3) else c_stone_hi)
			else:
				var seam: bool = (y == 11 or y == 15 or (y < 11 and x == 8) or (y > 11 and x == 6))
				img.set_pixel(x, y, c_dark if seam else (c_stone_hi if x < 6 else c_stone))
	return ImageTexture.create_from_image(img)

static func is_connectable_neighbor(world: Node2D, cell: Vector2i) -> bool:
	if not world.wall_map.has(cell):
		return false
	var w_data: Dictionary = world.wall_map[cell]
	var b_id: int = int(w_data.get("id", 0))
	if b_id == 8:
		return false
	if b_id in [1, 2, 3, 4, 6, 9]:
		return true
	if bool(w_data.get("is_door", false)) or bool(w_data.get("is_window", false)):
		return true
	return false

static func is_room_boundary(world: Node2D, cell: Vector2i) -> bool:
	return is_connectable_neighbor(world, cell)

static func mark_rooms_dirty() -> void:
	_rooms_dirty = true

static func rebuild_rooms_cache(world: Node2D) -> void:
	ensure_roof_textures()
	var prev_alphas: Dictionary = {}
	for r in _rooms_cache:
		var sig_cell: Vector2i = r.get("anchor", Vector2i(9999, 9999))
		prev_alphas[sig_cell] = float(r.get("alpha", 1.0))

	_rooms_cache.clear()
	_cell_to_room_id.clear()
	_roof_cell_to_room_id.clear()
	_rooms_dirty = false

	var visited: Dictionary = {}
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	for start_cell in world.ground_map.keys():
		var g_type: int = int(world.ground_map[start_cell])
		if g_type != 2 and g_type != 7:
			continue
		if visited.has(start_cell) or is_room_boundary(world, start_cell):
			continue

		var queue: Array[Vector2i] = [start_cell]
		var q_head: int = 0
		var room_interior: Dictionary = { start_cell: true }
		visited[start_cell] = true

		var min_x: int = start_cell.x
		var max_x: int = start_cell.x
		var min_y: int = start_cell.y
		var max_y: int = start_cell.y

		while q_head < queue.size():
			var cur: Vector2i = queue[q_head]
			q_head += 1

			for d in dirs:
				var nb: Vector2i = cur + d
				if room_interior.has(nb) or is_room_boundary(world, nb):
					continue
				var nb_ground: int = int(world.ground_map.get(nb, 0))
				if nb_ground != 2 and nb_ground != 7:
					continue
				if room_interior.size() >= 260:
					break

				min_x = mini(min_x, nb.x)
				max_x = maxi(max_x, nb.x)
				min_y = mini(min_y, nb.y)
				max_y = maxi(max_y, nb.y)
				room_interior[nb] = true
				visited[nb] = true
				queue.append(nb)

		if room_interior.size() < 4:
			continue

		var roof_set: Dictionary = {}
		for ic in room_interior.keys():
			roof_set[ic] = true
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var wc: Vector2i = ic + Vector2i(dx, dy)
					if is_room_boundary(world, wc):
						roof_set[wc] = true

		var room_idx: int = _rooms_cache.size()
		var anchor_cell: Vector2i = queue[0]
		for ic in room_interior.keys():
			_cell_to_room_id[ic] = room_idx
		for rc in roof_set.keys():
			_roof_cell_to_room_id[rc] = room_idx

		var roof_cells_list: Array[Vector2i] = []
		for rc in roof_set.keys():
			roof_cells_list.append(rc)

		_rooms_cache.append({
			"id": room_idx,
			"anchor": anchor_cell,
			"interior_set": room_interior,
			"roof_set": roof_set,
			"roof_cells": roof_cells_list,
			"min_x": min_x - 1,
			"max_x": max_x + 1,
			"min_y": min_y - 1,
			"max_y": max_y + 1,
			"alpha": float(prev_alphas.get(anchor_cell, 1.0))
		})

static func get_player_active_room_id(world: Node2D) -> int:
	if _rooms_dirty:
		rebuild_rooms_cache(world)
	if not is_instance_valid(world.player):
		return -1
	var p_cell: Vector2i = world._world_to_cell(world.player.global_position)
	if _cell_to_room_id.has(p_cell):
		return int(_cell_to_room_id[p_cell])
	return -1

static func is_player_inside_any_room(world: Node2D) -> bool:
	return get_player_active_room_id(world) != -1

static func is_cell_in_lit_room(world: Node2D, win_cell: Vector2i) -> bool:
	if _rooms_dirty:
		rebuild_rooms_cache(world)
	var room_id: int = int(_roof_cell_to_room_id.get(win_cell, -1))
	if room_id >= 0 and room_id < _rooms_cache.size():
		if get_player_active_room_id(world) == room_id:
			return true
		var r_set: Dictionary = _rooms_cache[room_id]["roof_set"]
		for fc in world.campfires:
			if r_set.has(fc):
				return true
		for tc in world.wall_torches:
			if r_set.has(tc) or r_set.has(tc + Vector2i(0, -1)):
				return true
	return false

static func update_roof_alphas(world: Node2D, delta: float) -> void:
	if _rooms_dirty:
		rebuild_rooms_cache(world)
	var active_room: int = get_player_active_room_id(world)
	for r in _rooms_cache:
		var target_a: float = 0.0 if int(r["id"]) == active_room else 1.0
		r["alpha"] = move_toward(float(r["alpha"]), target_a, delta * 4.5)

static func draw_all_roofs(layer: Node2D, world: Node2D) -> void:
	if _rooms_dirty:
		rebuild_rooms_cache(world)
	ensure_roof_textures()
	var total_frames: int = tex_roof_wood_frames.size()
	if total_frames < 8:
		return

	var c_size: int = world.CELL_SIZE
	for r in _rooms_cache:
		var a: float = float(r.get("alpha", 1.0))
		if a <= 0.01:
			continue
		var roof_set: Dictionary = r["roof_set"]
		var roof_cells: Array = r["roof_cells"]
		var min_y: int = int(r["min_y"])
		var max_y: int = int(r["max_y"])
		var min_x: int = int(r["min_x"])
		var max_x: int = int(r["max_x"])
		var ridge_y: int = (min_y + max_y) / 2

		for rc in roof_cells:
			var cell: Vector2i = rc
			var pos := Vector2(cell * c_size)
			if not roof_set.has(cell + Vector2i(0, 1)):
				Phase1Visuals.draw_soft_shadow(layer, pos + Vector2(10, 15), Vector2(24, 12), 0.42 * a)

		for rc in roof_cells:
			var cell: Vector2i = rc
			var pos := Vector2(cell * c_size) + Vector2(0, -8)
			var is_bottom_edge: bool = not roof_set.has(cell + Vector2i(0, 1))
			var is_top_edge: bool = not roof_set.has(cell + Vector2i(0, -1))
			var is_left_edge: bool = not roof_set.has(cell + Vector2i(-1, 0))
			var is_right_edge: bool = not roof_set.has(cell + Vector2i(1, 0))

			var frame_idx: int = 0
			var slope_mod := Color(1.0, 1.0, 1.0, a)
			if is_bottom_edge:
				frame_idx = 7
			elif cell.y == ridge_y:
				frame_idx = 6
			elif cell.y < ridge_y:
				frame_idx = 4 + (ArtLoader.cell_hash(cell, 19) % 2)
				slope_mod = Color(0.82, 0.80, 0.86, a)
			else:
				frame_idx = ArtLoader.cell_hash(cell, 23) % 4

			layer.draw_texture_rect(tex_roof_wood_frames[frame_idx], Rect2(pos, Vector2(16, 16)), false, slope_mod)

			var edge_col := Color(0.14, 0.10, 0.08, a * 0.92)
			var beam_col := Color(0.38, 0.26, 0.18, a * 0.92)
			if is_top_edge:
				layer.draw_rect(Rect2(pos, Vector2(16, 2)), edge_col, true)
			if is_left_edge:
				layer.draw_rect(Rect2(pos + Vector2(1, 0), Vector2(2, 16)), beam_col, true)
				layer.draw_rect(Rect2(pos, Vector2(1, 16)), edge_col, true)
			if is_right_edge:
				layer.draw_rect(Rect2(pos + Vector2(13, 0), Vector2(2, 16)), beam_col.darkened(0.2), true)
				layer.draw_rect(Rect2(pos + Vector2(15, 0), Vector2(1, 16)), edge_col, true)

		if (max_x - min_x) >= 4 and tex_chimney_sprite != null:
			var ch_cell := Vector2i(max_x - 2, ridge_y - 1)
			if not roof_set.has(ch_cell):
				ch_cell = Vector2i(max_x - 2, ridge_y)
			if roof_set.has(ch_cell):
				var ch_pos := Vector2(ch_cell * c_size) + Vector2(0, -16)
				Phase1Visuals.draw_soft_shadow(layer, ch_pos + Vector2(11, 18), Vector2(18, 9), 0.38 * a)
				layer.draw_texture_rect(tex_chimney_sprite, Rect2(ch_pos, Vector2(16, 20)), false, Color(1, 1, 1, a))
				var t_sec: float = float(Time.get_ticks_msec()) * 0.0022
				for i in range(3):
					var dy: float = fmod(t_sec * 7.5 + float(i) * 6.0, 18.0)
					var dx: float = sin(t_sec + float(i) * 1.4) * 3.0
					var sm_pos := ch_pos + Vector2(6.0 + dx, -3.0 - dy)
					var sm_a: float = clampf((0.36 - dy * 0.016) * a, 0.0, 0.40)
					layer.draw_rect(Rect2(sm_pos, Vector2(4, 4)), Color(0.82, 0.85, 0.90, sm_a), true)

static func compute_autowall_mask(world: Node2D, cell: Vector2i) -> int:
	var mask: int = 0
	if is_connectable_neighbor(world, cell + Vector2i(0, -1)):
		mask |= 1
	if is_connectable_neighbor(world, cell + Vector2i(1, 0)):
		mask |= 2
	if is_connectable_neighbor(world, cell + Vector2i(0, 1)):
		mask |= 4
	if is_connectable_neighbor(world, cell + Vector2i(-1, 0)):
		mask |= 8
	return mask

# ПУНКТ 2.2: Определение ориентации блока (false = фронтальная стена З-В, true = боковая стена С-Ю)
static func compute_block_is_side(world: Node2D, cell: Vector2i, fallback_to_player_look: bool = true) -> bool:
	var mask: int = compute_autowall_mask(world, cell)
	var ns_count: int = (1 if (mask & 1) != 0 else 0) + (1 if (mask & 4) != 0 else 0)
	var ew_count: int = (1 if (mask & 2) != 0 else 0) + (1 if (mask & 8) != 0 else 0)
	if ns_count > ew_count:
		return true
	if ew_count > ns_count:
		return false
	if fallback_to_player_look and is_instance_valid(world.player):
		# Если соседей поровну (0 или 2 в углу) — ориентируем перпендикулярно взгляду игрока!
		return absf(world.player.look_direction.x) > absf(world.player.look_direction.y)
	return false

static func _apply_oriented_collider(w_data: Dictionary, mask: int) -> void:
	var b_id: int = int(w_data.get("id", 0))
	var is_door: bool = bool(w_data.get("is_door", false))
	var is_win: bool = (b_id == 9 or bool(w_data.get("is_window", false)))
	if not is_door and not is_win:
		return

	var ns_count: int = (1 if (mask & 1) != 0 else 0) + (1 if (mask & 4) != 0 else 0)
	var ew_count: int = (1 if (mask & 2) != 0 else 0) + (1 if (mask & 8) != 0 else 0)
	var is_side: bool = bool(w_data.get("is_side", false))
	if ns_count > ew_count:
		is_side = true
	elif ew_count > ns_count:
		is_side = false
	w_data["is_side"] = is_side

	var col: CollisionShape2D = w_data.get("col", null)
	if is_instance_valid(col) and col.shape is RectangleShape2D:
		var r_shape: RectangleShape2D = col.shape as RectangleShape2D
		if is_door:
			r_shape.size = Vector2(8.0, 16.0) if is_side else Vector2(16.0, 10.0)
		else:
			r_shape.size = Vector2(10.0, 16.0) if is_side else Vector2(16.0, 12.0)

static func update_autowall_around(world: Node2D, center_cell: Vector2i) -> void:
	mark_rooms_dirty()
	var cells_to_update: Array[Vector2i] = [
		center_cell,
		center_cell + Vector2i(0, -1),
		center_cell + Vector2i(1, 0),
		center_cell + Vector2i(0, 1),
		center_cell + Vector2i(-1, 0)
	]
	for c in cells_to_update:
		if world.wall_map.has(c):
			var mask: int = compute_autowall_mask(world, c)
			_autowall_mask_cache[c] = mask
			world.wall_map[c]["autowall_mask"] = mask
			_apply_oriented_collider(world.wall_map[c], mask)
		else:
			_autowall_mask_cache.erase(c)

static func rebuild_all_autowalls(world: Node2D) -> void:
	ensure_autowall_textures()
	_autowall_mask_cache.clear()
	for cell in world.wall_map.keys():
		var mask: int = compute_autowall_mask(world, cell)
		_autowall_mask_cache[cell] = mask
		world.wall_map[cell]["autowall_mask"] = mask
		_apply_oriented_collider(world.wall_map[cell], mask)
	rebuild_rooms_cache(world)

static func get_autowall_mask(world: Node2D, cell: Vector2i) -> int:
	if _autowall_mask_cache.has(cell):
		return int(_autowall_mask_cache[cell])
	var mask: int = compute_autowall_mask(world, cell)
	_autowall_mask_cache[cell] = mask
	return mask

static func get_door_draw_texture(is_side: bool, anim_t: float) -> Texture2D:
	ensure_autowall_textures()
	var idx: int = clampi(int(round(anim_t * 3.0)), 0, 3)
	if is_side and tex_door_side_frames.size() == 4:
		return tex_door_side_frames[idx]
	if tex_door_front_frames.size() == 4:
		return tex_door_front_frames[idx]
	return null

static func get_window_draw_texture(world: Node2D, is_side: bool, is_lit: bool) -> Texture2D:
	ensure_autowall_textures()
	var idx: int = 1 if is_lit else 0
	if is_side and tex_window_side_frames.size() == 2:
		return tex_window_side_frames[idx]
	if not world.tex_block_window_frames.is_empty():
		return world.tex_block_window_frames[mini(idx, world.tex_block_window_frames.size() - 1)]
	return null

static func get_wall_draw_texture(world: Node2D, cell: Vector2i, b_id: int) -> Texture2D:
	ensure_autowall_textures()
	if b_id == 3:
		return world.tex_wall_pillar
	if b_id == 8:
		return world.tex_pine_snow if world.current_weather == 3 else world.tex_pine_day

	var mask: int = clampi(get_autowall_mask(world, cell), 0, 15)
	var v_idx: int = ArtLoader.cell_hash(cell, 43) % 4

	if b_id == 1 and tex_autowall_wood_vars.size() == 4:
		return tex_autowall_wood_vars[v_idx][mask]
	if b_id == 2 and tex_autowall_brick_vars.size() == 4:
		return tex_autowall_brick_vars[v_idx][mask]
	if b_id == 4 and tex_autowall_stone_vars.size() == 4:
		return tex_autowall_stone_vars[v_idx][mask]

	var s_var: int = ArtLoader.pick_cell_variant(cell, world.tex_wall_stone_sec.size())
	return world.tex_wall_stone_sec[s_var]

static func get_reach_cells(world: Node2D) -> float:
	var p_cfg: Dictionary = world.config.get("player", {})
	return float(p_cfg.get("reach_cells", 4.5)) + 3.5

static func is_cell_occupied_by_station(world: Node2D, cell: Vector2i) -> bool:
	if cell == world.water_well_cell or cell == world.bed_cell:
		return true
	if world.campfires.has(cell) or world.workbenches.has(cell):
		return true
	if world.watchtowers.has(cell) or world.loot_crates.has(cell):
		return true
	return false

static func is_cell_occupied_by_actor(world: Node2D, cell: Vector2i) -> bool:
	var c_size: int = world.CELL_SIZE
	var cell_rect := Rect2(Vector2(cell * c_size) + Vector2(1, 1), Vector2(c_size - 2, c_size - 2))

	if is_instance_valid(world.player):
		var p_rect := Rect2(world.player.global_position - Vector2(5, 5), Vector2(10, 10))
		if cell_rect.intersects(p_rect):
			return true

	if is_instance_valid(world.colonists_layer):
		for ch in world.colonists_layer.get_children():
			if ch is ColonistEntity:
				var col_rect := Rect2(ch.global_position - Vector2(5, 5), Vector2(10, 10))
				if cell_rect.intersects(col_rect):
					return true

	if is_instance_valid(world.titans_layer):
		for ch in world.titans_layer.get_children():
			if ch is TitanEntity and ch.state != TitanEntity.State.DYING:
				var t_rect := Rect2(ch.global_position - Vector2(12, 12), Vector2(24, 24))
				if cell_rect.intersects(t_rect):
					return true

	return false

# ПУНКТ 2.3: Диагностика возможности постройки с точной причиной запрета для подсказки у курсора!
static func get_place_block_status(world: Node2D, cell: Vector2i, b_id: int) -> Dictionary:
	if b_id <= 0:
		return {"ok": false, "reason": "Слот пуст"}
	if not is_instance_valid(world.player) or world.player.is_dead:
		return {"ok": false, "reason": ""}
	if abs(cell.x) > world.MAP_RADIUS or abs(cell.y) > world.MAP_RADIUS:
		return {"ok": false, "reason": "Край карты"}

	var p_cell: Vector2i = world._world_to_cell(world.player.global_position)
	if Vector2(p_cell).distance_to(Vector2(cell)) > get_reach_cells(world):
		return {"ok": false, "reason": "Далеко"}

	var b_info: Dictionary = world.blocks_db.get(str(b_id), {})
	if b_info.is_empty():
		return {"ok": false, "reason": "Нет блока"}

	var cost_item: String = str(b_info.get("cost_item", "wood"))
	if int(world.player.surv.inventory.get(cost_item, 0)) < 1:
		var item_name: String = str(world.player.surv.items_db.get(cost_item, {}).get("name", cost_item))
		return {"ok": false, "reason": "Нет: " + item_name}

	if world.wall_map.has(cell) or is_cell_occupied_by_station(world, cell):
		return {"ok": false, "reason": "Занято"}

	var is_solid: bool = bool(b_info.get("solid", true))
	if not is_solid:
		var target_floor: int = int(b_info.get("floor_type", 7 if b_id == 10 else 2))
		if int(world.ground_map.get(cell, 0)) == target_floor:
			return {"ok": false, "reason": "Уже уложено"}
		return {"ok": true, "reason": ""}

	if is_cell_occupied_by_actor(world, cell):
		return {"ok": false, "reason": "Мешает существо"}

	return {"ok": true, "reason": ""}

static func can_place_block(world: Node2D, cell: Vector2i, b_id: int) -> bool:
	return bool(get_place_block_status(world, cell, b_id).get("ok", false))

static func try_place_block(world: Node2D, cell: Vector2i, b_id: int) -> bool:
	if not can_place_block(world, cell, b_id):
		return false
	var b_info: Dictionary = world.blocks_db.get(str(b_id), {})
	var cost_item: String = str(b_info.get("cost_item", "wood"))
	if not world.player.surv.remove_item(cost_item, 1):
		return false
	world._set_block(cell, b_id, true)
	world.play_sfx("build")
	return true

static func try_remove_block(world: Node2D, cell: Vector2i) -> bool:
	if not is_instance_valid(world.player) or world.player.is_dead:
		return false
	var p_cell: Vector2i = world._world_to_cell(world.player.global_position)
	if Vector2(p_cell).distance_to(Vector2(cell)) > get_reach_cells(world):
		return false
	if world.watchtowers.has(cell):
		return false

	if world.wall_map.has(cell):
		var w_data: Dictionary = world.wall_map[cell]
		var drop_item: String = str(w_data.get("drop", "wood"))
		world._remove_wall(cell, true)
		world.player.surv.add_item(drop_item, 1)
		world.play_sfx("build")
		return true
	else:
		var g_type: int = int(world.ground_map.get(cell, 0))
		if (g_type == 2 or g_type == 7) and not is_cell_occupied_by_station(world, cell):
			var ret_item: String = "stone" if g_type == 7 else "wood"
			world.ground_map[cell] = 1
			mark_rooms_dirty()
			world.player.surv.add_item(ret_item, 1)
			world.play_sfx("build")
			world.queue_redraw()
			return true

	return false

# ПУНКТ 2.3: Линейная интерполяция клеток (Брезенхэм), чтобы при быстрой протяжке мыши/пальца стена ставилась ровной линией без дыр!
static func _trace_line_cells(c0: Vector2i, c1: Vector2i) -> Array[Vector2i]:
	if c0.x == 9999 or c0.distance_to(c1) > 12.0:
		return [c1]
	var res: Array[Vector2i] = []
	var steps: int = maxi(absi(c1.x - c0.x), absi(c1.y - c0.y))
	if steps <= 0:
		return [c1]
	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		var cx: int = int(round(lerpf(float(c0.x), float(c1.x), t)))
		var cy: int = int(round(lerpf(float(c0.y), float(c1.y), t)))
		var pt := Vector2i(cx, cy)
		if res.is_empty() or res[res.size() - 1] != pt:
			res.append(pt)
	return res

static func place_station_near_player(world: Node2D, st_kind: String) -> bool:
	if not is_instance_valid(world.player) or world.player.is_dead:
		return false
	var p_cell: Vector2i = world._world_to_cell(world.player.global_position)
	var look_step := Vector2i(int(round(world.player.look_direction.x)), int(round(world.player.look_direction.y)))
	if look_step == Vector2i.ZERO:
		look_step = Vector2i(0, 1)

	var offsets: Array[Vector2i] = [
		look_step,
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]

	for off in offsets:
		var c: Vector2i = p_cell + off
		if world.wall_map.has(c) or is_cell_occupied_by_station(world, c) or is_cell_occupied_by_actor(world, c):
			continue
		if st_kind == "campfire":
			world.campfires.append(c)
			world.decor_map.erase(c)
			var pl := PointLight2D.new()
			pl.position = Vector2(c * world.CELL_SIZE) + Vector2(8, 8)
			pl.texture = world.light_tex
			pl.texture_scale = 0.85
			pl.color = Color("#ffb35a")
			pl.energy = 0.45
			world.add_child(pl)
			world.campfire_lights.append(pl)
			world.queue_redraw()
			return true
		elif st_kind == "workbench":
			world.workbenches.append(c)
			world.decor_map.erase(c)
			world.queue_redraw()
			return true
		elif st_kind == "spike_trap":
			world._set_block(c, 1, false)
			world.queue_redraw()
			return true
	return false

static func try_select_hotbar_at_screen_pos(world: Node2D, screen_pt: Vector2) -> bool:
	var vp_size: Vector2 = world.get_viewport_rect().size
	if screen_pt.y < vp_size.y - (HOTBAR_HEIGHT + 16.0):
		return false
	var total_w: float = 10.0 * HOTBAR_SLOT_W + 9.0 * HOTBAR_GAP
	var start_x: float = (vp_size.x - total_w) * 0.5
	var rel_x: float = screen_pt.x - start_x
	if rel_x >= -6.0 and rel_x <= total_w + 6.0:
		var slot_idx: int = clampi(int(floor(rel_x / (HOTBAR_SLOT_W + HOTBAR_GAP))), 0, 9)
		if world.has_method("select_hotbar_slot_index"):
			world.select_hotbar_slot_index(slot_idx, true)
		else:
			world.selected_hotbar_slot = slot_idx
			world.selected_block_id = slot_idx + 1
		return true
	return false

static func screen_to_world_pos(world: Node2D, screen_pt: Vector2) -> Vector2:
	return world.get_canvas_transform().affine_inverse() * screen_pt

static func handle_touch_build_at_screen_pos(world: Node2D, screen_pt: Vector2) -> bool:
	if not world.build_mode_active:
		return false
	var world_pt: Vector2 = screen_to_world_pos(world, screen_pt)
	last_touch_world_pos = world_pt
	has_touch_preview = true
	var target_cell: Vector2i = world._world_to_cell(world_pt)

	var is_demolish: bool = false
	if "mobile_hud" in world and world.mobile_hud != null:
		is_demolish = bool(world.mobile_hud.demolish_mode)

	if is_demolish:
		if target_cell != _last_removed_cell:
			for c_step in _trace_line_cells(_last_removed_cell, target_cell):
				try_remove_block(world, c_step)
			_last_removed_cell = target_cell
	else:
		if target_cell != _last_built_cell:
			for c_step in _trace_line_cells(_last_built_cell, target_cell):
				try_place_block(world, c_step, world.selected_block_id)
			_last_built_cell = target_cell
	return true

static func reset_touch_build_memory() -> void:
	_last_built_cell = Vector2i(9999, 9999)
	_last_removed_cell = Vector2i(9999, 9999)

static func handle_hotbar_and_build_input(world: Node2D) -> bool:
	var viewport_mouse: Vector2 = world.get_viewport().get_mouse_position()
	if world.has_method("is_screen_point_on_ui") and world.is_screen_point_on_ui(viewport_mouse):
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			try_select_hotbar_at_screen_pos(world, viewport_mouse)
		return true

	if not world.build_mode_active:
		_lmb_was_down = false
		_rmb_was_down = false
		return false

	var target_cell: Vector2i = world._world_to_cell(world.get_global_mouse_position())
	var lmb: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var rmb: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var is_demolish_toggle: bool = ("mobile_hud" in world and world.mobile_hud != null and world.mobile_hud.demolish_mode)

	if lmb:
		has_touch_preview = true
		last_touch_world_pos = world.get_global_mouse_position()
		if is_demolish_toggle:
			if not _lmb_was_down or target_cell != _last_removed_cell:
				for c_step in _trace_line_cells(_last_removed_cell, target_cell):
					try_remove_block(world, c_step)
				_last_removed_cell = target_cell
		else:
			if not _lmb_was_down or target_cell != _last_built_cell:
				for c_step in _trace_line_cells(_last_built_cell, target_cell):
					try_place_block(world, c_step, world.selected_block_id)
				_last_built_cell = target_cell
	else:
		_last_built_cell = Vector2i(9999, 9999)

	if rmb:
		if not _rmb_was_down or target_cell != _last_removed_cell:
			for c_step in _trace_line_cells(_last_removed_cell, target_cell):
				try_remove_block(world, c_step)
			_last_removed_cell = target_cell
	else:
		if not is_demolish_toggle:
			_last_removed_cell = Vector2i(9999, 9999)

	_lmb_was_down = lmb
	_rmb_was_down = rmb
	return true

# ПУНКТ 2.2 и 2.3: Призрак постройки показывает точную будущую ориентацию (боковую или фронтальную) для двери, окна и автостен!
static func get_preview_texture(world: Node2D, b_id: int, cell: Vector2i) -> Texture2D:
	ensure_autowall_textures()
	if b_id <= 0:
		return null
	var is_side_here: bool = compute_block_is_side(world, cell, true)
	match b_id:
		1, 2, 4:
			return get_wall_draw_texture(world, cell, b_id)
		3:
			return world.tex_wall_pillar
		5:
			return world.tex_wood_floor
		6:
			return get_door_draw_texture(is_side_here, 0.0)
		8:
			return world.tex_pine_snow if world.current_weather == 3 else world.tex_pine_day
		9:
			return get_window_draw_texture(world, is_side_here, false)
		10:
			return world.tex_floor_stone
		_:
			var s_var: int = ArtLoader.pick_cell_variant(cell, world.tex_wall_stone_sec.size())
			return world.tex_wall_stone_sec[s_var]

static func draw_build_ghost(world: Node2D) -> void:
	if not world.build_mode_active or (world.inv_panel and world.inv_panel.visible):
		return
	if not is_instance_valid(world.player):
		return

	var default_ahead: Vector2 = world.player.global_position + world.player.look_direction.normalized() * 32.0
	var sample_world_pos: Vector2 = last_touch_world_pos if has_touch_preview else default_ahead
	if sample_world_pos.distance_to(world.player.global_position) > get_reach_cells(world) * float(world.CELL_SIZE) * 1.35:
		sample_world_pos = default_ahead

	var cell: Vector2i = world._world_to_cell(sample_world_pos)
	var pos := Vector2(cell * world.CELL_SIZE)
	var is_demolish: bool = ("mobile_hud" in world and world.mobile_hud != null and world.mobile_hud.demolish_mode)
	var font: Font = ThemeDB.fallback_font

	if is_demolish:
		var p_cell_d: Vector2i = world._world_to_cell(world.player.global_position)
		var in_reach_d: bool = Vector2(p_cell_d).distance_to(Vector2(cell)) <= get_reach_cells(world)
		var has_target_d: bool = world.wall_map.has(cell) or (int(world.ground_map.get(cell, 0)) in [2, 7])
		var can_dem: bool = in_reach_d and has_target_d and not world.watchtowers.has(cell)
		var dem_col := Color(1.0, 0.35, 0.25, 0.90) if can_dem else Color(0.6, 0.6, 0.6, 0.45)
		world.draw_rect(Rect2(pos, Vector2(world.CELL_SIZE, world.CELL_SIZE)), Color(1.0, 0.2, 0.2, 0.28), true)
		world.draw_rect(Rect2(pos, Vector2(world.CELL_SIZE, world.CELL_SIZE)), dem_col, false, 1.5)
		if not can_dem:
			var dem_msg: String = "Далеко" if not in_reach_d else ("Башня" if world.watchtowers.has(cell) else "Пусто")
			_draw_world_cursor_badge(world, pos + Vector2(8, -10), dem_msg, Color("#ff7b7b"), font)
		return

	if world.selected_block_id <= 0:
		return

	var status: Dictionary = get_place_block_status(world, cell, world.selected_block_id)
	var ok: bool = bool(status.get("ok", false))
	var reason: String = str(status.get("reason", ""))
	var ghost_mod := Color(0.35, 1.0, 0.45, 0.62) if ok else Color(1.0, 0.32, 0.32, 0.58)
	var border_col := Color(0.35, 1.0, 0.45, 0.95) if ok else Color(1.0, 0.32, 0.32, 0.95)

	var b_info: Dictionary = world.blocks_db.get(str(world.selected_block_id), {})
	var is_solid: bool = bool(b_info.get("solid", true))
	var tex: Texture2D = get_preview_texture(world, world.selected_block_id, cell)

	if tex != null:
		if not is_solid:
			world.draw_texture_rect(tex, Rect2(pos, Vector2(16, 16)), false, ghost_mod)
		elif world.selected_block_id == 8:
			world.draw_texture_rect(tex, Rect2(pos + Vector2(-8, -28), ArtLoader.get_frame_size("tree_pine")), false, ghost_mod)
		else:
			world.draw_texture_rect(tex, Rect2(pos + Vector2(0, -8), Vector2(16, 24)), false, ghost_mod)

	world.draw_rect(Rect2(pos, Vector2(world.CELL_SIZE, world.CELL_SIZE)), border_col, false, 1.2)

	# ПУНКТ 2.3: Подсказка ориентации или точная причина запрета прямо у клетки курсора!
	if not ok and reason != "":
		_draw_world_cursor_badge(world, pos + Vector2(8, -10), reason, Color("#ff8080"), font)
	elif ok and (world.selected_block_id == 6 or world.selected_block_id == 9):
		var is_side_orient: bool = compute_block_is_side(world, cell, true)
		var orient_lbl: String = "Бок (С-Ю)" if is_side_orient else "Фронт (З-В)"
		_draw_world_cursor_badge(world, pos + Vector2(8, -10), orient_lbl, Color("#b8f2be"), font)

static func _draw_world_cursor_badge(world: Node2D, top_center: Vector2, text: String, text_col: Color, font: Font) -> void:
	var w_box: float = maxf(46.0, float(text.length()) * 5.6 + 10.0)
	var rect := Rect2(top_center - Vector2(w_box * 0.5, 13.0), Vector2(w_box, 12.0))
	world.draw_rect(rect, Color(0.06, 0.06, 0.08, 0.88), true)
	world.draw_rect(rect, text_col.darkened(0.35), false, 1.0)
	world.draw_string(font, rect.position + Vector2(3, 9), text, HORIZONTAL_ALIGNMENT_CENTER, w_box - 6.0, 8, text_col)

static func draw_build_banner(hb: Control, world: Node2D, start_x: float, total_w: float, font: Font) -> void:
	var banner_rect := Rect2(Vector2(start_x - 8, -30), Vector2(total_w + 16, 26))
	if not world.build_mode_active:
		var slot_data: Dictionary = world.combat_hotbar_slots[world.selected_hotbar_slot] if ("combat_hotbar_slots" in world and world.selected_hotbar_slot < world.combat_hotbar_slots.size()) else {}
		var item_title: String = str(slot_data.get("name", "Пустой слот"))
		hb.draw_rect(banner_rect, Color(0.07, 0.07, 0.08, 0.88), true)
		hb.draw_rect(banner_rect, Color("#3b3733"), false, 1.0)
		var hint_c: String = "Выбрано: %s  ·  Открой Рюкзак (Tab), чтобы переставить или убрать слоты" % item_title
		hb.draw_string(font, banner_rect.position + Vector2(10, 17), hint_c, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#d8d2c8"))
		return

	var b_info: Dictionary = world.blocks_db.get(str(world.selected_block_id), {})
	var b_name: String = str(b_info.get("name", "Слот пуст (назначь в Рюкзаке)"))
	var cost_id: String = str(b_info.get("cost_item", "wood"))
	var cost_name: String = str(world.player.surv.items_db.get(cost_id, {}).get("name", cost_id))
	var have_cnt: int = int(world.player.surv.inventory.get(cost_id, 0))
	var is_dem: bool = ("mobile_hud" in world and world.mobile_hud != null and world.mobile_hud.demolish_mode)
	var mode_str: String = "РЕЖИМ СНОСА (веди по линии)" if is_dem else "Веди по линии — строить · ПКМ — снести"
	hb.draw_rect(banner_rect, Color(0.07, 0.07, 0.08, 0.94), true)
	hb.draw_rect(banner_rect, Color("#b83b3b") if is_dem else Color("#d99136"), false, 1.0)
	var txt: String = "[СТРОЙКА] %s (%s: %d) · %s" % [b_name, cost_name, have_cnt, mode_str]
	hb.draw_string(font, banner_rect.position + Vector2(10, 17), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#f2ead8"))
