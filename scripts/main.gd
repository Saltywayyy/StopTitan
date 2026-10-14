extends Node2D

const CELL_SIZE: int = 16
const MAP_RADIUS: int = 65

var config: Dictionary = {}
var blocks_db: Dictionary = {}

var game_hour: float = 15.6
var game_day: int = 3
var time_scale_mult: float = 1.0
var real_sec_per_hour: float = 60.0

var current_weather: int = 0
var core_stones_placed: int = 2
var titans_killed_count: int = 0

var sky_modulate: CanvasModulate
var world_canvas: Node2D
var colonists_layer: Node2D
var titans_layer: Node2D
var fx_layer: Node2D
var player: PlayerController
var camera: Camera2D

var light_tex: ImageTexture
var player_light: PointLight2D
var campfire_lights: Array[PointLight2D] = []

# НАБОР ПИКСЕЛЬНЫХ ТЕКСТУР 16x16 (Пункты 1, 2 и 3 твоего списка!)
var tex_grass_variants: Array[ImageTexture] = [] # 5 вариантов травяных тайлов
var tex_dirt_variants: Array[ImageTexture] = []  # 2 варианта вытоптанной земли
var tex_path_tile: ImageTexture                  # Каменная дорожка между постройками
var tex_wood_floor: ImageTexture                 # Половые доски
var tex_garden_tile: ImageTexture                # Грядка с капустой
var tex_wall_variants: Array[ImageTexture] = []  # 4 вариации каменной стены с мхом и разной кладкой
var tex_tower: ImageTexture                      # Зубчатая башня
var tex_house_exterior: ImageTexture             # Детализированный Дом с черепицей, трубой, 2 окнами и дверью!
var tex_pine_day: ImageTexture
var tex_pine_snow: ImageTexture
var tex_bush: ImageTexture                       # Декоративный куст
var tex_rock: ImageTexture                       # Декоративный булыжник
var tex_well: ImageTexture                       # Пиксельный колодец (вместо круга!)
var tex_campfire: ImageTexture                   # Пиксельный костёр из брёвен и камней
var tex_crate: ImageTexture                      # Деревянный ящик

var sfx_player: AudioStreamPlayer
var sfx_playback: AudioStreamGeneratorPlayback

# ground_map: 0=трава, 1=вытоптанная земля у дома, 2=пол внутри дома, 3=грядка, 4=каменная дорожка, 5=снег
var ground_map: Dictionary = {}
var wall_map: Dictionary = {}
var decor_map: Dictionary = {} # Vector2i -> "bush" или "rock" (редкие кусты и камни!)
var ash_piles: Array[Vector2] = []

var water_well_cell := Vector2i(-5, 3)
var bed_cell := Vector2i(-12, -9)
var campfires: Array[Vector2i] = [Vector2i(-6, -8), Vector2i(-6, -1)]
var workbenches: Array[Vector2i] = [Vector2i(-10, -2), Vector2i(2, 1)]
var watchtowers: Array[Vector2i] = [Vector2i(-15, -13), Vector2i(14, -13), Vector2i(-15, 7), Vector2i(14, 7)]
var loot_crates: Dictionary = {}
var hit_sparks: Array[Dictionary] = []

var selected_block_id: int = 4
var selected_hotbar_slot: int = 0
var build_mode_active: bool = false
var screen_shake_amount: float = 0.0

var hud_bars_ctrl: Control
var lbl_day_clock: Label
var lbl_quest_list: Label
var minimap_ctrl: Control
var hotbar_ctrl: Control
var alert_panel: PanelContainer
var lbl_alert_title: Label
var lbl_alert_sub: Label
var prompt_e_panel: PanelContainer
var lbl_prompt_e: Label

var inv_panel: PanelContainer
var inv_recipes_box: VBoxContainer
var lbl_detail_title: Label
var lbl_detail_desc: Label
var lbl_detail_ing: Label
var btn_craft_action: Button
var selected_recipe_index: int = 0

func _ready() -> void:
	# Включаем жёсткую привязку к пиксельной сетке (никаких дробных сглаженных пикселей!)
	get_viewport().snap_2d_transforms_to_pixel = true
	get_viewport().snap_2d_vertices_to_pixel = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_load_config()
	_generate_all_pixel_art_tiles()
	_setup_procedural_audio()
	_setup_lighting()
	_setup_world_layer()
	_generate_fortress_from_reference()
	_setup_player()
	_spawn_campfire_point_lights()
	_spawn_initial_colonists()
	_spawn_initial_titans()
	_setup_reference_hud()

func _load_config() -> void:
	var file_path := "res://data/config.json"
	if FileAccess.file_exists(file_path):
		var text := FileAccess.get_file_as_string(file_path)
		var parsed = JSON.parse_string(text)
		if typeof(parsed) == TYPE_DICTIONARY:
			config = parsed
	blocks_db = config.get("blocks", {})

