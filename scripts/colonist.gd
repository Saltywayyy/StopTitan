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

var move_speed: float = 65.0
var work_timer: float = 4.0
var shoot_cooldown: float = 0.0
var walk_phase: float = 0.0
var last_action_text: String = "В лагере"
var bolt_shot_line_timer: float = 0.0
var bolt_target_pos: Vector2 = Vector2.ZERO

var world_ref: Node2D
var player_ref: Node2D
var home_pos: Vector2 = Vector2(-2 * 16, 0)
var wander_offset: Vector2 = Vector2.ZERO

var tex_idle: ImageTexture
var tex_walk: ImageTexture

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	col.shape = circle
	add_child(col)
	_pick_wander_offset()
	_rebuild_sprites()

func setup_profile(p_name: String, p_prof: String, p_trait: String, p_role: String, recruited: bool) -> void:
	col_name = p_name
	profession = p_prof
	trait_name = p_trait
	job_role = p_role
	is_recruited = recruited
	_rebuild_sprites()

func _rebuild_sprites() -> void:
	var coat := Color("#543d28")
	var hair := Color("#3d271d")
	if job_role == "cook_med":
		coat = Color("#2f4854")
		hair = Color("#593122")
	elif job_role == "guard":
		coat = Color("#2b3442")
		hair = Color("#181a20")
	tex_idle = _make_colonist_sprite(coat, hair, 0)
	tex_walk = _make_colonist_sprite(coat, hair, 1)

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
	wander_offset = Vector2(randf_range(-48.0, 48.0), randf_range(-32.0, 32.0))

func _physics_process(delta: float) -> void:
	if bolt_shot_line_timer > 0.0:
		bolt_shot_line_timer -= delta
	if not is_recruited:
		velocity = Vector2.ZERO
		return
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta

	var target_pt: Vector2 = home_pos + wander_offset
	if direct_order == "follow" and is_instance_valid(player_ref):
		target_pt = player_ref.global_position + Vector2(-18, 14)

	var to_t: Vector2 = target_pt - global_position
	if to_t.length() > 8.0:
		velocity = to_t.normalized() * move_speed
		walk_phase += delta * 7.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
		walk_phase = 0.0
		if randf() < 0.012:
			_pick_wander_offset()

	work_timer -= delta
	if work_timer <= 0.0:
		work_timer = 6.0
		_perform_colonist_job()

	if (job_role == "guard" or direct_order == "follow") and shoot_cooldown <= 0.0:
		_try_crossbow_shot()

	move_and_slide()
	queue_redraw()

func _perform_colonist_job() -> void:
	if not is_instance_valid(world_ref) or not is_instance_valid(player_ref):
		return
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

func _draw() -> void:
	var t: ImageTexture = tex_walk if (velocity.length() > 8.0 and int(floor(walk_phase)) % 2 == 1) else tex_idle
	if t != null:
		draw_texture(t, Vector2(-8, -22))
	if bolt_shot_line_timer > 0.0:
		draw_line(Vector2(0, -10), bolt_target_pos - global_position, Color("#ffd166"), 1.0)
