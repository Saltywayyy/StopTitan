@warning_ignore("integer_division")
class_name PlayerController
extends CharacterBody2D

const GRAB_ESCAPE_TAPS_REQUIRED: int = 4
const GRAB_DAMAGE_PER_SEC: float = 22.0

var walk_speed: float = 62.0
var run_speed: float = 105.0
var crouch_speed: float = 36.0
var move_speed_mult: float = 0.85
var slash_reach_cells: float = 1.65

var max_range_px: float = 288.0
var pull_accel: float = 420.0
var gas_boost_accel: float = 580.0
var max_swing_speed: float = 340.0

var gas: float = 100.0
var gas_max: float = 100.0
var gas_boost_cost: float = 14.0
var gas_reel_cost: float = 5.0

var blade_dmg: float = 35.0
var blade_durability: float = 100.0
var spare_blades: int = 4
var rope_durability: float = 100.0
var focus: float = 100.0

var hook_left_active: bool = false
var hook_left_pos: Vector2 = Vector2.ZERO
var hook_left_timer: float = 0.0
var hook_right_active: bool = false
var hook_right_pos: Vector2 = Vector2.ZERO
var hook_right_timer: float = 0.0
var is_gas_boosting: bool = false
var hook_wall_stuck_timer: float = 0.0
var hook_hint_shown: bool = false

var is_crouching: bool = false
var is_running: bool = false
var current_noise_radius: float = 0.0
var look_direction: Vector2 = Vector2.DOWN
var facing_left: bool = false
var z_height: float = 0.0
var z_velocity: float = 0.0
var torch_lit: bool = true

var walk_anim_phase: float = 0.0
var attack_anim_timer: float = 0.0
var attack_anim_duration: float = 0.24
var combo_stage: int = 0
var combo_reset_timer: float = 0.0
var last_combat_msg: String = "Днём — прячься. Ночью — добывай."

var is_grabbed: bool = false
var grabbing_titan: Node2D = null
var grab_timer: float = 0.0
var grab_escape_progress: int = 0
var is_dead: bool = false
var _escape_key_was_down: bool = false

var world_ref: Node2D
var surv: SurvivalSystem

# ПУНКТ 3.1: 4-направленные текстуры взрослого разведчика (0=Вниз, 1=Вверх/Спина, 2=Профиль/Вбок)
var tex_down_frames: Array[ImageTexture] = []
var tex_up_frames: Array[ImageTexture] = []
var tex_side_frames: Array[ImageTexture] = []

var tex_idle: Texture2D
var tex_walk1: Texture2D
var tex_walk2: Texture2D
var using_external_hero_png: bool = false

var mobile_move_vec: Vector2 = Vector2.ZERO
var mobile_jump_queued: bool = false
var mobile_run_toggle: bool = false
var mobile_crouch_toggle: bool = false
var mobile_gas_held: bool = false
var mobile_attack_queued: bool = false

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var col_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.5
	col_shape.shape = circle
	add_child(col_shape)

	if surv == null:
		surv = SurvivalSystem.new()
		add_child(surv)

	tex_down_frames.clear()
	tex_up_frames.clear()
	tex_side_frames.clear()
	for f in range(3):
		tex_down_frames.append(_build_directional_scout_sprite(0, f))
		tex_up_frames.append(_build_directional_scout_sprite(1, f))
		tex_side_frames.append(_build_directional_scout_sprite(2, f))

	tex_idle = tex_down_frames[0]
	tex_walk1 = tex_down_frames[1]
	tex_walk2 = tex_down_frames[2]
	using_external_hero_png = false