# ГЕНЕРАЦИЯ ВСЕХ ПОПИКСЕЛЬНЫХ ТАЙЛОВ И СПРАЙТОВ ПО СЕТКЕ 16x16
func _generate_all_pixel_art_tiles() -> void:
	# 1. Мягкий свет для PointLight2D
	var l_img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var center := Vector2(64, 64)
	for x in range(128):
		for y in range(128):
			var d: float = Vector2(x, y).distance_to(center) / 64.0
			l_img.set_pixel(x, y, Color(1, 1, 1, pow(clampf(1.0 - d, 0.0, 1.0), 2.2)))
	light_tex = ImageTexture.create_from_image(l_img)

	# 2. Пять вариантов травяных тайлов 16x16 (Пункт 3: спокойная база + редкие пиксельные пучки)
	for v in range(5):
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for x in range(16):
			for y in range(16):
				var n: int = ((x * 13 + y * 29 + v * 7) % 9)
				var col := Color("#233422") if n < 6 else Color("#1f2e1e")
				img.set_pixel(x, y, col)
		if v == 1 or v == 2:
			# Маленький аккуратный пучок травы из 4 пикселей
			var gx: int = 4 + v * 3
			var gy: int = 6 + v * 2
			img.set_pixel(gx, gy, Color("#334d30"))
			img.set_pixel(gx, gy - 1, Color("#3e5c39"))
			img.set_pixel(gx + 2, gy, Color("#334d30"))
		elif v == 3:
			# Редкий тёмный клевер/мох
			img.set_pixel(9, 10, Color("#192618"))
			img.set_pixel(10, 10, Color("#2f472d"))
		tex_grass_variants.append(ImageTexture.create_from_image(img))

	# 3. Вытоптанная земля около дома (2 варианта) и Каменная дорожка
	for v in range(2):
		var d_img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for x in range(16):
			for y in range(16):
				var n: int = ((x * 17 + y * 31 + v * 11) % 7)
				d_img.set_pixel(x, y, Color("#3b2e22") if n < 5 else Color("#33271c"))
		if v == 1:
			d_img.set_pixel(5, 8, Color("#4a3b2c"))
			d_img.set_pixel(6, 8, Color("#4a3b2c"))
		tex_dirt_variants.append(ImageTexture.create_from_image(d_img))

	# Каменная дорожка (брусчатка из отдельных округлых булыжников на земле)
	var p_img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	p_img.fill(Color("#362a1f"))
	var stones := [Rect2i(2, 2, 5, 4), Rect2i(9, 3, 5, 4), Rect2i(3, 9, 6, 5), Rect2i(10, 10, 4, 4)]
	for r in stones:
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				var edge: bool = (x == r.position.x or y == r.position.y or x == r.end.x - 1 or y == r.end.y - 1)
				p_img.set_pixel(x, y, Color("#1c1815") if edge else Color("#525861"))
	tex_path_tile = ImageTexture.create_from_image(p_img)

	# Деревянный пол и Грядка огорода
	var wf_img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(16):
		for y in range(16):
			wf_img.set_pixel(x, y, Color("#29190f") if (y == 7 or y == 15) else Color("#4a301d"))
	tex_wood_floor = ImageTexture.create_from_image(wf_img)

	var g_img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	g_img.fill(Color("#241911"))
	for x in range(2, 14):
		for y in range(2, 14):
			var d: int = abs(x - 8) + abs(y - 8)
			if d == 5:
				g_img.set_pixel(x, y, Color("#121619"))
			elif d < 5:
				g_img.set_pixel(x, y, Color("#568c44") if d <= 2 else Color("#345c2c"))
	tex_garden_tile = ImageTexture.create_from_image(g_img)

	# 4. Четыре вариации каменных стен 16x24 (Пункт 2: разные камни, трещины и мох!)
	for v in range(4):
		var w_img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
		var c_out := Color("#0f1318")
		var c_top := Color("#505866")
		var c_front := Color("#3a404a")
		var c_dark := Color("#2a2f37")
		var c_moss := Color("#2d472b")

		for x in range(16):
			for y in range(4, 24):
				if x == 0 or x == 15 or y == 4 or y == 23 or y == 12:
					w_img.set_pixel(x, y, c_out)
				elif y < 12:
					w_img.set_pixel(x, y, c_top)
				else:
					w_img.set_pixel(x, y, c_front if y < 19 else c_dark)

		# Индивидуальный рисунок камней и швов для каждого из 4 вариантов
		var seam_x1: int = 5 + (v * 3) % 6
		var seam_x2: int = 3 + ((v + 2) * 3) % 8
		for y in range(13, 18):
			w_img.set_pixel(seam_x1, y, c_out)
		for x in range(1, 15):
			w_img.set_pixel(x, 18, c_out)
		for y in range(19, 23):
			w_img.set_pixel(seam_x2, y, c_out)

		# Зубец сверху на чётных вариантах и пятна мха на варианте 2
		if v % 2 == 0:
			for x in range(3, 13):
				for y in range(0, 5):
					w_img.set_pixel(x, y, c_out if (x == 3 or x == 12 or y == 0) else c_top.lightened(0.08))
		if v == 1 or v == 3:
			w_img.set_pixel(seam_x1 + 1, 13, c_moss)
			w_img.set_pixel(seam_x1 + 2, 13, c_moss)
			w_img.set_pixel(seam_x1 + 1, 14, c_moss)

		tex_wall_variants.append(ImageTexture.create_from_image(w_img))

	# 5. Редкие пиксельные кусты и булыжники 16x16 (Пункт 3!)
	var b_img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(2, 14):
		for y in range(4, 15):
			var d: int = abs(x - 8) + abs(y - 10)
			if d == 6 or y == 14:
				b_img.set_pixel(x, y, Color("#0f1418"))
			elif d < 6:
				b_img.set_pixel(x, y, Color("#2f4f31") if y < 9 else Color("#1c3320"))
	b_img.set_pixel(6, 8, Color("#c94040")) # Ягодка
	b_img.set_pixel(10, 9, Color("#c94040"))
	tex_bush = ImageTexture.create_from_image(b_img)

	var r_img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(3, 13):
		for y in range(6, 14):
			var d: int = abs(x - 8) + abs(y - 10)
			if d == 5 or y == 13:
				r_img.set_pixel(x, y, Color("#0f1418"))
			elif d < 5:
				r_img.set_pixel(x, y, Color("#636b75") if y < 9 else Color("#434952"))
	tex_rock = ImageTexture.create_from_image(r_img)

	# 6. Пиксельный колодец 16x16, костёр 16x16 и ящик 16x16 (вместо векторных кругов!)
	var well_img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(1, 15):
		for y in range(2, 15):
			var d: int = abs(x - 8) + abs(y - 8)
			if d == 6 or d == 5:
				well_img.set_pixel(x, y, Color("#0f1318") if d == 6 else Color("#525a66"))
			elif d < 5:
				well_img.set_pixel(x, y, Color("#1b4661"))
	for x in range(2, 14):
		well_img.set_pixel(x, 2, Color("#5c3c24"))
		well_img.set_pixel(x, 3, Color("#422a18"))
	tex_well = ImageTexture.create_from_image(well_img)

	var cf_img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(3, 13):
		for y in range(8, 15):
			if abs(x - 8) + abs(y - 11) <= 5:
				cf_img.set_pixel(x, y, Color("#4a301d") if y > 10 else Color("#ff6d1c"))
	cf_img.set_pixel(8, 6, Color("#ffd54f"))
	cf_img.set_pixel(7, 7, Color("#ff9800"))
	cf_img.set_pixel(8, 7, Color("#fff176"))
	tex_campfire = ImageTexture.create_from_image(cf_img)

	var cr_img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(2, 14):
		for y in range(2, 14):
			var edge: bool = (x == 2 or x == 13 or y == 2 or y == 13 or y == 8)
			cr_img.set_pixel(x, y, Color("#121519") if edge else (Color("#8f612e") if y < 6 else Color("#734c22")))
	tex_crate = ImageTexture.create_from_image(cr_img)

	# 7. ПЕРЕРАБОТАННЫЙ ДОМ 144x96 (Пункт 2: контурная черепичная крыша, дымоход, дверь и 2 светящихся окна!)
	tex_house_exterior = _create_detailed_house_sprite()
	tex_pine_day = _create_procedural_pine_texture(false)
	tex_pine_snow = _create_procedural_pine_texture(true)

