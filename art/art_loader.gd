@warning_ignore("integer_division")
class_name ArtLoader
extends RefCounted

# Включаем приоритет богатых многовариантных наборов над старыми 1-кадровыми PNG-заглушками
static var PREFER_RICH_PROCEDURAL_VARIETY: bool = true

static var ASSET_SPECS: Dictionary = {
	"wall_stone": { "file": "wall_stone.png", "path": "res://art/wall_stone.png", "size": Vector2(16, 24), "frames": 4 },
	"wall_pillar": { "file": "wall_pillar.png", "path": "res://art/wall_pillar.png", "size": Vector2(16, 24), "frames": 1 },
	"wall_wood_top": { "file": "wall_wood_top.png", "path": "res://art/wall_wood_top.png", "size": Vector2(16, 24), "frames": 1 },
	"wall_side": { "file": "wall_side.png", "path": "res://art/wall_side.png", "size": Vector2(16, 24), "frames": 1 },
	"gate_closed": { "file": "gate_closed.png", "path": "res://art/gate_closed.png", "size": Vector2(16, 24), "frames": 1 },
	"tower": { "file": "tower.png", "path": "res://art/tower.png", "size": Vector2(24, 34), "frames": 1 },
	"tree_pine": { "file": "tree_pine.png", "path": "res://art/tree_pine.png", "size": Vector2(32, 44), "frames": 4 },
	"tree_oak": { "file": "tree_oak.png", "path": "res://art/tree_oak.png", "size": Vector2(32, 42), "frames": 4 },
	"bush": { "file": "bush.png", "path": "res://art/bush.png", "size": Vector2(16, 16), "frames": 4 },
	"rock": { "file": "rock.png", "path": "res://art/rock.png", "size": Vector2(16, 16), "frames": 4 },
	"campfire": { "file": "campfire.png", "path": "res://art/campfire.png", "size": Vector2(16, 16), "frames": 3 },
	"hero": { "file": "hero.png", "path": "res://art/hero.png", "size": Vector2(16, 24), "frames": 3 },
	"titan": { "file": "titan.png", "path": "res://art/titan.png", "size": Vector2(48, 64), "frames": 4 },

	"wall_torch": { "file": "wall_torch.png", "path": "res://art/wall_torch.png", "size": Vector2(16, 16), "frames": 2 },
	"tree_pine_snow": { "file": "tree_pine_snow.png", "path": "res://art/tree_pine_snow.png", "size": Vector2(32, 44), "frames": 4 },
	"flowers": { "file": "flowers.png", "path": "res://art/flowers.png", "size": Vector2(16, 16), "frames": 4 },
	"stump": { "file": "stump.png", "path": "res://art/stump.png", "size": Vector2(16, 16), "frames": 1 },
	"fallen_log": { "file": "fallen_log.png", "path": "res://art/fallen_log.png", "size": Vector2(16, 16), "frames": 1 },
	"grass_tuft": { "file": "grass_tuft.png", "path": "res://art/grass_tuft.png", "size": Vector2(16, 16), "frames": 4 },
	"workbench": { "file": "workbench.png", "path": "res://art/workbench.png", "size": Vector2(16, 16), "frames": 1 },
	"crate": { "file": "crate.png", "path": "res://art/crate.png", "size": Vector2(16, 16), "frames": 1 },
	"barrel": { "file": "barrel.png", "path": "res://art/barrel.png", "size": Vector2(16, 16), "frames": 1 },
	"well": { "file": "well.png", "path": "res://art/well.png", "size": Vector2(16, 16), "frames": 1 },
	"colonist": { "file": "colonist.png", "path": "res://art/colonist.png", "size": Vector2(16, 24), "frames": 2 },
	"hotbar_0": { "file": "hotbar_0.png", "path": "res://art/hotbar_0.png", "size": Vector2(32, 32), "frames": 1 },
	"hotbar_1": { "file": "hotbar_1.png", "path": "res://art/hotbar_1.png", "size": Vector2(32, 32), "frames": 1 },
	"hotbar_2": { "file": "hotbar_2.png", "path": "res://art/hotbar_2.png", "size": Vector2(32, 32), "frames": 1 },
	"hotbar_3": { "file": "hotbar_3.png", "path": "res://art/hotbar_3.png", "size": Vector2(32, 32), "frames": 1 },
	"hotbar_4": { "file": "hotbar_4.png", "path": "res://art/hotbar_4.png", "size": Vector2(32, 32), "frames": 1 },
	"hotbar_5": { "file": "hotbar_5.png", "path": "res://art/hotbar_5.png", "size": Vector2(32, 32), "frames": 1 },
	"hotbar_6": { "file": "hotbar_6.png", "path": "res://art/hotbar_6.png", "size": Vector2(32, 32), "frames": 1 },
	"hotbar_7": { "file": "hotbar_7.png", "path": "res://art/hotbar_7.png", "size": Vector2(32, 32), "frames": 1 },
	"hotbar_8": { "file": "hotbar_8.png", "path": "res://art/hotbar_8.png", "size": Vector2(32, 32), "frames": 1 },
	"hotbar_9": { "file": "hotbar_9.png", "path": "res://art/hotbar_9.png", "size": Vector2(32, 32), "frames": 1 },

	"ground_grass": { "file": "ground_grass.png", "path": "res://art/ground_grass.png", "size": Vector2(16, 16), "frames": 8 },
	"ground_dirt": { "file": "ground_dirt.png", "path": "res://art/ground_dirt.png", "size": Vector2(16, 16), "frames": 6 },
	"ground_dirt_edge": { "file": "ground_dirt_edge.png", "path": "res://art/ground_dirt_edge.png", "size": Vector2(16, 16), "frames": 16 },
	"ground_path": { "file": "ground_path.png", "path": "res://art/ground_path.png", "size": Vector2(16, 16), "frames": 6 },
	"ground_wood_floor": { "file": "ground_wood_floor.png", "path": "res://art/ground_wood_floor.png", "size": Vector2(16, 16), "frames": 4 },
	"ground_garden": { "file": "ground_garden.png", "path": "res://art/ground_garden.png", "size": Vector2(16, 16), "frames": 4 },
	"ash_pile": { "file": "ash_pile.png", "path": "res://art/ash_pile.png", "size": Vector2(16, 16), "frames": 1 },
	"titan_crawler": { "file": "titan_crawler.png", "path": "res://art/titan_crawler.png", "size": Vector2(48, 32), "frames": 2 },
	"ui_heart": { "file": "ui_heart.png", "path": "res://art/ui_heart.png", "size": Vector2(16, 16), "frames": 1 },
	"ui_food": { "file": "ui_food.png", "path": "res://art/ui_food.png", "size": Vector2(16, 16), "frames": 1 },
	"ui_water": { "file": "ui_water.png", "path": "res://art/ui_water.png", "size": Vector2(16, 16), "frames": 1 },
	"ui_key_e": { "file": "ui_key_e.png", "path": "res://art/ui_key_e.png", "size": Vector2(16, 16), "frames": 1 },
	"ui_panel": { "file": "ui_panel.png", "path": "res://art/ui_panel.png", "size": Vector2(24, 24), "frames": 1 },

	"autowall_wood": { "file": "autowall_wood.png", "path": "res://art/autowall_wood.png", "size": Vector2(16, 24), "frames": 16 },
	"autowall_brick": { "file": "autowall_brick.png", "path": "res://art/autowall_brick.png", "size": Vector2(16, 24), "frames": 16 },
	"autowall_stone": { "file": "autowall_stone.png", "path": "res://art/autowall_stone.png", "size": Vector2(16, 24), "frames": 16 },

	"block_window": { "file": "block_window.png", "path": "res://art/block_window.png", "size": Vector2(16, 24), "frames": 2 },
	"block_door": { "file": "block_door.png", "path": "res://art/block_door.png", "size": Vector2(16, 24), "frames": 2 },
	"floor_stone": { "file": "floor_stone.png", "path": "res://art/floor_stone.png", "size": Vector2(16, 16), "frames": 4 },
	"roof_wood": { "file": "roof_wood.png", "path": "res://art/roof_wood.png", "size": Vector2(16, 16), "frames": 8 }
}

