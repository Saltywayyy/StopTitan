class_name TitanEntity
extends CharacterBody2D

enum State { DORMANT, WANDER, SUSPICIOUS, CHASE, GRABBING, STUNNED, DYING }

var titan_type: String = "wanderer"
var titan_name: String = "Бродяга"
var max_nape_hp: float = 40.0
var nape_hp: float = 40.0
var move_speed: float = 38.0
var chase_speed: float = 66.0
var vision_day_px: float = 224.0
var vision_night_px: float = 45.0
var vision_cos: float = 0.707

var state: State = State.WANDER
var facing: Vector2 = Vector2.DOWN
var target_pos: Vector2 = Vector2.ZERO
var state_timer: float = 0.0
var night_awoken_timer: float = 0.0
var leg_crippled_timer: float = 0.0
var trap_stun_timer: float = 0.0
var ash_fade: float = 1.0
var step_anim_clock: float = 0.0

var world_ref: Node2D
var player_ref: Node2D

static var tex_titan_day_1: ImageTexture
static var tex_titan_day_2: ImageTexture
static var tex_titan_night: ImageTexture

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	col.shape = circle
	add_child(col)
	_pick_new_wander_dir()
	if tex_titan_day_1 == null:
		tex_titan_day_1 = _generate_titan_pixel_sprite(false, 0)
		tex_titan_day_2 = _generate_titan_pixel_sprite(false, 1)
		tex_titan_night = _generate_titan_pixel_sprite(true, 0)

# Попиксельный спрайт гиганта 48x64 (в единой пиксельной сетке с ёлками и героем, как на референсе!)
func _generate_titan_pixel_sprite(dormant: bool, step_frame: int) -> ImageTexture:
	var w: int = 48
	var h: int = 64
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_out := Color("#0e1116")
	var c_skin := Color("#303644") if dormant else Color("#876962")
	var c_shade := Color("#212630") if dormant else Color("#664d48")
	var c_high := Color("#3e4656") if dormant else Color("#9c7b73")

	# Пиксельная тень у стоп (y: 58..62)
	for x in range(11, 37):
		for y in range(58, 63):
			if abs(x - 24) + abs(y - 60) * 3 < 16:
				img.set_pixel(x, y, Color(0, 0, 0, 0.45))

	# Голова гиганта (y: 4..17, x: 17..30)
	for x in range(17, 31):
		for y in range(4, 18):
			var edge: bool = (x == 17 or x == 30 or y == 4 or y == 17)
			if edge:
				img.set_pixel(x, y, c_out)
			elif y <= 6:
				img.set_pixel(x, y, Color("#241d1b"))
			else:
				img.set_pixel(x, y, c_high if y < 11 else c_skin)

	# Глубокие глазницы и оскал
	for x in [20, 21, 26, 27]:
		img.set_pixel(x, 10, c_out)
		img.set_pixel(x, 11, Color("#d94343") if not dormant else c_out)
	for x in range(20, 28):
		img.set_pixel(x, 14, c_out)
		if x % 2 == 0:
			img.set_pixel(x, 15, Color("#d8d0c5"))

	# Массивный торс и грудная клетка (y: 18..41, x: 12..35)
	for x in range(12, 36):
		for y in range(18, 42):
			var edge: bool = (x == 12 or x == 35 or y == 18 or y == 41)
			if edge:
				img.set_pixel(x, y, c_out)
			else:
				var col := c_skin
				# Пиксельный рельеф грудных мышц и пресса
				if y == 25 and (x >= 15 and x <= 32 and x != 23 and x != 24):
					col = c_shade
				elif (x == 23 or x == 24) and y >= 21 and y <= 38:
					col = c_shade
				elif y in [30, 34] and (x >= 18 and x <= 29):
					col = c_shade
				elif y < 23 and x > 15 and x < 32:
					col = c_high
				img.set_pixel(x, y, col)

	# Длинные свисающие руки (x: 7..11 и 36..40, y: 19..46)
	var l_arm_off: int = step_frame * 2
	var r_arm_off: int = -step_frame * 2
	for x in range(7, 12):
		for y in range(19 + l_arm_off, 46 + l_arm_off):
			var edge: bool = (x == 7 or x == 11 or y == 19 + l_arm_off or y == 45 + l_arm_off)
			img.set_pixel(x, y, c_out if edge else (c_shade if x == 10 else c_skin))
	for x in range(36, 41):
		for y in range(19 + r_arm_off, 46 + r_arm_off):
			var edge: bool = (x == 36 or x == 40 or y == 19 + r_arm_off or y == 45 + r_arm_off)
			img.set_pixel(x, y, c_out if edge else (c_shade if x == 37 else c_skin))

	# Мощные ноги-колонны (y: 42..59)
	var l_leg_h: int = 59 - step_frame * 2
	var r_leg_h: int = 57 + step_frame * 2
	for x in range(14, 23):
		for y in range(42, l_leg_h):
			var edge: bool = (x == 14 or x == 22 or y == l_leg_h - 1)
			img.set_pixel(x, y, c_out if edge else (c_shade if x > 19 else c_skin))
	for x in range(25, 34):
		for y in range(42, r_leg_h):
			var edge: bool = (x == 25 or x == 33 or y == r_leg_h - 1)
			img.set_pixel(x, y, c_out if edge else (c_shade if x < 28 else c_skin))

	return ImageTexture.create_from_image(img)

