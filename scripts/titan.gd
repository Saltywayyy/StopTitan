@warning_ignore("integer_division")
class_name TitanEntity
extends CharacterBody2D

enum State { DORMANT, WANDER, SUSPICIOUS, CHASE, GRABBING, STUNNED, DYING }

var titan_type: String = "wanderer"
var titan_name: String = "Бродяга"
var max_nape_hp: float = 40.0
var nape_hp: float = 40.0
var move_speed: float = 36.0
var chase_speed: float = 64.0
var vision_day_px: float = 240.0
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

var wall_attack_cooldown: float = 0.0
var stuck_timer: float = 0.0
var last_frame_pos: Vector2 = Vector2.ZERO
var steer_bias_sign: float = 1.0

var world_ref: Node2D
var player_ref: Node2D

static var tex_wanderer_frames: Array[ImageTexture] = []
static var tex_wanderer_night: ImageTexture
static var tex_crawler_frames: Array[ImageTexture] = []
static var tex_crawler_night: ImageTexture
static var tex_wanderer_silhouette: ImageTexture
static var tex_crawler_silhouette: ImageTexture

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0 if titan_type != "crawler" else 7.5
	col.shape = circle
	add_child(col)
	steer_bias_sign = 1.0 if (randi() % 2 == 0) else -1.0
	last_frame_pos = global_position
	_pick_new_wander_dir()
	_ensure_coherent_titan_sprites()

static func _ensure_coherent_titan_sprites() -> void:
	if not tex_wanderer_frames.is_empty():
		return
	for f in range(3):
		tex_wanderer_frames.append(_build_hunched_titan_sprite(false, f))
	tex_wanderer_night = _build_hunched_titan_sprite(true, 0)

	for f in range(2):
		tex_crawler_frames.append(_build_crawler_titan_sprite(false, f))
	tex_crawler_night = _build_crawler_titan_sprite(true, 0)

	tex_wanderer_silhouette = _build_alpha_outline_texture(tex_wanderer_frames[0])
	tex_crawler_silhouette = _build_alpha_outline_texture(tex_crawler_frames[0])

# Строит тонкий 1px чёрный контур по альфа-каналу спрайта (для Пункта 1.4)
static func _build_alpha_outline_texture(src_tex: Texture2D) -> ImageTexture:
	if src_tex == null:
		return null
	var src_img: Image = src_tex.get_image()
	if src_img == null or src_img.is_empty():
		return null
	var w: int = src_img.get_width()
	var h: int = src_img.get_height()
	var out_img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var dirs := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for y in range(h):
		for x in range(w):
			var a: float = src_img.get_pixel(x, y).a
			if a > 0.5:
				var is_border: bool = false
				for d in dirs:
					var nx: int = x + d.x
					var ny: int = y + d.y
					if nx < 0 or ny < 0 or nx >= w or ny >= h or src_img.get_pixel(nx, ny).a <= 0.5:
						is_border = true
						break
				if is_border:
					out_img.set_pixel(x, y, Color(0.04, 0.04, 0.05, 0.96))
	return ImageTexture.create_from_image(out_img)

static func _apply_clean_outline(img: Image, outline_col: Color) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var copy: Image = img.duplicate()
	var dirs := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for y in range(h):
		for x in range(w):
			if copy.get_pixel(x, y).a == 0.0:
				for d in dirs:
					var nx: int = x + d.x
					var ny: int = y + d.y
					if nx >= 0 and ny >= 0 and nx < w and ny < h:
						if copy.get_pixel(nx, ny).a > 0.8:
							img.set_pixel(x, y, outline_col)
							break

