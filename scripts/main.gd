@warning_ignore("integer_division")
extends Node2D

const CELL_SIZE: int = 16
const MAP_RADIUS: int = 65

var config: Dictionary = {}
var blocks_db: Dictionary = {}

var game_hour: float = 16.33
var game_day: int = 3
var time_scale_mult: float = 1.0
var real_sec_per_hour: float = 60.0

var current_weather: int = 0
var core_stones_placed: int = 2
var titans_killed_count: int = 0

var master_volume: float = 0.80
var screen_shake_enabled: bool = true
var silhouette_radius_cells: float = 8.0

var sky_modulate: CanvasModulate
var atmosphere_layer: CanvasLayer
var world_canvas: Node2D
var colonists_layer: Node2D
var titans_layer: Node2D
var fx_layer: Node2D
var player: PlayerController
var camera: Camera2D

var light_tex: ImageTexture
var player_light: PointLight2D
var campfire_lights: Array[PointLight2D] = []
var sconce_lights: Array[PointLight2D] = []

var tex_grass_variants: Array[Texture2D] = []
var tex_dirt_variants: Array[Texture2D] = []
var tex_dirt_blend_variants: Array[Texture2D] = []
var tex_dirt_edge_grass: Texture2D
var tex_path_variants: Array[Texture2D] = []
var tex_path_tile: Texture2D
var tex_wood_floor_variants: Array[Texture2D] = []
var tex_wood_floor: Texture2D
var tex_floor_stone_variants: Array[Texture2D] = []
var tex_floor_stone: Texture2D
var tex_garden_crops: Array[Texture2D] = []
var tex_garden_tile: Texture2D

var tex_wall_pillar: Texture2D
var tex_wall_stone_sec: Array[Texture2D] = []
var tex_wall_wood_sec: Texture2D
var tex_wall_side: Texture2D
var tex_gate_closed: Texture2D
var tex_gate_open: Texture2D
var tex_tower_sprite: Texture2D

var tex_block_door_frames: Array[Texture2D] = []
var tex_block_window_frames: Array[Texture2D] = []

var tex_pine_variants: Array[Texture2D] = []
var tex_pine_snow_variants: Array[Texture2D] = []
var tex_oak_variants: Array[Texture2D] = []
var tex_oak_snow_variants: Array[Texture2D] = []
var tex_pine_day: Texture2D
var tex_pine_snow: Texture2D
var tex_oak_tree: Texture2D

var tex_bush: Texture2D
var tex_bush_variants: Array[Texture2D] = []
var tex_flowers: Texture2D
var tex_flowers_variants: Array[Texture2D] = []
var tex_rock: Texture2D
var tex_rock_variants: Array[Texture2D] = []
var tex_grass_tuft_variants: Array[Texture2D] = []
var has_grass_tuft_png: bool = false

var tex_stump: Texture2D
var tex_fallen_log: Texture2D
var tex_well: Texture2D
var tex_bed: Texture2D
var tex_tent: ImageTexture
var tex_woodpile: ImageTexture
var tex_sawhorse: ImageTexture
var tex_cart: ImageTexture
var tex_campfire_frames: Array[Texture2D] = []
var tex_wall_torch_frames: Array[Texture2D] = []
var has_wall_torch_png: bool = false
var tex_ash_pile: Texture2D
var has_ash_pile_png: bool = false

var tex_crate: Texture2D
var tex_workbench: Texture2D
var tex_barrel: Texture2D
var tex_hotbar_icons: Array[Texture2D] = []

var tex_ui_heart: Texture2D
var tex_ui_food: Texture2D
var tex_ui_water: Texture2D
var tex_ui_key_e: Texture2D
var tex_ui_panel: Texture2D

var tex_hero_silhouette: ImageTexture
var tex_colonist_silhouette: ImageTexture

var sfx_player: AudioStreamPlayer
var sfx_playback: AudioStreamGeneratorPlayback

var ground_map: Dictionary = {}
var wall_map: Dictionary = {}
var decor_map: Dictionary = {}
var door_anim_progress: Dictionary = {}

var _ground_tint_cache: Dictionary = {}
var _grass_variant_cache: Dictionary = {}
var _watchtower_set: Dictionary = {}
var ash_piles: Array[Vector2] = []

var wall_torches: Array[Vector2i] = [
	Vector2i(-11, -13), Vector2i(-3, -13), Vector2i(3, -13), Vector2i(11, -13),
	Vector2i(-11, 7), Vector2i(-3, 7), Vector2i(3, 7), Vector2i(11, 7),
	Vector2i(-15, -5), Vector2i(-15, 2), Vector2i(14, -5), Vector2i(14, 2),
	Vector2i(-10, -5), Vector2i(-8, -5), Vector2i(3, -3), Vector2i(11, -3)
]

var water_well_cell := Vector2i(-5, 3)
var bed_cell := Vector2i(-12, -9)
var campfires: Array[Vector2i] = [Vector2i(5, 2), Vector2i(4, -9)]
var workbenches: Array[Vector2i] = [Vector2i(-7, -9), Vector2i(2, 1)]
var watchtowers: Array[Vector2i] = [
	Vector2i(-15, -13), Vector2i(14, -13), Vector2i(-15, 7), Vector2i(14, 7),
	Vector2i(-2, -13), Vector2i(2, -13)
]
var loot_crates: Dictionary = {}
var hit_sparks: Array[Dictionary] = []

var combat_hotbar_slots: Array[Dictionary] = []
var build_hotbar_slots: Array[int] = [1, 2, 3, 4, 5, 6, 9, 10, 0, 0]

var selected_block_id: int = 1
var selected_hotbar_slot: int = 0
var build_mode_active: bool = false
var screen_shake_amount: float = 0.0
# ПУНКТ 3.2 и 3.4: Микро-заморозка кадра (hit-stop) и всплывающая боевая подсказка
var hit_stop_timer: float = 0.0
var combat_hint_text: String = ""
var combat_hint_timer: float = 0.0

var hud_bars_ctrl: Control
var clock_card_ctrl: PanelContainer
var quest_card_ctrl: PanelContainer
var quick_bar_ctrl: HBoxContainer
var lbl_day_clock: Label
var lbl_quest_list: Label
var minimap_ctrl: Control
var hotbar_ctrl: Control
var alert_panel: PanelContainer
var lbl_alert_title: Label
var lbl_alert_sub: Label
var prompt_e_panel: PanelContainer
var lbl_prompt_e: Label
var mobile_hud: MobileHUD

var inv_panel: PanelContainer
var current_bag_tab: int = 0
var inv_list_box: VBoxContainer
var lbl_detail_title: Label
var lbl_detail_desc: Label
var lbl_detail_ing: Label
var detail_actions_box: VBoxContainer
var selected_bag_entry_index: int = 0
var selected_recipe_index: int = 0

var settings_panel: PanelContainer
var death_panel: PanelContainer
var lbl_death_stats: Label

func _ready() -> void:
	get_viewport().snap_2d_transforms_to_pixel = true
	get_viewport().snap_2d_vertices_to_pixel = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	Phase1Visuals.ensure_initialized()
	ArtLoader.check_and_report_missing()
	_load_config()
	_init_default_hotbars()
	_generate_all_pixel_art_tiles()
	_setup_procedural_audio()
	_setup_lighting()
	_setup_world_layer()
	_generate_fortress_from_reference()
	_setup_player()
	_build_entity_silhouette_textures()
	_spawn_campfire_point_lights()
	_spawn_initial_colonists()
	_spawn_initial_titans()
	atmosphere_layer = Phase1Visuals.create_atmosphere_vignette_layer()
	add_child(atmosphere_layer)
	_setup_reference_hud()
	show_combat_hint("Наведи прицел на титана или стену: кнопки L / R (Q / E) — крюки, Меч (F) — серия ударов!")

func show_combat_hint(msg: String, duration: float = 5.5) -> void:
	combat_hint_text = msg
	combat_hint_timer = duration

func trigger_hit_stop(duration: float = 0.055) -> void:
	hit_stop_timer = maxf(hit_stop_timer, duration)
	Engine.time_scale = 0.06

func _load_config() -> void:
	var file_path := "res://data/config.json"
	if FileAccess.file_exists(file_path):
		var text := FileAccess.get_file_as_string(file_path)
		var parsed = JSON.parse_string(text)
		if typeof(parsed) == TYPE_DICTIONARY:
			config = parsed
	blocks_db = config.get("blocks", {})

	if not config.has("player"):
		config["player"] = {}
	if not config["player"].has("slash_reach_cells"):
		config["player"]["slash_reach_cells"] = 1.65

	if not blocks_db.has("9"):
		blocks_db["9"] = {
			"id": 9, "name": "Окно", "hp": 40, "span": 4, "anchor": false,
			"solid": true, "is_window": true, "lets_light": true, "hookable": true,
			"drop": "wood", "cost_item": "wood"
		}
	if not blocks_db.has("10"):
		blocks_db["10"] = {
			"id": 10, "name": "Каменный пол", "hp": 45, "span": 8, "anchor": false,
			"solid": false, "floor_type": 7, "hookable": false,
			"drop": "stone", "cost_item": "stone"
		}

func _init_default_hotbars() -> void:
	combat_hotbar_slots = [
		{"kind": "tool", "id": "torch", "name": "Факел (свет вокруг героя)", "icon_idx": 0},
		{"kind": "tool", "id": "axe", "name": "Топор лесоруба", "icon_idx": 1},
		{"kind": "tool", "id": "pickaxe", "name": "Кирка каменотёса", "icon_idx": 2},
		{"kind": "tool", "id": "blades", "name": "Парные клинки (Перезарядка: R)", "icon_idx": 3},
		{"kind": "tool", "id": "crossbow", "name": "Охотничий арбалет", "icon_idx": 4},
		{"kind": "item", "id": "core_stone", "name": "Остов-камень", "icon_idx": 5},
		{"kind": "item", "id": "wood", "name": "Деревянные доски", "icon_idx": 6},
		{"kind": "item", "id": "stone", "name": "Булыжник", "icon_idx": 7},
		{"kind": "item", "id": "herbs", "name": "Целебные травы", "icon_idx": 8},
		{"kind": "item", "id": "canned_food", "name": "Консервы (Тап — съесть)", "icon_idx": 9}
	]
	build_hotbar_slots = [1, 2, 3, 4, 5, 6, 9, 10, 0, 0]
	selected_hotbar_slot = 0
	selected_block_id = build_hotbar_slots[0]

func select_hotbar_slot_index(slot_idx: int, allow_consume_on_reselect: bool = false) -> void:
	slot_idx = clampi(slot_idx, 0, 9)
	var was_already_selected: bool = (selected_hotbar_slot == slot_idx)
	selected_hotbar_slot = slot_idx

	if slot_idx < build_hotbar_slots.size():
		selected_block_id = int(build_hotbar_slots[slot_idx])

	if not build_mode_active and slot_idx < combat_hotbar_slots.size():
		var s_data: Dictionary = combat_hotbar_slots[slot_idx]
		var s_kind: String = str(s_data.get("kind", "empty"))
		var s_id: String = str(s_data.get("id", ""))
		if s_kind == "tool" and s_id == "torch" and was_already_selected and allow_consume_on_reselect:
			player.torch_lit = not player.torch_lit
			if is_instance_valid(player_light):
				player_light.visible = player.torch_lit
		elif s_kind == "item" and was_already_selected and allow_consume_on_reselect and s_id != "":
			var i_type: String = str(player.surv.items_db.get(s_id, {}).get("type", "mat"))
			if i_type in ["food", "drink", "med", "placeable"]:
				player.use_inventory_item(s_id)
	play_sfx("ui")
	queue_redraw()

func _cycle_day_night_weather() -> void:
	if current_weather == 3:
		current_weather = 0
		game_hour = 16.33
	elif game_hour < 18.0:
		game_hour = 22.2
	else:
		current_weather = 3
		game_hour = 8.5
	play_sfx("ui")
	queue_redraw()

func _build_entity_silhouette_textures() -> void:
	if is_instance_valid(player) and player.tex_idle != null:
		tex_hero_silhouette = TitanEntity._build_alpha_outline_texture(player.tex_idle)
	var col_sample := ColonistEntity.new()
	col_sample._rebuild_sprites()
	if col_sample.tex_idle != null:
		tex_colonist_silhouette = TitanEntity._build_alpha_outline_texture(col_sample.tex_idle)
	col_sample.free()

func _generate_all_pixel_art_tiles() -> void:
	light_tex = Phase1Visuals.build_natural_torch_light_texture()

	var ground_pack: Dictionary = Phase1Visuals.generate_ground_textures()
	tex_grass_variants = ArtLoader.get_frames("ground_grass", ground_pack["grass"])
	tex_dirt_variants = ArtLoader.get_frames("ground_dirt", ground_pack["dirt"])
	tex_dirt_blend_variants = ArtLoader.get_frames("ground_dirt_edge", ground_pack["blend"])
	tex_dirt_edge_grass = tex_dirt_blend_variants[0]

	var fb_paths: Array = []
	for v in range(6):
		fb_paths.append(_create_path_variant_tile(v))
	tex_path_variants = ArtLoader.get_frames("ground_path", fb_paths)
	tex_path_tile = tex_path_variants[0]

	var fb_wood_floors: Array = []
	var fb_stone_floors: Array = []
	for v in range(4):
		fb_wood_floors.append(_create_wood_floor_variant_tile(v))
		fb_stone_floors.append(_create_stone_floor_variant_tile(v))
	tex_wood_floor_variants = ArtLoader.get_frames("ground_wood_floor", fb_wood_floors)
	tex_wood_floor = tex_wood_floor_variants[0]
	tex_floor_stone_variants = ArtLoader.get_frames("floor_stone", fb_stone_floors)
	tex_floor_stone = tex_floor_stone_variants[0]

	var fb_gardens: Array = []
	for v in range(4):
		fb_gardens.append(_create_garden_crop_tile(v))
	tex_garden_crops = ArtLoader.get_frames("ground_garden", fb_gardens)
	tex_garden_tile = tex_garden_crops[0]

	tex_wall_pillar = ArtLoader.get_single("wall_pillar", _create_wall_pillar_tile())
	var fb_walls: Array = []
	for v in range(4):
		fb_walls.append(_create_wall_stone_section_tile(v))
	tex_wall_stone_sec = ArtLoader.get_frames("wall_stone", fb_walls)
	tex_wall_wood_sec = ArtLoader.get_single("wall_wood_top", _create_wall_wood_topped_tile())
	tex_wall_side = ArtLoader.get_single("wall_side", _create_wall_side_tile())

	var fb_door_closed := _create_door_frame_tile(false)
	var fb_door_open := _create_door_frame_tile(true)
	tex_gate_closed = ArtLoader.get_single("gate_closed", fb_door_closed)
	tex_gate_open = fb_door_open
	tex_block_door_frames = ArtLoader.get_frames("block_door", [tex_gate_closed, fb_door_open])

	var fb_win_day := _create_window_frame_tile(false)
	var fb_win_lit := _create_window_frame_tile(true)
	tex_block_window_frames = ArtLoader.get_frames("block_window", [fb_win_day, fb_win_lit])

	tex_tower_sprite = ArtLoader.get_single("tower", _create_corner_tower_sprite())

	var fb_bushes: Array = []
	var fb_flowers_arr: Array = []
	var fb_rocks: Array = []
	for v in range(4):
		fb_bushes.append(_create_bush_variant_tile(v))
		fb_flowers_arr.append(_create_flowers_variant_tile(v))
		fb_rocks.append(_create_rock_variant_tile(v))
	tex_bush_variants = ArtLoader.get_frames("bush", fb_bushes)
	tex_bush = tex_bush_variants[0]
	tex_flowers_variants = ArtLoader.get_frames("flowers", fb_flowers_arr)
	tex_flowers = tex_flowers_variants[0]
	tex_rock_variants = ArtLoader.get_frames("rock", fb_rocks)
	tex_rock = tex_rock_variants[0]

	var fb_tufts: Array = []
	for v in range(4):
		fb_tufts.append(_create_grass_tuft_variant_tile(v))
	tex_grass_tuft_variants = ArtLoader.get_frames("grass_tuft", fb_tufts)
	has_grass_tuft_png = true

	tex_stump = ArtLoader.get_single("stump", _create_stump_tile())
	tex_fallen_log = ArtLoader.get_single("fallen_log", _create_fallen_log_tile())
	tex_well = ArtLoader.get_single("well", _create_well_tile())
	tex_bed = _create_bed_tile()
	tex_tent = _create_survivor_tent_sprite()
	tex_woodpile = _create_woodpile_tile()
	tex_sawhorse = _create_sawhorse_tile()
	tex_cart = _create_wooden_cart_sprite()
	tex_crate = ArtLoader.get_single("crate", _create_crate_tile())
	tex_workbench = ArtLoader.get_single("workbench", _create_workbench_tile())
	tex_barrel = ArtLoader.get_single("barrel", _create_barrel_tile())

	var fb_cf: Array = []
	for f in range(3):
		fb_cf.append(_create_campfire_tile(f))
	tex_campfire_frames = ArtLoader.get_frames("campfire", fb_cf)

	has_wall_torch_png = ArtLoader.has_file("wall_torch")
	if has_wall_torch_png:
		tex_wall_torch_frames = ArtLoader.get_frames("wall_torch", [])

	has_ash_pile_png = ArtLoader.has_file("ash_pile")
	if has_ash_pile_png:
		tex_ash_pile = ArtLoader.get_single("ash_pile", null)

	var fb_pines: Array = []
	var fb_pines_snow: Array = []
	var fb_oaks: Array = []
	tex_oak_snow_variants.clear()
	for v in range(4):
		fb_pines.append(_create_procedural_pine_texture(false, v))
		fb_pines_snow.append(_create_procedural_pine_texture(true, v))
		fb_oaks.append(_create_procedural_oak_texture(v, false))
		tex_oak_snow_variants.append(_create_procedural_oak_texture(v, true))
	tex_pine_variants = ArtLoader.get_frames("tree_pine", fb_pines)
	tex_pine_snow_variants = ArtLoader.get_frames("tree_pine_snow", fb_pines_snow)
	tex_oak_variants = ArtLoader.get_frames("tree_oak", fb_oaks)
	tex_pine_day = tex_pine_variants[0]
	tex_pine_snow = tex_pine_snow_variants[0]
	tex_oak_tree = tex_oak_variants[0]

	BuildSystem.ensure_autowall_textures()
	BuildSystem.ensure_roof_textures()

	_generate_hotbar_icons()
	tex_ui_heart = ArtLoader.get_single("ui_heart", null)
	tex_ui_food = ArtLoader.get_single("ui_food", null)
	tex_ui_water = ArtLoader.get_single("ui_water", null)
	tex_ui_key_e = ArtLoader.get_single("ui_key_e", null)
	tex_ui_panel = ArtLoader.get_single("ui_panel", null)