# ПУНКТ 3.1: Серьёзный взрослый разведчик 16x24 (взрослые пропорции, тёмно-оливковый плащ,
# кожаная куртка корпуса разведки, перекрещенные ремни снаряжения, стальные ножны УПМ на бёдрах)
func _build_directional_scout_sprite(dir_idx: int, frame: int) -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	var c_out := Color("#121316")
	var c_skin := Color("#d6ab83")
	var c_skin_sh := Color("#ad825d")
	var c_hair := Color("#1e1713")
	var c_cloak_dk := Color("#1a261b")
	var c_cloak := Color("#253626")
	var c_cloak_hi := Color("#354d36")
	var c_jacket := Color("#5c4028")
	var c_jacket_sh := Color("#422d1b")
	var c_shirt := Color("#363a40")
	var c_strap := Color("#c7bfb3")
	var c_buckle := Color("#d9a74a")
	var c_gear_steel := Color("#7a8491")
	var c_gear_hi := Color("#aeb8c4")
	var c_pants := Color("#23272e")
	var c_boot := Color("#161413")
	var c_scarf := Color("#5e2c25")

	var l_off: int = -1 if frame == 1 else (1 if frame == 2 else 0)
	var r_off: int = 1 if frame == 1 else (-1 if frame == 2 else 0)
	var bob: int = 1 if frame != 0 else 0

	# 1. ГОЛОВА И ПРИЧЁСКА РАЗВЕДЧИКА (компактная взрослая голова y=1..8)
	var hx0: int = 5 if dir_idx == 2 else 4
	var hx1: int = 11 if dir_idx == 2 else 11
	for x in range(hx0, hx1 + 1):
		for y in range(1 + bob, 9 + bob):
			var is_b: bool = (x == hx0 or x == hx1 or y == 1 + bob or y == 8 + bob)
			if is_b:
				img.set_pixel(x, y, c_out)
			elif dir_idx == 1:
				# Вид со спины: тёмные волосы и ворот капюшона
				img.set_pixel(x, y, c_hair if y < 7 + bob else c_cloak_dk)
			elif dir_idx == 2:
				# Профиль (смотрит вправо)
				if y <= 3 + bob or x <= 7 or (y <= 5 + bob and x <= 8):
					img.set_pixel(x, y, c_hair)
				else:
					img.set_pixel(x, y, c_skin if x >= 9 else c_skin_sh)
			else:
				# Анфас: строгая чёлка и скулы
				if y <= 3 + bob or x == hx0 + 1 or (x == hx1 - 1 and y <= 4 + bob):
					img.set_pixel(x, y, c_hair)
				else:
					img.set_pixel(x, y, c_skin if y < 7 + bob else c_skin_sh)

	if dir_idx == 0:
		img.set_pixel(6, 5 + bob, c_out)
		img.set_pixel(9, 5 + bob, c_out)
	elif dir_idx == 2:
		img.set_pixel(9, 5 + bob, c_out)

	# 2. ТОРС, ТЁМНЫЙ ПЛАЩ РАЗВЕДКОРПУСА И РЕМНИ СНАРЯЖЕНИЯ (y=8..16)
	var tx0: int = 4 if dir_idx == 2 else 3
	var tx1: int = 12 if dir_idx == 2 else 12
	for x in range(tx0, tx1 + 1):
		for y in range(8 + bob, 17 + bob):
			var edge: bool = (x == tx0 or x == tx1 or y == 16 + bob)
			if edge:
				img.set_pixel(x, y, c_out)
			elif y == 8 + bob or (y == 9 + bob and x >= 5 and x <= 10):
				img.set_pixel(x, y, c_cloak_dk if dir_idx == 1 else c_scarf)
			elif dir_idx == 1:
				# Спина: тёмно-зелёный плащ со складками и перекрестием ремней УПМ
				var is_back_strap: bool = (y >= 11 + bob and (x == y - 4 or x == 20 - y))
				if is_back_strap:
					img.set_pixel(x, y, c_strap)
				elif x == 5 or x == 10:
					img.set_pixel(x, y, c_cloak_dk)
				elif y <= 11 + bob:
					img.set_pixel(x, y, c_cloak_hi if (x == 7 or x == 8) else c_cloak)
				else:
					img.set_pixel(x, y, c_cloak)
			elif dir_idx == 2:
				# Профиль: плечо плаща слева, кожаная куртка и ремень справа
				if x <= 7:
					img.set_pixel(x, y, c_cloak_hi if x == 5 else c_cloak)
				elif y == 14 + bob:
					img.set_pixel(x, y, c_buckle if x == 10 else c_boot)
				elif x == 9 and y >= 10 + bob:
					img.set_pixel(x, y, c_strap)
				else:
					img.set_pixel(x, y, c_jacket if y < 13 + bob else c_jacket_sh)
			else:
				# Анфас: распахнутый на плечах плащ, куртка, ремни портупеи и пряжка
				if y == 14 + bob:
					img.set_pixel(x, y, c_buckle if (x == 7 or x == 8) else c_boot)
				elif x == 4 or x == 11:
					img.set_pixel(x, y, c_cloak_hi if x == 4 else c_cloak)
				elif (x == 6 and y >= 10 + bob) or (x == 9 and y >= 10 + bob):
					img.set_pixel(x, y, c_strap)
				elif x == 7 or x == 8:
					img.set_pixel(x, y, c_shirt)
				else:
					img.set_pixel(x, y, c_jacket if x < 8 else c_jacket_sh)

	# 3. СТАЛЬНЫЕ НОЖНЫ И БАЛЛОНЫ УПМ НА БЁДРАХ (выразительный силуэт!)
	if dir_idx != 2:
		for sy in range(13 + bob, 19 + bob):
			img.set_pixel(2, sy, c_out if (sy == 13 + bob or sy == 18 + bob) else c_gear_hi)
			img.set_pixel(3, sy, c_gear_steel)
			img.set_pixel(12, sy, c_gear_steel)
			img.set_pixel(13, sy, c_out if (sy == 13 + bob or sy == 18 + bob) else c_gear_steel)
	else:
		# В профиль ножны идут наискосок вдоль бедра
		for i in range(5):
			var gx: int = 5 + i
			var gy: int = 13 + bob + i
			img.set_pixel(gx, gy, c_gear_hi)
			img.set_pixel(gx, gy + 1, c_out)

	# 4. НОГИ И ВЫСОКИЕ САПОГИ РАЗВЕДЧИКА (y=17..23)
	if dir_idx == 2:
		# Шаг в профиль
		for x in range(5, 9):
			for y in range(17, 23 + l_off):
				if y < 24:
					var edge_l: bool = (x == 5 or x == 8 or y == 22 + l_off)
					img.set_pixel(x, y, c_out if edge_l else (c_boot if y >= 19 else c_pants))
		for x in range(7, 11):
			for y in range(17, 23 + r_off):
				if y < 24:
					var edge_r: bool = (x == 7 or x == 10 or y == 22 + r_off)
					img.set_pixel(x, y, c_out if edge_r else (c_boot if y >= 19 else c_pants))
	else:
		for x in range(4, 8):
			for y in range(17, 23 + l_off):
				if y < 24:
					var edge_l: bool = (x == 4 or x == 7 or y == 22 + l_off)
					img.set_pixel(x, y, c_out if edge_l else (c_boot if y >= 19 else c_pants))
		for x in range(8, 12):
			for y in range(17, 23 + r_off):
				if y < 24:
					var edge_r: bool = (x == 8 or x == 11 or y == 22 + r_off)
					img.set_pixel(x, y, c_out if edge_r else (c_boot if y >= 19 else c_pants))

	return ImageTexture.create_from_image(img)

