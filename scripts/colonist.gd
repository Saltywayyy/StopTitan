@warning_ignore("integer_division")
class_name ColonistEntity
extends CharacterBody2D

var is_recruited: bool = false
var col_name: String = "Марк"
var profession: String = "Плотник"
var trait_name: String = "Смелый"

var hp: float = 100.0
var hunger: float = 85.0
var mood: float = 78.0
var mental_break: String = ""

var job_role: String = "gather"
var direct_order: String = "auto"

var move_speed: float = 52.0
var work_timer: float = 4.5
var work_anim_timer: float = 0.0
var pause_at_point_timer: float = 0.0
var shoot_cooldown: float = 0.0
var walk_phase: float = 0.0
var facing_left: bool = false
var last_action_text: String = "В лагере"
var bolt_shot_line_timer: float = 0.0
var bolt_target_pos: Vector2 = Vector2.ZERO

var world_ref: Node2D
var player_ref: Node2D
var home_pos: Vector2 = Vector2(-2 * 16, 0)
var wander_offset: Vector2 = Vector2.ZERO
var work_waypoints: Array[Vector2] = []
var current_wp_idx: int = 0

var tex_idle: Texture2D
var tex_walk: Texture2D
var col_tint: Color = Color.WHITE

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	col.shape = circle
	add_child(col)
	_build_role_waypoints()
	_rebuild_sprites()

func setup_profile(p_name: String, p_prof: String, p_trait: String, p_role: String, recruited: bool) -> void:
	col_name = p_name
	profession = p_prof
	trait_name = p_trait
	job_role = p_role
	is_recruited = recruited
	_build_role_waypoints()
	_rebuild_sprites()

func _build_role_waypoints() -> void:
	work_waypoints.clear()
	match job_role:
		"gather":
			work_waypoints = [
				Vector2(-3 * 16 + 8, -4 * 16 + 8),
				Vector2(2 * 16 + 8, 0 * 16 + 8),
				Vector2(-12 * 16 + 8, -4 * 16 + 8),
				Vector2(1 * 16 + 8, 2 * 16 + 8)
			]
		"cook_med":
			work_waypoints = [
				Vector2(-5 * 16 + 8, 2 * 16 + 8),
				Vector2(4 * 16 + 8, 2 * 16 + 8),
				Vector2(7 * 16 + 8, -5 * 16 + 8),
				Vector2(-8 * 16 + 8, -4 * 16 + 8)
			]
		"guard":
			work_waypoints = [
				Vector2(0 * 16 + 8, 5 * 16 + 8),
				Vector2(10 * 16 + 8, 1 * 16 + 8),
				Vector2(0 * 16 + 8, -11 * 16 + 8),
				Vector2(-9 * 16 + 8, 3 * 16 + 8)
			]
		_:
			work_waypoints = [home_pos, home_pos + Vector2(48, 0), home_pos + Vector2(0, 48)]
	current_wp_idx = randi() % maxi(1, work_waypoints.size())

func _rebuild_sprites() -> void:
	var coat := Color("#543d28")
	var hair := Color("#3d271d")
	if job_role == "cook_med":
		coat = Color("#2f4854")
		hair = Color("#593122")
	elif job_role == "guard":
		coat = Color("#2b3442")
		hair = Color("#181a20")

	var fb_idle := _make_colonist_sprite(coat, hair, 0)
	var fb_walk := _make_colonist_sprite(coat, hair, 1)
	var frames: Array[Texture2D] = ArtLoader.get_frames("colonist", [fb_idle, fb_walk])
	tex_idle = frames[0] if frames.size() > 0 else fb_idle
	tex_walk = frames[1] if frames.size() > 1 else tex_idle

	if ArtLoader.has_file("colonist"):
		col_tint = Color.WHITE.lerp(coat.lightened(0.35), 0.35)
	else:
		col_tint = Color.WHITE

func _make_colonist_sprite(c_coat: Color, c_hair: Color, step: int) -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	var c_out := Color("#0f1318")
	var c_skin := Color("#dfb48c")
	var c_pants := Color("#222730")

	for x in range(4, 12):
		img.set_pixel(x, 22, Color(0, 0, 0, 0.42))
		img.set_pixel(x, 23, Color(0, 0, 0, 0.25))

	for x in range(4, 12):
		for y in range(3, 11):
			if x == 4 or x == 11 or y == 3 or y == 10:
				img.set_pixel(x, y, c_out)
			elif y <= 5 or x == 5 or x == 10:
				img.set_pixel(x, y, c_hair)
			else:
				img.set_pixel(x, y, c_skin)
	img.set_pixel(6, 7, c_out)
	img.set_pixel(9, 7, c_out)

	for x in range(3, 13):
		for y in range(11, 18):
			if x == 3 or x == 12 or y == 17:
				img.set_pixel(x, y, c_out)
			elif y == 15:
				img.set_pixel(x, y, Color("#241810"))
			else:
				img.set_pixel(x, y, c_coat)

	var l_off: int = -step
	var r_off: int = step
	for x in range(4, 8):
		for y in range(18, 22 + l_off):
			img.set_pixel(x, y, c_out if (x == 4 or x == 7 or y == 21 + l_off) else c_pants)
	for x in range(8, 12):
		for y in range(18, 22 + r_off):
			img.set_pixel(x, y, c_out if (x == 8 or x == 11 or y == 21 + r_off) else c_pants)

	return ImageTexture.create_from_image(img)

func _pick_wander_offset() -> void:
	if not work_waypoints.is_empty():
		current_wp_idx = (current_wp_idx + 1) % work_waypoints.size()