func _create_survivor_tent_sprite() -> ImageTexture:
	var img := Image.create(32, 24, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	var c_cloth_hi := Color("#8c7a62")
	var c_cloth := Color("#6e5e49")
	var c_cloth_sh := Color("#4a3e30")
	var c_wood := Color("#5b3a22")
	for y in range(3, 22):
		var span: int = int(float(y - 2) * 0.72)
		for x in range(16 - span, 16 + span + 1):
			if x == 16 - span or x == 16 + span or y == 21:
				img.set_pixel(x, y, c_out)
			elif abs(x - 16) <= 3 and y >= 11:
				img.set_pixel(x, y, Color("#1a1410"))
			elif x < 16:
				img.set_pixel(x, y, c_cloth_hi if (x + y) % 4 != 0 else c_cloth)
			else:
				img.set_pixel(x, y, c_cloth if (x - y) % 4 != 0 else c_cloth_sh)
	img.set_pixel(16, 2, c_wood)
	img.set_pixel(16, 3, c_wood)
	return ImageTexture.create_from_image(img)

func _create_woodpile_tile() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	var logs := [Vector2i(4, 12), Vector2i(8, 12), Vector2i(12, 12), Vector2i(6, 9), Vector2i(10, 9), Vector2i(8, 6)]
	for l in logs:
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				if abs(dx) + abs(dy) <= 3:
					var edge: bool = (abs(dx) + abs(dy) == 3)
					var cut: bool = (abs(dx) <= 1 and abs(dy) <= 1)
					img.set_pixel(l.x + dx, l.y + dy, c_out if edge else (Color("#b88454") if cut else Color("#5b3a22")))
	return ImageTexture.create_from_image(img)

func _create_sawhorse_tile() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	for x in range(2, 14):
		for y in range(6, 10):
			img.set_pixel(x, y, c_out if (y == 6 or y == 9 or x == 2 or x == 13) else Color("#7a5230"))
	for i in range(4):
		img.set_pixel(4 - i / 2, 10 + i, Color("#5b3a22"))
		img.set_pixel(5 + i / 2, 10 + i, Color("#3b2516"))
		img.set_pixel(11 - i / 2, 10 + i, Color("#5b3a22"))
		img.set_pixel(12 + i / 2, 10 + i, Color("#3b2516"))
	return ImageTexture.create_from_image(img)

func _create_wooden_cart_sprite() -> ImageTexture:
	var img := Image.create(24, 18, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	for x in range(3, 19):
		for y in range(4, 13):
			var edge: bool = (x == 3 or x == 18 or y == 4 or y == 12 or y == 8)
			img.set_pixel(x, y, c_out if edge else (Color("#8a5d36") if y < 8 else Color("#5b3a22")))
	for x in range(19, 23):
		img.set_pixel(x, 10, Color("#5b3a22"))
	for dx in range(-4, 5):
		for dy in range(-4, 5):
			var d: float = Vector2(dx, dy).length()
			if d >= 3.2 and d <= 4.4:
				img.set_pixel(10 + dx, 13 + dy, c_out if d > 3.9 else Color("#7a5230"))
			elif (dx == 0 or dy == 0) and d < 3.5:
				img.set_pixel(10 + dx, 13 + dy, Color("#5b3a22"))
	return ImageTexture.create_from_image(img)

func _create_grass_tuft_variant_tile(v: int) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var blades := [-4, -2, 0, 2, 4]
	for i in range(blades.size()):
		var bx: int = 8 + blades[i] + ((v + i) % 2) - 1
		var bh: int = 4 + ((i * 3 + v * 2) % 5)
		for s in range(bh):
			var bend: int = (1 if blades[i] >= 0 else -1) if s > 3 else 0
			var col := Color("#5c8046") if s >= bh - 1 else (Color("#3d5431") if s >= 2 else Color("#1e2b19"))
			img.set_pixel(clampi(bx + bend, 1, 14), 13 - s, col)
	return ImageTexture.create_from_image(img)

func _create_path_variant_tile(v: int) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var dirt_cols := [Color("#593f2b"), Color("#664932"), Color("#735339")]
	for x in range(16):
		for y in range(16):
			var d_idx: int = ((x * 5 + y * 7 + v * 3) % 3)
			img.set_pixel(x, y, dirt_cols[d_idx])

	var layouts := [
		[Rect2i(1, 1, 6, 5), Rect2i(8, 2, 6, 6), Rect2i(2, 7, 5, 7), Rect2i(8, 9, 7, 5)],
		[Rect2i(2, 0, 7, 6), Rect2i(10, 1, 5, 5), Rect2i(1, 7, 6, 6), Rect2i(8, 7, 6, 7)],
		[Rect2i(0, 2, 5, 6), Rect2i(6, 1, 8, 5), Rect2i(2, 9, 7, 6), Rect2i(10, 8, 5, 6)],
		[Rect2i(1, 1, 7, 7), Rect2i(9, 2, 6, 5), Rect2i(1, 9, 5, 5), Rect2i(7, 8, 8, 6)],
		[Rect2i(2, 1, 5, 5), Rect2i(8, 0, 6, 6), Rect2i(0, 7, 8, 6), Rect2i(9, 7, 6, 7)],
		[Rect2i(1, 2, 6, 5), Rect2i(8, 1, 7, 6), Rect2i(2, 8, 6, 6), Rect2i(9, 9, 5, 5)]
	]
	var stones: Array = layouts[v % layouts.size()]
	for i in range(stones.size()):
		var r: Rect2i = stones[i]
		var tone_shift: float = -0.05 if ((i + v) % 2 == 0) else 0.04
		var c_base := Color("#5c626b").lightened(tone_shift)
		var c_hi := Color("#878f99").lightened(tone_shift)
		var c_sh := Color("#2b2f36")
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				var is_corner: bool = (
					(x == r.position.x or x == r.end.x - 1) and
					(y == r.position.y or y == r.end.y - 1)
				)
				if is_corner:
					continue
				var is_bot_edge: bool = (y == r.end.y - 1 or x == r.end.x - 1)
				var is_top_edge: bool = (y == r.position.y or x == r.position.x)
				if is_bot_edge:
					img.set_pixel(x, y, c_sh)
				elif is_top_edge:
					img.set_pixel(x, y, c_hi)
				else:
					img.set_pixel(x, y, c_base)

	if v % 2 == 0:
		img.set_pixel(7, 6, Color("#354d2b"))
		img.set_pixel(7, 7, Color("#263620"))
	return ImageTexture.create_from_image(img)

func _create_wood_floor_variant_tile(v: int) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var tones := [Color("#6e472b"), Color("#5b3a22"), Color("#7a5230"), Color("#4f321d")]
	for x in range(16):
		for y in range(16):
			var row: int = y / 4
			var joint_x: int = ((row * 5 + v * 3) % 12) + 2
			var seam: bool = (y % 4 == 3 or x == joint_x)
			if seam:
				img.set_pixel(x, y, Color("#2b190e"))
			else:
				var col: Color = tones[(row + v) % tones.size()]
				if y % 4 == 0:
					col = col.lightened(0.06)
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _create_stone_floor_variant_tile(v: int) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c_mortar := Color("#2b2f36")
	var slates := [Color("#4a4f59"), Color("#565c68"), Color("#40454f"), Color("#636975")]
	var split_x: int = 6 + (v * 3) % 6
	for x in range(16):
		for y in range(16):
			var seam_h: bool = (y == 0 or y == 8)
			var seam_v: bool = ((y < 8 and (x == 0 or x == split_x)) or (y >= 8 and (x == 3 or x == 11)))
			if seam_h or seam_v:
				img.set_pixel(x, y, c_mortar)
			elif y == 1 or y == 9:
				img.set_pixel(x, y, Color("#7c838f"))
			else:
				var idx: int = ((x / 5) + (y / 8) * 2 + v) % slates.size()
				img.set_pixel(x, y, slates[idx])
	return ImageTexture.create_from_image(img)

func _create_garden_crop_tile(crop_type: int) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(16):
		for y in range(16):
			var furrow: bool = (y % 4 == 0 or y % 4 == 3)
			var soil := Color("#21150d") if (y % 4 == 0) else (Color("#2b1c12") if furrow else Color("#382518"))
			if (x + y * 3 + crop_type) % 11 == 0:
				soil = soil.lightened(0.08)
			img.set_pixel(x, y, soil)

	for cx in [4, 11]:
		for cy in [5, 11]:
			match crop_type % 4:
				0:
					for dx in range(-2, 3):
						for dy in range(-2, 3):
							if abs(dx) + abs(dy) <= 3:
								var c_leaf := Color("#6f8f4c") if (dx + dy <= 0) else Color("#3d5a2e")
								if dx == 0 and dy == 0:
									c_leaf = Color("#8fb366")
								img.set_pixel(cx + dx, cy + dy, c_leaf)
				1:
					img.set_pixel(cx, cy + 1, Color("#e07a2b"))
					img.set_pixel(cx, cy, Color("#f2913d"))
					img.set_pixel(cx - 1, cy - 1, Color("#4d6d37"))
					img.set_pixel(cx, cy - 1, Color("#6f8f4c"))
					img.set_pixel(cx + 1, cy - 1, Color("#3d5a2e"))
					img.set_pixel(cx, cy - 2, Color("#6f8f4c"))
				2:
					img.set_pixel(cx, cy + 1, Color("#2f4526"))
					img.set_pixel(cx, cy, Color("#3d5a2e"))
					img.set_pixel(cx - 1, cy - 1, Color("#5c99d6"))
					img.set_pixel(cx + 1, cy - 1, Color("#5c99d6"))
					img.set_pixel(cx, cy - 2, Color("#85bbf0"))
				_:
					img.set_pixel(cx, cy + 1, Color("#2f4526"))
					img.set_pixel(cx, cy, Color("#4d6d37"))
					img.set_pixel(cx - 1, cy - 1, Color("#6f8f4c"))
					img.set_pixel(cx + 1, cy, Color("#6f8f4c"))
	return ImageTexture.create_from_image(img)

func _create_bed_tile() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	var c_wood := Color("#5b3a22")
	var c_pillow := Color("#d8d2c8")
	var c_blanket := Color("#873b2b")
	for x in range(2, 14):
		for y in range(1, 15):
			var edge: bool = (x == 2 or x == 13 or y == 1 or y == 14)
			if edge:
				img.set_pixel(x, y, c_out)
			elif y <= 3 or y == 13:
				img.set_pixel(x, y, c_wood)
			elif y <= 6:
				img.set_pixel(x, y, c_pillow)
			else:
				img.set_pixel(x, y, c_blanket if y < 11 else c_blanket.darkened(0.18))
	return ImageTexture.create_from_image(img)

func _create_door_frame_tile(is_open: bool) -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	var c_wood_hi := Color("#9a6b3f")
	var c_wood_mid := Color("#7a5230")
	var c_wood_dark := Color("#5b3a22")
	var c_iron := Color("#9aa1ab")
	var c_sill := Color("#4a4f59")

	if not is_open:
		for x in range(16):
			for y in range(2, 24):
				var edge: bool = (x == 0 or x == 15 or y == 2 or y == 23)
				var iron_band: bool = (y == 8 or y == 18)
				var plank_seam: bool = (x % 4 == 0)
				if edge or plank_seam:
					img.set_pixel(x, y, c_out)
				elif iron_band:
					img.set_pixel(x, y, c_iron if x % 3 == 1 else c_sill)
				else:
					img.set_pixel(x, y, c_wood_mid if y < 14 else c_wood_dark)
		img.set_pixel(12, 13, Color("#ffcc66"))
	else:
		for x in range(1, 15):
			img.set_pixel(x, 22, c_sill)
			img.set_pixel(x, 23, c_out)
		for y in range(2, 24):
			for x in range(0, 5):
				var edge: bool = (x == 0 or x == 4 or y == 2 or y == 23)
				img.set_pixel(x, y, c_out if edge else (c_wood_hi if x == 1 else c_wood_mid))
			for x in range(13, 16):
				var edge_r: bool = (x == 13 or x == 15 or y == 2 or y == 23)
				img.set_pixel(x, y, c_out if edge_r else c_wood_dark)
		for x in range(0, 16):
			for y in range(2, 6):
				var arch_edge: bool = (y == 2 or y == 5 or x == 0 or x == 15)
				img.set_pixel(x, y, c_out if arch_edge else c_wood_hi)
	return ImageTexture.create_from_image(img)

func _create_window_frame_tile(is_lit: bool) -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	var c_top_hl := Color("#9aa1ab")
	var c_top := Color("#6c727d")
	var c_front := Color("#4a4f59")
	var c_mortar := Color("#2b2f36")
	var c_frame := Color("#5b3a22")
	var c_sill := Color("#9a6b3f")

	for x in range(16):
		for y in range(3, 24):
			if y == 3 or y == 11 or y == 23 or x == 0 or x == 15:
				img.set_pixel(x, y, c_out)
			elif y < 11:
				img.set_pixel(x, y, c_top_hl if y <= 5 else c_top)
			elif y >= 20:
				img.set_pixel(x, y, c_mortar if y == 20 else c_front)
			else:
				img.set_pixel(x, y, c_front)

	for x in range(3, 13):
		for y in range(12, 20):
			var is_border: bool = (x == 3 or x == 12 or y == 12 or y == 19)
			var is_cross: bool = (x == 7 or x == 8 or y == 15)
			if y == 19:
				img.set_pixel(x, y, c_sill)
			elif is_border or is_cross:
				img.set_pixel(x, y, c_out if is_border else c_frame)
			else:
				if is_lit:
					var glow := Color("#fff3b0") if (y <= 14 and x <= 6) else Color("#ffcc66")
					img.set_pixel(x, y, glow)
				else:
					var glass := Color("#3b556e") if (x + y) % 2 == 0 else Color("#283b4f")
					img.set_pixel(x, y, glass)
	return ImageTexture.create_from_image(img)

func _create_wall_pillar_tile() -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	var c_top_hl := Color("#9aa1ab")
	var c_top := Color("#6c727d")
	var c_front := Color("#4a4f59")
	var c_shade := Color("#2b2f36")
	for x in range(16):
		for y in range(0, 24):
			var edge: bool = (x == 0 or x == 15 or y == 0 or y == 23 or y == 9)
			if edge:
				img.set_pixel(x, y, c_out)
			elif y < 9:
				var inner: bool = (x >= 2 and x <= 11 and y >= 1 and y <= 5)
				img.set_pixel(x, y, c_top_hl if inner else c_top)
			else:
				var seam: bool = (y == 14 or y == 19 or x == 2 or x == 13)
				if seam:
					img.set_pixel(x, y, c_shade)
				else:
					img.set_pixel(x, y, c_top if (y < 14 and x < 8) else (c_front if y < 19 else c_shade))
	return ImageTexture.create_from_image(img)

func _create_wall_stone_section_tile(v: int) -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	var c_top_hl := Color("#9aa1ab")
	var c_top := Color("#6c727d")
	var c_front := Color("#4a4f59")
	var c_mortar := Color("#2b2f36")
	var c_moss := Color("#3f5f32")

	for x in range(16):
		for y in range(3, 24):
			if y == 3 or y == 11 or y == 23:
				img.set_pixel(x, y, c_out)
			elif y < 11:
				var top_seam: bool = (x == (5 + v * 3) % 12 + 2)
				img.set_pixel(x, y, c_mortar if top_seam else (c_top_hl if (y <= 5 and x < 12) else c_top))
			elif y >= 19:
				img.set_pixel(x, y, c_out if (y == 19 or x == 7) else c_mortar)
			else:
				var row_seam: bool = (y == 15)
				var col_seam: bool = ((y < 15 and x == (3 + v * 3)) or (y > 15 and x == (11 - v * 2)))
				if row_seam or col_seam:
					img.set_pixel(x, y, c_mortar)
				else:
					var top_lit: bool = (y == 12 or (y == 16 and x < 9))
					img.set_pixel(x, y, c_top if top_lit else c_front)

	if v % 2 == 1:
		img.set_pixel(4 + v * 2, 12, c_moss)
		img.set_pixel(5 + v * 2, 12, c_moss)
		img.set_pixel(4 + v * 2, 13, c_moss)
	return ImageTexture.create_from_image(img)

func _create_wall_wood_topped_tile() -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	var c_wood_hi := Color("#9a6b3f")
	var c_wood_mid := Color("#7a5230")
	var c_wood_dark := Color("#5b3a22")
	var c_stone_base := Color("#4a4f59")

	for x in range(16):
		for y in range(3, 24):
			if y == 3 or y == 9 or y == 17 or y == 23:
				img.set_pixel(x, y, c_out)
			elif y < 9:
				img.set_pixel(x, y, c_out if (x % 8 == 0) else (c_wood_hi if y <= 5 else c_wood_mid))
			elif y < 17:
				var log_seam: bool = (x % 4 == 0)
				img.set_pixel(x, y, c_out if log_seam else (c_wood_mid if (x % 4 == 1) else c_wood_dark))
			else:
				img.set_pixel(x, y, Color("#2b2f36") if (x == 8 or y > 20) else c_stone_base)
	return ImageTexture.create_from_image(img)

func _create_wall_side_tile() -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	var c_top_hl := Color("#9aa1ab")
	var c_top := Color("#6c727d")
	var c_side := Color("#4a4f59")
	for x in range(16):
		for y in range(2, 24):
			if x == 0 or x == 15 or y == 2 or y == 23:
				img.set_pixel(x, y, c_out)
			elif x >= 11:
				img.set_pixel(x, y, Color("#2b2f36") if (y % 6 == 0) else c_side)
			else:
				img.set_pixel(x, y, Color("#2b2f36") if (y % 8 == 0) else (c_top_hl if x <= 4 else c_top))
	return ImageTexture.create_from_image(img)

func _create_corner_tower_sprite() -> ImageTexture:
	var img := Image.create(24, 34, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	var c_stone_l := Color("#9aa1ab")
	var c_stone := Color("#6c727d")
	var c_stone_d := Color("#4a4f59")
	var c_mortar := Color("#2b2f36")
	var c_wood := Color("#7a5230")

	for x in range(1, 23):
		for y in range(4, 34):
			var edge: bool = (x == 1 or x == 22 or y == 4 or y == 33 or y == 14)
			if edge:
				img.set_pixel(x, y, c_out)
			elif y < 14:
				var inner: bool = (x >= 4 and x <= 19 and y >= 6 and y <= 12)
				img.set_pixel(x, y, c_wood if inner else (c_stone_l if x < 14 else c_stone))
			else:
				var seam: bool = (y % 6 == 0 or (x + (y / 6) * 4) % 7 == 0)
				var shade_right: bool = (x >= 16 or y >= 26)
				img.set_pixel(x, y, c_mortar if seam else (c_stone_d if shade_right else c_stone))
	for bx in [1, 9, 17]:
		for x in range(bx, bx + 6):
			for y in range(0, 5):
				if x < 23:
					var b_edge: bool = (x == bx or x == bx + 5 or y == 0)
					img.set_pixel(x, y, c_out if b_edge else c_stone_l)
	for y in range(18, 24):
		img.set_pixel(7, y, c_out)
		img.set_pixel(8, y, c_out)
		img.set_pixel(15, y, c_out)
		img.set_pixel(16, y, c_out)
	return ImageTexture.create_from_image(img)

func _create_bush_variant_tile(v: int) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	var rx: int = 8 + (v % 2) - 1
	var rad: int = 5 if v == 1 else 6
	for x in range(1, 15):
		for y in range(3, 15):
			var d: int = abs(x - rx) + abs(y - 9) + ((x * 3 + y + v) % 2)
			if d == rad or (y == 14 and abs(x - rx) <= rad - 1):
				img.set_pixel(x, y, c_out)
			elif d < rad and y < 14:
				var col := Color("#6f8f4c") if (y < 7 and x < rx + 1) else (Color("#4d6d37") if y < 10 else Color("#2f4526"))
				img.set_pixel(x, y, col)
	if v % 2 == 0:
		img.set_pixel(6, 7, Color("#d9443b"))
		img.set_pixel(10, 8, Color("#d9443b"))
	elif v == 3:
		img.set_pixel(7, 8, Color("#e8b84b"))
		img.set_pixel(9, 7, Color("#e8b84b"))
	return ImageTexture.create_from_image(img)

func _create_flowers_variant_tile(v: int) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var layouts := [
		[Vector2i(5, 6), Vector2i(10, 7), Vector2i(7, 11)],
		[Vector2i(4, 9), Vector2i(9, 5), Vector2i(11, 11)],
		[Vector2i(6, 5), Vector2i(11, 8), Vector2i(5, 11), Vector2i(9, 12)],
		[Vector2i(4, 6), Vector2i(8, 8), Vector2i(12, 6)]
	]
	var pts: Array = layouts[v % layouts.size()]
	var petals := [Color("#f2f5f8"), Color("#ffcc66"), Color("#b882eb"), Color("#e87a7a")]
	for i in range(pts.size()):
		var p: Vector2i = pts[i]
		img.set_pixel(p.x, p.y + 1, Color("#2f4526"))
		var petal: Color = petals[(i + v) % petals.size()]
		img.set_pixel(p.x - 1, p.y, petal)
		img.set_pixel(p.x + 1, p.y, petal)
		img.set_pixel(p.x, p.y - 1, petal)
		img.set_pixel(p.x, p.y, Color("#ffcc66") if petal != Color("#ffcc66") else Color("#d96b27"))
	return ImageTexture.create_from_image(img)

func _create_rock_variant_tile(v: int) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	var cx: int = 8 + (v % 3) - 1
	var w_rad: int = 6 - (v % 2)
	for x in range(2, 14):
		for y in range(5, 14):
			var d: int = abs(x - cx) + abs(y - 10)
			if d == w_rad or (y == 13 and abs(x - cx) < w_rad):
				img.set_pixel(x, y, c_out)
			elif d < w_rad:
				var col := Color("#9aa1ab") if (y < 8 and x < cx + 1) else (Color("#6c727d") if y < 11 else Color("#4a4f59"))
				img.set_pixel(x, y, col)
	if v != 2:
		img.set_pixel(cx - 2, 12, Color("#3f5f32"))
		img.set_pixel(cx - 1, 12, Color("#3f5f32"))
	return ImageTexture.create_from_image(img)

func _create_stump_tile() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	for x in range(3, 13):
		for y in range(5, 14):
			if x == 3 or x == 12 or y == 5 or y == 13:
				img.set_pixel(x, y, c_out)
			elif y <= 8:
				img.set_pixel(x, y, Color("#9a6b3f") if (x + y) % 2 == 0 else Color("#7a5230"))
			else:
				img.set_pixel(x, y, Color("#5b3a22") if x < 8 else Color("#3b2516"))
	return ImageTexture.create_from_image(img)

func _create_fallen_log_tile() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	for x in range(1, 15):
		for y in range(6, 13):
			if x == 1 or x == 14 or y == 6 or y == 12:
				img.set_pixel(x, y, c_out)
			elif x == 2:
				img.set_pixel(x, y, Color("#9a6b3f"))
			else:
				img.set_pixel(x, y, Color("#3f5f32") if (y == 7 and x >= 6 and x <= 10) else (Color("#7a5230") if y < 9 else Color("#3b2516")))
	return ImageTexture.create_from_image(img)

func _create_well_tile() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(1, 15):
		for y in range(2, 15):
			var d: int = abs(x - 8) + abs(y - 9)
			if d == 6 or d == 5:
				img.set_pixel(x, y, Color("#171412") if d == 6 else (Color("#9aa1ab") if y < 9 else Color("#4a4f59")))
			elif d < 5:
				img.set_pixel(x, y, Color("#1d3e59") if y > 8 else Color("#2d5d82"))
	for x in range(2, 14):
		img.set_pixel(x, 2, Color("#7a5230"))
		img.set_pixel(x, 3, Color("#5b3a22"))
	return ImageTexture.create_from_image(img)

func _create_campfire_tile(frame: int) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(2, 14):
		for y in range(9, 15):
			var d: int = abs(x - 8) + abs(y - 12)
			if d == 5:
				img.set_pixel(x, y, Color("#4a4f59"))
			elif d < 5:
				img.set_pixel(x, y, Color("#5b3a22") if (x + y) % 2 == 0 else Color("#3b2516"))
	var top_shift: int = (frame % 3) - 1
	for x in range(5, 11):
		for y in range(4, 12):
			var d: int = abs(x - 8) + max(0, (9 - y) / 2)
			if d <= 3:
				var col := Color("#ff7b29")
				if y >= 7 and abs(x - 8) <= 1:
					col = Color("#fff3b0")
				elif y >= 5 and abs(x - 8 - top_shift) <= 1:
					col = Color("#ffb35a")
				img.set_pixel(x, y, col)
	img.set_pixel(8 + top_shift, 3, Color("#ffcc66"))
	return ImageTexture.create_from_image(img)

func _create_crate_tile() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	for x in range(2, 14):
		for y in range(2, 14):
			var edge: bool = (x == 2 or x == 13 or y == 2 or y == 13 or y == 6)
			var diag: bool = (x == y and y > 6)
			var col := Color("#9a6b3f") if y < 6 else (Color("#5b3a22") if (diag or x > 10) else Color("#7a5230"))
			img.set_pixel(x, y, c_out if edge else col)
	return ImageTexture.create_from_image(img)

func _create_workbench_tile() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	for x in range(1, 15):
		for y in range(3, 15):
			if y < 9:
				var edge: bool = (x == 1 or x == 14 or y == 3 or y == 8)
				img.set_pixel(x, y, c_out if edge else (Color("#9a6b3f") if y % 2 == 0 else Color("#7a5230")))
			elif x in [2, 3, 12, 13]:
				img.set_pixel(x, y, c_out if (x == 2 or x == 13 or y == 14) else Color("#5b3a22"))
	img.set_pixel(5, 5, Color("#9aa1ab"))
	img.set_pixel(6, 5, Color("#9aa1ab"))
	img.set_pixel(10, 6, Color("#ffcc66"))
	return ImageTexture.create_from_image(img)

func _create_barrel_tile() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	for x in range(3, 13):
		for y in range(2, 15):
			var edge: bool = (x == 3 or x == 12 or y == 2 or y == 14 or y == 6)
			var hoop: bool = (y == 8 or y == 12)
			if edge:
				img.set_pixel(x, y, c_out)
			elif hoop:
				img.set_pixel(x, y, Color("#4a4f59"))
			else:
				img.set_pixel(x, y, Color("#7a5230") if x < 8 else Color("#5b3a22"))
	return ImageTexture.create_from_image(img)

func _create_procedural_pine_texture(snowy: bool, variant: int = 0) -> ImageTexture:
	var w: int = 32
	var h: int = 44
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var outline := Color("#141210")
	var trunk_c := Color("#4f311c")

	var palettes := [
		[Color("#1d2e18"), Color("#2c4223"), Color("#3e5930"), Color("#587a42")],
		[Color("#172619"), Color("#243b27"), Color("#335236"), Color("#4b704d")],
		[Color("#243018"), Color("#364724"), Color("#4a5e32"), Color("#688246")],
		[Color("#1a2916"), Color("#283d22"), Color("#38542e"), Color("#507340")]
	]
	var pal: Array = palettes[variant % palettes.size()]
	var c_dark: Color = pal[0] if not snowy else Color("#364959")
	var c_mid: Color = pal[1] if not snowy else Color("#6e879c")
	var c_light: Color = pal[2] if not snowy else Color("#cfe0f0")
	var c_rim: Color = pal[3] if not snowy else Color("#f2f7fc")

	for x in range(13, 19):
		for y in range(33, 43):
			img.set_pixel(x, y, outline if (x == 13 or x == 18 or y == 42) else trunk_c)

	var top_shift: int = (variant % 3) * 2
	var width_mod: int = -1 if variant == 1 else (1 if variant == 2 else 0)
	var tiers := [
		{"top": 2 + top_shift, "bot": 15 + top_shift / 2, "max_r": 7 + width_mod},
		{"top": 9 + top_shift / 2, "bot": 23, "max_r": 10 + width_mod},
		{"top": 17, "bot": 31, "max_r": 13 + width_mod},
		{"top": 24, "bot": 37, "max_r": 14 + width_mod}
	]
	for t in tiers:
		var top_y: int = int(t["top"])
		var bot_y: int = int(t["bot"])
		var max_r: int = int(t["max_r"])
		for y in range(top_y, bot_y + 1):
			var prog: float = float(y - top_y) / float(maxi(1, bot_y - top_y))
			var jag: int = ((y * 7 + variant * 3) % 3) - 1
			var half_w: int = clampi(int(round(prog * float(max_r))) + jag, 1, 15)
			for x in range(16 - half_w, 16 + half_w + 1):
				var is_edge: bool = (x == 16 - half_w or x == 16 + half_w or y == bot_y)
				if is_edge:
					img.set_pixel(x, y, outline)
				else:
					var col := c_mid
					if y < top_y + 3 and x < 15:
						col = c_rim
					elif y < top_y + 6 and x < 17:
						col = c_light
					elif y > bot_y - 4 or x > 17:
						col = c_dark
					img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _create_procedural_oak_texture(variant: int = 0, snowy: bool = false) -> ImageTexture:
	var w: int = 32
	var h: int = 42
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_out := Color("#141210")
	var c_trunk := Color("#54351e")

	var palettes := [
		[Color("#23361c"), Color("#334d28"), Color("#466637"), Color("#638a4c")],
		[Color("#2b3619"), Color("#3f4f24"), Color("#566b32"), Color("#789146")],
		[Color("#1d3320"), Color("#2b4a2e"), Color("#3b633e"), Color("#548556")],
		[Color("#333019"), Color("#4a4523"), Color("#665e30"), Color("#877c41")]
	]
	var pal: Array = palettes[variant % palettes.size()]
	var c_dark: Color = pal[0] if not snowy else Color("#3d4d5c")
	var c_mid: Color = pal[1] if not snowy else Color("#72889c")
	var c_light: Color = pal[2] if not snowy else Color("#d2e1f0")
	var c_rim: Color = pal[3] if not snowy else Color("#f2f7fc")

	for x in range(13, 19):
		for y in range(27, 41):
			img.set_pixel(x, y, c_out if (x == 13 or x == 18 or y == 40) else c_trunk)

	var shift_x: int = (variant % 3) - 1
	var blobs := [
		Vector3(16 + shift_x, 14, 11),
		Vector3(10, 19 - (variant % 2), 8),
		Vector3(22, 18 + (variant % 2), 8),
		Vector3(12 - shift_x, 11, 7),
		Vector3(20 + shift_x, 12, 7)
	]
	for x in range(2, 30):
		for y in range(3, 30):
			var min_norm: float = 99.0
			for b in blobs:
				var d: float = Vector2(x - b.x, y - b.y).length() / b.z
				if d < min_norm:
					min_norm = d
			if min_norm <= 1.05:
				if min_norm > 0.88:
					img.set_pixel(x, y, c_out)
				elif y < 11 and x < 17:
					img.set_pixel(x, y, c_rim)
				elif y < 16 and x < 20:
					img.set_pixel(x, y, c_light)
				elif y > 20 or x > 19:
					img.set_pixel(x, y, c_dark)
				else:
					img.set_pixel(x, y, c_mid)
	return ImageTexture.create_from_image(img)

func _generate_hotbar_icons() -> void:
	tex_hotbar_icons.clear()
	for idx in range(10):
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		var c_wood := Color("#8c5830")
		var c_steel := Color("#9aa6b5")
		var c_steel_hl := Color("#d0dae6")
		match idx:
			0:
				for i in range(4, 13):
					img.set_pixel(i, 15 - i, c_wood)
					img.set_pixel(i + 1, 15 - i, Color("#5c381c"))
				for x in range(10, 14):
					for y in range(2, 6):
						img.set_pixel(x, y, Color("#ffcc66") if (x + y) % 2 == 0 else Color("#ffb35a"))
			1:
				for i in range(3, 13):
					img.set_pixel(i, 15 - i, c_wood)
				for x in range(8, 14):
					for y in range(2, 8):
						if x - y >= 3:
							img.set_pixel(x, y, c_steel_hl if x == 13 else c_steel)
			2:
				for i in range(3, 13):
					img.set_pixel(i, 15 - i, c_wood)
				for k in range(-3, 4):
					img.set_pixel(10 + k, 5 + abs(k) / 2, c_steel_hl)
					img.set_pixel(10 + k, 6 + abs(k) / 2, c_steel)
			3:
				for i in range(2, 11):
					img.set_pixel(i, 15 - i, c_wood)
				for i in range(10, 14):
					img.set_pixel(i, 15 - i, c_steel_hl)
					img.set_pixel(i - 1, 15 - i, c_steel)
			4:
				for i in range(4, 13):
					img.set_pixel(i, i, c_wood)
				for k in range(-4, 5):
					img.set_pixel(6 - k / 2, 6 + k, c_steel)
			5:
				for x in range(4, 12):
					for y in range(5, 12):
						if abs(x - 8) + abs(y - 8) <= 4:
							img.set_pixel(x, y, Color("#4a4f59") if (x + y) % 2 == 0 else Color("#2b2f36"))
			6:
				for x in range(3, 13):
					for y in range(4, 12):
						img.set_pixel(x, y, Color("#3b2516") if (y == 7 or y == 11) else c_wood)
			7:
				for x in range(3, 13):
					for y in range(5, 13):
						if abs(x - 8) + abs(y - 9) <= 5:
							img.set_pixel(x, y, c_steel if y < 8 else Color("#6c727d"))
			8:
				for y in range(6, 13):
					img.set_pixel(8, y, Color("#3d5a2e"))
				for p in [Vector2i(6, 6), Vector2i(10, 6), Vector2i(8, 4), Vector2i(7, 8), Vector2i(9, 8)]:
					img.set_pixel(p.x, p.y, Color("#5c99d6"))
			9:
				for y in range(5, 13):
					img.set_pixel(8, y, Color("#4d6d37"))
				img.set_pixel(6, 7, Color("#6f8f4c"))
				img.set_pixel(7, 7, Color("#6f8f4c"))
				img.set_pixel(9, 6, Color("#6f8f4c"))
				img.set_pixel(10, 6, Color("#6f8f4c"))
		var fb_icon := ImageTexture.create_from_image(img)
		tex_hotbar_icons.append(ArtLoader.get_single("hotbar_%d" % idx, fb_icon))

func _setup_procedural_audio() -> void:
	sfx_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.25
	sfx_player.stream = gen
	add_child(sfx_player)
	sfx_player.play()
	sfx_playback = sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback

func play_sfx(kind: String) -> void:
	if sfx_playback == null or master_volume <= 0.01:
		return
	var rate: float = 22050.0
	var avail: int = sfx_playback.get_frames_available()
	var want_samples: int = 1400
	if kind == "ui":
		want_samples = 650
	elif kind == "item":
		want_samples = 1100
	elif kind == "build":
		want_samples = 1600
	elif kind == "hook" or kind == "blade":
		want_samples = 1800
	elif kind == "hit" or kind == "roar":
		want_samples = 2400

	var samples: int = mini(want_samples, avail)
	for i in range(samples):
		var t: float = float(i) / rate
		var prog: float = float(i) / float(maxi(1, samples))
		var env: float = pow(clampf(1.0 - prog, 0.0, 1.0), 1.8)
		var sig: float = 0.0

		match kind:
			"ui":
				sig = sin(TAU * 210.0 * t) * 0.09 * env
			"item":
				var f_it: float = 280.0 if prog < 0.45 else 360.0
				sig = sin(TAU * f_it * t) * 0.12 * env
			"build":
				var thud: float = sin(TAU * lerpf(155.0, 72.0, prog) * t) * 0.24
				var wood_noise: float = randf_range(-0.18, 0.18) * (1.0 - prog)
				sig = (thud + wood_noise) * env
			"hook":
				var f_hk: float = lerpf(240.0, 620.0, prog)
				sig = (sin(TAU * f_hk * t) * 0.14 + randf_range(-0.08, 0.08)) * env
			"blade":
				var f_bl: float = lerpf(580.0, 190.0, prog)
				sig = (sin(TAU * f_bl * t) * 0.15 + randf_range(-0.16, 0.16)) * env
			"hit", "roar":
				sig = (sin(TAU * 95.0 * t) + randf_range(-0.45, 0.45)) * 0.30 * env
			_:
				sig = sin(TAU * 240.0 * t) * 0.10 * env

		sig *= master_volume
		sfx_playback.push_frame(Vector2(sig, sig))

func _setup_lighting() -> void:
	sky_modulate = CanvasModulate.new()
	sky_modulate.color = Phase1Visuals.sample_sky_color(game_hour, false)
	add_child(sky_modulate)

func _setup_world_layer() -> void:
	world_canvas = Node2D.new()
	add_child(world_canvas)
	colonists_layer = Node2D.new()
	add_child(colonists_layer)
	titans_layer = Node2D.new()
	add_child(titans_layer)
	fx_layer = Node2D.new()
	fx_layer.draw.connect(func(): _draw_roof_and_chimney_smoke(fx_layer))
	add_child(fx_layer)

func _generate_fortress_from_reference() -> void:
	_watchtower_set.clear()
	for tw in watchtowers:
		_watchtower_set[tw] = true

	for x in range(-MAP_RADIUS, MAP_RADIUS + 1):
		for y in range(-MAP_RADIUS, MAP_RADIUS + 1):
			ground_map[Vector2i(x, y)] = 0

	for x in range(-14, 14):
		for y in range(-12, 7):
			var around_house: bool = (x >= -13 and x <= -4 and y >= -11 and y <= -3)
			var around_work: bool = (x >= -3 and x <= 5 and y >= -2 and y <= 4)
			var n_val: float = Phase1Visuals.ground_noise.get_noise_2d(float(x) * 6.5, float(y) * 6.5)
			if around_house or (around_work and n_val > -0.15) or (y == 6 and abs(x) <= 4):
				ground_map[Vector2i(x, y)] = 1

	for y in range(-5, 7):
		ground_map[Vector2i(-9, y)] = 4
		ground_map[Vector2i(0, y)] = 4
	for y in range(-12, -1):
		ground_map[Vector2i(0, y)] = 4
	for x in range(-9, 6):
		ground_map[Vector2i(x, -2)] = 4

	for x in range(-15, 15):
		if x in [-1, 0, 1]:
			_set_block(Vector2i(x, -13), 6, false)
			_set_block(Vector2i(x, 7), 6, false)
		elif x in [-15, -11, -7, -3, 3, 7, 11, 14]:
			_set_block(Vector2i(x, -13), 3, false)
			_set_block(Vector2i(x, 7), 3, false)
		else:
			var is_wood_span: bool = (abs(x) >= 8 and abs(x) <= 10)
			var sec_id: int = 1 if is_wood_span else 4
			_set_block(Vector2i(x, -13), sec_id, false)
			_set_block(Vector2i(x, 7), sec_id, false)

	for y in range(-13, 8):
		var is_side_pillar: bool = (y in [-13, -9, -5, -1, 3, 7])
		var side_id: int = 3 if is_side_pillar else 4
		_set_block(Vector2i(-15, y), side_id, false)
		_set_block(Vector2i(14, y), side_id, false)

	for x in range(-13, -4):
		for y in range(-11, -5):
			ground_map[Vector2i(x, y)] = 2
			var border: bool = (x == -13 or x == -5 or y == -11 or y == -6)
			if border:
				var c := Vector2i(x, y)
				if c == Vector2i(-9, -6):
					_set_block(c, 6, false)
				elif (y == -6 and (x == -11 or x == -7)) or (y == -9 and (x == -13 or x == -5)):
					_set_block(c, 9, false)
				elif (x == -13 or x == -5) and (y == -11 or y == -6):
					_set_block(c, 3, false)
				else:
					_set_block(c, 2, false)

	for gx in range(4, 11):
		for gy in range(-8, -4):
			if gx != 7:
				ground_map[Vector2i(gx, gy)] = 3
	for gx in range(7, 12):
		for gy in range(2, 5):
			ground_map[Vector2i(gx, gy)] = 3

	var courtyard_clusters := [
		{ "pos": Vector2i(11, -11), "kind": "tent" },
		{ "pos": Vector2i(-13, -5), "kind": "woodpile" },
		{ "pos": Vector2i(-12, -5), "kind": "woodpile" },
		{ "pos": Vector2i(-4, -8), "kind": "woodpile" },
		{ "pos": Vector2i(-3, -4), "kind": "sawhorse" },
		{ "pos": Vector2i(-2, 4), "kind": "cart" },
		{ "pos": Vector2i(-13, -3), "kind": "barrel" },
		{ "pos": Vector2i(-4, -5), "kind": "barrel" },
		{ "pos": Vector2i(-11, -10), "kind": "barrel" },
		{ "pos": Vector2i(-13, 3), "kind": "bush" },
		{ "pos": Vector2i(-12, 4), "kind": "flowers" },
		{ "pos": Vector2i(-13, 5), "kind": "rock" },
		{ "pos": Vector2i(-11, 5), "kind": "stump" },
		{ "pos": Vector2i(-6, 5), "kind": "log" },
		{ "pos": Vector2i(2, -11), "kind": "bush" },
		{ "pos": Vector2i(3, -11), "kind": "rock" },
		{ "pos": Vector2i(12, -8), "kind": "barrel" },
		{ "pos": Vector2i(12, -2), "kind": "bush" },
		{ "pos": Vector2i(13, -1), "kind": "rock" },
		{ "pos": Vector2i(12, 5), "kind": "bush" },
		{ "pos": Vector2i(6, 5), "kind": "flowers" }
	]
	for cl in courtyard_clusters:
		decor_map[cl["pos"]] = cl["kind"]

	Phase1Visuals.populate_dense_forest(self, MAP_RADIUS)
	BuildSystem.rebuild_all_autowalls(self)
	rebuild_ground_tint_cache()

	loot_crates[Vector2i(-6, -10)] = ["canned_food", "bandage", "wood"]
	loot_crates[Vector2i(11, -9)] = ["wood", "wood", "stone", "canned_food"]
	loot_crates[Vector2i(-4, 1)] = ["raw_meat", "herbs", "scrap", "wood"]
	loot_crates[Vector2i(3, 2)] = ["canned_food", "cloth", "wood", "stone"]

func rebuild_ground_tint_cache() -> void:
	_ground_tint_cache.clear()
	_grass_variant_cache.clear()
	var noise_ref: FastNoiseLite = Phase1Visuals.macro_patch_noise if Phase1Visuals.macro_patch_noise != null else Phase1Visuals.ground_noise
	var g_count: int = maxi(1, tex_grass_variants.size())

	for x in range(-MAP_RADIUS, MAP_RADIUS + 1):
		for y in range(-MAP_RADIUS, MAP_RADIUS + 1):
			var c := Vector2i(x, y)
			var macro_n: float = noise_ref.get_noise_2d(float(x) * 3.0, float(y) * 3.0) if noise_ref != null else 0.0
			var base_tint := Color(1.0 + macro_n * 0.04, 1.0 + macro_n * 0.03, 1.0 - macro_n * 0.03, 1.0)
			_ground_tint_cache[c] = base_tint * _compute_cell_warmth(c)
			_grass_variant_cache[c] = Phase1Visuals.sample_grass_variant(c, g_count)

func _compute_cell_warmth(cell: Vector2i) -> Color:
	var warmth: float = 0.0
	for fc in campfires:
		var d: float = Vector2(cell).distance_to(Vector2(fc))
		if d < 4.2:
			warmth = maxf(warmth, (1.0 - d / 4.2) * 0.14)
	for tc in wall_torches:
		var dt: float = Vector2(cell).distance_to(Vector2(tc))
		if dt < 3.0:
			warmth = maxf(warmth, (1.0 - dt / 3.0) * 0.10)
	return Color(1.0 + warmth * 0.65, 1.0 + warmth * 0.25, 1.0 - warmth * 0.20, 1.0)

func _sample_surface_warmth(cell: Vector2i) -> Color:
	return _ground_tint_cache.get(cell, Color.WHITE)

func _set_block(cell: Vector2i, b_id: int, recalc_support: bool = true) -> void:
	var b_info: Dictionary = blocks_db.get(str(b_id), {"hp": 30, "solid": true})
	var is_solid: bool = bool(b_info.get("solid", true))
	if not is_solid:
		var floor_type: int = int(b_info.get("floor_type", 7 if b_id == 10 else 2))
		ground_map[cell] = floor_type
		decor_map.erase(cell)
		if recalc_support:
			BuildSystem.mark_rooms_dirty()
		queue_redraw()
		return

	_remove_wall(cell, false)
	decor_map.erase(cell)
	var body := StaticBody2D.new()
	body.position = Vector2(cell * CELL_SIZE) + Vector2(8, 8)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 10) if b_id == 8 else Vector2(CELL_SIZE, CELL_SIZE)
	col.shape = rect
	body.add_child(col)
	world_canvas.add_child(body)

	wall_map[cell] = {
		"id": b_id,
		"hp": int(b_info.get("hp", 36 if b_id == 8 else 30)),
		"max_hp": int(b_info.get("hp", 36 if b_id == 8 else 30)),
		"is_door": bool(b_info.get("is_door", false)),
		"is_window": (b_id == 9 or bool(b_info.get("is_window", false))),
		"lets_light": (b_id == 9 or bool(b_info.get("lets_light", false))),
		"door_open": false,
		"is_side": false,
		"hookable": bool(b_info.get("hookable", true)),
		"drop": str(b_info.get("drop", "wood")),
		"body": body,
		"col": col
	}
	door_anim_progress[cell] = 0.0
	if recalc_support:
		BuildSystem.update_autowall_around(self, cell)
		if b_id == 4 or b_id == 2 or b_id == 1 or b_id == 3 or b_id == 9:
			core_stones_placed = mini(5, core_stones_placed + 1)
	queue_redraw()

func _remove_wall(cell: Vector2i, recalc_support: bool = true) -> void:
	if wall_map.has(cell):
		if is_instance_valid(col_or_body(cell)):
			wall_map[cell]["body"].queue_free()
		wall_map.erase(cell)
		door_anim_progress.erase(cell)
		if recalc_support:
			BuildSystem.update_autowall_around(self, cell)
		queue_redraw()

func col_or_body(cell: Vector2i) -> Node:
	return wall_map.get(cell, {}).get("body", null)

func place_station_near_player(st_kind: String) -> bool:
	var ok: bool = BuildSystem.place_station_near_player(self, st_kind)
	if ok and st_kind == "campfire":
		rebuild_ground_tint_cache()
	return ok

func _is_window_room_lit(win_cell: Vector2i) -> bool:
	if BuildSystem.is_cell_in_lit_room(self, win_cell):
		return true
	var p_cell: Vector2i = _world_to_cell(player.global_position)
	if Vector2(p_cell).distance_to(Vector2(win_cell)) <= 4.5:
		return true
	return false

func _setup_player() -> void:
	player = PlayerController.new()
	player.position = Vector2(-9 * CELL_SIZE + 8, -4 * CELL_SIZE)
	player.world_ref = self
	add_child(player)
	player.apply_config(config)
	player.surv.add_item("wood", 24)
	player.surv.add_item("stone", 11)
	player.surv.add_item("core_stone", 6)
	player.surv.add_item("scrap", 4)
	player.surv.add_item("canned_food", 2)
	player.surv.add_item("clean_water", 2)
	player.surv.add_item("bandage", 2)

	player_light = PointLight2D.new()
	player_light.texture = light_tex
	player_light.texture_scale = 0.78
	player_light.color = Color("#ffb35a")
	player_light.energy = 0.42
	player.add_child(player_light)

	camera = Camera2D.new()
	camera.zoom = Vector2(2.0, 2.0)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)
	func _spawn_campfire_point_lights() -> void:
	for ch in campfire_lights:
		if is_instance_valid(ch):
			ch.queue_free()
	campfire_lights.clear()
	for ch in sconce_lights:
		if is_instance_valid(ch):
			ch.queue_free()
	sconce_lights.clear()

	for fc in campfires:
		var pl := PointLight2D.new()
		pl.position = Vector2(fc * CELL_SIZE) + Vector2(8, 8)
		pl.texture = light_tex
		pl.texture_scale = 0.88
		pl.color = Color("#ffb35a")
		pl.energy = 0.48
		add_child(pl)
		campfire_lights.append(pl)

	for wx in [-11.0, -7.0]:
		var wl := PointLight2D.new()
		wl.position = Vector2(wx * float(CELL_SIZE) + 8.0, -6.0 * float(CELL_SIZE))
		wl.texture = light_tex
		wl.texture_scale = 0.65
		wl.color = Color("#ffcc66")
		wl.energy = 0.36
		add_child(wl)
		campfire_lights.append(wl)

	for tc in wall_torches:
		var tl := PointLight2D.new()
		tl.position = Vector2(tc * CELL_SIZE) + Vector2(8, 4)
		pl_setup_sconce(tl)
		add_child(tl)
		sconce_lights.append(tl)

func pl_setup_sconce(tl: PointLight2D) -> void:
	tl.texture = light_tex
	tl.texture_scale = 0.72
	tl.color = Color("#ffb35a")
	tl.energy = 0.34

func _spawn_initial_colonists() -> void:
	var list: Array = [
		{ "name": "Анна", "prof": "Врач", "trait": "Целитель", "role": "cook_med", "x": -7, "y": -3, "hx": -8, "hy": -4 },
		{ "name": "Борн", "prof": "Плотник", "trait": "Мастер", "role": "gather", "x": 1, "y": -2, "hx": 2, "hy": -3 },
		{ "name": "Ворон", "prof": "Солдат", "trait": "Смелый", "role": "guard", "x": 4, "y": 2, "hx": 0, "hy": 4 }
	]
	for item in list:
		var c := ColonistEntity.new()
		c.position = Vector2(float(item["x"]) * CELL_SIZE, float(item["y"]) * CELL_SIZE)
		c.world_ref = self
		c.player_ref = player
		c.home_pos = Vector2(float(item["hx"]) * CELL_SIZE, float(item["hy"]) * CELL_SIZE)
		c.setup_profile(str(item["name"]), str(item["prof"]), str(item["trait"]), str(item["role"]), true)
		colonists_layer.add_child(c)

func get_recruited_colonists() -> Array[ColonistEntity]:
	var res: Array[ColonistEntity] = []
	for ch in colonists_layer.get_children():
		if ch is ColonistEntity and ch.is_recruited:
			res.append(ch)
	return res

func has_combat_line_of_sight(origin: Vector2, target_pos: Vector2) -> bool:
	var diff: Vector2 = target_pos - origin
	var dist: float = diff.length()
	if dist <= 6.0:
		return true
	var dir: Vector2 = diff / dist
	var start_cell: Vector2i = _world_to_cell(origin)
	var end_cell: Vector2i = _world_to_cell(target_pos)
	var d: float = 6.0
	while d < dist - 4.0:
		var c: Vector2i = _world_to_cell(origin + dir * d)
		if c != start_cell and c != end_cell and wall_map.has(c):
			var w_data: Dictionary = wall_map[c]
			var is_open_door: bool = bool(w_data.get("is_door", false)) and bool(w_data.get("door_open", false))
			if not is_open_door:
				return false
		d += 5.0
	var mid_cell: Vector2i = _world_to_cell((origin + target_pos) * 0.5)
	if wall_map.has(mid_cell):
		var mw: Dictionary = wall_map[mid_cell]
		var is_op: bool = bool(mw.get("is_door", false)) and bool(mw.get("door_open", false))
		if not is_op:
			return false
	return true

func colonist_shoot_nearest_titan(origin: Vector2, max_range: float, dmg: float) -> Dictionary:
	for child in titans_layer.get_children():
		if child is TitanEntity and child.state != TitanEntity.State.DYING and child.state != TitanEntity.State.DORMANT:
			if origin.distance_to(child.global_position) <= max_range and has_combat_line_of_sight(origin, child.global_position):
				child.nape_hp -= dmg
				if child.nape_hp <= 0.0:
					child.nape_hp = 0.0
					child.state = TitanEntity.State.DYING
				return {"hit": true, "pos": child.global_position}
	return {"hit": false}

func _spawn_initial_titans() -> void:
	spawn_titan_at(Vector2(-1 * CELL_SIZE, -17 * CELL_SIZE), "wanderer")
	spawn_titan_at(Vector2(19 * CELL_SIZE, -8 * CELL_SIZE), "wanderer")
	spawn_titan_at(Vector2(8 * CELL_SIZE, 14 * CELL_SIZE), "wanderer")
	spawn_titan_at(Vector2(-21 * CELL_SIZE, 2 * CELL_SIZE), "crawler")

func spawn_titan_at(pos: Vector2, p_type: String) -> void:
	var t := TitanEntity.new()
	t.position = pos
	t.world_ref = self
	t.player_ref = player
	var t_cfg: Dictionary = config.get("titans", {}).get(p_type, {})
	t.apply_config(t_cfg, p_type)
	titans_layer.add_child(t)

# ПУНКТ 3.4: Понятный зацеп крюка за весь прямоугольник спрайта титана (а не только за узкую точку 15px у стоп!)
func raycast_hook_anchor(origin: Vector2, dir: Vector2, max_dist: float) -> Dictionary:
	var d: float = 8.0
	while d <= max_dist:
		var pt: Vector2 = origin + dir * d
		for child in titans_layer.get_children():
			if child is TitanEntity and child.state != TitanEntity.State.DYING:
				var is_cr: bool = (child.titan_type == "crawler")
				var body_rect := Rect2(
					child.global_position + Vector2(-20.0 if is_cr else -18.0, -26.0 if is_cr else -52.0),
					Vector2(40.0 if is_cr else 36.0, 26.0 if is_cr else 50.0)
				)
				if body_rect.has_point(pt):
					var clamp_anchor: Vector2 = pt.clamp(body_rect.position + Vector2(4, 4), body_rect.end - Vector2(4, 4))
					return {"hit": true, "pos": clamp_anchor, "kind": "titan"}
		var c: Vector2i = _world_to_cell(pt)
		if wall_map.has(c) and bool(wall_map[c].get("hookable", true)):
			var b_id: int = int(wall_map[c].get("id", 0))
			return {"hit": true, "pos": Vector2(c * CELL_SIZE) + Vector2(8, 8), "kind": "tree" if b_id == 8 else "wall"}
		d += 5.0
	return {"hit": false}

# ПУНКТ 3.2: Попадание клинками вызывает искры, тряску камеры и короткую заморозку кадра (hit-stop)
func player_slash_attack(origin: Vector2, _look_dir: Vector2, speed: float, base_dmg: float, max_spd: float) -> Dictionary:
	var best_res := {"hit": false}
	var reach_px: float = (player.slash_reach_cells if is_instance_valid(player) else 1.65) * float(CELL_SIZE)
	for child in titans_layer.get_children():
		if child is TitanEntity and child.state != TitanEntity.State.DYING:
			if origin.distance_to(child.global_position) <= reach_px + 10.0 and has_combat_line_of_sight(origin, child.global_position):
				var res: Dictionary = child.take_blade_hit(origin, speed, base_dmg, max_spd)
				if bool(res.get("hit", false)):
					best_res = res
					if screen_shake_enabled:
						screen_shake_amount = 5.5
					trigger_hit_stop(0.055)
					for k in range(5):
						var sp_off := Vector2(randf_range(-10.0, 10.0), randf_range(-28.0, -8.0))
						hit_sparks.append({
							"pos": child.global_position + sp_off,
							"vel": Vector2(randf_range(-85.0, 85.0), randf_range(-95.0, 35.0)),
							"timer": 0.26,
							"col": Color("#fff3b0") if k % 2 == 0 else Color("#ff7b29")
						})
					play_sfx("hit")
					break
	return best_res

func player_harvest_nearby(origin: Vector2, look_dir: Vector2) -> bool:
	var p_cell: Vector2i = _world_to_cell(origin)
	var step_dir := Vector2i(int(round(look_dir.x)), int(round(look_dir.y)))
	if step_dir == Vector2i.ZERO:
		step_dir = Vector2i(0, 1)

	var active_tool_id: String = ""
	if selected_hotbar_slot < combat_hotbar_slots.size():
		active_tool_id = str(combat_hotbar_slots[selected_hotbar_slot].get("id", ""))

	var check_cells: Array[Vector2i] = [
		p_cell + step_dir,
		p_cell + step_dir * 2,
		p_cell + Vector2i(1, 0), p_cell + Vector2i(-1, 0),
		p_cell + Vector2i(0, 1), p_cell + Vector2i(0, -1),
		p_cell + Vector2i(1, 1), p_cell + Vector2i(-1, 1),
		p_cell + Vector2i(1, -1), p_cell + Vector2i(-1, -1)
	]

	for c in check_cells:
		if wall_map.has(c) and int(wall_map[c].get("id", 0)) == 8:
			var dmg: int = 20 if active_tool_id == "axe" else 12
			var cur_hp: int = int(wall_map[c].get("hp", 36)) - dmg
			wall_map[c]["hp"] = cur_hp
			play_sfx("build")
			if screen_shake_enabled:
				screen_shake_amount = 2.2
			hit_sparks.append({"pos": Vector2(c * CELL_SIZE) + Vector2(8, 4), "vel": Vector2(randf_range(-35, 35), -40), "timer": 0.22, "col": Color("#b88454")})
			if cur_hp <= 0:
				_remove_wall(c, false)
				decor_map[c] = "stump"
				player.surv.add_item("wood", 3 if active_tool_id == "axe" else 2)
				play_sfx("item")
			queue_redraw()
			return true

		if decor_map.has(c):
			var kind: String = str(decor_map[c])
			if kind == "rock":
				decor_map.erase(c)
				player.surv.add_item("stone", 2 if active_tool_id == "pickaxe" else 1)
				if active_tool_id == "pickaxe" or randi() % 2 == 0:
					player.surv.add_item("core_stone", 1)
				hit_sparks.append({"pos": Vector2(c * CELL_SIZE) + Vector2(8, 8), "vel": Vector2(randf_range(-40, 40), -45), "timer": 0.22, "col": Color("#9aa1ab")})
				play_sfx("build")
				queue_redraw()
				return true
			elif kind == "stump" or kind == "log":
				decor_map.erase(c)
				player.surv.add_item("wood", 2)
				hit_sparks.append({"pos": Vector2(c * CELL_SIZE) + Vector2(8, 8), "vel": Vector2(randf_range(-35, 35), -40), "timer": 0.22, "col": Color("#b88454")})
				play_sfx("build")
				queue_redraw()
				return true
			elif kind == "bush" or kind == "flowers":
				decor_map.erase(c)
				player.surv.add_item("herbs", 1)
				play_sfx("item")
				queue_redraw()
				return true

	return false

func on_titan_killed(pos: Vector2) -> void:
	ash_piles.append(pos)
	titans_killed_count += 1
	queue_redraw()

func on_player_died() -> void:
	Engine.time_scale = 1.0
	hit_stop_timer = 0.0
	build_mode_active = false
	if inv_panel:
		inv_panel.visible = false
	if settings_panel:
		settings_panel.visible = false
	if death_panel:
		if lbl_death_stats:
			lbl_death_stats.text = "Вы погибли на День %d (%02d:%02d).\nТитанов повержено: %d" % [
				game_day, int(floor(game_hour)), int(floor(fmod(game_hour, 1.0) * 60.0)), titans_killed_count
			]
		death_panel.visible = true
	play_sfx("roar")
	queue_redraw()

func respawn_player() -> void:
	if not is_instance_valid(player):
		return
	var spawn_pos: Vector2 = Vector2(bed_cell * CELL_SIZE) + Vector2(8, 20)
	player.respawn_at(spawn_pos)
	if death_panel:
		death_panel.visible = false
	play_sfx("item")
	queue_redraw()

func _is_near_station(list: Array[Vector2i], radius_cells: float = 3.2) -> bool:
	var pc: Vector2i = _world_to_cell(player.global_position)
	for c in list:
		if Vector2(pc).distance_to(Vector2(c)) <= radius_cells:
			return true
	return false

func _is_titan_nearby(radius_cells: float) -> bool:
	var max_d: float = radius_cells * float(CELL_SIZE)
	for child in titans_layer.get_children():
		if child is TitanEntity and child.state != TitanEntity.State.DYING and child.state != TitanEntity.State.DORMANT:
			if child.global_position.distance_to(player.global_position) <= max_d:
				return true
	return false

func get_nearest_interactable() -> Dictionary:
	if not is_instance_valid(player) or player.is_dead:
		return {}
	var p_pos: Vector2 = player.global_position
	var pc: Vector2i = _world_to_cell(p_pos)
	var best := {}
	var best_dist: float = 9999.0

	for x in range(pc.x - 2, pc.x + 3):
		for y in range(pc.y - 2, pc.y + 3):
			var c := Vector2i(x, y)
			if wall_map.has(c) and bool(wall_map[c].get("is_door", false)):
				var c_center: Vector2 = Vector2(c * CELL_SIZE) + Vector2(8, 8)
				var d: float = p_pos.distance_to(c_center)
				if d <= 25.0 and d < best_dist:
					best_dist = d
					var is_op: bool = bool(wall_map[c].get("door_open", false))
					best = {
						"kind": "door",
						"cell": c,
						"pos": c_center,
						"prompt": "[E] Закрыть" if is_op else "[E] Открыть"
					}

	var bed_center: Vector2 = Vector2(bed_cell * CELL_SIZE) + Vector2(8, 8)
	var d_bed: float = p_pos.distance_to(bed_center)
	if d_bed <= 28.0 and d_bed < best_dist:
		best_dist = d_bed
		best = {"kind": "bed", "cell": bed_cell, "pos": bed_center, "prompt": "[E] Проснуться" if player.surv.is_sleeping else "[E] Спать"}

	for wb_c in workbenches:
		var wb_center: Vector2 = Vector2(wb_c * CELL_SIZE) + Vector2(8, 8)
		var d_wb: float = p_pos.distance_to(wb_center)
		if d_wb <= 28.0 and d_wb < best_dist:
			best_dist = d_wb
			best = {"kind": "workbench", "cell": wb_c, "pos": wb_center, "prompt": "[E] Верстак"}

	for cr_c in loot_crates.keys():
		var cr_center: Vector2 = Vector2(cr_c * CELL_SIZE) + Vector2(8, 8)
		var d_cr: float = p_pos.distance_to(cr_center)
		if d_cr <= 26.0 and d_cr < best_dist:
			best_dist = d_cr
			best = {"kind": "crate", "cell": cr_c, "pos": cr_center, "prompt": "[E] Взять припасы"}

	var well_center: Vector2 = Vector2(water_well_cell * CELL_SIZE) + Vector2(8, 8)
	var d_well: float = p_pos.distance_to(well_center)
	if d_well <= 28.0 and d_well < best_dist:
		best_dist = d_well
		best = {"kind": "well", "cell": water_well_cell, "pos": well_center, "prompt": "[E] Набрать воды"}

	return best

func interact_nearby() -> void:
	if player.is_dead:
		return
	var target: Dictionary = get_nearest_interactable()
	if target.is_empty():
		return

	var kind: String = str(target.get("kind", ""))
	var c: Vector2i = target.get("cell", Vector2i.ZERO)

	match kind:
		"door":
			if wall_map.has(c):
				var w: Dictionary = wall_map[c]
				var is_op: bool = not bool(w.get("door_open", false))
				w["door_open"] = is_op
				var col: CollisionShape2D = w.get("col")
				if is_instance_valid(col):
					col.disabled = is_op
				play_sfx("build")
				queue_redraw()
		"bed":
			player.surv.is_sleeping = not player.surv.is_sleeping
			play_sfx("item")
		"workbench":
			current_bag_tab = 2
			_toggle_inventory_window()
		"crate":
			if loot_crates.has(c):
				for item_id in loot_crates[c]:
					player.surv.add_item(str(item_id), 1)
				loot_crates.erase(c)
				play_sfx("item")
				queue_redraw()
		"well":
			player.surv.add_item("clean_water", 1)
			player.surv.thirst = minf(100.0, player.surv.thirst + 35.0)
			play_sfx("item")

func _process(delta: float) -> void:
	# Обработка восстановления скорости после микро-заморозки кадра (hit-stop) в реальном времени
	var unscaled_dt: float = delta / maxf(0.01, Engine.time_scale)
	if hit_stop_timer > 0.0:
		hit_stop_timer -= unscaled_dt
		if hit_stop_timer <= 0.0:
			hit_stop_timer = 0.0
			Engine.time_scale = 1.0

	if combat_hint_timer > 0.0:
		combat_hint_timer = maxf(0.0, combat_hint_timer - unscaled_dt)

	_update_adaptive_hud_positions()
	_update_game_clock_and_survival(delta)
	_update_camera_shake(unscaled_dt)
	_update_cursor_and_input()

	for d_cell in door_anim_progress.keys():
		if wall_map.has(d_cell) and bool(wall_map[d_cell].get("is_door", false)):
			var want_t: float = 1.0 if bool(wall_map[d_cell].get("door_open", false)) else 0.0
			var cur_t: float = float(door_anim_progress[d_cell])
			if absf(cur_t - want_t) > 0.005:
				door_anim_progress[d_cell] = move_toward(cur_t, want_t, delta * 4.5)

	for i in range(hit_sparks.size() - 1, -1, -1):
		hit_sparks[i]["timer"] = float(hit_sparks[i]["timer"]) - unscaled_dt
		if hit_sparks[i].has("vel"):
			hit_sparks[i]["pos"] = Vector2(hit_sparks[i]["pos"]) + Vector2(hit_sparks[i]["vel"]) * unscaled_dt
		if float(hit_sparks[i]["timer"]) <= 0.0:
			hit_sparks.remove_at(i)
	BuildSystem.update_roof_alphas(self, delta)
	if fx_layer:
		fx_layer.queue_redraw()
	if hud_bars_ctrl:
		hud_bars_ctrl.queue_redraw()
	if minimap_ctrl:
		minimap_ctrl.queue_redraw()
	if hotbar_ctrl:
		hotbar_ctrl.queue_redraw()
	queue_redraw()

func _update_adaptive_hud_positions() -> void:
	var vp: Vector2 = get_viewport_rect().size
	if vp.x <= 10.0 or vp.y <= 10.0:
		return
	if minimap_ctrl:
		minimap_ctrl.position = Vector2(vp.x - minimap_ctrl.size.x - 14.0, 14.0)
	if hotbar_ctrl:
		hotbar_ctrl.size = Vector2(vp.x, BuildSystem.HOTBAR_HEIGHT)
		hotbar_ctrl.position = Vector2(0.0, vp.y - BuildSystem.HOTBAR_HEIGHT - 6.0)
	if alert_panel:
		alert_panel.position = Vector2(vp.x - 262.0, 146.0)
	if prompt_e_panel:
		prompt_e_panel.position = Vector2((vp.x - 220.0) * 0.5, vp.y - BuildSystem.HOTBAR_HEIGHT - 78.0)
	if death_panel:
		death_panel.position = (vp - death_panel.custom_minimum_size) * 0.5

func is_screen_point_on_ui(screen_pt: Vector2) -> bool:
	var vp: Vector2 = get_viewport_rect().size
	if (inv_panel and inv_panel.visible) or (settings_panel and settings_panel.visible) or (death_panel and death_panel.visible):
		return true
	if screen_pt.y >= vp.y - (BuildSystem.HOTBAR_HEIGHT + 16.0):
		var total_w: float = 10.0 * BuildSystem.HOTBAR_SLOT_W + 9.0 * BuildSystem.HOTBAR_GAP
		var start_x: float = (vp.x - total_w) * 0.5
		if screen_pt.x >= start_x - 12.0 and screen_pt.x <= start_x + total_w + 12.0:
			return true
	if screen_pt.x <= 360.0 and screen_pt.y <= 265.0:
		return true
	if minimap_ctrl and Rect2(minimap_ctrl.position, minimap_ctrl.size).grow(6.0).has_point(screen_pt):
		return true
	if mobile_hud and mobile_hud.is_point_on_mobile_controls(screen_pt):
		return true
	return false

func _update_game_clock_and_survival(delta: float) -> void:
	var sleep_mult: float = 6.0 if player.surv.is_sleeping else 1.0
	var hours_passed: float = (delta / real_sec_per_hour) * time_scale_mult * sleep_mult
	game_hour += hours_passed
	if game_hour >= 24.0:
		game_hour -= 24.0
		game_day += 1

	var is_night: bool = (game_hour >= 20.0 or game_hour < 5.5)
	var is_dusk_or_dawn: bool = ((game_hour >= 17.5 and game_hour < 20.0) or (game_hour >= 5.0 and game_hour < 7.0))
	var inside_shelter: bool = BuildSystem.is_player_inside_any_room(self)
	var near_fire: bool = _is_near_station(campfires, 3.8)
	var near_titan: bool = _is_titan_nearby(14.0)
	var is_winter_zone: bool = (current_weather == 3)

	var night_factor: float = clampf(Phase1Visuals.get_light_night_factor(game_hour), 0.0, 1.0)
	var t_sec: float = float(Time.get_ticks_msec()) * 0.001

	var p_flicker: float = 1.0 + sin(t_sec * 11.0) * 0.04
	var base_p_energy: float = lerpf(0.22, 0.58, night_factor)
	if is_instance_valid(player_light) and is_instance_valid(player):
		player_light.position = player_light.position.lerp(player.get_torch_hand_offset(), delta * 14.0)
		player_light.energy = lerpf(player_light.energy, base_p_energy * p_flicker, delta * 8.0)

	var base_cf_energy: float = lerpf(0.25, 0.62, night_factor)
	for i in range(campfire_lights.size()):
		var pl: PointLight2D = campfire_lights[i]
		if is_instance_valid(pl):
			var f_mult: float = 1.0 + sin(t_sec * 9.5 + float(i) * 1.9) * 0.04
			pl.energy = lerpf(pl.energy, base_cf_energy * f_mult, delta * 6.0)

	var base_sc_energy: float = lerpf(0.18, 0.46, night_factor)
	for i in range(sconce_lights.size()):
		var sl: PointLight2D = sconce_lights[i]
		if is_instance_valid(sl):
			var f_mult: float = 1.0 + cos(t_sec * 10.5 + float(i) * 1.3) * 0.04
			sl.energy = lerpf(sl.energy, base_sc_energy * f_mult, delta * 6.0)

	if not player.is_dead:
		player.surv.update_survival(delta, hours_passed, is_night, near_fire, inside_shelter, near_titan, 1.2, -12.0 if is_winter_zone else 0.0, false)
		if player.surv.hp <= 0.0:
			player._trigger_player_death()

	var target_mod: Color = Phase1Visuals.sample_sky_color(game_hour, is_winter_zone)
	sky_modulate.color = sky_modulate.color.lerp(target_mod, delta * 4.5)

	var icon_str: String = "☀"
	if is_winter_zone:
		icon_str = "❄"
	elif is_night:
		icon_str = "🌙"
	elif is_dusk_or_dawn:
		icon_str = "🌅"

	var hh: int = int(floor(game_hour))
	var mm: int = int(floor((game_hour - float(hh)) * 60.0))
	if lbl_day_clock:
		lbl_day_clock.text = "День %d   %s\n%02d:%02d" % [game_day, icon_str, hh, mm]

	if lbl_quest_list:
		var q1_mark: String = "☑" if core_stones_placed >= 5 else "☐"
		var w_cnt: int = int(player.surv.inventory.get("wood", 0))
		var q2_mark: String = "☑" if w_cnt >= 10 else "☐"
		lbl_quest_list.text = "Задания:\n%s Построить стену (%d/5)\n%s Собрать доски (%d/10)" % [
			q1_mark, core_stones_placed, q2_mark, mini(w_cnt, 10)
		]

	if alert_panel:
		alert_panel.visible = (near_titan or is_winter_zone) and not player.is_dead

	if prompt_e_panel:
		var near_obj: Dictionary = get_nearest_interactable()
		if player.is_dead or near_obj.is_empty():
			prompt_e_panel.visible = false
		else:
			prompt_e_panel.visible = true
			lbl_prompt_e.text = str(near_obj.get("prompt", "[E] Действие"))

func _update_camera_shake(delta: float) -> void:
	if screen_shake_enabled and screen_shake_amount > 0.1:
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * screen_shake_amount
		screen_shake_amount = move_toward(screen_shake_amount, 0.0, 28.0 * delta)
	else:
		camera.offset = Vector2.ZERO
		screen_shake_amount = 0.0

func _world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / float(CELL_SIZE)), floor(pos.y / float(CELL_SIZE)))