func _create_detailed_house_sprite() -> ImageTexture:
	var w: int = 144 # 9 клеток
	var h: int = 96  # 6 клеток
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_out := Color("#0e1217")
	var c_roof_top := Color("#6e3f28")
	var c_roof_mid := Color("#542f1e")
	var c_roof_dark := Color("#3b2014")
	var c_wall := Color("#47301f")
	var c_log := Color("#362315")
	var c_stone := Color("#434a54")

	# 1. Двускатная черепичная крыша с коньком и ступенчатым пиксельным контуром (y: 8..60)
	for y in range(8, 62):
		var margin: int = max(0, (24 - y) / 2)
		for x in range(margin, w - margin):
			var is_border: bool = (x == margin or x == w - margin - 1 or y == 8 or y == 61 or y == 14)
			if is_border:
				img.set_pixel(x, y, c_out)
			elif y < 14:
				img.set_pixel(x, y, c_roof_top) # Деревянный конёк крыши
			else:
				# Пиксельная чешуя черепицы (арочный узор каждые 6x6 пикселей)
				var tile_row: bool = (y % 7 == 0)
				var tile_col: bool = ((x + (y / 7) * 3) % 6 == 0)
				if tile_row or tile_col:
					img.set_pixel(x, y, c_roof_dark)
				else:
					img.set_pixel(x, y, c_roof_mid if y < 44 else c_roof_dark.lightened(0.05))

	# 2. Каменный дымоход на правой части крыши (x: 104..120, y: 0..28)
	for x in range(104, 121):
		for y in range(0, 28):
			var edge: bool = (x == 104 or x == 120 or y == 0 or y == 27 or y == 4)
			if edge:
				img.set_pixel(x, y, c_out)
			else:
				img.set_pixel(x, y, c_stone.lightened(0.1) if y < 4 else (c_stone if (x + y) % 5 != 0 else c_stone.darkened(0.2)))

	# 3. Бревенчатый фасад стены с каменным цоколем внизу (y: 62..95, x: 4..140)
	for x in range(4, w - 4):
		for y in range(62, h):
			if x == 4 or x == w - 5 or y == h - 1:
				img.set_pixel(x, y, c_out)
			elif y >= h - 7:
				img.set_pixel(x, y, c_stone if (x % 8 != 0) else c_out)
			elif y % 5 == 0:
				img.set_pixel(x, y, c_log)
			else:
				img.set_pixel(x, y, c_wall)

	# 4. Деревянная дверь с коваными петлями и порогом (x: 56..76, y: 66..95)
	for x in range(56, 77):
		for y in range(66, h):
			if x == 56 or x == 76 or y == 66:
				img.set_pixel(x, y, c_out)
			elif (x - 56) % 5 == 0:
				img.set_pixel(x, y, Color("#24150c"))
			else:
				img.set_pixel(x, y, Color("#633d22"))
	# Ручка-кольцо и петли на двери
	img.set_pixel(72, 80, Color("#d4a349"))
	img.set_pixel(72, 81, Color("#d4a349"))

	# 5. ДВА СВЕТЯЩИХСЯ ОКНА со ставнями слева и справа от двери (x: 20..38 и x: 96..114)
	for wx in [20, 96]:
		for x in range(wx, wx + 19):
			for y in range(68, 84):
				var border: bool = (x == wx or x == wx + 18 or y == 68 or y == 83)
				var cross: bool = (x == wx + 9 or y == 75)
				if border or cross:
					img.set_pixel(x, y, c_out)
				else:
					var glow := Color("#ffab40") if (y < 75 and x < wx + 9) else Color("#ff8f00")
					img.set_pixel(x, y, glow)

	return ImageTexture.create_from_image(img)

func _create_procedural_pine_texture(snowy: bool) -> ImageTexture:
	var w: int = 32
	var h: int = 44
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var outline := Color("#0f1419")
	var trunk_c := Color("#422c1d")
	var c_dark := Color("#16281e") if not snowy else Color("#3e5466")
	var c_mid := Color("#213d2b") if not snowy else Color("#6e879c")
	var c_light := Color("#2f5439") if not snowy else Color("#d8e4f0")

	for x in range(13, 19):
		for y in range(34, 43):
			img.set_pixel(x, y, outline if (x == 13 or x == 18 or y == 42) else trunk_c)

	var tiers := [
		{"top": 2, "bot": 15, "max_r": 7},
		{"top": 9, "bot": 23, "max_r": 10},
		{"top": 17, "bot": 31, "max_r": 13},
		{"top": 24, "bot": 37, "max_r": 14}
	]
	for t in tiers:
		var top_y: int = int(t["top"])
		var bot_y: int = int(t["bot"])
		var max_r: int = int(t["max_r"])
		for y in range(top_y, bot_y + 1):
			var prog: float = float(y - top_y) / float(bot_y - top_y)
			var jag: int = ((y * 7) % 3) - 1
			var half_w: int = clampi(int(round(prog * float(max_r))) + jag, 1, 15)
			for x in range(16 - half_w, 16 + half_w + 1):
				var is_edge: bool = (x == 16 - half_w or x == 16 + half_w or y == bot_y)
				if is_edge:
					img.set_pixel(x, y, outline)
				else:
					var h_val: int = ((x * 19 + y * 37) % 10)
					var col := c_mid
					if y < top_y + 4 or (x < 15 and h_val < 4):
						col = c_light
					elif y > bot_y - 3 or x > 17 or h_val > 6:
						col = c_dark
					img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

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
	if sfx_playback == null:
		return
	var rate: float = 22050.0
	var samples: int = mini(2000, sfx_playback.get_frames_available())
	for i in range(samples):
		var t: float = float(i) / rate
		var env: float = clampf(1.0 - (float(i) / float(samples)), 0.0, 1.0)
		var sig: float = sin(TAU * 380.0 * t) * 0.2 * env
		if kind == "hit" or kind == "roar":
			sig = (sin(TAU * 110.0 * t) + randf_range(-0.5, 0.5)) * 0.32 * env
		sfx_playback.push_frame(Vector2(sig, sig))

func _setup_lighting() -> void:
	sky_modulate = CanvasModulate.new()
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