# Ключи тайлов мира и деревьев, где процедурные вариации заменяют однотипные плоские 1-кадровые PNG
static var _FORCE_VARIETY_KEYS: Array[String] = [
	"ground_grass", "ground_dirt", "ground_dirt_edge", "ground_path",
	"ground_wood_floor", "ground_garden", "floor_stone", "roof_wood",
	"wall_stone", "autowall_wood", "autowall_brick", "autowall_stone",
	"tree_pine", "tree_oak", "tree_pine_snow",
	"bush", "rock", "flowers", "grass_tuft",
	"block_window", "block_door"
]

static var _cache: Dictionary = {}
static var _reported_missing: bool = false

static func has_file(key: String) -> bool:
	if PREFER_RICH_PROCEDURAL_VARIETY and (key in _FORCE_VARIETY_KEYS):
		return false
	if not ASSET_SPECS.has(key):
		return false
	var path: String = str(ASSET_SPECS[key]["path"])
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)

static func get_frame_size(key: String) -> Vector2:
	if ASSET_SPECS.has(key):
		return ASSET_SPECS[key]["size"]
	return Vector2(16, 16)

static func check_and_report_missing() -> void:
	if _reported_missing:
		return
	_reported_missing = true

static func _slice_image_safely(img: Image, target_frame_w: int, spec_frames: int) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	if img == null or img.is_empty():
		return out
	var w: int = img.get_width()
	var h: int = img.get_height()
	if w <= 0 or h <= 0:
		return out

	var actual_frames: int = spec_frames
	if target_frame_w > 0 and w >= target_frame_w and (w % target_frame_w == 0):
		var by_size: int = w / target_frame_w
		if by_size >= 1 and by_size <= 32:
			actual_frames = by_size
	actual_frames = clampi(actual_frames, 1, w)
	var fw: int = maxi(1, w / actual_frames)

	for i in range(actual_frames):
		var rx: int = i * fw
		if rx + fw <= w:
			var sub_img: Image = img.get_region(Rect2i(rx, 0, fw, h))
			if sub_img != null and not sub_img.is_empty():
				var tex := ImageTexture.create_from_image(sub_img)
				if tex != null:
					out.append(tex)
	return out