func _input(event: InputEvent) -> void:
	if death_panel and death_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_R):
			respawn_player()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if inv_panel and inv_panel.visible:
				inv_panel.visible = false
			else:
				_toggle_settings_window()
			return
		elif event.keycode == KEY_TAB or event.keycode == KEY_I:
			_toggle_inventory_window()
			return
		elif event.keycode == KEY_V or event.keycode == KEY_E:
			interact_nearby()
			return
		elif event.keycode == KEY_B:
			build_mode_active = not build_mode_active
			BuildSystem.has_touch_preview = false
			selected_block_id = int(build_hotbar_slots[selected_hotbar_slot])
			player.release_hooks()
			play_sfx("ui")
			return
		elif event.keycode == KEY_T:
			_cycle_day_night_weather()
			return

	if (inv_panel and inv_panel.visible) or (settings_panel and settings_panel.visible):
		return

	if mobile_hud and mobile_hud.handle_screen_input(event):
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			if BuildSystem.try_select_hotbar_at_screen_pos(self, event.position):
				return
			if not is_screen_point_on_ui(event.position) and build_mode_active:
				BuildSystem.handle_touch_build_at_screen_pos(self, event.position)
				return
		else:
			BuildSystem.reset_touch_build_memory()
	elif event is InputEventScreenDrag:
		if build_mode_active and not is_screen_point_on_ui(event.position):
			BuildSystem.handle_touch_build_at_screen_pos(self, event.position)
			return