static func _build_hunched_titan_sprite(dormant: bool, frame: int) -> ImageTexture:
	var w: int = 48
	var h: int = 64
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)

	var c_out := Color("#171412")
	var c_hi := Color("#465063") if dormant else Color("#b59893")
	var c_base := Color("#323947") if dormant else Color("#967873")
	var c_shade := Color("#222733") if dormant else Color("#6e534f")
	var c_cavity := Color("#151820") if dormant else Color("#3b2626")
	var c_mane := Color("#2a303d") if dormant else Color("#c9b58c")
	var c_mane_sh := Color("#1c2029") if dormant else Color("#8c7853")

	var step_l: int = -2 if frame == 1 else (2 if frame == 2 else 0)
	var step_r: int = 2 if frame == 1 else (-2 if frame == 2 else 0)
	var hunch_bob: int = 1 if frame != 0 else 0

	for y in range(54, 62):
		for x in range(9, 39):
			var d_sh: float = Vector2((x - 24.0) / 14.5, (y - 58.0) / 3.8).length()
			if d_sh <= 1.0:
				img.set_pixel(x, y, Color(0.04, 0.05, 0.08, 0.68))

	for side in [-1, 1]:
		var s_off: int = step_l if side == -1 else step_r
		var hip_x: float = 24.0 + side * 7.5
		var knee_x: float = 24.0 + side * 10.5
		var foot_x: float = 24.0 + side * 9.5
		for y in range(38, 58 + s_off):
			var t: float = float(y - 38) / 20.0
			var cx: float = lerpf(hip_x, knee_x, t * 2.0) if t < 0.5 else lerpf(knee_x, foot_x, (t - 0.5) * 2.0)
			var rad: float = 4.6 if t < 0.65 else 3.8
			for x in range(int(cx - rad), int(cx + rad) + 1):
				var col: Color = c_base
				if x < cx - 1.0 and y < 48:
					col = c_hi
				elif x > cx + 1.5 or y > 52 + s_off:
					col = c_shade
				img.set_pixel(x, y, col)
		var fy: int = 57 + s_off
		for fx in range(int(foot_x - 4), int(foot_x + 5)):
			img.set_pixel(fx, fy, c_base)
			if (fx - int(foot_x)) % 2 == 0:
				img.set_pixel(fx, fy + 1, c_hi)

	for y in range(15 + hunch_bob, 43 + hunch_bob):
		var py: float = float(y - (15 + hunch_bob)) / 28.0
		var half_w: float = 14.5 - pow(absf(py - 0.32), 1.4) * 9.5
		for x in range(int(24.0 - half_w), int(24.0 + half_w) + 1):
			var dx: float = x - 24.0
			var col: Color = c_base
			if py < 0.22 and dx < 6.0:
				col = c_hi
			elif dx > half_w * 0.52 or py > 0.82:
				col = c_shade

			var belly_d: float = Vector2(dx / 7.5, (y - (34.0 + hunch_bob)) / 5.5).length()
			if belly_d <= 1.0:
				col = c_cavity if belly_d < 0.78 else c_shade
			elif y in [22 + hunch_bob, 25 + hunch_bob, 28 + hunch_bob] and absf(dx) >= 3.0 and absf(dx) <= 10.5:
				col = c_shade
			img.set_pixel(x, y, col)

	for side in [-1, 1]:
		var arm_swing: int = -step_l if side == -1 else -step_r
		var sh_pt := Vector2(24.0 + side * 13.0, 19.0 + hunch_bob)
		var el_pt := Vector2(24.0 + side * 19.5, 29.0 + hunch_bob + arm_swing * 0.5)
		var wr_pt := Vector2(24.0 + side * 17.5, 43.0 + hunch_bob + arm_swing)

		for seg in range(2):
			var p0: Vector2 = sh_pt if seg == 0 else el_pt
			var p1: Vector2 = el_pt if seg == 0 else wr_pt
			var r0: float = 4.2 if seg == 0 else 3.4
			var r1: float = 3.4 if seg == 0 else 3.8
			for s in range(16):
				var t: float = float(s) / 15.0
				var cp: Vector2 = p0.lerp(p1, t)
				var cr: float = lerpf(r0, r1, t)
				for dy in range(int(-cr - 1), int(cr + 2)):
					for dx in range(int(-cr - 1), int(cr + 2)):
						if Vector2(dx, dy).length() <= cr:
							var px: int = clampi(int(cp.x + dx), 1, w - 2)
							var py: int = clampi(int(cp.y + dy), 1, h - 2)
							var col: Color = c_hi if (dy < -1 or (side == -1 and dx < 0)) else (c_shade if dy > 1 else c_base)
							img.set_pixel(px, py, col)

	var head_cx: int = 24
	var head_cy: int = 19 + hunch_bob

	for y in range(head_cy - 9, head_cy + 5):
		for x in range(head_cx - 10, head_cx + 11):
			var ang: float = atan2(y - head_cy, x - head_cx)
			var spike: float = sin(ang * 9.0) * 1.8
			var d: float = Vector2(x - head_cx, y - head_cy).length()
			if d >= 4.2 and d <= 8.8 + spike and y < head_cy + 3:
				img.set_pixel(x, y, c_mane if y < head_cy - 1 else c_mane_sh)

	for y in range(head_cy - 4, head_cy + 6):
		for x in range(head_cx - 5, head_cx + 6):
			if Vector2((x - head_cx) / 5.2, (y - head_cy) / 5.5).length() <= 1.0:
				img.set_pixel(x, y, c_shade if y < head_cy else c_base)

	for ex in [head_cx - 2, head_cx + 2]:
		img.set_pixel(ex, head_cy - 1, c_out)
		if not dormant:
			img.set_pixel(ex, head_cy, Color("#f5f0e6"))
	for y in range(head_cy + 2, head_cy + 5):
		for x in range(head_cx - 2, head_cx + 3):
			img.set_pixel(x, y, c_cavity)
	for x in range(head_cx - 2, head_cx + 3, 2):
		img.set_pixel(x, head_cy + 2, Color("#e8dfd5"))

	_apply_clean_outline(img, c_out)
	return ImageTexture.create_from_image(img)