func apply_config(full_cfg: Dictionary) -> void:
	if surv == null:
		surv = SurvivalSystem.new()
		add_child(surv)
	surv.setup(full_cfg)

	var p_cfg: Dictionary = full_cfg.get("player", {})
	var w_cfg: Dictionary = full_cfg.get("web_gear", {})

	walk_speed = float(p_cfg.get("walk_speed", 80.0)) * 0.72
	run_speed = float(p_cfg.get("run_speed", 140.0)) * 0.70
	crouch_speed = float(p_cfg.get("crouch_speed", 45.0)) * 0.75
	slash_reach_cells = float(p_cfg.get("slash_reach_cells", 1.65))

	if not w_cfg.is_empty():
		max_range_px = float(w_cfg.get("max_range_cells", 18.0)) * 16.0
		pull_accel = float(w_cfg.get("pull_accel", 420.0))
		gas_boost_accel = float(w_cfg.get("gas_boost_accel", 580.0))
		max_swing_speed = float(w_cfg.get("max_swing_speed", 340.0))
		gas_max = float(w_cfg.get("gas_max", 100.0))
		gas = gas_max
		blade_dmg = float(w_cfg.get("blade_base_damage", 35.0))
		spare_blades = int(w_cfg.get("spare_blades", 4))

func use_inventory_item(item_id: String) -> void:
	if is_dead or not surv.items_db.has(item_id):
		return
	if int(surv.inventory.get(item_id, 0)) <= 0:
		return

	var info: Dictionary = surv.items_db[item_id]
	var itype: String = str(info.get("type", "mat"))

	if itype == "food" or itype == "drink" or itype == "med":
		surv.remove_item(item_id, 1)
		surv.hunger = clampf(surv.hunger + float(info.get("food", 0.0)), 0.0, 100.0)
		surv.thirst = clampf(surv.thirst + float(info.get("water", 0.0)), 0.0, 100.0)
		surv.hp = clampf(surv.hp + float(info.get("hp", 0.0)), 0.0, surv.max_hp)
		surv.body_temp = clampf(surv.body_temp + float(info.get("warmth", 0.0)), 32.0, 38.0)
		surv.stress = clampf(surv.stress + float(info.get("stress", 0.0)), 0.0, 100.0)
		if bool(info.get("stop_bleed", false)):
			surv.bleeding_rate = 0.0
		if bool(info.get("cure_root", false)):
			surv.root_infection = 0.0
		if world_ref and world_ref.has_method("play_sfx"):
			world_ref.play_sfx("item")
	elif itype == "placeable":
		if world_ref and world_ref.has_method("place_station_near_player"):
			var st_kind: String = str(info.get("place", "campfire"))
			if world_ref.place_station_near_player(st_kind):
				surv.remove_item(item_id, 1)
				if world_ref.has_method("play_sfx"):
					world_ref.play_sfx("build")

# ПУНКТ 3.4: Улучшенный зацеп крюка с волной натяжения троса и подсказкой при первом пуске
func fire_hook(is_left: bool, target_world_pos: Vector2) -> void:
	if is_dead or is_grabbed or surv.is_sleeping or rope_durability <= 0.0:
		return
	if not world_ref or not world_ref.has_method("raycast_hook_anchor"):
		return
	var dir: Vector2 = (target_world_pos - global_position).normalized()
	if dir.length() < 0.05:
		dir = look_direction

	var hit: Dictionary = world_ref.raycast_hook_anchor(global_position, dir, max_range_px)
	if bool(hit.get("hit", false)):
		var anchor: Vector2 = hit.get("pos", global_position)
		if is_left:
			hook_left_active = true
			hook_left_pos = anchor
			hook_left_timer = 0.0
		else:
			hook_right_active = true
			hook_right_pos = anchor
			hook_right_timer = 0.0
		hook_wall_stuck_timer = 0.0
		look_direction = (anchor - global_position).normalized()
		if absf(look_direction.x) > 0.15:
			facing_left = (look_direction.x < 0.0)
		rope_durability = maxf(0.0, rope_durability - 0.6)
		current_noise_radius = maxf(current_noise_radius, 10.0)
		if z_height < 6.0:
			z_velocity = 95.0
		if not hook_hint_shown and world_ref.has_method("show_combat_hint"):
			hook_hint_shown = true
			world_ref.show_combat_hint("Крюк закреплён! Зажми РЫВОК для ускорения и жми УДАР у титана!")
		if world_ref.has_method("play_sfx"):
			world_ref.play_sfx("hook")
	else:
		if is_left:
			hook_left_active = false
		else:
			hook_right_active = false