func _update_cursor_and_input() -> void:
	if death_panel and death_panel.visible:
		return
	for i in range(1, 10):
		if Input.is_key_pressed(KEY_0 + i):
			select_hotbar_slot_index(i - 1, false)
	if Input.is_key_pressed(KEY_0):
		select_hotbar_slot_index(9, false)

	if (inv_panel and inv_panel.visible) or (settings_panel and settings_panel.visible):
		return

	var viewport_mouse: Vector2 = get_viewport().get_mouse_position()
	if mobile_hud and (mobile_hud.joy_touch_idx != -1 or mobile_hud.left_hook_touch_idx != -1 or mobile_hud.right_hook_touch_idx != -1):
		return
	if is_screen_point_on_ui(viewport_mouse):
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			BuildSystem.try_select_hotbar_at_screen_pos(self, viewport_mouse)
		return

	if build_mode_active:
		BuildSystem.handle_hotbar_and_build_input(self)

func _draw_merged_garden_cell(cell: Vector2i, cell_rect: Rect2, mod_col: Color = Color.WHITE) -> void:
	var pos: Vector2 = cell_rect.position
	var crop_idx: int = abs(cell.x + (cell.y / 3) * 2) % tex_garden_crops.size()
	draw_texture_rect(tex_garden_crops[crop_idx], cell_rect, false, mod_col)

	var has_n: bool = (int(ground_map.get(cell + Vector2i(0, -1), 0)) == 3)
	var has_s: bool = (int(ground_map.get(cell + Vector2i(0, 1), 0)) == 3)
	var has_w: bool = (int(ground_map.get(cell + Vector2i(-1, 0), 0)) == 3)
	var has_e: bool = (int(ground_map.get(cell + Vector2i(1, 0), 0)) == 3)

	var c_out := Color("#171412")
	var c_wood_hi := Color("#8a5d36") * mod_col
	var c_wood_dark := Color("#5b3a22") * mod_col

	if not has_n:
		draw_rect(Rect2(pos, Vector2(16, 1)), c_out, true)
		draw_rect(Rect2(pos + Vector2(0, 1), Vector2(16, 2)), c_wood_hi, true)
	if not has_s:
		draw_rect(Rect2(pos + Vector2(0, 13), Vector2(16, 2)), c_wood_dark, true)
		draw_rect(Rect2(pos + Vector2(0, 15), Vector2(16, 1)), c_out, true)
	if not has_w:
		draw_rect(Rect2(pos, Vector2(1, 16)), c_out, true)
		draw_rect(Rect2(pos + Vector2(1, 0), Vector2(2, 16)), c_wood_hi, true)
	if not has_e:
		draw_rect(Rect2(pos + Vector2(13, 0), Vector2(2, 16)), c_wood_dark, true)
		draw_rect(Rect2(pos + Vector2(15, 0), Vector2(1, 16)), c_out, true)