# СТРОИМ КРЕПОСТЬ С ДОРОЖКАМИ МЕЖДУ ПОСТРОЙКАМИ, ВЫТОПТАННЫМ ДВОРОМ, КУСТАМИ И ВАЛУНАМИ
func _generate_fortress_from_reference() -> void:
	for x in range(-MAP_RADIUS, MAP_RADIUS + 1):
		for y in range(-MAP_RADIUS, MAP_RADIUS + 1):
			var c := Vector2i(x, y)
			ground_map[c] = 5 if y < -26 else 0

			# Редкие кусты и камни на траве (Пункт 3: не забиваем каждый пиксель, только ~6% клеток!)
			var h_val: int = abs((x * 73856093) ^ (y * 19349663)) % 100
			if (x < -16 or x > 15 or y < -14 or y > 8) and h_val < 5:
				decor_map[c] = "bush" if h_val < 3 else "rock"

	# Внутри крепости: трава по краям, вытоптанная земля около дома (-12..-3, -6..0) и КАМЕННЫЕ ДОРОЖКИ между постройками!
	for x in range(-12, -2):
		for y in range(-6, 1):
			ground_map[Vector2i(x, y)] = 1 # Вытоптанная площадка перед крыльцом дома

	# Каменная дорожка от крыльца дома (-9, -5) к колодцу, огороду (5, -4) и южным воротам (0, 7)
	for y in range(-5, 3):
		ground_map[Vector2i(-9, y)] = 4
	for x in range(-9, 6):
		ground_map[Vector2i(x, -2)] = 4
	for y in range(-2, 8):
		ground_map[Vector2i(0, y)] = 4

	# Кусты и камни во дворе крепости (в углах у стен)
	decor_map[Vector2i(-13, 4)] = "bush"
	decor_map[Vector2i(-12, 5)] = "rock"
	decor_map[Vector2i(11, -11)] = "bush"
	decor_map[Vector2i(12, 4)] = "bush"
	decor_map[Vector2i(3, -10)] = "rock"

	# Каменный периметр стены
	for x in range(-15, 15):
		if abs(x) > 1:
			_set_block(Vector2i(x, -13), 4, false)
			_set_block(Vector2i(x, 7), 4, false)
		else:
			_set_block(Vector2i(x, 7), 6, false)
	for y in range(-13, 8):
		_set_block(Vector2i(-15, y), 4, false)
		_set_block(Vector2i(14, y), 4, false)

	# Главный жилой дом (-13..-5, -11..-6)
	for x in range(-13, -4):
		for y in range(-11, -5):
			ground_map[Vector2i(x, y)] = 2
			var border: bool = (x == -13 or x == -5 or y == -11 or y == -6)
			if border and Vector2i(x, y) != Vector2i(-9, -6):
				_set_block(Vector2i(x, y), 2, false)
	_set_block(Vector2i(-9, -6), 6, false)

	# Огород 4x3
	for gx in range(5, 10):
		for gy in range(-7, -3):
			ground_map[Vector2i(gx, gy)] = 3

	# Еловый лес снаружи стен
	for x in range(-50, 52, 4):
		for y in range(-45, 45, 4):
			if x >= -18 and x <= 17 and y >= -17 and y <= 11:
				continue
			var tx: int = x + ((y * 5) % 2)
			var ty: int = y + ((x * 7) % 2)
			if (abs(tx * 13 + ty * 7) % 10) < 6:
				_set_block(Vector2i(tx, ty), 8, false)
				decor_map.erase(Vector2i(tx, ty))

	loot_crates[Vector2i(11, -9)] = ["wood", "wood", "stone", "canned_food"]
	loot_crates[Vector2i(-12, 2)] = ["raw_meat", "herbs", "scrap", "wood"]
	loot_crates[Vector2i(9, 3)] = ["canned_food", "cloth", "wood", "stone"]

func _set_block(cell: Vector2i, b_id: int, recalc_support: bool = true) -> void:
	var b_info: Dictionary = blocks_db.get(str(b_id), {"hp": 30, "solid": true})
	if not bool(b_info.get("solid", true)):
		ground_map[cell] = 2
		queue_redraw()
		return

	_remove_wall(cell, false)
	var body := StaticBody2D.new()
	body.position = Vector2(cell * CELL_SIZE) + Vector2(8, 8)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(CELL_SIZE, CELL_SIZE)
	col.shape = rect
	body.add_child(col)
	world_canvas.add_child(body)

	wall_map[cell] = {
		"id": b_id,
		"hp": int(b_info.get("hp", 30)),
		"max_hp": int(b_info.get("hp", 30)),
		"is_door": bool(b_info.get("is_door", false)),
		"door_open": false,
		"hookable": bool(b_info.get("hookable", true)),
		"drop": str(b_info.get("drop", "wood")),
		"body": body,
		"col": col
	}
	if recalc_support and (b_id == 4 or b_id == 2 or b_id == 1):
		core_stones_placed = mini(5, core_stones_placed + 1)
	queue_redraw()

func _remove_wall(cell: Vector2i, _recalc_support: bool = true) -> void:
	if wall_map.has(cell):
		var body: StaticBody2D = wall_map[cell].get("body")
		if is_instance_valid(body):
			body.queue_free()
		wall_map.erase(cell)
		queue_redraw()

func _setup_player() -> void:
	player = PlayerController.new()
	player.position = Vector2(-6 * CELL_SIZE, -1 * CELL_SIZE)
	player.world_ref = self
	add_child(player)
	player.apply_config(config)
	player.surv.add_item("wood", 12)
	player.surv.add_item("stone", 8)

	player_light = PointLight2D.new()
	player_light.texture = light_tex
	player_light.texture_scale = 2.0
	player_light.color = Color("#ffaa44")
	player_light.energy = 0.25
	player.add_child(player_light)

	camera = Camera2D.new()
	# КРУПНЫЕ ЧЁТКИЕ ПИКСЕЛИ (Пункт 1: Zoom 3.0x кратно пиксельной сетке!)
	camera.zoom = Vector2(3.0, 3.0)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)

func _spawn_campfire_point_lights() -> void:
	for ch in campfire_lights:
		if is_instance_valid(ch):
			ch.queue_free()
	campfire_lights.clear()
	for fc in campfires:
		var pl := PointLight2D.new()
		pl.position = Vector2(fc * CELL_SIZE) + Vector2(8, 8)
		pl.texture = light_tex
		pl.texture_scale = 2.2
		pl.color = Color("#ff8c2b")
		pl.energy = 0.45
		add_child(pl)
		campfire_lights.append(pl)

func _spawn_initial_colonists() -> void:
	var list: Array = [
		{ "name": "Анна", "prof": "Врач", "trait": "Целитель", "role": "cook_med", "x": -7, "y": -8 },
		{ "name": "Борн", "prof": "Плотник", "trait": "Мастер", "role": "gather", "x": 1, "y": 0 },
		{ "name": "Ворон", "prof": "Солдат", "trait": "Смелый", "role": "guard", "x": 4, "y": 2 }
	]
	for item in list:
		var c := ColonistEntity.new()
		c.position = Vector2(float(item["x"]) * CELL_SIZE, float(item["y"]) * CELL_SIZE)
		c.world_ref = self
		c.player_ref = player
		c.home_pos = Vector2(-2 * CELL_SIZE, 0)
		c.setup_profile(str(item["name"]), str(item["prof"]), str(item["trait"]), str(item["role"]), true)
		colonists_layer.add_child(c)

func get_recruited_colonists() -> Array[ColonistEntity]:
	var res: Array[ColonistEntity] = []
	for ch in colonists_layer.get_children():
		if ch is ColonistEntity and ch.is_recruited:
			res.append(ch)
	return res

func colonist_shoot_nearest_titan(origin: Vector2, max_range: float, dmg: float) -> Dictionary:
	for child in titans_layer.get_children():
		if child is TitanEntity and child.state != TitanEntity.State.DYING and child.state != TitanEntity.State.DORMANT:
			if origin.distance_to(child.global_position) <= max_range:
				child.nape_hp -= dmg
				if child.nape_hp <= 0.0:
					child.nape_hp = 0.0
					child.state = TitanEntity.State.DYING
				return {"hit": true, "pos": child.global_position}
	return {"hit": false}