func _compute_separation_force() -> Vector2:
	var push := Vector2.ZERO
	if get_parent() == null:
		return push
	for sibling in get_parent().get_children():
		if sibling != self and sibling is Node2D:
			var diff: Vector2 = global_position - sibling.global_position
			var d: float = diff.length()
			if d > 0.1 and d < 18.0:
				push += (diff / d) * ((18.0 - d) / 18.0) * 42.0
	return push

func _physics_process(delta: float) -> void:
	if bolt_shot_line_timer > 0.0:
		bolt_shot_line_timer -= delta
	if work_anim_timer > 0.0:
		work_anim_timer -= delta
	if not is_recruited:
		velocity = Vector2.ZERO
		return
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta

	var target_pt: Vector2 = work_waypoints[current_wp_idx] if not work_waypoints.is_empty() else (home_pos + wander_offset)
	if direct_order == "follow" and is_instance_valid(player_ref):
		target_pt = player_ref.global_position + Vector2(-18, 14)

	if pause_at_point_timer > 0.0:
		pause_at_point_timer -= delta
		velocity = velocity.move_toward(Vector2.ZERO, 320.0 * delta)
		walk_phase = 0.0
	else:
		var to_t: Vector2 = target_pt - global_position
		if to_t.length() > 8.0:
			var desired_vel: Vector2 = to_t.normalized() * move_speed + _compute_separation_force()
			velocity = velocity.move_toward(desired_vel, 360.0 * delta)
			walk_phase += delta * 6.5
			if absf(velocity.x) > 4.0:
				facing_left = (velocity.x < 0.0)
		else:
			velocity = Vector2.ZERO
			walk_phase = 0.0
			pause_at_point_timer = randf_range(2.2, 4.0)
			work_anim_timer = 0.8
			_pick_wander_offset()

	work_timer -= delta
	if work_timer <= 0.0:
		work_timer = 7.5
		_perform_colonist_job()

	if (job_role == "guard" or direct_order == "follow") and shoot_cooldown <= 0.0:
		_try_crossbow_shot()

	var collided := move_and_slide()
	if collided and pause_at_point_timer <= 0.0:
		_pick_wander_offset()

func _perform_colonist_job() -> void:
	if not is_instance_valid(world_ref) or not is_instance_valid(player_ref):
		return
	work_anim_timer = 0.65
	if job_role == "gather":
		player_ref.surv.add_item("wood", 1)
	elif job_role == "cook_med":
		if global_position.distance_to(player_ref.global_position) <= 95.0:
			player_ref.surv.bleeding_rate = 0.0
			player_ref.surv.hp = minf(player_ref.surv.max_hp, player_ref.surv.hp + 15.0)

func _try_crossbow_shot() -> void:
	if not world_ref or not world_ref.has_method("colonist_shoot_nearest_titan"):
		return
	var res: Dictionary = world_ref.colonist_shoot_nearest_titan(global_position, 195.0, 14.0)
	if bool(res.get("hit", false)):
		shoot_cooldown = 3.2
		bolt_shot_line_timer = 0.25
		bolt_target_pos = res.get("pos", global_position)

# ПУНКТ 1.3 и 1.4: Отрисовка колониста и его силуэта за препятствиями из Y-Sort конвейера main._draw()
func draw_entity_onto(canvas: CanvasItem) -> void:
	var p: Vector2 = global_position
	Phase1Visuals.draw_soft_shadow(canvas, p + Vector2(2, 0), Vector2(15, 7), 0.45)
	var t: Texture2D = tex_walk if (velocity.length() > 8.0 and int(floor(walk_phase)) % 2 == 1) else tex_idle
	if t != null:
		var sz: Vector2 = ArtLoader.get_frame_size("colonist")
		var bob_y: float = -1.0 if (velocity.length() > 8.0 and int(floor(walk_phase * 2.0)) % 2 == 1) else 0.0
		var draw_w: float = -sz.x if facing_left else sz.x
		var draw_x: float = sz.x * 0.5 if facing_left else -sz.x * 0.5
		canvas.draw_texture_rect(t, Rect2(p + Vector2(draw_x, -22.0 + bob_y), Vector2(draw_w, sz.y)), false, col_tint)

	if work_anim_timer > 0.0:
		var swing: float = sin(work_anim_timer * 18.0) * 3.0
		var tool_x: float = -6.0 if facing_left else 6.0
		canvas.draw_line(p + Vector2(tool_x, -11.0), p + Vector2(tool_x + (-4.0 if facing_left else 4.0), -15.0 + swing), Color("#d0dae6"), 1.5)

	if bolt_shot_line_timer > 0.0:
		canvas.draw_line(p + Vector2(0, -10), bolt_target_pos, Color("#ffd166"), 1.0)

func draw_occluded_silhouette(canvas: CanvasItem, sil_tex: Texture2D) -> void:
	if sil_tex == null:
		return
	var p: Vector2 = global_position
	var sz: Vector2 = ArtLoader.get_frame_size("colonist")
	var bob_y: float = -1.0 if (velocity.length() > 8.0 and int(floor(walk_phase * 2.0)) % 2 == 1) else 0.0
	var draw_w: float = -sz.x if facing_left else sz.x
	var draw_x: float = sz.x * 0.5 if facing_left else -sz.x * 0.5
	canvas.draw_texture_rect(sil_tex, Rect2(p + Vector2(draw_x, -22.0 + bob_y), Vector2(draw_w, sz.y)), false)