# ПУНКТ 3.4: Наглядный прицел крюка (золотой/зелёный в зоне досягаемости, серо-красный при недолёте)
func _draw_auto_aim_reticle() -> void:
	if mobile_hud == null or not mobile_hud.auto_aim_enabled or not mobile_hud.has_valid_aim_target:
		return
	if build_mode_active or player.is_dead:
		return
	var target_pt: Vector2 = mobile_hud.current_aim_target_pos
	var in_rng: bool = mobile_hud.aim_target_in_range
	var t_kind: String = mobile_hud.aim_target_kind

	var pulse: float = 9.0 + sin(float(Time.get_ticks_msec()) * 0.01) * 1.8
	var col := Color(1.0, 0.78, 0.25, 0.90) if (in_rng and t_kind == "titan") else (Color(0.45, 0.92, 0.55, 0.72) if in_rng else Color(0.85, 0.35, 0.35, 0.75))

	draw_arc(target_pt, pulse, 0.0, TAU, 24, col, 1.5)
	draw_line(target_pt - Vector2(pulse + 4.0, 0), target_pt - Vector2(pulse - 3.0, 0), col, 1.5)
	draw_line(target_pt + Vector2(pulse - 3.0, 0), target_pt + Vector2(pulse + 4.0, 0), col, 1.5)
	draw_line(target_pt - Vector2(0, pulse + 4.0), target_pt - Vector2(0, pulse - 3.0), col, 1.5)
	draw_line(target_pt + Vector2(0, pulse - 3.0), target_pt + Vector2(0, pulse + 4.0), col, 1.5)

	if t_kind == "titan":
		var badge_txt: String = "ЗАЦЕП [L/R]" if in_rng else "ДАЛЕКО"
		BuildSystem._draw_world_cursor_badge(self, target_pt + Vector2(0, -pulse - 2.0), badge_txt, col, ThemeDB.fallback_font)

