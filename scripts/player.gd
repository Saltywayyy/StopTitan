class_name PlayerController
extends CharacterBody2D

var walk_speed: float = 90.0
var run_speed: float = 155.0
var crouch_speed: float = 48.0

var max_range_px: float = 288.0
var pull_accel: float = 340.0
var gas_boost_accel: float = 520.0
var max_swing_speed: float = 330.0

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
var hook_right_active: bool = false
var hook_right_pos: Vector2 = Vector2.ZERO
var is_gas_boosting: bool = false

var is_crouching: bool = false
var is_running: bool = false
var current_noise_radius: float = 0.0
var look_direction: Vector2 = Vector2.DOWN
var z_height: float = 0.0
var z_velocity: float = 0.0
var torch_lit: bool = true

var walk_anim_phase: float = 0.0
var attack_anim_timer: float = 0.0
var last_combat_msg: String = "Днём — прячься. Ночью — добывай."

var is_grabbed: bool = false
var grabbing_titan: Node2D = null
var grab_timer: float = 0.0
var grab_escape_progress: int = 0
var is_dead: bool = false

var world_ref: Node2D
var surv: SurvivalSystem

# Попиксельные кадры героя (стоя и в шаге)
var tex_idle: ImageTexture
var tex_walk1: ImageTexture
var tex_walk2: ImageTexture

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

	tex_idle = _build_hero_sprite(0)
	tex_walk1 = _build_hero_sprite(1)
	tex_walk2 = _build_hero_sprite(2)

# Попиксельная сборка спрайта героя 16x24 (строгая сетка, 1px контур!)
func _build_hero_sprite(frame: int) -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	var c_out := Color("#0f1318")
	var c_skin := Color("#e0b48c")
	var c_hair := Color("#261a14")
	var c_coat := Color("#26382e")
	var c_vest := Color("#784d30")
	var c_belt := Color("#d4a045")
	var c_pants := Color("#242a34")
	var c_boot := Color("#1a1410")

	# Тень у ног
	for x in range(4, 12):
		img.set_pixel(x, 22, Color(0, 0, 0, 0.45))
		img.set_pixel(x, 23, Color(0, 0, 0, 0.3))

	# Голова и волосы (y: 2..10, x: 4..11)
	for x in range(4, 12):
		for y in range(2, 11):
			if x == 4 or x == 11 or y == 2 or y == 10:
				img.set_pixel(x, y, c_out)
			elif y <= 5 or x == 5 or x == 10:
				img.set_pixel(x, y, c_hair)
			else:
				img.set_pixel(x, y, c_skin)
	# Глаза
	img.set_pixel(6, 7, c_out)
	img.set_pixel(9, 7, c_out)

	# Торс, плащ и ремень (y: 11..17, x: 3..12)
	for x in range(3, 13):
		for y in range(11, 18):
			if x == 3 or x == 12 or y == 17:
				img.set_pixel(x, y, c_out)
			elif y == 16:
				img.set_pixel(x, y, c_belt if (x == 7 or x == 8) else c_boot)
			elif x >= 6 and x <= 9:
				img.set_pixel(x, y, c_vest)
			else:
				img.set_pixel(x, y, c_coat)

	# Ноги с покадровым шагом (y: 18..22)
	var l_off: int = -1 if frame == 1 else (1 if frame == 2 else 0)
	var r_off: int = 1 if frame == 1 else (-1 if frame == 2 else 0)
	for x in range(4, 8):
		for y in range(18, 22 + l_off):
			if y >= 0 and y < 24:
				img.set_pixel(x, y, c_out if (x == 4 or x == 7 or y == 21 + l_off) else (c_boot if y >= 20 else c_pants))
	for x in range(8, 12):
		for y in range(18, 22 + r_off):
			if y >= 0 and y < 24:
				img.set_pixel(x, y, c_out if (x == 8 or x == 11 or y == 21 + r_off) else (c_boot if y >= 20 else c_pants))

	# Пиксельный факел в правой руке
	img.set_pixel(13, 14, c_out)
	img.set_pixel(13, 13, Color("#704828"))
	img.set_pixel(14, 12, Color("#704828"))
	img.set_pixel(14, 11, Color("#ff6d1c"))
	img.set_pixel(14, 10, Color("#ffe066"))
	img.set_pixel(13, 11, Color("#ff9800"))

	return ImageTexture.create_from_image(img)

func apply_config(full_cfg: Dictionary) -> void:
	if surv == null:
		surv = SurvivalSystem.new()
		add_child(surv)
	surv.setup(full_cfg)

	var p_cfg: Dictionary = full_cfg.get("player", {})
	var w_cfg: Dictionary = full_cfg.get("web_gear", {})

	walk_speed = float(p_cfg.get("walk_speed", 90.0))
	run_speed = float(p_cfg.get("run_speed", 155.0))
	crouch_speed = float(p_cfg.get("crouch_speed", 48.0))

	if not w_cfg.is_empty():
		max_range_px = float(w_cfg.get("max_range_cells", 18.0)) * 16.0
		pull_accel = float(w_cfg.get("pull_accel", 340.0))
		gas_boost_accel = float(w_cfg.get("gas_boost_accel", 520.0))
		max_swing_speed = float(w_cfg.get("max_swing_speed", 330.0))
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
		else:
			hook_right_active = true
			hook_right_pos = anchor
		rope_durability = maxf(0.0, rope_durability - 0.8)
		current_noise_radius = maxf(current_noise_radius, 10.0)
		if z_height < 6.0:
			z_velocity = 95.0
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
	surv.is_sleeping = false
	is_grabbed = true
	grabbing_titan = titan
	grab_timer = 2.0
	grab_escape_progress = 0
	surv.hp = maxf(5.0, surv.hp - 18.0)
	surv.bleeding_rate = 5.0
	surv.stress = minf(100.0, surv.stress + 28.0)
	release_hooks()
	if world_ref and world_ref.has_method("play_sfx"):
		world_ref.play_sfx("roar")