func _spawn_initial_titans() -> void:
	spawn_titan_at(Vector2(-8 * CELL_SIZE, -16 * CELL_SIZE), "wanderer")
	spawn_titan_at(Vector2(8 * CELL_SIZE, -16 * CELL_SIZE), "wanderer")
	spawn_titan_at(Vector2(19 * CELL_SIZE, -2 * CELL_SIZE), "wanderer")
	spawn_titan_at(Vector2(-19 * CELL_SIZE, 2 * CELL_SIZE), "crawler")

func spawn_titan_at(pos: Vector2, p_type: String) -> void:
	var t := TitanEntity.new()
	t.position = pos
	t.world_ref = self
	t.player_ref = player
	var t_cfg: Dictionary = config.get("titans", {}).get(p_type, {})
	t.apply_config(t_cfg, p_type)
	titans_layer.add_child(t)

func raycast_hook_anchor(origin: Vector2, dir: Vector2, max_dist: float) -> Dictionary:
	var d: float = 10.0
	while d <= max_dist:
		var pt: Vector2 = origin + dir * d
		for child in titans_layer.get_children():
			if child is TitanEntity and child.state != TitanEntity.State.DYING:
				if pt.distance_to(child.global_position) <= 15.0:
					return {"hit": true, "pos": child.global_position}
		var c: Vector2i = _world_to_cell(pt)
		if wall_map.has(c) and bool(wall_map[c].get("hookable", true)):
			return {"hit": true, "pos": Vector2(c * CELL_SIZE) + Vector2(8, 8)}
		d += 6.0
	return {"hit": false}

func player_slash_attack(origin: Vector2, _look_dir: Vector2, speed: float, base_dmg: float, max_spd: float) -> Dictionary:
	var best_res := {"hit": false}
	for child in titans_layer.get_children():
		if child is TitanEntity and child.state != TitanEntity.State.DYING:
			if origin.distance_to(child.global_position) <= 40.0:
				var res: Dictionary = child.take_blade_hit(origin, speed, base_dmg, max_spd)
				if bool(res.get("hit", false)):
					best_res = res
					screen_shake_amount = 5.0
					play_sfx("hit")
					break
	return best_res

func on_titan_killed(pos: Vector2) -> void:
	ash_piles.append(pos)
	titans_killed_count += 1
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

func _process(delta: float) -> void:
	_update_game_clock_and_survival(delta)
	_update_camera_shake(delta)
	_update_cursor_and_input()
	if fx_layer:
		fx_layer.queue_redraw()
	if hud_bars_ctrl:
		hud_bars_ctrl.queue_redraw()
	if minimap_ctrl:
		minimap_ctrl.queue_redraw()
	if hotbar_ctrl:
		hotbar_ctrl.queue_redraw()
	queue_redraw()

func _update_game_clock_and_survival(delta: float) -> void:
	var sleep_mult: float = 6.0 if player.surv.is_sleeping else 1.0
	var hours_passed: float = (delta / real_sec_per_hour) * time_scale_mult * sleep_mult
	game_hour += hours_passed
	if game_hour >= 24.0:
		game_hour -= 24.0
		game_day += 1

	var is_night: bool = (game_hour >= 20.0 or game_hour < 5.5)
	var p_cell: Vector2i = _world_to_cell(player.global_position)
	var inside_shelter: bool = (int(ground_map.get(p_cell, 0)) == 2)
	var near_fire: bool = _is_near_station(campfires, 3.8)
	var near_titan: bool = _is_titan_nearby(14.0)
	var is_winter_zone: bool = (p_cell.y < -26 or current_weather == 3)

	var target_light_energy: float = 1.15 if is_night else 0.25
	if is_instance_valid(player_light):
		player_light.energy = lerpf(player_light.energy, target_light_energy, delta * 4.0)
	for pl in campfire_lights:
		if is_instance_valid(pl):
			pl.energy = lerpf(pl.energy, 1.2 if is_night else 0.4, delta * 4.0)

	player.surv.update_survival(delta, hours_passed, is_night, near_fire, inside_shelter, near_titan, 1.2, -12.0 if is_winter_zone else 0.0, false)

	var target_mod := Color("#b5afa2")
	var icon_str: String = "☀ День"
	if is_winter_zone:
		icon_str = "❄ Зима"
		target_mod = Color("#a8b8cc")
	elif game_hour >= 20.0 or game_hour < 5.5:
		icon_str = "🌙 Ночь"
		target_mod = Color("#182232")

	sky_modulate.color = sky_modulate.color.lerp(target_mod, delta * 3.0)

	var hh: int = int(floor(game_hour))
	var mm: int = int(floor((game_hour - float(hh)) * 60.0))
	if lbl_day_clock:
		lbl_day_clock.text = "%s · День %d\n%02d:%02d" % [icon_str, game_day, hh, mm]

	if lbl_quest_list:
		var q1_mark: String = "☑" if core_stones_placed >= 5 else "☐"
		var w_cnt: int = int(player.surv.inventory.get("wood", 0))
		var q2_mark: String = "☑" if w_cnt >= 10 else "☐"
		lbl_quest_list.text = "%s Построить стену (%d/5)\n%s Собрать доски (%d/10)" % [
			q1_mark, core_stones_placed, q2_mark, mini(w_cnt, 10)
		]

	if alert_panel:
		alert_panel.visible = near_titan or is_winter_zone

	if prompt_e_panel:
		if p_cell.distance_to(bed_cell) <= 2.5:
			prompt_e_panel.visible = true
			lbl_prompt_e.text = "[E] Спать"
		elif _is_near_station(workbenches, 2.5):
			prompt_e_panel.visible = true
			lbl_prompt_e.text = "[E] Верстак"
		else:
			prompt_e_panel.visible = false

func _update_camera_shake(delta: float) -> void:
	if screen_shake_amount > 0.1:
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * screen_shake_amount
		screen_shake_amount = move_toward(screen_shake_amount, 0.0, 28.0 * delta)
	else:
		camera.offset = Vector2.ZERO

func _world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / float(CELL_SIZE)), floor(pos.y / float(CELL_SIZE)))