func is_actor_occluded_by_grid(actor_world_pos: Vector2, is_large_titan: bool = false) -> bool:
	var c: Vector2i = _world_to_cell(actor_world_pos)
	var x_span: Array[int] = [-1, 0, 1] if is_large_titan else [0]
	for dy in [1, 2]:
		for dx in x_span:
			var check_c := Vector2i(c.x + dx, c.y + dy)
			if _watchtower_set.has(check_c):
				return true
			if wall_map.has(check_c):
				var w_data: Dictionary = wall_map[check_c]
				var b_id: int = int(w_data.get("id", 0))
				if b_id == 8:
					return true
				elif dy == 1:
					var open_door: bool = bool(w_data.get("is_door", false)) and bool(w_data.get("door_open", false))
					if not open_door:
						return true
	return false

func _draw_single_wall_or_tree_cell(c: Vector2i, is_winter: bool, is_night: bool, wall_sz: Vector2) -> void:
	var w_data: Dictionary = wall_map[c]
	var b_id: int = int(w_data.get("id", 1))
	var pos := Vector2(c * CELL_SIZE)

	if b_id == 8:
		var tree_hash: int = ArtLoader.cell_hash(c, 61)
		var is_oak: bool = ((tree_hash % 5) < 2)
		var t_var: int = (tree_hash >> 3)

		var tree_arr: Array[Texture2D] = (tex_oak_snow_variants if is_winter else tex_oak_variants) if is_oak else (tex_pine_snow_variants if is_winter else tex_pine_variants)
		if tree_arr.is_empty():
			tree_arr = [tex_oak_tree] if is_oak else [tex_pine_day]

		var tree_tex: Texture2D = tree_arr[t_var % tree_arr.size()]
		var base_sz := Vector2(32, 42) if is_oak else Vector2(32, 44)
		var flip_tree: float = -1.0 if ((tree_hash & 2) != 0) else 1.0
		var jx_t: float = float((tree_hash % 5) - 2)
		var jy_t: float = float(((tree_hash >> 2) % 3) - 1)
		var shade_v: float = 0.92 + float((tree_hash >> 7) % 3) * 0.04
		var tree_mod := Color(shade_v, shade_v, shade_v, 1.0)

		Phase1Visuals.draw_soft_shadow(self, pos + Vector2(12 + jx_t, 12 + jy_t), Vector2(32, 15), 0.46)
		if tree_tex != null:
			var draw_pos := pos + Vector2(8.0 + jx_t - base_sz.x * 0.5 + (base_sz.x if flip_tree < 0 else 0.0), 16.0 + jy_t - base_sz.y)
			draw_texture_rect(tree_tex, Rect2(draw_pos, Vector2(base_sz.x * flip_tree, base_sz.y)), false, tree_mod)
		return

	var is_side_orient: bool = bool(w_data.get("is_side", false))

	if bool(w_data.get("is_door", false)):
		var is_open: bool = bool(w_data.get("door_open", false))
		var anim_t: float = float(door_anim_progress.get(c, 1.0 if is_open else 0.0))
		Phase1Visuals.draw_soft_shadow(self, pos + Vector2(11, 15), Vector2(22, 10), lerpf(0.46, 0.22, anim_t))
		var door_tex: Texture2D = BuildSystem.get_door_draw_texture(is_side_orient, anim_t)
		if door_tex != null:
			draw_texture_rect(door_tex, Rect2(pos + Vector2(0, -8), Vector2(16, 24)), false)
		return

	if b_id == 9 or bool(w_data.get("is_window", false)):
		Phase1Visuals.draw_soft_shadow(self, pos + Vector2(11, 15), Vector2(24, 11), 0.46)
		var lit_now: bool = is_night and _is_window_room_lit(c)
		var win_tex: Texture2D = BuildSystem.get_window_draw_texture(self, is_side_orient, lit_now)
		if win_tex != null:
			draw_texture_rect(win_tex, Rect2(pos + Vector2(0, -8), Vector2(16, 24)), false)
		return

	Phase1Visuals.draw_soft_shadow(self, pos + Vector2(11, 15), Vector2(24, 11), 0.46)
	var w_tex: Texture2D = BuildSystem.get_wall_draw_texture(self, c, b_id)
	if w_tex != null:
		draw_texture_rect(w_tex, Rect2(pos + Vector2(0, -8), wall_sz), false, _ground_tint_cache.get(c, Color.WHITE))

func _draw() -> void:
	var p_cell: Vector2i = _world_to_cell(player.global_position)
	var view_w: int = 38
	var view_h: int = 24
	var is_winter: bool = (current_weather == 3)
	var is_night: bool = (game_hour >= 19.5 or game_hour < 6.0)
	var anim_tick: int = int(Time.get_ticks_msec() / 160)
	var tile_sz := Vector2(16, 16)
	var winter_tint := Color(0.84, 0.91, 1.02, 1.0) if is_winter else Color.WHITE

	for x in range(p_cell.x - view_w, p_cell.x + view_w + 1):
		for y in range(p_cell.y - view_h, p_cell.y + view_h + 1):
			var c := Vector2i(x, y)
			var pos := Vector2(c * CELL_SIZE)
			var cell_rect := Rect2(pos, tile_sz)
			var g_type: int = int(ground_map.get(c, 0))
			var ground_tint: Color = _ground_tint_cache.get(c, Color.WHITE) * winter_tint

			if g_type == 2:
				var wf_idx: int = ArtLoader.pick_cell_variant(c, tex_wood_floor_variants.size())
				draw_texture_rect(tex_wood_floor_variants[wf_idx], cell_rect, false)
			elif g_type == 7:
				var sf_idx: int = ArtLoader.pick_cell_variant(c, tex_floor_stone_variants.size())
				draw_texture_rect(tex_floor_stone_variants[sf_idx], cell_rect, false)
			elif g_type == 3:
				_draw_merged_garden_cell(c, cell_rect, Color(0.80, 0.88, 0.98, 1.0) if is_winter else Color.WHITE)
			elif g_type == 4:
				var p_idx: int = ArtLoader.cell_hash(c, 37) % tex_path_variants.size()
				draw_texture_rect(tex_path_variants[p_idx], cell_rect, false, ground_tint)
			elif g_type == 1:
				var d_idx: int = ArtLoader.pick_cell_variant(c, tex_dirt_variants.size())
				draw_texture_rect(tex_dirt_variants[d_idx], cell_rect, false, ground_tint)
			else:
				var b_mask: int = Phase1Visuals.compute_dirt_blend_mask(c, ground_map)
				if b_mask > 0 and b_mask < tex_dirt_blend_variants.size():
					draw_texture_rect(tex_dirt_blend_variants[b_mask], cell_rect, false, ground_tint)
				else:
					var g_idx: int = int(_grass_variant_cache.get(c, 0)) % tex_grass_variants.size()
					draw_texture_rect(tex_grass_variants[g_idx], cell_rect, false, ground_tint)

			if not tex_grass_tuft_variants.is_empty() and g_type == 0 and not decor_map.has(c):
				var th: int = ArtLoader.cell_hash(c, 71)
				if th % 7 == 0:
					var tf_idx: int = th % tex_grass_tuft_variants.size()
					var ox: float = float((th >> 4) % 3) - 1.0
					var oy: float = float((th >> 7) % 3) - 1.0
					var flip_w: float = -16.0 if ((th & 1) == 0) else 16.0
					var tuft_mod := Color(0.85, 0.92, 1.02, 0.9) if is_winter else Color.WHITE
					draw_texture_rect(tex_grass_tuft_variants[tf_idx], Rect2(pos + Vector2(ox + (16.0 if flip_w < 0 else 0.0), oy), Vector2(flip_w, 16.0)), false, tuft_mod)

			if decor_map.has(c):
				var kind: String = str(decor_map[c])
				var dh: int = ArtLoader.cell_hash(c, 83)
				var jx: float = float((dh % 3) - 1)
				var jy: float = float(((dh >> 3) % 3) - 1)
				var flip_s: float = -1.0 if ((dh & 4) != 0) else 1.0
				var prop_mod := Color(0.85, 0.92, 1.02, 1.0) if is_winter else Color.WHITE
				Phase1Visuals.draw_soft_shadow(self, pos + Vector2(9 + jx, 12 + jy), Vector2(18, 9), 0.35)
				match kind:
					"bush":
						var bv: int = dh % tex_bush_variants.size()
						var draw_p := pos + Vector2(jx + (16.0 if flip_s < 0 else 0.0), jy)
						draw_texture_rect(tex_bush_variants[bv], Rect2(draw_p, Vector2(16.0 * flip_s, 16.0)), false, prop_mod)
					"rock":
						var rv: int = dh % tex_rock_variants.size()
						var draw_pr := pos + Vector2(jx + (16.0 if flip_s < 0 else 0.0), jy)
						draw_texture_rect(tex_rock_variants[rv], Rect2(draw_pr, Vector2(16.0 * flip_s, 16.0)), false, prop_mod)
					"flowers":
						if not is_winter:
							var fv: int = dh % tex_flowers_variants.size()
							draw_texture_rect(tex_flowers_variants[fv], Rect2(pos + Vector2(jx, jy), Vector2(16, 16)), false)
					"stump":
						draw_texture_rect(tex_stump, Rect2(pos + Vector2(jx, jy), Vector2(16, 16)), false, prop_mod)
					"log":
						draw_texture_rect(tex_fallen_log, Rect2(pos + Vector2(jx, jy), Vector2(16, 16)), false, prop_mod)
					"barrel":
						draw_texture_rect(tex_barrel, Rect2(pos, Vector2(16, 16)), false)
					"woodpile":
						draw_texture_rect(tex_woodpile, Rect2(pos, Vector2(16, 16)), false)
					"sawhorse":
						draw_texture_rect(tex_sawhorse, Rect2(pos, Vector2(16, 16)), false)
					"tent":
						Phase1Visuals.draw_soft_shadow(self, pos + Vector2(16, 18), Vector2(34, 14), 0.45)
						draw_texture_rect(tex_tent, Rect2(pos - Vector2(0, 6), Vector2(32, 24)), false)
					"cart":
						Phase1Visuals.draw_soft_shadow(self, pos + Vector2(12, 15), Vector2(26, 11), 0.42)
						draw_texture_rect(tex_cart, Rect2(pos - Vector2(2, 2), Vector2(24, 18)), false)

	for ap in ash_piles:
		Phase1Visuals.draw_soft_shadow(self, ap + Vector2(2, 2), Vector2(18, 9), 0.35)
		if has_ash_pile_png and tex_ash_pile != null:
			var ash_sz: Vector2 = ArtLoader.get_frame_size("ash_pile")
			draw_texture_rect(tex_ash_pile, Rect2(ap - ash_sz * 0.5, ash_sz), false)
		else:
			draw_rect(Rect2(ap - Vector2(7, 3), Vector2(14, 6)), Color("#495059"), true)
			draw_rect(Rect2(ap - Vector2(5, 5), Vector2(10, 4)), Color("#6c727d"), true)

	var bed_pos := Vector2(bed_cell * CELL_SIZE)
	Phase1Visuals.draw_soft_shadow(self, bed_pos + Vector2(9, 12), Vector2(16, 10), 0.38)
	draw_texture_rect(tex_bed, Rect2(bed_pos, Vector2(16, 16)), false)

	var well_pos := Vector2(water_well_cell * CELL_SIZE)
	Phase1Visuals.draw_soft_shadow(self, well_pos + Vector2(10, 12), Vector2(20, 10), 0.44)
	draw_texture_rect(tex_well, Rect2(well_pos, ArtLoader.get_frame_size("well")), false)

	var cf_tex: Texture2D = tex_campfire_frames[anim_tick % tex_campfire_frames.size()]
	var cf_sz: Vector2 = ArtLoader.get_frame_size("campfire")
	for fc in campfires:
		var fc_pos := Vector2(fc * CELL_SIZE)
		Phase1Visuals.draw_soft_shadow(self, fc_pos + Vector2(9, 12), Vector2(16, 8), 0.32)
		draw_texture_rect(cf_tex, Rect2(fc_pos, cf_sz), false)

	var wb_sz: Vector2 = ArtLoader.get_frame_size("workbench")
	for wb_cell in workbenches:
		var wb_pos := Vector2(wb_cell * CELL_SIZE)
		Phase1Visuals.draw_soft_shadow(self, wb_pos + Vector2(10, 12), Vector2(20, 9), 0.42)
		draw_texture_rect(tex_workbench, Rect2(wb_pos, wb_sz), false)

	var cr_sz: Vector2 = ArtLoader.get_frame_size("crate")
	for crate_cell in loot_crates.keys():
		var cr_pos := Vector2(crate_cell * CELL_SIZE)
		Phase1Visuals.draw_soft_shadow(self, cr_pos + Vector2(10, 12), Vector2(18, 9), 0.42)
		draw_texture_rect(tex_crate, Rect2(cr_pos, cr_sz), false)

	var entities_by_row: Dictionary = {}
	var occluded_draw_queue: Array[Dictionary] = []
	var sil_max_dist_px: float = silhouette_radius_cells * float(CELL_SIZE)

	if is_instance_valid(player):
		var p_occ: bool = is_actor_occluded_by_grid(player.global_position, false)
		if p_occ:
			occluded_draw_queue.append({"kind": "player", "ref": player})
		else:
			var p_row: int = _world_to_cell(player.global_position).y
			if not entities_by_row.has(p_row):
				entities_by_row[p_row] = []
			entities_by_row[p_row].append({"y": player.global_position.y, "kind": "player", "ref": player})

	for ch in colonists_layer.get_children():
		if ch is ColonistEntity:
			var c_occ: bool = is_actor_occluded_by_grid(ch.global_position, false)
			if c_occ:
				if ch.global_position.distance_to(player.global_position) <= sil_max_dist_px:
					occluded_draw_queue.append({"kind": "colonist", "ref": ch})
			else:
				var c_row: int = _world_to_cell(ch.global_position).y
				if not entities_by_row.has(c_row):
					entities_by_row[c_row] = []
				entities_by_row[c_row].append({"y": ch.global_position.y, "kind": "colonist", "ref": ch})

	for ch in titans_layer.get_children():
		if ch is TitanEntity:
			var t_occ: bool = is_actor_occluded_by_grid(ch.global_position, true)
			if t_occ:
				if ch.global_position.distance_to(player.global_position) <= sil_max_dist_px:
					occluded_draw_queue.append({"kind": "titan", "ref": ch})
			else:
				var t_row: int = _world_to_cell(ch.global_position).y
				if not entities_by_row.has(t_row):
					entities_by_row[t_row] = []
				entities_by_row[t_row].append({"y": ch.global_position.y, "kind": "titan", "ref": ch})

	var wall_sz: Vector2 = ArtLoader.get_frame_size("wall_stone")
	var tower_sz: Vector2 = ArtLoader.get_frame_size("tower")

	for y in range(p_cell.y - view_h, p_cell.y + view_h + 1):
		for x in range(p_cell.x - view_w, p_cell.x + view_w + 1):
			var c := Vector2i(x, y)
			if wall_map.has(c):
				_draw_single_wall_or_tree_cell(c, is_winter, is_night, wall_sz)
			if _watchtower_set.has(c):
				var tpos := Vector2(c * CELL_SIZE)
				Phase1Visuals.draw_soft_shadow(self, tpos + Vector2(13, 14), Vector2(32, 14), 0.52)
				draw_texture_rect(tex_tower_sprite, Rect2(tpos - Vector2(4, 18), tower_sz), false)

		if entities_by_row.has(y):
			var row_list: Array = entities_by_row[y]
			row_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["y"]) < float(b["y"]))
			for item in row_list:
				var ent = item["ref"]
				if is_instance_valid(ent) and ent.has_method("draw_entity_onto"):
					ent.draw_entity_onto(self)

	var torch_sz: Vector2 = ArtLoader.get_frame_size("wall_torch")
	for i in range(wall_torches.size()):
		var tc: Vector2i = wall_torches[i]
		var fl_phase: int = (anim_tick + i) % 3
		var is_side_wall: bool = (tc.x == -15 or tc.x == 14)
		var side_shift: float = (4.0 if tc.x == -15 else -4.0) if is_side_wall else 0.0
		var t_pos := Vector2(tc * CELL_SIZE) + Vector2(6.0 + side_shift, -5.0)
		draw_rect(Rect2(t_pos + Vector2(1, 3), Vector2(2, 5)), Color("#3b2516"), true)
		if is_side_wall:
			draw_rect(Rect2(t_pos + Vector2(-1 if tc.x == -15 else 2, 5), Vector2(2, 2)), Color("#4a4f59"), true)
		var spark_pos := Vector2(tc * CELL_SIZE) + Vector2(6.0 + side_shift + float(fl_phase - 1), -6.0 - float(fl_phase % 2))
		draw_rect(Rect2(spark_pos, Vector2(3, 3)), Color("#ff9429"), true)
		draw_rect(Rect2(spark_pos + Vector2(1, 1), Vector2(2, 2)), Color("#fff3b0"), true)

	for occ in occluded_draw_queue:
		var k: String = str(occ["kind"])
		var ref_node = occ["ref"]
		if not is_instance_valid(ref_node):
			continue
		if k == "player":
			ref_node.draw_occluded_silhouette(self, tex_hero_silhouette)
		elif k == "colonist":
			ref_node.draw_occluded_silhouette(self, tex_colonist_silhouette)
		elif k == "titan":
			ref_node.draw_occluded_silhouette(self)

	for sp in hit_sparks:
		var sp_pos: Vector2 = sp["pos"]
		var sp_col: Color = sp["col"]
		draw_rect(Rect2(sp_pos + Vector2(-2, -2), Vector2(3, 3)), sp_col, true)
		draw_rect(Rect2(sp_pos + Vector2(1, -1), Vector2(2, 2)), sp_col.lightened(0.35), true)

	if not build_mode_active and not player.is_dead:
		var near_inter: Dictionary = get_nearest_interactable()
		if not near_inter.is_empty():
			var icell: Vector2i = near_inter["cell"]
			var ipos := Vector2(icell * CELL_SIZE)
			var pulse_a: float = 0.65 + sin(float(Time.get_ticks_msec()) * 0.008) * 0.25
			draw_rect(Rect2(ipos - Vector2(1, 1), Vector2(18, 18)), Color(1.0, 0.82, 0.32, pulse_a), false, 1.5)
			var prompt_txt: String = str(near_inter.get("prompt", "[E]"))
			BuildSystem._draw_world_cursor_badge(self, ipos + Vector2(8, -10), prompt_txt, Color("#ffe699"), ThemeDB.fallback_font)

	_draw_auto_aim_reticle()
	BuildSystem.draw_build_ghost(self)

	var fort_rect := Rect2(Vector2(-15 * CELL_SIZE, -13 * CELL_SIZE), Vector2(30 * CELL_SIZE, 21 * CELL_SIZE))
	Phase1Visuals.draw_outside_atmosphere(self, fort_rect)