func apply_config(cfg: Dictionary, p_type: String = "wanderer") -> void:
	titan_type = p_type
	titan_name = str(cfg.get("name", "Бродяга"))
	max_nape_hp = float(cfg.get("nape_hp", 40.0))
	nape_hp = max_nape_hp
	move_speed = float(cfg.get("speed", 38.0))
	chase_speed = float(cfg.get("chase_speed", 66.0))
	vision_day_px = float(cfg.get("vision_cells_day", 14.0)) * 16.0
	vision_night_px = float(cfg.get("vision_cells_night", 2.5)) * 16.0

func get_nape_world_pos() -> Vector2:
	return global_position + Vector2(0, -34.0)

func trap_caught() -> void:
	trap_stun_timer = 10.0
	state = State.STUNNED
	nape_hp = maxf(0.0, nape_hp - 12.0)

func _physics_process(delta: float) -> void:
	if state == State.DYING:
		ash_fade -= delta * 0.45
		if ash_fade <= 0.0:
			if world_ref and world_ref.has_method("on_titan_killed"):
				world_ref.on_titan_killed(global_position)
			queue_free()
		queue_redraw()
		return

	if trap_stun_timer > 0.0:
		trap_stun_timer -= delta
		velocity = Vector2.ZERO
		return

	var is_night: bool = false
	if world_ref and "game_hour" in world_ref:
		var h: float = float(world_ref.game_hour)
		is_night = (h >= 20.5 or h < 5.0)

	if is_night and night_awoken_timer <= 0.0:
		state = State.DORMANT
		velocity = Vector2.ZERO
		queue_redraw()
		return
	elif not is_night and state == State.DORMANT:
		state = State.WANDER

	_sense_player(is_night)

	match state:
		State.WANDER:
			state_timer -= delta
			if state_timer <= 0.0:
				_pick_new_wander_dir()
			velocity = facing * move_speed
		State.SUSPICIOUS:
			var to_t := target_pos - global_position
			if to_t.length() > 10.0:
				facing = to_t.normalized()
				velocity = facing * move_speed
			else:
				state = State.WANDER
		State.CHASE:
			if is_instance_valid(player_ref):
				var to_p := player_ref.global_position - global_position
				if to_p.length() > 4.0:
					facing = to_p.normalized()
				velocity = facing * chase_speed
				if to_p.length() < 21.0 and player_ref.z_height < 16.0 and not player_ref.is_grabbed:
					state = State.GRABBING
					player_ref.on_grabbed_by_titan(self)

	if velocity.length() > 5.0:
		step_anim_clock += delta

	var collided := move_and_slide()
	if collided and state == State.WANDER:
		_pick_new_wander_dir()

	queue_redraw()

func _pick_new_wander_dir() -> void:
	facing = Vector2.from_angle(randf() * TAU)
	state_timer = randf_range(2.5, 5.5)

func _sense_player(is_night: bool) -> void:
	if not is_instance_valid(player_ref) or player_ref.is_dead:
		return
	var dist: float = global_position.distance_to(player_ref.global_position)
	var max_vis: float = vision_night_px if is_night else vision_day_px
	if dist <= max_vis:
		state = State.CHASE
		state_timer = 6.0
		target_pos = player_ref.global_position

func take_blade_hit(_attacker_pos: Vector2, attacker_speed: float, base_dmg: float, max_spd: float) -> Dictionary:
	if state == State.DYING:
		return {"hit": false}
	var speed_ratio: float = clampf(attacker_speed / maxf(max_spd, 1.0), 0.3, 1.3)
	var final_dmg: float = base_dmg * (0.5 + speed_ratio)
	nape_hp -= final_dmg
	var killed: bool = false
	if nape_hp <= 0.0:
		nape_hp = 0.0
		state = State.DYING
		killed = true
	return {"hit": true, "damage": final_dmg, "zone": "УЗЕЛ", "killed": killed}

func release_grab_stunned() -> void:
	state = State.WANDER
	state_timer = 3.0

func _draw() -> void:
	var t: ImageTexture = tex_titan_night if state == State.DORMANT else (tex_titan_day_1 if int(floor(step_anim_clock * 4.0)) % 2 == 0 else tex_titan_day_2)
	if t != null:
		draw_texture(t, Vector2(-24, -58), Color(1, 1, 1, ash_fade))
	if nape_hp < max_nape_hp and state != State.DYING:
		var ratio: float = clampf(nape_hp / max_nape_hp, 0.0, 1.0)
		draw_rect(Rect2(Vector2(-14, -62), Vector2(28, 3)), Color("#0e1116"), true)
		draw_rect(Rect2(Vector2(-13, -61), Vector2(26.0 * ratio, 1)), Color("#d94343"), true)