func interact_nearby() -> void:
	var pc: Vector2i = _world_to_cell(player.global_position)
	if pc.distance_to(bed_cell) <= 2.8:
		player.surv.is_sleeping = not player.surv.is_sleeping
		return
	if _is_near_station(workbenches, 2.8):
		_toggle_inventory_window()
		return
	for x in range(pc.x - 2, pc.x + 3):
		for y in range(pc.y - 2, pc.y + 3):
			var c := Vector2i(x, y)
			if wall_map.has(c) and bool(wall_map[c].get("is_door", false)):
				var w: Dictionary = wall_map[c]
				var is_op: bool = not bool(w.get("door_open", false))
				w["door_open"] = is_op
				var col: CollisionShape2D = w.get("col")
				if is_instance_valid(col):
					col.disabled = is_op
				play_sfx("build")
				queue_redraw()
				return
	for crate_cell in loot_crates.keys():
		if Vector2(pc).distance_to(Vector2(crate_cell)) <= 2.5:
			for item_id in loot_crates[crate_cell]:
				player.surv.add_item(str(item_id), 1)
			loot_crates.erase(crate_cell)
			play_sfx("item")
			return
	if Vector2(pc).distance_to(Vector2(water_well_cell)) <= 2.8:
		player.surv.add_item("clean_water", 1)
		player.surv.thirst = minf(100.0, player.surv.thirst + 35.0)
		play_sfx("item")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.keycode == KEY_I:
			_toggle_inventory_window()
		elif event.keycode == KEY_V or event.keycode == KEY_E:
			interact_nearby()
		elif event.keycode == KEY_B:
			build_mode_active = not build_mode_active
			player.release_hooks()
		elif event.keycode == KEY_T:
			if game_hour < 18.0:
				game_hour = 22.2
			elif current_weather != 3:
				current_weather = 3
				game_hour = 8.3
			else:
				current_weather = 0
				game_hour = 15.6

func _update_cursor_and_input() -> void:
	for i in range(1, 10):
		if Input.is_key_pressed(KEY_0 + i):
			selected_hotbar_slot = i - 1
			selected_block_id = mini(i, 8)

	if inv_panel and inv_panel.visible:
		return

	var viewport_mouse: Vector2 = get_viewport().get_mouse_position()
	var vp_size: Vector2 = get_viewport_rect().size
	if viewport_mouse.y > vp_size.y - 95.0:
		return

	var world_mouse: Vector2 = get_global_mouse_position()
	if not build_mode_active:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if not player.hook_left_active:
				player.fire_hook(true, world_mouse)
		else:
			player.hook_left_active = false
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if not player.hook_right_active:
				player.fire_hook(false, world_mouse)
		else:
			player.hook_right_active = false

# ОТРИСОВКА МИРА СТРОГО ПО РАСТРОВЫМ ПИКСЕЛЬНЫМ ТАЙЛАМ 16x16!
func _draw() -> void:
	var p_cell: Vector2i = _world_to_cell(player.global_position)
	var view_w: int = 22
	var view_h: int = 14
	var is_winter: bool = (current_weather == 3 or p_cell.y < -26)

	# 1. Рисуем 5 вариантов травы, вытоптанную землю у дома, каменные дорожки и грядки
	for x in range(p_cell.x - view_w, p_cell.x + view_w + 1):
		for y in range(p_cell.y - view_h, p_cell.y + view_h + 1):
			var c := Vector2i(x, y)
			var pos := Vector2(c * CELL_SIZE)
			var g_type: int = int(ground_map.get(c, 0))
			var v_idx: int = abs((x * 37 + y * 13)) % 5

			if is_winter and g_type != 2:
				draw_rect(Rect2(pos, Vector2(16, 16)), Color("#a8b8cc"), true)
			elif g_type == 0:
				draw_texture(tex_grass_variants[v_idx], pos)
			elif g_type == 1:
				draw_texture(tex_dirt_variants[v_idx % 2], pos)
			elif g_type == 2:
				draw_texture(tex_wood_floor, pos)
			elif g_type == 3:
				draw_texture(tex_garden_tile, pos)
			elif g_type == 4:
				draw_texture(tex_path_tile, pos)

			# Редкие кусты и валуны поверх земли
			if decor_map.has(c):
				var kind: String = str(decor_map[c])
				draw_texture(tex_bush if kind == "bush" else tex_rock, pos)

	# 2. Пиксельная мебель, колодец, костры и ящики (никаких векторных кругов!)
	draw_texture(tex_well, Vector2(water_well_cell * CELL_SIZE))
	for fc in campfires:
		draw_texture(tex_campfire, Vector2(fc * CELL_SIZE))
	for wb_cell in workbenches:
		draw_texture(tex_crate, Vector2(wb_cell * CELL_SIZE))
	for crate_cell in loot_crates.keys():
		draw_texture(tex_crate, Vector2(crate_cell * CELL_SIZE))

	# 3. Стены (4 разные вариации камней и мха!) и попиксельные ели
	var pine_tex: ImageTexture = tex_pine_snow if is_winter else tex_pine_day
	for y in range(p_cell.y - view_h, p_cell.y + view_h + 1):
		for x in range(p_cell.x - view_w, p_cell.x + view_w + 1):
			var c := Vector2i(x, y)
			if not wall_map.has(c):
				continue
			var w_data: Dictionary = wall_map[c]
			var b_id: int = int(w_data.get("id", 1))
			var pos := Vector2(c * CELL_SIZE)

			if bool(w_data.get("is_door", false)) and bool(w_data.get("door_open", false)):
				continue

			if b_id == 8:
				draw_texture(pine_tex, pos + Vector2(-8, -28))
				continue

			# Скрываем блоки фасада дома, когда рисуется цельный пиксельный спрайт Дома снаружи
			var is_house_wall: bool = (x >= -13 and x <= -5 and y >= -11 and y <= -6)
			var player_in_house: bool = (p_cell.x >= -13 and p_cell.x <= -5 and p_cell.y >= -11 and p_cell.y <= -6)
			if is_house_wall and not player_in_house:
				continue

			var wall_var: int = abs(x * 19 + y * 7) % 4
			draw_texture(tex_wall_variants[wall_var], pos + Vector2(0, -8))

	# 4. Угловые зубчатые башни
	for tw in watchtowers:
		var tpos := Vector2(tw * CELL_SIZE)
		draw_rect(Rect2(tpos - Vector2(4, 18), Vector2(24, 32)), Color("#0f1318"), true)
		draw_rect(Rect2(tpos - Vector2(3, 17), Vector2(22, 30)), Color("#3d4450"), true)
		draw_rect(Rect2(tpos - Vector2(5, 21), Vector2(26, 7)), Color("#0f1318"), true)
		draw_rect(Rect2(tpos - Vector2(4, 20), Vector2(24, 5)), Color("#525b69"), true)
		draw_rect(Rect2(tpos + Vector2(2, -8), Vector2(3, 6)), Color("#0f1318"), true)
		draw_rect(Rect2(tpos + Vector2(11, -8), Vector2(3, 6)), Color("#0f1318"), true)