func _draw_roof_and_chimney_smoke(layer: Node2D) -> void:
	BuildSystem.draw_all_roofs(layer, self)
	if is_instance_valid(player) and is_actor_occluded_by_grid(player.global_position, false):
		player.draw_occluded_silhouette(layer, tex_hero_silhouette)

func _draw_top_left_portrait_and_bars(ctrl: Control) -> void:
	var s: SurvivalSystem = player.surv
	ctrl.draw_rect(Rect2(Vector2(0, 0), Vector2(204, 56)), Color(0.07, 0.07, 0.08, 0.94), true)
	ctrl.draw_rect(Rect2(Vector2(0, 0), Vector2(204, 56)), Color("#3b3733"), false, 1.5)
	ctrl.draw_rect(Rect2(Vector2(6, 6), Vector2(44, 44)), Color("#161514"), true)
	ctrl.draw_rect(Rect2(6, 6, 44, 44), Color("#524b44"), false, 1.5)
	if player and player.tex_idle:
		ctrl.draw_texture_rect(player.tex_idle, Rect2(Vector2(12, 8), Vector2(32, 40)), false)

	var bars := [
		{"ratio": clampf(s.hp / 100.0, 0.0, 1.0), "col": Color("#cc3b3b"), "y": 10.0, "icon": tex_ui_heart},
		{"ratio": clampf(s.hunger / 100.0, 0.0, 1.0), "col": Color("#d18c32"), "y": 24.0, "icon": tex_ui_food},
		{"ratio": clampf(s.thirst / 100.0, 0.0, 1.0), "col": Color("#4986b8"), "y": 38.0, "icon": tex_ui_water}
	]
	for b in bars:
		var by: float = float(b["y"])
		var bar_x: float = 58.0
		var bar_w: float = 134.0
		if b["icon"] != null:
			ctrl.draw_texture_rect(b["icon"], Rect2(Vector2(54, by - 3.0), Vector2(14, 14)), false)
			bar_x = 72.0
			bar_w = 120.0
		ctrl.draw_rect(Rect2(Vector2(bar_x, by), Vector2(bar_w, 9)), Color("#141416"), true)
		ctrl.draw_rect(Rect2(Vector2(bar_x, by), Vector2(bar_w * float(b["ratio"]), 9)), b["col"], true)
		ctrl.draw_rect(Rect2(Vector2(bar_x, by), Vector2(bar_w, 9)), Color("#2e2c2a"), false, 1.0)