func _physics_process(delta: float) -> void:
	if surv.hp <= 0.0 and not is_dead:
		is_dead = true

	if is_dead:
		velocity = Vector2.ZERO
		queue_redraw()
		return

	if surv.is_sleeping:
		velocity = Vector2.ZERO
		current_noise_radius = 0.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_D) or mobile_move_vec.length() > 0.1:
			surv.is_sleeping = false
		queue_redraw()
		return

	if is_grabbed:
		if not is_instance_valid(grabbing_titan):
			is_grabbed = false
		else:
			global_position = grabbing_titan.global_position + Vector2(0, 8)
			grab_timer -= delta
			if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_F) or mobile_jump_queued or mobile_attack_queued:
				mobile_jump_queued = false
				mobile_attack_queued = false
				grab_escape_progress += 1
				if grab_escape_progress >= 2 and blade_durability > 0.0:
					blade_durability = maxf(0.0, blade_durability - 20.0)
					is_grabbed = false
					if grabbing_titan.has_method("release_grab_stunned"):
						grabbing_titan.release_grab_stunned()
					velocity = -grabbing_titan.facing * 220.0
					z_velocity = 140.0
					if world_ref and world_ref.has_method("play_sfx"):
						world_ref.play_sfx("hit")
			if grab_timer <= 0.0 and is_grabbed:
				is_dead = true
		queue_redraw()
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

	var move_vec: Vector2 = input_vec + mobile_move_vec
	if move_vec.length() > 1.0:
		move_vec = move_vec.normalized()
	if move_vec.length() > 0.1:
		look_direction = move_vec.normalized()

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
		if dist < 10.0 or dist > max_range_px * 1.15:
			release_hooks()
		else:
			var rope_dir: Vector2 = to_anchor / dist
			var tangent := Vector2(-rope_dir.y, rope_dir.x)
			if move_vec.length() > 0.1 and tangent.dot(move_vec) < 0.0:
				tangent = -tangent
			var accel: Vector2 = rope_dir * pull_accel
			if move_vec.length() > 0.1:
				accel += tangent * (pull_accel * 0.85)
			if (Input.is_key_pressed(KEY_SHIFT) or mobile_gas_held) and gas > 0.0:
				is_gas_boosting = true
				gas = maxf(0.0, gas - gas_boost_cost * delta)
				accel += (rope_dir * 0.65 + tangent * 0.75).normalized() * gas_boost_accel
			velocity += accel * delta
			if velocity.length() > max_swing_speed:
				velocity = velocity.normalized() * max_swing_speed
			z_height = move_toward(z_height, 14.0, 65.0 * delta)
			z_velocity = 0.0
	else:
		is_crouching = Input.is_key_pressed(KEY_CTRL) or mobile_crouch_toggle
		is_running = (Input.is_key_pressed(KEY_SHIFT) or mobile_run_toggle) and not is_crouching
		var target_speed: float = crouch_speed if is_crouching else (run_speed if is_running else walk_speed)
		if move_vec.length() > 0.05:
			velocity = velocity.move_toward(move_vec * target_speed, 650.0 * delta)
			walk_anim_phase += delta * (11.0 if is_running else 7.0)
			current_noise_radius = 1.5 if is_crouching else (8.0 if is_running else 3.0)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
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
	queue_redraw()

func _perform_blade_strike() -> void:
	if blade_durability <= 0.0:
		return
	attack_anim_timer = 0.2
	if world_ref and world_ref.has_method("play_sfx"):
		world_ref.play_sfx("blade")
	if world_ref and world_ref.has_method("player_slash_attack"):
		var res: Dictionary = world_ref.player_slash_attack(global_position, look_direction, velocity.length(), blade_dmg, max_swing_speed)
		if bool(res.get("hit", false)):
			blade_durability = maxf(0.0, blade_durability - 14.0)
			if bool(res.get("killed", false)):
				surv.add_item("ash", 1)

func _draw() -> void:
	var y_off: int = -int(round(z_height))
	if hook_left_active:
		draw_line(Vector2(-4, -10 + y_off), hook_left_pos - global_position, Color("#8ea0b2"), 1.0)
	if hook_right_active:
		draw_line(Vector2(4, -10 + y_off), hook_right_pos - global_position, Color("#8ea0b2"), 1.0)

	var cur_tex: ImageTexture = tex_idle
	if velocity.length() > 10.0:
		cur_tex = tex_walk1 if int(floor(walk_anim_phase)) % 2 == 0 else tex_walk2

	if cur_tex != null:
		draw_texture(cur_tex, Vector2(-8, -22 + y_off))