# ЦЕЛЬНЫЙ ПИКСЕЛЬНЫЙ СПРАЙТ ДОМА С КРЫШЕЙ, ДЫМОХОДОМ, ДВЕРЬЮ И 2 ОКНАМИ (Пункт 2!)
func _draw_roof_and_chimney_smoke(layer: Node2D) -> void:
	var p_cell: Vector2i = _world_to_cell(player.global_position)
	var player_in_house: bool = (p_cell.x >= -13 and p_cell.x <= -5 and p_cell.y >= -11 and p_cell.y <= -6)

	if not player_in_house and tex_house_exterior != null:
		var h_pos := Vector2(-13 * CELL_SIZE, -11 * CELL_SIZE)
		layer.draw_texture(tex_house_exterior, h_pos)
		# Пиксельные клубы дыма из каменного дымохода
		var t_sec: float = float(Time.get_ticks_msec()) * 0.002
		for i in range(3):
			var dy: float = fmod(t_sec * 8.0 + float(i) * 6.0, 18.0)
			var dx: float = sin(t_sec + float(i)) * 3.0
			var smoke_pt := h_pos + Vector2(112 + int(dx), -4 - int(dy))
			layer.draw_rect(Rect2(smoke_pt, Vector2(4, 4)), Color(0.8, 0.84, 0.88, 0.45 - dy * 0.02), true)

func _draw_top_left_portrait_and_bars(ctrl: Control) -> void:
	var s: SurvivalSystem = player.surv
	ctrl.draw_rect(Rect2(Vector2(0, 0), Vector2(196, 54)), Color(0.08, 0.10, 0.13, 0.92), true)
	ctrl.draw_rect(Rect2(Vector2(0, 0), Vector2(196, 54)), Color(0.26, 0.30, 0.36, 0.9), false, 1.5)
	ctrl.draw_rect(Rect2(Vector2(6, 6), Vector2(42, 42)), Color("#1c222b"), true)
	ctrl.draw_rect(Rect2(Vector2(6, 6), Vector2(42, 42)), Color("#525c6b"), false, 1.5)
	if player and player.tex_idle:
		ctrl.draw_texture_rect(player.tex_idle, Rect2(Vector2(11, 8), Vector2(32, 38)), false)

	var bars := [
		{"ratio": clampf(s.hp / 100.0, 0.0, 1.0), "col": Color("#d94343"), "y": 11.0},
		{"ratio": clampf(s.hunger / 100.0, 0.0, 1.0), "col": Color("#d99b38"), "y": 25.0},
		{"ratio": clampf(s.thirst / 100.0, 0.0, 1.0), "col": Color("#3b8cd9"), "y": 39.0}
	]
	for b in bars:
		var by: float = float(b["y"])
		ctrl.draw_rect(Rect2(Vector2(56, by), Vector2(128, 8)), Color("#1b2028"), true)
		ctrl.draw_rect(Rect2(Vector2(56, by), Vector2(128.0 * float(b["ratio"]), 8)), b["col"], true)

func _draw_minimap(mm: Control) -> void:
	var rect := Rect2(Vector2.ZERO, mm.size)
	mm.draw_rect(rect, Color(0.07, 0.09, 0.12, 0.92), true)
	mm.draw_rect(rect, Color(0.38, 0.44, 0.52, 0.9), false, 1.5)
	var c: Vector2 = mm.size * 0.5
	mm.draw_line(Vector2(c.x, 14), Vector2(c.x, mm.size.y - 14), Color(0.3, 0.36, 0.42, 0.45), 1.0)
	mm.draw_line(Vector2(14, c.y), Vector2(mm.size.x - 14, c.y), Color(0.3, 0.36, 0.42, 0.45), 1.0)
	var font: Font = ThemeDB.fallback_font
	mm.draw_string(font, Vector2(c.x - 4, 12), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color("#d0d8e0"))
	mm.draw_string(font, Vector2(c.x - 4, mm.size.y - 3), "S", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color("#d0d8e0"))
	mm.draw_string(font, Vector2(4, c.y + 4), "W", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#d0d8e0"))
	mm.draw_string(font, Vector2(mm.size.x - 13, c.y + 4), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#d0d8e0"))

	for child in titans_layer.get_children():
		if child is TitanEntity and child.state != TitanEntity.State.DYING:
			var rel: Vector2 = (child.global_position - player.global_position) / float(CELL_SIZE)
			var pt: Vector2 = c + (rel * 1.45).limit_length(52.0)
			mm.draw_rect(Rect2(pt - Vector2(2, 2), Vector2(4, 4)), Color("#ff5252"), true)
	mm.draw_rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), Color("#ffffff"), true)

func _draw_bottom_hotbar(hb: Control) -> void:
	var slot_w: float = 44.0
	var gap: float = 4.0
	var total_w: float = 10.0 * slot_w + 9.0 * gap
	var start_x: float = (hb.size.x - total_w) * 0.5
	var font: Font = ThemeDB.fallback_font

	hb.draw_rect(Rect2(Vector2(start_x - 6, 0), Vector2(total_w + 12, 52)), Color(0.07, 0.09, 0.12, 0.92), true)
	hb.draw_rect(Rect2(Vector2(start_x - 6, 0), Vector2(total_w + 12, 52)), Color(0.28, 0.33, 0.40, 0.9), false, 1.5)

	var counts := [2, 3, player.spare_blades, int(player.surv.inventory.get("wood", 0)), int(player.surv.inventory.get("stone", 0)), 7, 4, 2, core_stones_placed, 1]
	for i in range(10):
		var sx: float = start_x + float(i) * (slot_w + gap)
		var r := Rect2(Vector2(sx, 4), Vector2(slot_w, 44))
		var is_sel: bool = (i == selected_hotbar_slot)
		hb.draw_rect(r, Color("#1b222c") if is_sel else Color("#12161d"), true)
		hb.draw_rect(r, Color("#70a8ff") if is_sel else Color("#2c3440"), false, 2.0 if is_sel else 1.0)
		hb.draw_rect(Rect2(r.position + Vector2(14, 12), Vector2(16, 16)), Color("#6e7b8b") if i > 4 else Color("#9e7348"), true)
		hb.draw_string(font, r.position + Vector2(26, 40), str(counts[i]), HORIZONTAL_ALIGNMENT_RIGHT, 14, 11, Color("#d8e0e8"))

func _toggle_inventory_window() -> void:
	if inv_panel:
		inv_panel.visible = not inv_panel.visible
		if inv_panel.visible:
			_refresh_inventory_ui()

func _refresh_inventory_ui() -> void:
	if not inv_panel or not inv_panel.visible:
		return
	for ch in inv_recipes_box.get_children():
		ch.queue_free()
	var recipes: Array = player.surv.recipes_db
	for idx in range(recipes.size()):
		var rec: Dictionary = recipes[idx]
		var btn := Button.new()
		btn.text = "  ⚒  " + str(rec.get("name", "Рецепт"))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var i_copy: int = idx
		btn.pressed.connect(func():
			selected_recipe_index = i_copy
			_refresh_inventory_ui()
		)
		inv_recipes_box.add_child(btn)

	if selected_recipe_index >= 0 and selected_recipe_index < recipes.size():
		var sel_rec: Dictionary = recipes[selected_recipe_index]
		lbl_detail_title.text = str(sel_rec.get("name", "Предмет"))
		lbl_detail_desc.text = "Основной строительный и походный материал выжившего."
		var cost: Dictionary = sel_rec.get("cost", {})
		var ing_lines: Array[String] = []
		for ck in cost.keys():
			ing_lines.append("• %s: %d/%d" % [str(player.surv.items_db.get(ck, {}).get("name", ck)), int(player.surv.inventory.get(ck, 0)), int(cost[ck])])
		lbl_detail_ing.text = "Ингредиенты:\n" + "\n".join(ing_lines)
		btn_craft_action.disabled = not player.surv.has_items(cost)