func _draw_minimap(mm: Control) -> void:
	var rect := Rect2(Vector2.ZERO, mm.size)
	mm.draw_rect(rect, Color(0.07, 0.07, 0.08, 0.94), true)
	mm.draw_rect(rect, Color("#3b3733"), false, 1.5)
	var c: Vector2 = mm.size * 0.5
	mm.draw_rect(Rect2(c - Vector2(20, 16), Vector2(40, 26)), Color(0.42, 0.40, 0.38, 0.55), false, 1.0)
	mm.draw_line(Vector2(c.x, 14), Vector2(c.x, mm.size.y - 14), Color(0.28, 0.27, 0.26, 0.45), 1.0)
	mm.draw_line(Vector2(14, c.y), Vector2(mm.size.x - 14, c.y), Color(0.28, 0.27, 0.26, 0.45), 1.0)
	var font: Font = ThemeDB.fallback_font
	mm.draw_string(font, Vector2(c.x - 4, 12), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color("#b8b2a8"))
	mm.draw_string(font, Vector2(c.x - 4, mm.size.y - 3), "S", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color("#b8b2a8"))
	mm.draw_string(font, Vector2(4, c.y + 4), "W", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#b8b2a8"))
	mm.draw_string(font, Vector2(mm.size.x - 13, c.y + 4), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#b8b2a8"))

	for child in titans_layer.get_children():
		if child is TitanEntity and child.state != TitanEntity.State.DYING:
			var rel: Vector2 = (child.global_position - player.global_position) / float(CELL_SIZE)
			var pt: Vector2 = c + (rel * 1.45).limit_length(50.0)
			mm.draw_rect(Rect2(pt - Vector2(2, 2), Vector2(4, 4)), Color("#d94343"), true)
	mm.draw_rect(Rect2(c - Vector2(2, 2), Vector2(5, 5)), Color("#e8e2d8"), true)

func _draw_bottom_hotbar(hb: Control) -> void:
	var slot_w: float = BuildSystem.HOTBAR_SLOT_W
	var gap: float = BuildSystem.HOTBAR_GAP
	var total_w: float = 10.0 * slot_w + 9.0 * gap
	var start_x: float = (hb.size.x - total_w) * 0.5
	var font: Font = ThemeDB.fallback_font
	var icon_sz := Vector2(30, 30)

	# Если активна всплывающая боевая подсказка (при первом запуске или первом выстреле крюка), выводим её над хотбаром
	if combat_hint_timer > 0.0 and not build_mode_active:
		var hint_rect := Rect2(Vector2(start_x - 8, -30), Vector2(total_w + 16, 26))
		hb.draw_rect(hint_rect, Color(0.08, 0.11, 0.14, 0.94), true)
		hb.draw_rect(hint_rect, Color("#d99136"), false, 1.5)
		hb.draw_string(font, hint_rect.position + Vector2(10, 17), "💡 " + combat_hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ffe699"))
	else:
		BuildSystem.draw_build_banner(hb, self, start_x, total_w, font)

	hb.draw_rect(Rect2(Vector2(start_x - 8, 0), Vector2(total_w + 16, BuildSystem.HOTBAR_HEIGHT)), Color(0.07, 0.07, 0.08, 0.94), true)
	hb.draw_rect(Rect2(Vector2(start_x - 8, 0), Vector2(total_w + 16, BuildSystem.HOTBAR_HEIGHT)), Color("#3b3733"), false, 1.5)

	for i in range(10):
		var sx: float = start_x + float(i) * (slot_w + gap)
		var r := Rect2(Vector2(sx, 5), Vector2(slot_w, slot_w))
		var is_sel: bool = (i == selected_hotbar_slot)
		hb.draw_rect(r, Color("#29231d") if is_sel else Color("#141416"), true)
		hb.draw_rect(r, Color("#d99136") if is_sel else Color("#2e2c2a"), false, 2.5 if is_sel else 1.0)

		if build_mode_active:
			var b_id: int = int(build_hotbar_slots[i]) if i < build_hotbar_slots.size() else 0
			if b_id > 0 and blocks_db.has(str(b_id)):
				var b_tex: Texture2D = BuildSystem.get_preview_texture(self, b_id, Vector2i.ZERO)
				if b_tex != null:
					hb.draw_texture_rect(b_tex, Rect2(r.position + Vector2(14, 7), Vector2(26, 28)), false)
				var c_item: String = str(blocks_db[str(b_id)].get("cost_item", "wood"))
				var cnt: int = int(player.surv.inventory.get(c_item, 0))
				hb.draw_string(font, r.position + Vector2(slot_w - 24, slot_w - 5), str(cnt), HORIZONTAL_ALIGNMENT_RIGHT, 20, 11, Color("#ece5d8"))
		else:
			var s_data: Dictionary = combat_hotbar_slots[i] if i < combat_hotbar_slots.size() else {}
			var s_kind: String = str(s_data.get("kind", "empty"))
			if s_kind != "empty":
				var ic_idx: int = clampi(int(s_data.get("icon_idx", 0)), 0, tex_hotbar_icons.size() - 1)
				if not tex_hotbar_icons.is_empty() and tex_hotbar_icons[ic_idx] != null:
					hb.draw_texture_rect(tex_hotbar_icons[ic_idx], Rect2(r.position + Vector2((slot_w - icon_sz.x) * 0.5, 6), icon_sz), false)
				var s_id: String = str(s_data.get("id", ""))
				var cnt_str: String = ""
				if s_kind == "item":
					cnt_str = str(int(player.surv.inventory.get(s_id, 0)))
				elif s_id == "blades":
					cnt_str = "%d%%" % int(player.blade_durability)
				if cnt_str != "":
					hb.draw_string(font, r.position + Vector2(slot_w - 30, slot_w - 5), cnt_str, HORIZONTAL_ALIGNMENT_RIGHT, 26, 11, Color("#ece5d8"))

		hb.draw_string(font, r.position + Vector2(5, 13), str((i + 1) % 10), HORIZONTAL_ALIGNMENT_LEFT, 16, 10, Color("#9a9186"))

func _toggle_inventory_window() -> void:
	if player.is_dead:
		return
	if settings_panel and settings_panel.visible:
		settings_panel.visible = false
	if inv_panel:
		inv_panel.visible = not inv_panel.visible
		if inv_panel.visible:
			_refresh_inventory_ui()

func _toggle_settings_window() -> void:
	if player.is_dead:
		return
	if inv_panel and inv_panel.visible:
		inv_panel.visible = false
	if settings_panel:
		settings_panel.visible = not settings_panel.visible

func _move_selected_hotbar_slot(dir: int) -> void:
	var cur: int = selected_hotbar_slot
	var nxt: int = (cur + dir + 10) % 10
	if build_mode_active or current_bag_tab == 1:
		var tmp_b: int = build_hotbar_slots[cur]
		build_hotbar_slots[cur] = build_hotbar_slots[nxt]
		build_hotbar_slots[nxt] = tmp_b
		selected_hotbar_slot = nxt
		selected_block_id = int(build_hotbar_slots[nxt])
	else:
		var tmp_c: Dictionary = combat_hotbar_slots[cur]
		combat_hotbar_slots[cur] = combat_hotbar_slots[nxt]
		combat_hotbar_slots[nxt] = tmp_c
		selected_hotbar_slot = nxt
	play_sfx("ui")
	_refresh_inventory_ui()
	queue_redraw()

func _clear_selected_hotbar_slot() -> void:
	if build_mode_active or current_bag_tab == 1:
		build_hotbar_slots[selected_hotbar_slot] = 0
		selected_block_id = 0
	else:
		combat_hotbar_slots[selected_hotbar_slot] = {"kind": "empty", "id": "", "name": "Пустой слот", "icon_idx": 0}
	play_sfx("ui")
	_refresh_inventory_ui()
	queue_redraw()

func _get_icon_idx_for_item(item_id: String) -> int:
	match item_id:
		"core_stone", "ash", "scrap":
			return 5
		"wood", "campfire_kit", "workbench_kit":
			return 6
		"stone":
			return 7
		"herbs", "clean_water", "bandage", "antiseptic":
			return 8
		_:
			return 9

func _refresh_inventory_ui() -> void:
	if not inv_panel or not inv_panel.visible:
		return
	for ch in inv_list_box.get_children():
		ch.queue_free()
	for ch in detail_actions_box.get_children():
		ch.queue_free()

	if current_bag_tab == 0:
		var bag_entries: Array[Dictionary] = [
			{"kind": "tool", "id": "torch", "name": "🔥 Факел (освещение)", "desc": "Освещает путь в темноте и отпугивает ночных тварей.", "icon_idx": 0},
			{"kind": "tool", "id": "axe", "name": "🪓 Топор лесоруба", "desc": "Быстрая рубка деревьев в лесу (2 удара на дерево, +3 доски).", "icon_idx": 1},
			{"kind": "tool", "id": "pickaxe", "name": "⛏ Кирка каменотёса", "desc": "Добыча булыжника и остов-камня из валунов в лесу.", "icon_idx": 2},
			{"kind": "tool", "id": "blades", "name": "⚔ Парные клинки (%d%%)" % int(player.blade_durability), "desc": "Оружие против титанов. Запасных лезвий: %d." % player.spare_blades, "icon_idx": 3},
			{"kind": "tool", "id": "crossbow", "name": "🏹 Охотничий арбалет", "desc": "Дистанционное оружие поддержки.", "icon_idx": 4}
		]
		for item_id in player.surv.inventory.keys():
			var cnt: int = int(player.surv.inventory[item_id])
			if cnt <= 0:
				continue
			var i_info: Dictionary = player.surv.items_db.get(item_id, {"name": item_id, "type": "mat"})
			bag_entries.append({
				"kind": "item",
				"id": str(item_id),
				"count": cnt,
				"name": "%s  (x%d)" % [str(i_info.get("name", item_id)), cnt],
				"raw_name": str(i_info.get("name", item_id)),
				"type": str(i_info.get("type", "mat")),
				"desc": "Предмет в рюкзаке (тип: %s). Можно использовать или вынести на хотбар." % str(i_info.get("type", "материал")),
				"icon_idx": _get_icon_idx_for_item(str(item_id))
			})

		selected_bag_entry_index = clampi(selected_bag_entry_index, 0, maxi(0, bag_entries.size() - 1))
		for idx in range(bag_entries.size()):
			var entry: Dictionary = bag_entries[idx]
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(235, 36)
			btn.text = ("▶ " if idx == selected_bag_entry_index else "   ") + str(entry["name"])
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			var i_copy: int = idx
			btn.pressed.connect(func():
				selected_bag_entry_index = i_copy
				play_sfx("ui")
				_refresh_inventory_ui()
			)
			inv_list_box.add_child(btn)

		if selected_bag_entry_index < bag_entries.size():
			var sel: Dictionary = bag_entries[selected_bag_entry_index]
			lbl_detail_title.text = str(sel["name"])
			lbl_detail_desc.text = str(sel["desc"])
			var cur_slot_name: String = str(combat_hotbar_slots[selected_hotbar_slot].get("name", "Пусто"))
			lbl_detail_ing.text = "Выбранный слот хотбара [%d]:\n• %s" % [(selected_hotbar_slot + 1) % 10, cur_slot_name]

			if str(sel["kind"]) == "item":
				var item_id_str: String = str(sel["id"])
				var itype: String = str(sel.get("type", "mat"))
				if itype in ["food", "drink", "med", "placeable"]:
					var btn_use := Button.new()
					btn_use.custom_minimum_size = Vector2(200, 36)
					btn_use.text = "✔ Использовать / Установить"
					btn_use.pressed.connect(func():
						player.use_inventory_item(item_id_str)
						_refresh_inventory_ui()
					)
					detail_actions_box.add_child(btn_use)

				var btn_drop := Button.new()
				btn_drop.custom_minimum_size = Vector2(200, 34)
				btn_drop.text = "🗑 Выбросить 1 шт. из рюкзака"
				btn_drop.pressed.connect(func():
					player.surv.remove_item(item_id_str, 1)
					play_sfx("ui")
					_refresh_inventory_ui()
				)
				detail_actions_box.add_child(btn_drop)

			var btn_bind := Button.new()
			btn_bind.custom_minimum_size = Vector2(200, 36)
			btn_bind.text = "📌 Поставить в текущий слот [%d]" % ((selected_hotbar_slot + 1) % 10)
			btn_bind.pressed.connect(func():
				combat_hotbar_slots[selected_hotbar_slot] = {
					"kind": sel["kind"],
					"id": sel["id"],
					"name": sel.get("raw_name", sel["name"]),
					"icon_idx": int(sel.get("icon_idx", 6))
				}
				build_mode_active = false
				play_sfx("item")
				_refresh_inventory_ui()
				queue_redraw()
			)
			detail_actions_box.add_child(btn_bind)

	elif current_bag_tab == 1:
		var block_ids := [1, 2, 3, 4, 5, 6, 9, 10]
		selected_bag_entry_index = clampi(selected_bag_entry_index, 0, block_ids.size() - 1)
		for idx in range(block_ids.size()):
			var b_id: int = block_ids[idx]
			var b_info: Dictionary = blocks_db.get(str(b_id), {})
			var cost_id: String = str(b_info.get("cost_item", "wood"))
			var have_cnt: int = int(player.surv.inventory.get(cost_id, 0))
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(235, 36)
			btn.text = "%s[%d] %s (ресурс: %d)" % [("▶ " if idx == selected_bag_entry_index else "   "), b_id, str(b_info.get("name", "Блок")), have_cnt]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			var i_copy: int = idx
			btn.pressed.connect(func():
				selected_bag_entry_index = i_copy
				play_sfx("ui")
				_refresh_inventory_ui()
			)
			inv_list_box.add_child(btn)

		var sel_b_id: int = block_ids[selected_bag_entry_index]
		var sel_b_info: Dictionary = blocks_db.get(str(sel_b_id), {})
		var c_id: String = str(sel_b_info.get("cost_item", "wood"))
		var c_name: String = str(player.surv.items_db.get(c_id, {}).get("name", c_id))
		lbl_detail_title.text = "Блок: " + str(sel_b_info.get("name", "Блок"))
		lbl_detail_desc.text = "Прочность: %d HP  ·  Материал: %s (в наличии: %d)" % [
			int(sel_b_info.get("hp", 30)), c_name, int(player.surv.inventory.get(c_id, 0))
		]
		var cur_b_in_slot: int = int(build_hotbar_slots[selected_hotbar_slot])
		var cur_b_name: String = str(blocks_db.get(str(cur_b_in_slot), {}).get("name", "Пустой слот"))
		lbl_detail_ing.text = "Строительный слот [%d] сейчас:\n• %s" % [(selected_hotbar_slot + 1) % 10, cur_b_name]

		var btn_assign_b := Button.new()
		btn_assign_b.custom_minimum_size = Vector2(200, 38)
		btn_assign_b.text = "🔨 Назначить блок в слот [%d] и строить" % ((selected_hotbar_slot + 1) % 10)
		btn_assign_b.pressed.connect(func():
			build_hotbar_slots[selected_hotbar_slot] = sel_b_id
			selected_block_id = sel_b_id
			build_mode_active = true
			BuildSystem.has_touch_preview = false
			play_sfx("build")
			_refresh_inventory_ui()
			queue_redraw()
		)
		detail_actions_box.add_child(btn_assign_b)

	else:
		var recipes: Array = player.surv.recipes_db
		selected_recipe_index = clampi(selected_recipe_index, 0, maxi(0, recipes.size() - 1))
		for idx in range(recipes.size()):
			var rec: Dictionary = recipes[idx]
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(235, 36)
			btn.text = ("▶ ⚒ " if idx == selected_recipe_index else "   ⚒ ") + str(rec.get("name", "Рецепт"))
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			var i_copy: int = idx
			btn.pressed.connect(func():
				selected_recipe_index = i_copy
				play_sfx("ui")
				_refresh_inventory_ui()
			)
			inv_list_box.add_child(btn)

		if selected_recipe_index < recipes.size():
			var sel_rec: Dictionary = recipes[selected_recipe_index]
			lbl_detail_title.text = str(sel_rec.get("name", "Предмет"))
			lbl_detail_desc.text = "Создание снаряжения и припасов выжившего."
			var cost: Dictionary = sel_rec.get("cost", {})
			var ing_lines: Array[String] = []
			for ck in cost.keys():
				ing_lines.append("• %s: %d / %d" % [
					str(player.surv.items_db.get(ck, {}).get("name", ck)),
					int(player.surv.inventory.get(ck, 0)),
					int(cost[ck])
				])
			lbl_detail_ing.text = "Ингредиенты:\n" + "\n".join(ing_lines)

			var btn_craft := Button.new()
			btn_craft.custom_minimum_size = Vector2(200, 40)
			btn_craft.text = "⚒ Создать предмет"
			btn_craft.disabled = not player.surv.has_items(cost)
			btn_craft.pressed.connect(func():
				if player.surv.has_items(cost):
					for ck in cost.keys():
						player.surv.remove_item(str(ck), int(cost[ck]))
					var out_id: String = str(sel_rec.get("out", "wood"))
					var out_cnt: int = int(sel_rec.get("count", 1))
					player.surv.add_item(out_id, out_cnt)
					if player.surv.items_db.get(out_id, {}).get("type", "") == "placeable":
						player.use_inventory_item(out_id)
					play_sfx("build")
					_refresh_inventory_ui()
			)
			detail_actions_box.add_child(btn_craft)

	if current_bag_tab == 0 or current_bag_tab == 1:
		var slot_row := HBoxContainer.new()
		slot_row.add_theme_constant_override("separation", 6)
		detail_actions_box.add_child(slot_row)

		var btn_left := Button.new()
		btn_left.custom_minimum_size = Vector2(96, 34)
		btn_left.text = "◀ Сдвинуть"
		btn_left.pressed.connect(func(): _move_selected_hotbar_slot(-1))
		slot_row.add_child(btn_left)

		var btn_right := Button.new()
		btn_right.custom_minimum_size = Vector2(96, 34)
		btn_right.text = "Сдвинуть ▶"
		btn_right.pressed.connect(func(): _move_selected_hotbar_slot(1))
		slot_row.add_child(btn_right)

		var btn_clear := Button.new()
		btn_clear.custom_minimum_size = Vector2(200, 34)
		btn_clear.text = "✕ Очистить слот [%d] в хотбаре" % ((selected_hotbar_slot + 1) % 10)
		btn_clear.pressed.connect(func(): _clear_selected_hotbar_slot())
		detail_actions_box.add_child(btn_clear)

func _make_dark_card_style(border_col: Color = Color("#3b3733")) -> StyleBox:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.07, 0.07, 0.08, 0.95)
	st.border_color = border_col
	st.set_border_width_all(1)
	st.set_corner_radius_all(4)
	st.set_content_margin_all(12)
	return st

func _setup_reference_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	mobile_hud = MobileHUD.new()
	hud.add_child(mobile_hud)
	mobile_hud.setup(self)

	hud_bars_ctrl = Control.new()
	hud_bars_ctrl.position = Vector2(14, 14)
	hud_bars_ctrl.size = Vector2(204, 56)
	hud_bars_ctrl.draw.connect(func(): _draw_top_left_portrait_and_bars(hud_bars_ctrl))
	hud.add_child(hud_bars_ctrl)

	clock_card_ctrl = PanelContainer.new()
	clock_card_ctrl.position = Vector2(14, 76)
	clock_card_ctrl.custom_minimum_size = Vector2(150, 52)
	clock_card_ctrl.add_theme_stylebox_override("panel", _make_dark_card_style())
	hud.add_child(clock_card_ctrl)
	lbl_day_clock = Label.new()
	lbl_day_clock.add_theme_color_override("font_color", Color("#d8d2c8"))
	clock_card_ctrl.add_child(lbl_day_clock)

	quest_card_ctrl = PanelContainer.new()
	quest_card_ctrl.position = Vector2(14, 134)
	quest_card_ctrl.custom_minimum_size = Vector2(204, 74)
	quest_card_ctrl.add_theme_stylebox_override("panel", _make_dark_card_style())
	hud.add_child(quest_card_ctrl)
	lbl_quest_list = Label.new()
	lbl_quest_list.add_theme_color_override("font_color", Color("#ccc5bc"))
	quest_card_ctrl.add_child(lbl_quest_list)

	quick_bar_ctrl = HBoxContainer.new()
	quick_bar_ctrl.position = Vector2(14, 214)
	quick_bar_ctrl.add_theme_constant_override("separation", 5)
	hud.add_child(quick_bar_ctrl)

	var btn_phase := Button.new()
	btn_phase.custom_minimum_size = Vector2(82, 34)
	btn_phase.text = "День/Ночь"
	btn_phase.focus_mode = Control.FOCUS_NONE
	btn_phase.pressed.connect(func(): _cycle_day_night_weather())
	quick_bar_ctrl.add_child(btn_phase)

	var btn_wb := Button.new()
	btn_wb.custom_minimum_size = Vector2(82, 34)
	btn_wb.text = "Рюкзак"
	btn_wb.focus_mode = Control.FOCUS_NONE
	btn_wb.pressed.connect(func():
		play_sfx("ui")
		_toggle_inventory_window()
	)
	quick_bar_ctrl.add_child(btn_wb)

	var btn_build := Button.new()
	btn_build.custom_minimum_size = Vector2(82, 34)
	btn_build.text = "Стройка"
	btn_build.focus_mode = Control.FOCUS_NONE
	btn_build.pressed.connect(func():
		if player.is_dead:
			return
		build_mode_active = not build_mode_active
		BuildSystem.has_touch_preview = false
		selected_block_id = int(build_hotbar_slots[selected_hotbar_slot])
		player.release_hooks()
		play_sfx("ui")
	)
	quick_bar_ctrl.add_child(btn_build)

	var btn_cfg := Button.new()
	btn_cfg.custom_minimum_size = Vector2(92, 34)
	btn_cfg.text = "⚙ Настройки"
	btn_cfg.focus_mode = Control.FOCUS_NONE
	btn_cfg.pressed.connect(func():
		play_sfx("ui")
		_toggle_settings_window()
	)
	quick_bar_ctrl.add_child(btn_cfg)

	minimap_ctrl = Control.new()
	minimap_ctrl.size = Vector2(124, 124)
	minimap_ctrl.position = Vector2(1014, 14)
	minimap_ctrl.draw.connect(func(): _draw_minimap(minimap_ctrl))
	hud.add_child(minimap_ctrl)

	hotbar_ctrl = Control.new()
	hotbar_ctrl.size = Vector2(1152, BuildSystem.HOTBAR_HEIGHT)
	hotbar_ctrl.position = Vector2(0, 576)
	hotbar_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hotbar_ctrl.draw.connect(func(): _draw_bottom_hotbar(hotbar_ctrl))
	hud.add_child(hotbar_ctrl)

	alert_panel = PanelContainer.new()
	alert_panel.position = Vector2(885, 146)
	alert_panel.custom_minimum_size = Vector2(248, 70)
	alert_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_panel.add_theme_stylebox_override("panel", _make_dark_card_style(Color("#9e3333")))
	hud.add_child(alert_panel)
	var alert_vbox := VBoxContainer.new()
	alert_panel.add_child(alert_vbox)
	lbl_alert_title = Label.new()
	lbl_alert_title.text = "!  Титан рядом!"
	lbl_alert_title.add_theme_color_override("font_color", Color("#d94848"))
	alert_vbox.add_child(lbl_alert_title)
	lbl_alert_sub = Label.new()
	lbl_alert_sub.text = "Спрячься в тени или\nоставайся неподвижным."
	lbl_alert_sub.add_theme_color_override("font_color", Color("#c7bfb5"))
	alert_vbox.add_child(lbl_alert_sub)

	prompt_e_panel = PanelContainer.new()
	prompt_e_panel.visible = false
	prompt_e_panel.position = Vector2(460, 500)
	prompt_e_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_e_panel.add_theme_stylebox_override("panel", _make_dark_card_style(Color("#b88636")))
	hud.add_child(prompt_e_panel)
	var prompt_hbox := HBoxContainer.new()
	prompt_e_panel.add_child(prompt_hbox)
	if tex_ui_key_e != null:
		var key_rect := TextureRect.new()
		key_rect.texture = tex_ui_key_e
		key_rect.custom_minimum_size = Vector2(16, 16)
		key_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		prompt_hbox.add_child(key_rect)
	lbl_prompt_e = Label.new()
	prompt_hbox.add_child(lbl_prompt_e)

	_build_inventory_and_hotbar_modal(hud)
	_build_settings_modal(hud)
	_build_death_modal(hud)

func _build_death_modal(hud: CanvasLayer) -> void:
	death_panel = PanelContainer.new()
	death_panel.visible = false
	death_panel.custom_minimum_size = Vector2(380, 210)
	death_panel.position = Vector2(386, 210)
	death_panel.add_theme_stylebox_override("panel", _make_dark_card_style(Color("#b83b3b")))
	hud.add_child(death_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	death_panel.add_child(vbox)

	var title := Label.new()
	title.text = "☠  ВЫ ПОГИБЛИ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#e64848"))
	vbox.add_child(title)

	lbl_death_stats = Label.new()
	lbl_death_stats.text = "Титан сокрушил вас."
	lbl_death_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_death_stats.add_theme_color_override("font_color", Color("#d8d2c8"))
	vbox.add_child(lbl_death_stats)

	var btn_respawn := Button.new()
	btn_respawn.custom_minimum_size = Vector2(240, 44)
	btn_respawn.text = "↻  Возродиться в крепости"
	btn_respawn.pressed.connect(func(): respawn_player())
	vbox.add_child(btn_respawn)

func _build_inventory_and_hotbar_modal(hud: CanvasLayer) -> void:
	inv_panel = PanelContainer.new()
	inv_panel.visible = false
	inv_panel.position = Vector2(236, 76)
	inv_panel.custom_minimum_size = Vector2(680, 440)
	inv_panel.add_theme_stylebox_override("panel", _make_dark_card_style(Color("#524b44")))
	hud.add_child(inv_panel)

	var wb_vbox := VBoxContainer.new()
	wb_vbox.add_theme_constant_override("separation", 8)
	inv_panel.add_child(wb_vbox)

	var wb_top := HBoxContainer.new()
	wb_top.add_theme_constant_override("separation", 6)
	wb_vbox.add_child(wb_top)

	var tab_bag := Button.new()
	tab_bag.custom_minimum_size = Vector2(175, 36)
	tab_bag.text = "🎒 Рюкзак и Снаряжение"
	tab_bag.pressed.connect(func():
		current_bag_tab = 0
		play_sfx("ui")
		_refresh_inventory_ui()
	)
	wb_top.add_child(tab_bag)

	var tab_build := Button.new()
	tab_build.custom_minimum_size = Vector2(175, 36)
	tab_build.text = "🧱 Палитра стройки"
	tab_build.pressed.connect(func():
		current_bag_tab = 1
		play_sfx("ui")
		_refresh_inventory_ui()
	)
	wb_top.add_child(tab_build)

	var tab_craft := Button.new()
	tab_craft.custom_minimum_size = Vector2(155, 36)
	tab_craft.text = "⚒ Крафт (Верстак)"
	tab_craft.pressed.connect(func():
		current_bag_tab = 2
		play_sfx("ui")
		_refresh_inventory_ui()
	)
	wb_top.add_child(tab_craft)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wb_top.add_child(spacer)

	var btn_close := Button.new()
	btn_close.custom_minimum_size = Vector2(44, 36)
	btn_close.text = " ✕ "
	btn_close.pressed.connect(func():
		play_sfx("ui")
		inv_panel.visible = false
	)
	wb_top.add_child(btn_close)

	var wb_split := HBoxContainer.new()
	wb_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wb_split.add_theme_constant_override("separation", 10)
	wb_vbox.add_child(wb_split)

	var scroll_l := ScrollContainer.new()
	scroll_l.custom_minimum_size = Vector2(265, 340)
	wb_split.add_child(scroll_l)
	inv_list_box = VBoxContainer.new()
	inv_list_box.add_theme_constant_override("separation", 4)
	scroll_l.add_child(inv_list_box)

	var right_card := PanelContainer.new()
	right_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_card.add_theme_stylebox_override("panel", _make_dark_card_style(Color("#3b3733")))
	wb_split.add_child(right_card)

	var r_vbox := VBoxContainer.new()
	r_vbox.add_theme_constant_override("separation", 8)
	right_card.add_child(r_vbox)

	lbl_detail_title = Label.new()
	lbl_detail_title.add_theme_color_override("font_color", Color("#f2ead8"))
	r_vbox.add_child(lbl_detail_title)

	lbl_detail_desc = Label.new()
	lbl_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_detail_desc.add_theme_color_override("font_color", Color("#b8b0a4"))
	r_vbox.add_child(lbl_detail_desc)

	lbl_detail_ing = Label.new()
	lbl_detail_ing.add_theme_color_override("font_color", Color("#d99136"))
	r_vbox.add_child(lbl_detail_ing)

	detail_actions_box = VBoxContainer.new()
	detail_actions_box.add_theme_constant_override("separation", 6)
	r_vbox.add_child(detail_actions_box)

func _build_settings_modal(hud: CanvasLayer) -> void:
	settings_panel = PanelContainer.new()
	settings_panel.visible = false
	settings_panel.position = Vector2(256, 52)
	settings_panel.custom_minimum_size = Vector2(580, 476)
	settings_panel.add_theme_stylebox_override("panel", _make_dark_card_style(Color("#524b44")))
	hud.add_child(settings_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	settings_panel.add_child(root_vbox)

	var top_bar := HBoxContainer.new()
	root_vbox.add_child(top_bar)
	var title := Label.new()
	title.text = "⚙  Настройки игры и управления"
	title.add_theme_color_override("font_color", Color("#f2ead8"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)

	var btn_close := Button.new()
	btn_close.custom_minimum_size = Vector2(44, 34)
	btn_close.text = " ✕ "
	btn_close.pressed.connect(func():
		play_sfx("ui")
		settings_panel.visible = false
	)
	top_bar.add_child(btn_close)

	var sep := HSeparator.new()
	root_vbox.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	_add_slider_setting(list, "Громкость звука", 0.0, 1.0, 0.05, master_volume, func(v: float):
		master_volume = v
	)
	_add_slider_setting(list, "Скорость шага персонажа", 0.50, 1.40, 0.05, player.move_speed_mult, func(v: float):
		if is_instance_valid(player):
			player.move_speed_mult = v
	)
	_add_slider_setting(list, "Размер правых кнопок", 0.75, 1.35, 0.05, mobile_hud.button_scale, func(v: float):
		if mobile_hud:
			mobile_hud.button_scale = v
	)
	_add_slider_setting(list, "Размер виртуального джойстика", 0.85, 1.50, 0.05, mobile_hud.joy_size_scale, func(v: float):
		if mobile_hud:
			mobile_hud.joy_size_scale = v
	)
	_add_slider_setting(list, "Непрозрачность кнопок HUD", 0.40, 1.0, 0.05, mobile_hud.hud_opacity, func(v: float):
		if mobile_hud:
			mobile_hud.hud_opacity = v
	)
	_add_slider_setting(list, "Приближение камеры (Zoom)", 1.40, 2.80, 0.10, camera.zoom.x, func(v: float):
		if is_instance_valid(camera):
			camera.zoom = Vector2(v, v)
	)

	var row_sil := HBoxContainer.new()
	row_sil.add_theme_constant_override("separation", 10)
	list.add_child(row_sil)
	var lbl_sil := Label.new()
	lbl_sil.custom_minimum_size = Vector2(245, 28)
	lbl_sil.text = "Радиус контуров за стеной: %d кл." % int(round(silhouette_radius_cells))
	lbl_sil.add_theme_color_override("font_color", Color("#d8d2c8"))
	row_sil.add_child(lbl_sil)
	var sld_sil := HSlider.new()
	sld_sil.custom_minimum_size = Vector2(235, 28)
	sld_sil.min_value = 3.0
	sld_sil.max_value = 18.0
	sld_sil.step = 1.0
	sld_sil.value = silhouette_radius_cells
	sld_sil.value_changed.connect(func(val: float):
		silhouette_radius_cells = val
		lbl_sil.text = "Радиус контуров за стеной: %d кл." % int(round(val))
	)
	row_sil.add_child(sld_sil)

	var chk_float_joy := CheckButton.new()
	chk_float_joy.text = "Плавающий центр джойстика (подстраивается под палец)"
	chk_float_joy.button_pressed = mobile_hud.floating_joystick
	chk_float_joy.toggled.connect(func(on: bool):
		if mobile_hud:
			mobile_hud.floating_joystick = on
		play_sfx("ui")
	)
	list.add_child(chk_float_joy)

	var chk_aim := CheckButton.new()
	chk_aim.text = "Автоприцеливание на ближайшего титана / стену"
	chk_aim.button_pressed = mobile_hud.auto_aim_enabled
	chk_aim.toggled.connect(func(on: bool):
		if mobile_hud:
			mobile_hud.auto_aim_enabled = on
		play_sfx("ui")
	)
	list.add_child(chk_aim)

	var chk_shake := CheckButton.new()
	chk_shake.text = "Тряска экрана при ударах клинками"
	chk_shake.button_pressed = screen_shake_enabled
	chk_shake.toggled.connect(func(on: bool):
		screen_shake_enabled = on
		play_sfx("ui")
	)
	list.add_child(chk_shake)

func _add_slider_setting(parent: VBoxContainer, label_text: String, min_v: float, max_v: float, step_v: float, initial_v: float, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.custom_minimum_size = Vector2(245, 28)
	lbl.text = "%s: %d%%" % [label_text, int(round(initial_v * 100.0))]
	lbl.add_theme_color_override("font_color", Color("#d8d2c8"))
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(235, 28)
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.value = initial_v
	slider.value_changed.connect(func(val: float):
		lbl.text = "%s: %d%%" % [label_text, int(round(val * 100.0))]
		on_change.call(val)
	)
	row.add_child(slider)