static func get_frames(key: String, fallback_frames: Array = []) -> Array[Texture2D]:
	if _cache.has(key):
		return _cache[key]

	if PREFER_RICH_PROCEDURAL_VARIETY and (key in _FORCE_VARIETY_KEYS) and not fallback_frames.is_empty():
		var rich_list: Array[Texture2D] = []
		for fb in fallback_frames:
			if fb is Texture2D and fb != null:
				rich_list.append(fb)
		_cache[key] = rich_list
		return rich_list

	var result: Array[Texture2D] = []
	if has_file(key):
		var spec: Dictionary = ASSET_SPECS[key]
		var path: String = str(spec["path"])
		var spec_frames: int = maxi(1, int(spec["frames"]))
		var target_w: int = int(Vector2(spec["size"]).x)
		var loaded_tex: Texture2D = null

		if ResourceLoader.exists(path):
			loaded_tex = load(path) as Texture2D

		if loaded_tex != null:
			var img: Image = loaded_tex.get_image()
			result = _slice_image_safely(img, target_w, spec_frames)
			if result.is_empty():
				result.append(loaded_tex)
		elif FileAccess.file_exists(path):
			var raw_img := Image.load_from_file(ProjectSettings.globalize_path(path))
			result = _slice_image_safely(raw_img, target_w, spec_frames)

	if result.size() < fallback_frames.size():
		for i in range(result.size(), fallback_frames.size()):
			var fb = fallback_frames[i]
			if fb is Texture2D and fb != null:
				result.append(fb)

	if result.is_empty():
		for fb in fallback_frames:
			if fb is Texture2D and fb != null:
				result.append(fb)

	_cache[key] = result
	return result

static func get_single(key: String, fallback_tex: Texture2D = null) -> Texture2D:
	var fb_arr: Array = [fallback_tex] if fallback_tex != null else []
	var frames: Array[Texture2D] = get_frames(key, fb_arr)
	return frames[0] if not frames.is_empty() else fallback_tex

static func cell_hash(cell: Vector2i, salt: int = 0) -> int:
	var h: int = (cell.x * 374761393) + (cell.y * 668265263) + (salt * 2147483647)
	h = (h ^ (h >> 13)) * 1274126177
	return abs(h ^ (h >> 16))

static func pick_cell_variant(cell: Vector2i, count: int) -> int:
	if count <= 1:
		return 0
	return cell_hash(cell, 91) % count