func _make_dark_card_style(border_col: Color = Color(0.26, 0.31, 0.38, 0.9)) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.10, 0.13, 0.92)
	st.border_color = border_col
	st.set_border_width_all(1)
	st.set_corner_radius_all(6)
	st.set_content_margin_all(10)
	return st

func _setup_reference_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	hud_bars_ctrl = Control.new()
	hud_bars_ctrl.position = Vector2(14, 14)
	hud_bars_ctrl.size = Vector2(200, 56)
	hud_bars_ctrl.draw.connect(func(): _draw_top_left_portrait_and_bars(hud_bars_ctrl))
	hud.add_child(hud_bars_ctrl)

	var clock_card := PanelContainer.new()
	clock_card.position = Vector2(14, 76)
	clock_card.custom_minimum_size = Vector2(165, 52)
	clock_card.add_theme_stylebox_override("panel", _make_dark_card_style())
	hud.add_child(clock_card)
	lbl_day_clock = Label.new()
	clock_card.add_child(lbl_day_clock)

	var quest_card := PanelContainer.new()
	quest_card.position = Vector2(14, 134)
	quest_card.custom_minimum_size = Vector2(196, 62)
	quest_card.add_theme_stylebox_override("panel", _make_dark_card_style())
	hud.add_child(quest_card)
	lbl_quest_list = Label.new()
	quest_card.add_child(lbl_quest_list)

	var quick_bar := HBoxContainer.new()
	quick_bar.position = Vector2(14, 204)
	hud.add_child(quick_bar)

	var btn_phase := Button.new()
	btn_phase.text = "День/Ночь/Зима (T)"
	btn_phase.focus_mode = Control.FOCUS_NONE
	btn_phase.pressed.connect(func():
		if game_hour < 18.0:
			game_hour = 22.2
		elif current_weather != 3:
			current_weather = 3
			game_hour = 8.3
		else:
			current_weather = 0
			game_hour = 15.6
	)
	quick_bar.add_child(btn_phase)

	var btn_wb := Button.new()
	btn_wb.text = "Верстак (Tab)"
	btn_wb.focus_mode = Control.FOCUS_NONE
	btn_wb.pressed.connect(func(): _toggle_inventory_window())
	quick_bar.add_child(btn_wb)

	minimap_ctrl = Control.new()
	minimap_ctrl.size = Vector2(124, 124)
	minimap_ctrl.position = Vector2(1010, 14)
	minimap_ctrl.draw.connect(func(): _draw_minimap(minimap_ctrl))
	hud.add_child(minimap_ctrl)

	hotbar_ctrl = Control.new()
	hotbar_ctrl.size = Vector2(1152, 56)
	hotbar_ctrl.position = Vector2(0, 582)
	hotbar_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hotbar_ctrl.draw.connect(func(): _draw_bottom_hotbar(hotbar_ctrl))
	hud.add_child(hotbar_ctrl)

	alert_panel = PanelContainer.new()
	alert_panel.position = Vector2(885, 495)
	alert_panel.custom_minimum_size = Vector2(248, 74)
	alert_panel.add_theme_stylebox_override("panel", _make_dark_card_style(Color("#ff5252")))
	hud.add_child(alert_panel)
	var alert_vbox := VBoxContainer.new()
	alert_panel.add_child(alert_vbox)
	lbl_alert_title = Label.new()
	lbl_alert_title.text = "!  Титан рядом!"
	lbl_alert_title.add_theme_color_override("font_color", Color("#ff5252"))
	alert_vbox.add_child(lbl_alert_title)
	lbl_alert_sub = Label.new()
	lbl_alert_sub.text = "Спрячься в тени или\nоставайся неподвижным."
	alert_vbox.add_child(lbl_alert_sub)

	prompt_e_panel = PanelContainer.new()
	prompt_e_panel.visible = false
	prompt_e_panel.position = Vector2(540, 290)
	prompt_e_panel.add_theme_stylebox_override("panel", _make_dark_card_style(Color("#ffd166")))
	hud.add_child(prompt_e_panel)
	lbl_prompt_e = Label.new()
	prompt_e_panel.add_child(lbl_prompt_e)

	inv_panel = PanelContainer.new()
	inv_panel.visible = false
	inv_panel.position = Vector2(260, 120)
	inv_panel.custom_minimum_size = Vector2(620, 380)
	inv_panel.add_theme_stylebox_override("panel", _make_dark_card_style(Color("#455266")))
	hud.add_child(inv_panel)

	var wb_vbox := VBoxContainer.new()
	inv_panel.add_child(wb_vbox)
	var wb_top := HBoxContainer.new()
	wb_vbox.add_child(wb_top)
	var wb_title := Label.new()
	wb_title.text = "Верстак"
	wb_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wb_top.add_child(wb_title)
	var btn_close := Button.new()
	btn_close.text = " ✕ "
	btn_close.pressed.connect(func(): inv_panel.visible = false)
	wb_top.add_child(btn_close)

	var wb_split := HBoxContainer.new()
	wb_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wb_vbox.add_child(wb_split)
	var scroll_l := ScrollContainer.new()
	scroll_l.custom_minimum_size = Vector2(250, 300)
	wb_split.add_child(scroll_l)
	inv_recipes_box = VBoxContainer.new()
	scroll_l.add_child(inv_recipes_box)

	var right_card := PanelContainer.new()
	right_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_card.add_theme_stylebox_override("panel", _make_dark_card_style(Color("#2d3644")))
	wb_split.add_child(right_card)
	var r_vbox := VBoxContainer.new()
	right_card.add_child(r_vbox)
	lbl_detail_title = Label.new()
	r_vbox.add_child(lbl_detail_title)
	lbl_detail_desc = Label.new()
	r_vbox.add_child(lbl_detail_desc)
	lbl_detail_ing = Label.new()
	r_vbox.add_child(lbl_detail_ing)
	btn_craft_action = Button.new()
	btn_craft_action.text = "Создать"
	btn_craft_action.pressed.connect(func():
		var recipes: Array = player.surv.recipes_db
		if selected_recipe_index >= 0 and selected_recipe_index < recipes.size():
			var rec: Dictionary = recipes[selected_recipe_index]
			var cost: Dictionary = rec.get("cost", {})
			if player.surv.has_items(cost):
				for ck in cost.keys():
					player.surv.remove_item(str(ck), int(cost[ck]))
				player.surv.add_item(str(rec.get("out", "wood")), int(rec.get("count", 1)))
				play_sfx("build")
				_refresh_inventory_ui()
	)
	r_vbox.add_child(btn_craft_action)