func release_hooks() -> void:
	hook_left_active = false
	hook_right_active = false
	is_gas_boosting = false
	hook_wall_stuck_timer = 0.0

func reload_blades() -> void:
	if spare_blades > 0 and blade_durability < 100.0:
		spare_blades -= 1
		blade_durability = 100.0
		if world_ref and world_ref.has_method("play_sfx"):
			world_ref.play_sfx("blade")

func refill_at_station() -> void:
	gas = gas_max
	rope_durability = 100.0
	blade_durability = 100.0
	spare_blades = max(spare_blades, 4)
	focus = 100.0

func on_grabbed_by_titan(titan: Node2D) -> void:
	if is_dead:
		return
	surv.is_sleeping = false
	is_grabbed = true
	grabbing_titan = titan
	grab_timer = 3.2
	grab_escape_progress = 0
	_escape_key_was_down = false
	surv.hp = maxf(0.0, surv.hp - 16.0)
	surv.bleeding_rate = 4.5
	surv.stress = minf(100.0, surv.stress + 28.0)
	release_hooks()
	if world_ref and world_ref.has_method("play_sfx"):
		world_ref.play_sfx("roar")
	if surv.hp <= 0.0:
		_trigger_player_death()

func _trigger_player_death() -> void:
	if is_dead:
		return
	is_dead = true
	surv.hp = 0.0
	surv.is_sleeping = false
	release_hooks()
	velocity = Vector2.ZERO
	z_height = 0.0
	z_velocity = 0.0
	if is_grabbed:
		is_grabbed = false
		if is_instance_valid(grabbing_titan) and grabbing_titan.has_method("on_player_died_in_grab"):
			grabbing_titan.on_player_died_in_grab()
		grabbing_titan = null
	if world_ref and world_ref.has_method("on_player_died"):
		world_ref.on_player_died()

func respawn_at(spawn_world_pos: Vector2) -> void:
	is_dead = false
	is_grabbed = false
	grabbing_titan = null
	grab_timer = 0.0
	grab_escape_progress = 0
	surv.hp = surv.max_hp
	surv.hunger = maxf(surv.hunger, 75.0)
	surv.thirst = maxf(surv.thirst, 75.0)
	surv.bleeding_rate = 0.0
	surv.stress = 15.0
	surv.is_sleeping = false
	blade_durability = 100.0
	gas = gas_max
	global_position = spawn_world_pos
	velocity = Vector2.ZERO
	z_height = 0.0
	z_velocity = 0.0
	release_hooks()