static func _build_crawler_titan_sprite(dormant: bool, frame: int) -> ImageTexture:
	var w: int = 48
	var h: int = 32
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_out := Color("#171412")
	var c_hi := Color("#465063") if dormant else Color("#b59893")
	var c_base := Color("#323947") if dormant else Color("#967873")
	var c_shade := Color("#222733") if dormant else Color("#6e534f")
	var step: int = 2 if frame == 1 else -2

	for y in range(25, 30):
		for x in range(8, 40):
			if Vector2((x - 24.0) / 15.0, (y - 27.5) / 2.5).length() <= 1.0:
				img.set_pixel(x, y, Color(0.04, 0.05, 0.08, 0.62))

	for x in range(11, 35):
		var arch: int = int(sin(float(x - 11) / 24.0 * PI) * 4.0)
		for y in range(11 - arch, 20 - arch / 2):
			var col := c_hi if y < 13 - arch else (c_shade if y > 17 - arch / 2 else c_base)
			img.set_pixel(x, y, col)

	var limbs := [
		[Vector2(14, 15), Vector2(7 + step, 21), Vector2(9 + step, 28)],
		[Vector2(20, 17), Vector2(16 - step, 23), Vector2(17 - step, 29)],
		[Vector2(28, 16), Vector2(32 + step, 23), Vector2(30 + step, 29)],
		[Vector2(33, 15), Vector2(40 - step, 21), Vector2(38 - step, 28)]
	]
	for l in limbs:
		for seg in range(2):
			var p0: Vector2 = l[seg]
			var p1: Vector2 = l[seg + 1]
			for s in range(10):
				var cp: Vector2 = p0.lerp(p1, float(s) / 9.0)
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						if abs(dx) + abs(dy) <= 2:
							img.set_pixel(clampi(int(cp.x + dx), 1, w - 2), clampi(int(cp.y + dy), 1, h - 2), c_base if dy <= 0 else c_shade)

	for y in range(11, 20):
		for x in range(32, 42):
			if Vector2((x - 36.5) / 4.8, (y - 15.5) / 4.2).length() <= 1.0:
				img.set_pixel(x, y, c_hi if y < 14 else c_base)
	if not dormant:
		img.set_pixel(39, 15, Color("#f5f0e6"))

	_apply_clean_outline(img, c_out)
	return ImageTexture.create_from_image(img)

func apply_config(cfg: Dictionary, p_type: String = "wanderer") -> void:
	titan_type = p_type
	titan_name = str(cfg.get("name", "Бродяга"))
	max_nape_hp = float(cfg.get("nape_hp", 40.0))
	nape_hp = max_nape_hp
	move_speed = float(cfg.get("speed", 36.0))
	chase_speed = float(cfg.get("chase_speed", 64.0))
	vision_day_px = float(cfg.get("vision_cells_day", 15.0)) * 16.0
	vision_night_px = float(cfg.get("vision_cells_night", 2.5)) * 16.0

func get_nape_world_pos() -> Vector2:
	return global_position + Vector2(0, -34.0)

func trap_caught() -> void:
	trap_stun_timer = 10.0
	state = State.STUNNED
	nape_hp = maxf(0.0, nape_hp - 12.0)

func _has_line_of_sight_to_player() -> bool:
	if not is_instance_valid(world_ref) or not is_instance_valid(player_ref):
		return false
	var diff: Vector2 = player_ref.global_position - global_position
	var dist: float = diff.length()
	if dist <= 18.0:
		return true
	var dir: Vector2 = diff / dist
	var d: float = 14.0
	while d < dist - 14.0:
		var c: Vector2i = world_ref._world_to_cell(global_position + dir * d)
		if world_ref.wall_map.has(c):
			var w_data: Dictionary = world_ref.wall_map[c]
			var b_id: int = int(w_data.get("id", 0))
			var open_door: bool = bool(w_data.get("is_door", false)) and bool(w_data.get("door_open", false))
			if b_id != 8 and not open_door:
				return false
		d += 12.0
	return true