func _physics_process(delta: float) -> void:
	if surv.hp <= 0.0 and not is_dead:
		_trigger_player_death()

	if is_dead:
		velocity = Vector2.ZERO
		return

	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0:
			combo_stage = 0

	if hook_left_active:
		hook_left_timer += delta
	if hook_right_active:
		hook_right_timer += delta

	if surv.is_sleeping:
		velocity = Vector2.ZERO
		current_noise_radius = 0.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_D) or mobile_move_vec.length() > 0.1:
			surv.is_sleeping = false
		return

	if is_grabbed:
		if not is_instance_valid(grabbing_titan) or grabbing_titan.state == TitanEntity.State.DYING:
			is_grabbed = false
			grabbing_titan = null
		else:
			var hand_side: float = -10.0 if grabbing_titan.facing.x < 0.0 else 10.0
			global_position = grabbing_titan.global_position + Vector2(hand_side, -18.0)
			z_height = 14.0
			grab_timer -= delta
			surv.hp = maxf(0.0, surv.hp - GRAB_DAMAGE_PER_SEC * delta)

			var key_down_now: bool = Input.is_key_pressed(KEY_F) or Input.is_key_pressed(KEY_SPACE)
			var tap_escape: bool = (key_down_now and not _escape_key_was_down) or mobile_jump_queued or mobile_attack_queued
			_escape_key_was_down = key_down_now
			mobile_jump_queued = false
			mobile_attack_queued = false

			if tap_escape:
				grab_escape_progress += 1
				if world_ref and world_ref.has_method("play_sfx"):
					world_ref.play_sfx("blade")
				if grab_escape_progress >= GRAB_ESCAPE_TAPS_REQUIRED:
					blade_durability = maxf(0.0, blade_durability - 16.0)
					var escaped_from: Node2D = grabbing_titan
					is_grabbed = false
					grabbing_titan = null
					if is_instance_valid(escaped_from) and escaped_from.has_method("release_grab_stunned"):
						escaped_from.release_grab_stunned()
						velocity = -escaped_from.facing.normalized() * 210.0
					z_velocity = 135.0
					if world_ref and world_ref.has_method("play_sfx"):
						world_ref.play_sfx("hit")
					return

			if surv.hp <= 0.0 or grab_timer <= 0.0:
				_trigger_player_death()
		return

	var input_vec := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_vec.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_vec.y += 1.0

	var joy_curved := Vector2.ZERO
	if mobile_move_vec.length() > 0.01:
		var j_len: float = clampf(mobile_move_vec.length(), 0.0, 1.0)
		joy_curved = mobile_move_vec.normalized() * pow(j_len, 1.35)

	var move_vec: Vector2 = input_vec + joy_curved
	if move_vec.length() > 1.0:
		move_vec = move_vec.normalized()
	if move_vec.length() > 0.08:
		look_direction = move_vec.normalized()
		if absf(look_direction.x) > 0.12:
			facing_left = (look_direction.x < 0.0)

	if Input.is_key_pressed(KEY_Q) and not hook_left_active:
		fire_hook(true, get_global_mouse_position())
	if Input.is_key_pressed(KEY_E) and not hook_right_active:
		fire_hook(false, get_global_mouse_position())
	if Input.is_key_pressed(KEY_R):
		reload_blades()

	var any_hook: bool = hook_left_active or hook_right_active
	var want_jump: bool = Input.is_key_pressed(KEY_SPACE) or mobile_jump_queued
	mobile_jump_queued = false
	if want_jump:
		if any_hook:
			release_hooks()
			any_hook = false
			z_velocity = 110.0
		elif z_height <= 0.01:
			z_velocity = 135.0
			current_noise_radius = 6.0

	is_gas_boosting = false
	if any_hook:
		var anchor: Vector2 = (hook_left_pos + hook_right_pos) * 0.5 if (hook_left_active and hook_right_active) else (hook_left_pos if hook_left_active else hook_right_pos)
		var to_anchor: Vector2 = anchor - global_position
		var dist: float = to_anchor.length()
		if dist < 12.0 or dist > max_range_px * 1.15:
			release_hooks()
		else:
			var rope_dir: Vector2 = to_anchor / dist
			look_direction = rope_dir
			if absf(rope_dir.x) > 0.15:
				facing_left = (rope_dir.x < 0.0)
			var tangent := Vector2(-rope_dir.y, rope_dir.x)
			if move_vec.length() > 0.1 and tangent.dot(move_vec) < 0.0:
				tangent = -tangent
			var accel: Vector2 = rope_dir * pull_accel
			if move_vec.length() > 0.1:
				accel += tangent * (pull_accel * 0.78)
			if (Input.is_key_pressed(KEY_SHIFT) or mobile_gas_held) and gas > 0.0:
				is_gas_boosting = true
				gas = maxf(0.0, gas - gas_boost_cost * delta)
				accel += (rope_dir * 0.72 + tangent * 0.65).normalized() * gas_boost_accel
			velocity = velocity.move_toward(rope_dir * max_swing_speed * 0.85, accel.length() * delta)
			if velocity.length() > max_swing_speed:
				velocity = velocity.normalized() * max_swing_speed
			z_height = move_toward(z_height, 14.0, 75.0 * delta)
			z_velocity = 0.0
	else:
		is_crouching = Input.is_key_pressed(KEY_CTRL) or mobile_crouch_toggle
		is_running = (Input.is_key_pressed(KEY_SHIFT) or mobile_run_toggle) and not is_crouching
		var base_spd: float = crouch_speed if is_crouching else (run_speed if is_running else walk_speed)
		var target_speed: float = base_spd * move_speed_mult
		if move_vec.length() > 0.04:
			velocity = velocity.move_toward(move_vec * target_speed, 480.0 * delta)
			walk_anim_phase += delta * (9.2 if is_running else 5.5) * move_vec.length()
			current_noise_radius = 1.5 if is_crouching else (8.0 if is_running else 3.0)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 640.0 * delta)
			walk_anim_phase = 0.0
			current_noise_radius = move_toward(current_noise_radius, 0.0, 15.0 * delta)

		if z_height > 0.0 or z_velocity != 0.0:
			z_height += z_velocity * delta
			z_velocity -= 380.0 * delta
			if z_height <= 0.0:
				z_height = 0.0
				z_velocity = 0.0

	if attack_anim_timer > 0.0:
		attack_anim_timer -= delta
	if (Input.is_key_pressed(KEY_F) or mobile_attack_queued) and attack_anim_timer <= 0.0:
		mobile_attack_queued = false
		_perform_blade_strike()

	move_and_slide()

	# ПУНКТ 3.4: Авто-отцеп крюка при упоре в стену!
	if (hook_left_active or hook_right_active) and get_slide_collision_count() > 0:
		hook_wall_stuck_timer += delta
		if hook_wall_stuck_timer >= 0.20:
			release_hooks()
	else:
		hook_wall_stuck_timer = 0.0

# ПУНКТ 3.2: 3-ударное комбо клинками с повышенным уроном на 3-м ударе и вызовом hit-stop!
func _perform_blade_strike() -> void:
	if combo_reset_timer > 0.0:
		combo_stage = (combo_stage + 1) % 3
	else:
		combo_stage = 0
	combo_reset_timer = 0.72
	attack_anim_duration = 0.26 if combo_stage == 2 else 0.21
	attack_anim_timer = attack_anim_duration

	var hit_any_titan: bool = false
	var dmg_mult: float = 1.35 if combo_stage == 2 else (1.12 if combo_stage == 1 else 1.0)

	if blade_durability > 0.0 and world_ref and world_ref.has_method("player_slash_attack"):
		var res: Dictionary = world_ref.player_slash_attack(global_position, look_direction, velocity.length(), blade_dmg * dmg_mult, max_swing_speed)
		if bool(res.get("hit", false)):
			hit_any_titan = true
			blade_durability = maxf(0.0, blade_durability - 9.0)
			if bool(res.get("killed", false)):
				surv.add_item("ash", 1)

	if not hit_any_titan and world_ref and world_ref.has_method("player_harvest_nearby"):
		var harvested: bool = world_ref.player_harvest_nearby(global_position, look_direction)
		if harvested:
			return

	if not hit_any_titan and world_ref and world_ref.has_method("play_sfx"):
		world_ref.play_sfx("blade")

# ПУНКТ 3.1: Выбор кадра по 4 направлениям (вниз, вверх, вбок)
func get_current_frame_texture() -> Texture2D:
	var dir_arr: Array[ImageTexture] = tex_down_frames
	if absf(look_direction.x) > absf(look_direction.y) * 1.15:
		dir_arr = tex_side_frames
	elif look_direction.y < -0.35:
		dir_arr = tex_up_frames

	if dir_arr.is_empty():
		return tex_idle
	var f_idx: int = 0
	if velocity.length() > 8.0 and not is_dead:
		f_idx = 1 if int(floor(walk_anim_phase)) % 2 == 0 else 2
	return dir_arr[f_idx]

func get_torch_hand_offset() -> Vector2:
	var hand_dir: Vector2 = look_direction.normalized()
	if hand_dir.length() < 0.05:
		hand_dir = Vector2.DOWN
	return hand_dir * 7.0 + Vector2(4.0 if not facing_left else -4.0, -11.0 - z_height)

# ПУНКТ 3.4: Отрисовка троса с провисанием при выстреле и натяжением при тяге
func _draw_rope_with_sag(canvas: CanvasItem, from_pt: Vector2, to_pt: Vector2, rope_age: float) -> void:
	var diff: Vector2 = to_pt - from_pt
	var d_len: float = diff.length()
	if d_len < 2.0:
		return
	var perp := Vector2(-diff.y, diff.x) / d_len
	var sag_amp: float = clampf(1.0 - rope_age * 7.5, 0.0, 1.0) * 6.5

	if sag_amp > 0.3:
		var prev_p: Vector2 = from_pt
		for i in range(1, 9):
			var t: float = float(i) / 8.0
			var wave: float = sin(t * PI * 2.0 + rope_age * 35.0) * sag_amp * (1.0 - t * 0.5)
			var cur_p: Vector2 = from_pt.lerp(to_pt, t) + perp * wave
			canvas.draw_line(prev_p, cur_p, Color("#b8c7d9"), 1.3)
			prev_p = cur_p
	else:
		# Натянутый стальной трос
		canvas.draw_line(from_pt, to_pt, Color("#56606e"), 2.0)
		canvas.draw_line(from_pt, to_pt, Color("#c8d6e5"), 1.0)

	# Металлический якорь-гарпун в точке зацепа
	var dir_n: Vector2 = diff / d_len
	canvas.draw_line(to_pt, to_pt - dir_n * 5.0 + perp * 3.5, Color("#e6f0fa"), 1.5)
	canvas.draw_line(to_pt, to_pt - dir_n * 5.0 - perp * 3.5, Color("#e6f0fa"), 1.5)