func _handle_obstacle_collision(delta: float) -> void:
	if wall_attack_cooldown > 0.0:
		wall_attack_cooldown -= delta

	var moved_dist: float = global_position.distance_to(last_frame_pos)
	last_frame_pos = global_position

	if velocity.length() > 10.0 and moved_dist < 0.45:
		stuck_timer += delta
	else:
		stuck_timer = maxf(0.0, stuck_timer - delta * 2.0)

	if get_slide_collision_count() == 0 and stuck_timer < 0.25:
		return

	if is_instance_valid(world_ref):
		var probe_cell: Vector2i = world_ref._world_to_cell(global_position + facing.normalized() * 15.0)
		if world_ref.wall_map.has(probe_cell):
			var w_data: Dictionary = world_ref.wall_map[probe_cell]
			var b_id: int = int(w_data.get("id", 0))
			if b_id == 8:
				world_ref._remove_wall(probe_cell, false)
				world_ref.decor_map[probe_cell] = "stump"
				stuck_timer = 0.0
				return
			elif state == State.CHASE and wall_attack_cooldown <= 0.0:
				wall_attack_cooldown = 1.35
				var cur_hp: int = int(w_data.get("hp", 30)) - 12
				w_data["hp"] = cur_hp
				if is_instance_valid(player_ref) and global_position.distance_to(player_ref.global_position) <= 180.0:
					world_ref.play_sfx("hit")
				if cur_hp <= 0:
					world_ref._remove_wall(probe_cell, true)
				return

	if get_slide_collision_count() > 0:
		var col_norm: Vector2 = get_slide_collision(0).get_normal()
		var tangent := Vector2(-col_norm.y, col_norm.x) * steer_bias_sign
		facing = (facing * 0.35 + tangent * 0.65).normalized()
		velocity = facing * (chase_speed if state == State.CHASE else move_speed)

	if stuck_timer >= 0.45:
		stuck_timer = 0.0
		steer_bias_sign = -steer_bias_sign
		facing = facing.rotated(PI * 0.62 * steer_bias_sign).normalized()
		if state == State.CHASE:
			state = State.SUSPICIOUS
			target_pos = global_position + facing * 72.0
			state_timer = 2.5

func _physics_process(delta: float) -> void:
	if state == State.DYING:
		ash_fade -= delta * 0.45
		if ash_fade <= 0.0:
			if world_ref and world_ref.has_method("on_titan_killed"):
				world_ref.on_titan_killed(global_position)
			queue_free()
		return

	if trap_stun_timer > 0.0:
		trap_stun_timer -= delta
		velocity = Vector2.ZERO
		if trap_stun_timer <= 0.0 and state == State.STUNNED:
			state = State.WANDER
			_pick_new_wander_dir()
		return

	# В состоянии GRABBING титан держит героя на месте; если герой погиб или вырвался — возвращается в WANDER
	if state == State.GRABBING:
		velocity = Vector2.ZERO
		if not is_instance_valid(player_ref) or player_ref.is_dead or not player_ref.is_grabbed:
			state = State.WANDER
			_pick_new_wander_dir()
		return

	var is_night: bool = false
	if world_ref and "game_hour" in world_ref:
		var h: float = float(world_ref.game_hour)
		is_night = (h >= 20.5 or h < 5.0)

	if is_night and night_awoken_timer <= 0.0:
		state = State.DORMANT
		velocity = Vector2.ZERO
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
			state_timer -= delta
			var to_t := target_pos - global_position
			if to_t.length() > 10.0 and state_timer > 0.0:
				facing = to_t.normalized()
				velocity = facing * move_speed
			else:
				state = State.WANDER
				_pick_new_wander_dir()
		State.CHASE:
			state_timer -= delta
			if is_instance_valid(player_ref) and not player_ref.is_dead and state_timer > 0.0:
				var to_p := player_ref.global_position - global_position
				if to_p.length() > 4.0:
					facing = to_p.normalized()
				velocity = facing * chase_speed
				if to_p.length() < 21.0 and player_ref.z_height < 16.0 and not player_ref.is_grabbed:
					state = State.GRABBING
					velocity = Vector2.ZERO
					player_ref.on_grabbed_by_titan(self)
			else:
				state = State.WANDER
				_pick_new_wander_dir()

	if velocity.length() > 5.0:
		step_anim_clock += delta * (1.45 if state == State.CHASE else 1.0)
	else:
		step_anim_clock += delta * 0.4

	move_and_slide()
	_handle_obstacle_collision(delta)