# ПУНКТ 3.3: Отображение выбранного слота хотбара в руке героя с поворотом по взгляду и анимацией удара!
func _draw_held_item_in_hand(canvas: CanvasItem, p: Vector2, y_off: int) -> void:
	if is_dead or surv.is_sleeping or world_ref == null:
		return

	var aim_dir: Vector2 = look_direction.normalized()
	if aim_dir.length() < 0.05:
		aim_dir = Vector2.DOWN

	var swing_prog: float = 0.0
	if attack_anim_timer > 0.0 and attack_anim_duration > 0.001:
		swing_prog = 1.0 - (attack_anim_timer / attack_anim_duration)

	var swing_angle: float = 0.0
	if attack_anim_timer > 0.0:
		var start_a: float = -1.15 if combo_stage != 1 else 1.15
		var end_a: float = 1.15 if combo_stage != 1 else -1.15
		swing_angle = lerpf(start_a, end_a, swing_prog)

	var item_dir: Vector2 = aim_dir.rotated(swing_angle)
	var hand_pos: Vector2 = p + Vector2(-4.0 if facing_left else 4.0, -10.0 + float(y_off)) + aim_dir * 3.5

	# 1. В режиме стройки рисуем миниатюру выбранного строительного блока в руках
	if world_ref.build_mode_active:
		var b_id: int = int(world_ref.selected_block_id)
		if b_id > 0:
			var b_tex: Texture2D = BuildSystem.get_preview_texture(world_ref, b_id, Vector2i.ZERO)
			if b_tex != null:
				canvas.draw_texture_rect(b_tex, Rect2(hand_pos - Vector2(4, 6), Vector2(9, 10)), false)
				canvas.draw_rect(Rect2(hand_pos - Vector2(4, 6), Vector2(9, 10)), Color("#d99136"), false, 1.0)
		return

	var slot_idx: int = int(world_ref.selected_hotbar_slot)
	if slot_idx < 0 or slot_idx >= world_ref.combat_hotbar_slots.size():
		return
	var s_data: Dictionary = world_ref.combat_hotbar_slots[slot_idx]
	var s_kind: String = str(s_data.get("kind", "empty"))
	var s_id: String = str(s_data.get("id", ""))
	if s_kind == "empty":
		return

	# 2. Парные клинки разведчика (в обеих руках)
	if s_id == "blades":
		var l_hand: Vector2 = p + Vector2(-5.0, -10.0 + float(y_off))
		var r_hand: Vector2 = p + Vector2(5.0, -10.0 + float(y_off))
		var b_dir1: Vector2 = item_dir
		var b_dir2: Vector2 = aim_dir.rotated(-swing_angle if combo_stage == 2 else swing_angle * 0.85)
		canvas.draw_line(l_hand, l_hand + b_dir2 * 10.5, Color("#cfdbe6"), 1.6)
		canvas.draw_line(r_hand, r_hand + b_dir1 * 11.5, Color("#e8f2fc"), 1.8)
		return

	# 3. Горящий факел в руке
	if s_id == "torch":
		var tip: Vector2 = hand_pos + item_dir * 6.5 + Vector2(0, -3.0)
		canvas.draw_line(hand_pos, tip, Color("#6e472b"), 2.0)
		if torch_lit:
			var fl: int = int(Time.get_ticks_msec() / 95) % 3
			var fl_off := Vector2(float(fl - 1) * 0.8, -float(fl % 2) * 1.2)
			canvas.draw_rect(Rect2(tip + fl_off - Vector2(2, 3), Vector2(4, 4)), Color("#ff7b29"), true)
			canvas.draw_rect(Rect2(tip + fl_off - Vector2(1, 2), Vector2(2, 3)), Color("#fff3b0"), true)
		return

	# 4. Топор или Кирка (с деревянным топорищем и стальным лезвием)
	if s_id == "axe" or s_id == "pickaxe":
		var head_pt: Vector2 = hand_pos + item_dir * 8.5
		var perp := Vector2(-item_dir.y, item_dir.x)
		canvas.draw_line(hand_pos, head_pt, Color("#7a5230"), 1.8)
		if s_id == "axe":
			canvas.draw_line(head_pt - item_dir * 2.0, head_pt + perp * 4.5, Color("#d0dae6"), 2.6)
		else:
			canvas.draw_line(head_pt - perp * 4.5, head_pt + perp * 4.5, Color("#d0dae6"), 2.0)
		return

	# 5. Арбалет или предмет из рюкзака
	var ic_idx: int = clampi(int(s_data.get("icon_idx", 0)), 0, world_ref.tex_hotbar_icons.size() - 1)
	if not world_ref.tex_hotbar_icons.is_empty() and world_ref.tex_hotbar_icons[ic_idx] != null:
		canvas.draw_texture_rect(world_ref.tex_hotbar_icons[ic_idx], Rect2(hand_pos + item_dir * 3.0 - Vector2(5, 5), Vector2(10, 10)), false)

# ПУНКТ 3.2: Отрисовка изогнутой дуги рассечения воздуха для 3 фаз комбо
func _draw_combo_slash_arc(canvas: CanvasItem, p: Vector2, y_off: int) -> void:
	if attack_anim_timer <= 0.0 or is_dead:
		return
	var prog: float = 1.0 - (attack_anim_timer / maxf(0.001, attack_anim_duration))
	var base_ang: float = look_direction.angle()
	var sweep: float = 1.45 if combo_stage == 2 else 1.15
	var center: Vector2 = p + Vector2(0, -10 + y_off) + look_direction.normalized() * 4.0
	var radius: float = 15.5 if combo_stage != 2 else 18.5

	var pts_outer := PackedVector2Array()
	var steps: int = 8
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var a_ step: float = base_ang + lerpf(-sweep, sweep, t if combo_stage != 1 else (1.0 - t))
		pts_outer.append(center + Vector2.from_angle(a_step) * radius)

	var col_main := Color(0.90, 0.96, 1.0, (1.0 - prog * 0.5) * 0.92)
	var col_gold := Color(1.0, 0.82, 0.38, (1.0 - prog * 0.6) * 0.85)
	for i in range(steps):
		canvas.draw_line(pts_outer[i], pts_outer[i + 1], col_main, 2.8 if i >= 2 and i <= 5 else 1.6)
		var in_a: Vector2 = center.lerp(pts_outer[i], 0.72)
		var in_b: Vector2 = center.lerp(pts_outer[i + 1], 0.72)
		canvas.draw_line(in_a, in_b, col_gold, 1.4)

	# На 3-м ударе комбо рисуем встречную перекрёстную дугу второй сабли
	if combo_stage == 2:
		var p1: Vector2 = center + Vector2.from_angle(base_ang - 0.85) * (radius * 0.9)
		var p2: Vector2 = center + Vector2.from_angle(base_ang + 0.85) * (radius * 0.9)
		canvas.draw_line(p1, p2, Color(1.0, 0.92, 0.65, 0.9), 2.2)

func draw_entity_onto(canvas: CanvasItem) -> void:
	var p: Vector2 = global_position
	Phase1Visuals.draw_soft_shadow(canvas, p + Vector2(2, 0), Vector2(16, 8), 0.52)

	var bob_px: int = -1 if (velocity.length() > 8.0 and not is_dead and int(floor(walk_anim_phase * 2.0)) % 2 == 1) else 0
	var y_off: int = -int(round(z_height)) + bob_px

	if hook_left_active:
		_draw_rope_with_sag(canvas, p + Vector2(-4, -10 + y_off), hook_left_pos, hook_left_timer)
	if hook_right_active:
		_draw_rope_with_sag(canvas, p + Vector2(4, -10 + y_off), hook_right_pos, hook_right_timer)

	if is_gas_boosting:
		var trail := -velocity.normalized() * 10.0
		canvas.draw_rect(Rect2(p + trail + Vector2(-2, -10 + y_off), Vector2(4, 4)), Color(0.9, 0.95, 1.0, 0.78), true)
		canvas.draw_rect(Rect2(p + trail * 1.6 + Vector2(-1, -9 + y_off), Vector2(3, 3)), Color(0.75, 0.88, 1.0, 0.48), true)

	# Если герой смотрит вверх (спиной к камере), предмет в руке рисуется перед спиной
	if look_direction.y < -0.35:
		_draw_held_item_in_hand(canvas, p, y_off)

	var cur_tex: Texture2D = get_current_frame_texture()
	if cur_tex != null:
		var hero_sz: Vector2 = ArtLoader.get_frame_size("hero")
		var draw_w: float = -hero_sz.x if facing_left else hero_sz.x
		var draw_x: float = hero_sz.x * 0.5 if facing_left else -hero_sz.x * 0.5
		var mod_col := Color(0.55, 0.25, 0.25, 0.85) if is_dead else Color.WHITE
		canvas.draw_texture_rect(cur_tex, Rect2(p + Vector2(draw_x, -22 + y_off), Vector2(draw_w, hero_sz.y)), false, mod_col)

	if look_direction.y >= -0.35:
		_draw_held_item_in_hand(canvas, p, y_off)

	_draw_combo_slash_arc(canvas, p, y_off)

	if is_grabbed and not is_dead:
		var ratio: float = clampf(float(grab_escape_progress) / float(GRAB_ESCAPE_TAPS_REQUIRED), 0.0, 1.0)
		var bar_pos: Vector2 = p + Vector2(-18, -32 + y_off)
		canvas.draw_rect(Rect2(bar_pos, Vector2(36, 5)), Color("#141210"), true)
		canvas.draw_rect(Rect2(bar_pos + Vector2(1, 1), Vector2(34.0 * ratio, 3)), Color("#ffcc4d"), true)
		var font: Font = ThemeDB.fallback_font
		canvas.draw_string(font, bar_pos + Vector2(-18, -3), "ЖМИ УДАР! (%d/%d)" % [grab_escape_progress, GRAB_ESCAPE_TAPS_REQUIRED], HORIZONTAL_ALIGNMENT_CENTER, 72, 9, Color("#fff3b0"))

func draw_occluded_silhouette(canvas: CanvasItem, sil_Tex: Texture2D) -> void:
	if sil_Tex == null:
		return
	var p: Vector2 = global_position
	var bob_px: int = -1 if (velocity.length() > 8.0 and not is_dead and int(floor(walk_anim_phase * 2.0)) % 2 == 1) else 0
	var y_off: int = -int(round(z_height)) + bob_px
	var hero_sz: Vector2 = ArtLoader.get_frame_size("hero")
	var draw_w: float = -hero_sz.x if facing_left else hero_sz.x
	var draw_x: float = hero_sz.x * 0.5 if facing_left else -hero_sz.x * 0.5
	canvas.draw_texture_rect(sil_Tex, Rect2(p + Vector2(draw_x, -22 + y_off), Vector2(draw_w, hero_sz.y)), false)