func _pick_new_wander_dir() -> void:
	facing = Vector2.from_angle(randf() * TAU)
	if is_instance_valid(world_ref):
		var c: Vector2i = world_ref._world_to_cell(global_position + facing * 24.0)
		if world_ref.wall_map.has(c):
			facing = -facing
	state_timer = randf_range(2.5, 5.5)

func _sense_player(is_night: bool) -> void:
	if not is_instance_valid(player_ref) or player_ref.is_dead:
		return
	var dist: float = global_position.distance_to(player_ref.global_position)
	var max_vis: float = vision_night_px if is_night else vision_day_px
	if dist <= max_vis and _has_line_of_sight_to_player():
		state = State.CHASE
		state_timer = 5.0
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
		if is_instance_valid(player_ref) and player_ref.is_grabbed and player_ref.grabbing_titan == self:
			player_ref.is_grabbed = false
			player_ref.grabbing_titan = null
		killed = true
	return {"hit": true, "damage": final_dmg, "zone": "УЗЕЛ", "killed": killed}

func release_grab_stunned() -> void:
	trap_stun_timer = 3.0
	state = State.STUNNED
	velocity = Vector2.ZERO

func on_player_died_in_grab() -> void:
	state = State.WANDER
	_pick_new_wander_dir()

# ПУНКТ 1.3 и 1.4: Отрисовка титана и его силуэта за препятствиями из Y-Sort конвейера main._draw()
func draw_entity_onto(canvas: CanvasItem) -> void:
	_ensure_coherent_titan_sprites()
	var p: Vector2 = global_position
	var is_crawler: bool = (titan_type == "crawler")
	var t: ImageTexture = null

	if state == State.DORMANT:
		t = tex_crawler_night if is_crawler else tex_wanderer_night
	else:
		var frames_arr: Array[ImageTexture] = tex_crawler_frames if is_crawler else tex_wanderer_frames
		var f_idx: int = int(floor(step_anim_clock * 3.5)) % frames_arr.size() if velocity.length() > 5.0 else 0
		t = frames_arr[f_idx]

	if t != null:
		var sway_x: float = round(sin(step_anim_clock * 3.5) * 1.5) if velocity.length() > 5.0 else 0.0
		var lunge_y: float = -2.0 if (state == State.CHASE or state == State.GRABBING) else 0.0
		var offset := p + Vector2(-24.0 + sway_x, (-30.0 if is_crawler else -58.0) + lunge_y)
		var flip_h: bool = (facing.x < -0.25)
		var sz := Vector2(-48.0 if flip_h else 48.0, 32.0 if is_crawler else 64.0)
		if flip_h:
			offset.x += 48.0
		canvas.draw_texture_rect(t, Rect2(offset, sz), false, Color(1, 1, 1, ash_fade))

	if nape_hp < max_nape_hp and state != State.DYING:
		var ratio: float = clampf(nape_hp / max_nape_hp, 0.0, 1.0)
		var bar_y: float = -34.0 if is_crawler else -62.0
		canvas.draw_rect(Rect2(p + Vector2(-14, bar_y), Vector2(28, 3)), Color("#171412"), true)
		canvas.draw_rect(Rect2(p + Vector2(-13, bar_y + 1), Vector2(26.0 * ratio, 1)), Color("#d94343"), true)

func draw_occluded_silhouette(canvas: CanvasItem) -> void:
	_ensure_coherent_titan_sprites()
	var is_crawler: bool = (titan_type == "crawler")
	var sil_tex: ImageTexture = tex_crawler_silhouette if is_crawler else tex_wanderer_silhouette
	if sil_tex == null:
		return
	var p: Vector2 = global_position
	var sway_x: float = round(sin(step_anim_clock * 3.5) * 1.5) if velocity.length() > 5.0 else 0.0
	var offset := p + Vector2(-24.0 + sway_x, -30.0 if is_crawler else -58.0)
	var flip_h: bool = (facing.x < -0.25)
	var sz := Vector2(-48.0 if flip_h else 48.0, 32.0 if is_crawler else 64.0)
	if flip_h:
		offset.x += 48.0
	canvas.draw_texture_rect(sil_tex, Rect2(offset, sz), false)
