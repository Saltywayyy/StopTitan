@warning_ignore("integer_division")
class_name MobileHUD
extends Control

var world: Node2D

var button_scale: float = 1.0
var joy_size_scale: float = 1.18
var floating_joystick: bool = true
var hud_opacity: float = 0.90

var auto_aim_enabled: bool = true
var demolish_mode: bool = false
var current_aim_target_pos: Vector2 = Vector2.ZERO
var has_valid_aim_target: bool = false
var aim_target_in_range: bool = false
var aim_target_kind: String = "none"

var joy_touch_idx: int = -1
var joy_default_center := Vector2(138.0, 496.0)
var joy_center := Vector2(138.0, 496.0)
var joy_base_radius: float = 78.0
var joy_radius: float = 88.0
var joy_knob_pos := Vector2(138.0, 496.0)
var joy_vector := Vector2.ZERO

var left_hook_touch_idx: int = -1
var right_hook_touch_idx: int = -1
var gas_touch_idx: int = -1

var btn_anim: Dictionary = {
	"attack": 0.0,
	"dash": 0.0,
	"bag": 0.0,
	"hook_l": 0.0,
	"hook_r": 0.0,
	"use": 0.0,
	"build": 0.0,
	"demolish": 0.0,
	"autoaim": 0.0,
	"settings": 0.0,
	"joy": 0.0
}

var c_attack := Vector2.ZERO
const BASE_R_ATTACK: float = 38.0

var c_dash := Vector2.ZERO
const BASE_R_DASH: float = 30.0

var c_bag := Vector2.ZERO
const BASE_R_BAG: float = 29.0

var c_hook_l := Vector2.ZERO
const BASE_R_HOOK: float = 28.0

var c_hook_r := Vector2.ZERO

var c_use := Vector2.ZERO
const BASE_R_USE: float = 26.0

var c_build := Vector2.ZERO
const BASE_R_TOOL: float = 23.0

var c_demolish := Vector2.ZERO
var c_autoaim := Vector2.ZERO
var c_settings := Vector2.ZERO

func setup(w_ref: Node2D) -> void:
	world = w_ref
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_recalc_layout()

func _get_safe_viewport_size() -> Vector2:
	var vp := Vector2(1152.0, 648.0)
	if is_inside_tree():
		vp = get_viewport_rect().size
	if vp.x <= 10.0 or vp.y <= 10.0:
		vp = Vector2(1152.0, 648.0)
	return vp

func _get_r(base_r: float) -> float:
	return base_r * button_scale

func _recalc_layout() -> void:
	var vp: Vector2 = _get_safe_viewport_size()

	joy_radius = joy_base_radius * joy_size_scale
	joy_default_center = Vector2(clampf(joy_radius + 36.0, 118.0, 210.0), vp.y - joy_radius - 52.0)
	if joy_touch_idx == -1:
		joy_center = joy_default_center
		joy_knob_pos = joy_center

	var sc: float = button_scale
	c_attack = Vector2(vp.x - 98.0 * sc, vp.y - 98.0 * sc)
	c_dash = Vector2(vp.x - 66.0 * sc, vp.y - 188.0 * sc)
	c_bag = Vector2(vp.x - 56.0 * sc, vp.y - 272.0 * sc)

	c_hook_l = Vector2(vp.x - 180.0 * sc, vp.y - 86.0 * sc)
	c_hook_r = Vector2(vp.x - 144.0 * sc, vp.y - 158.0 * sc)
	c_use = Vector2(vp.x - 246.0 * sc, vp.y - 78.0 * sc)

	c_settings = Vector2(vp.x - 56.0 * sc, vp.y - 344.0 * sc)
	c_autoaim = Vector2(vp.x - 124.0 * sc, vp.y - 252.0 * sc)
	c_build = Vector2(vp.x - 180.0 * sc, vp.y - 228.0 * sc)
	c_demolish = Vector2(vp.x - 234.0 * sc, vp.y - 204.0 * sc)

func _is_in_joystick_touch_zone(pt: Vector2) -> bool:
	var vp: Vector2 = _get_safe_viewport_size()
	var zone_rect := Rect2(0.0, vp.y - 310.0, 310.0, 310.0)
	return zone_rect.has_point(pt) or pt.distance_to(joy_center) <= joy_radius + 36.0

func is_point_on_mobile_controls(pt: Vector2) -> bool:
	if _is_in_joystick_touch_zone(pt):
		return true
	var circles := [
		{"c": c_attack, "r": _get_r(BASE_R_ATTACK)},
		{"c": c_dash, "r": _get_r(BASE_R_DASH)},
		{"c": c_bag, "r": _get_r(BASE_R_BAG)},
		{"c": c_hook_l, "r": _get_r(BASE_R_HOOK)},
		{"c": c_hook_r, "r": _get_r(BASE_R_HOOK)},
		{"c": c_use, "r": _get_r(BASE_R_USE)},
		{"c": c_build, "r": _get_r(BASE_R_TOOL)},
		{"c": c_autoaim, "r": _get_r(BASE_R_TOOL)},
		{"c": c_settings, "r": _get_r(BASE_R_TOOL)}
	]
	if world and world.build_mode_active:
		circles.append({"c": c_demolish, "r": _get_r(BASE_R_TOOL)})

	for item in circles:
		if pt.distance_to(item["c"]) <= float(item["r"]) + 6.0:
			return true
	return false

func trigger_btn_anim(key: String) -> void:
	btn_anim[key] = 1.0
	queue_redraw()

func get_aim_world_position(for_hook: bool = true) -> Vector2:
	if world == null or not is_instance_valid(world.player):
		return Vector2.ZERO
	_update_auto_aim_target()
	if auto_aim_enabled and has_valid_aim_target and aim_target_in_range:
		return current_aim_target_pos

	var p_pos: Vector2 = world.player.global_position
	var base_dir: Vector2 = world.player.look_direction.normalized()
	if base_dir.length() < 0.05:
		base_dir = Vector2.DOWN

	if for_hook and world.has_method("raycast_hook_anchor"):
		var angles := [0.0, -0.18, 0.18, -0.36, 0.36, -0.55, 0.55]
		for ang in angles:
			var test_dir: Vector2 = base_dir.rotated(ang)
			var hit: Dictionary = world.raycast_hook_anchor(p_pos, test_dir, world.player.max_range_px)
			if bool(hit.get("hit", false)):
				return hit.get("pos", p_pos + test_dir * 140.0)

	return p_pos + base_dir * 160.0

func _has_clear_line_of_sight(from_pos: Vector2, to_pos: Vector2) -> bool:
	if world == null:
		return false
	var diff: Vector2 = to_pos - from_pos
	var dist: float = diff.length()
	if dist <= 16.0:
		return true
	var dir: Vector2 = diff / dist
	var step_px: float = 12.0
	var d: float = 12.0
	while d < dist - 14.0:
		var sample_pt: Vector2 = from_pos + dir * d
		var cell: Vector2i = world._world_to_cell(sample_pt)
		if world.wall_map.has(cell):
			var w_data: Dictionary = world.wall_map[cell]
			var b_id: int = int(w_data.get("id", 0))
			var is_open_door: bool = bool(w_data.get("is_door", false)) and bool(w_data.get("door_open", false))
			var is_window: bool = bool(w_data.get("is_window", false))
			if b_id != 8 and not is_open_door and not is_window:
				return false
		d += step_px
	return true

# ПУНКТ 3.4: Наглядный поиск цели для крюка и клинков (зеленый/желтый маркер в зоне досягаемости, серый/красный вне дальности)
func _update_auto_aim_target() -> void:
	has_valid_aim_target = false
	aim_target_in_range = false
	aim_target_kind = "none"
	if world == null or not is_instance_valid(world.player):
		return
	var p_pos: Vector2 = world.player.global_position
	var max_dist: float = world.player.max_range_px

	# 1. Ищем ближайшего видимого титана (даже если он чуть дальше дальности крюка — чтобы показать красный маркер «ДАЛЕКО»)
	var best_titan: Node2D = null
	var best_d: float = max_dist * 1.35
	if is_instance_valid(world.titans_layer):
		for ch in world.titans_layer.get_children():
			if ch is TitanEntity and ch.state != TitanEntity.State.DYING:
				var body_pt: Vector2 = ch.global_position + Vector2(0, -18.0 if ch.titan_type != "crawler" else -10.0)
				var d: float = p_pos.distance_to(body_pt)
				if d <= best_d and _has_clear_line_of_sight(p_pos, ch.global_position):
					best_d = d
					best_titan = ch

	if best_titan != null:
		# Цепляемся к ближайшей части спрайта титана (торс/плечи/затылок)
		var is_cr: bool = (best_titan.titan_type == "crawler")
		var t_rect := Rect2(best_titan.global_position + Vector2(-16.0, -24.0 if is_cr else -48.0), Vector2(32.0, 22.0 if is_cr else 44.0))
		current_aim_target_pos = p_pos.clamp(t_rect.position, t_rect.end)
		has_valid_aim_target = true
		aim_target_in_range = (p_pos.distance_to(current_aim_target_pos) <= max_dist)
		aim_target_kind = "titan"
		return

	# 2. Если титанов рядом нет — подсвечиваем точку зацепа крюка по направлению взгляда (стена/дерево)
	var base_dir: Vector2 = world.player.look_direction.normalized()
	if base_dir.length() < 0.05:
		base_dir = Vector2.DOWN
	if world.has_method("raycast_hook_anchor"):
		var hit: Dictionary = world.raycast_hook_anchor(p_pos, base_dir, max_dist)
		if bool(hit.get("hit", false)):
			current_aim_target_pos = hit.get("pos", p_pos + base_dir * 120.0)
			has_valid_aim_target = true
			aim_target_in_range = true
			aim_target_kind = str(hit.get("kind", "wall"))

func _process(delta: float) -> void:
	_recalc_layout()
	_update_auto_aim_target()

	for k in btn_anim.keys():
		if float(btn_anim[k]) > 0.0:
			btn_anim[k] = maxf(0.0, float(btn_anim[k]) - delta * 4.8)

	if left_hook_touch_idx != -1:
		btn_anim["hook_l"] = maxf(float(btn_anim["hook_l"]), 0.65)
	if right_hook_touch_idx != -1:
		btn_anim["hook_r"] = maxf(float(btn_anim["hook_r"]), 0.65)
	if gas_touch_idx != -1:
		btn_anim["dash"] = maxf(float(btn_anim["dash"]), 0.65)
	if joy_touch_idx != -1:
		btn_anim["joy"] = maxf(float(btn_anim["joy"]), 0.65)

	if world and is_instance_valid(world.player):
		world.player.mobile_move_vec = joy_vector
		world.player.mobile_run_toggle = (joy_vector.length() > 0.86)
		world.player.mobile_gas_held = (gas_touch_idx != -1)
	queue_redraw()

func handle_screen_input(event: InputEvent) -> bool:
	if world == null or not is_instance_valid(world.player):
		return false
	if (world.inv_panel and world.inv_panel.visible) or (world.settings_panel and world.settings_panel.visible):
		_reset_touches()
		return false

	if event is InputEventScreenTouch:
		var pt: Vector2 = event.position
		if event.pressed:
			if _try_press_control_at(pt, event.index):
				return true
		else:
			if _try_release_touch(event.index):
				return true

	elif event is InputEventScreenDrag:
		if event.index == joy_touch_idx:
			_update_joystick_knob(event.position)
			return true

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var m_pt: Vector2 = event.position
		if event.pressed:
			if _try_press_control_at(m_pt, 999):
				return true
		else:
			if _try_release_touch(999):
				return true

	elif event is InputEventMouseMotion:
		if joy_touch_idx == 999:
			_update_joystick_knob(event.position)
			return true

	return false

func _try_press_control_at(pt: Vector2, idx: int) -> bool:
	if pt.distance_to(c_settings) <= _get_r(BASE_R_TOOL) + 4.0:
		trigger_btn_anim("settings")
		if world.has_method("_toggle_settings_window"):
			world._toggle_settings_window()
		world.play_sfx("ui")
		return true

	if pt.distance_to(c_bag) <= _get_r(BASE_R_BAG) + 4.0:
		trigger_btn_anim("bag")
		world._toggle_inventory_window()
		world.play_sfx("ui")
		return true

	if pt.distance_to(c_autoaim) <= _get_r(BASE_R_TOOL) + 4.0:
		trigger_btn_anim("autoaim")
		auto_aim_enabled = not auto_aim_enabled
		world.play_sfx("ui")
		return true

	if pt.distance_to(c_build) <= _get_r(BASE_R_TOOL) + 4.0:
		trigger_btn_anim("build")
		world.build_mode_active = not world.build_mode_active
		if not world.build_mode_active:
			demolish_mode = false
		else:
			BuildSystem.has_touch_preview = false
		world.player.release_hooks()
		world.play_sfx("ui")
		return true

	if world.build_mode_active and pt.distance_to(c_demolish) <= _get_r(BASE_R_TOOL) + 4.0:
		trigger_btn_anim("demolish")
		demolish_mode = not demolish_mode
		world.play_sfx("ui")
		return true

	if pt.distance_to(c_use) <= _get_r(BASE_R_USE) + 4.0:
		trigger_btn_anim("use")
		world.interact_nearby()
		return true

	if pt.distance_to(c_attack) <= _get_r(BASE_R_ATTACK) + 5.0:
		trigger_btn_anim("attack")
		if auto_aim_enabled:
			_update_auto_aim_target()
			if has_valid_aim_target and aim_target_kind == "titan" and current_aim_target_pos.distance_to(world.player.global_position) <= 95.0:
				var dir_to_t: Vector2 = (current_aim_target_pos - world.player.global_position).normalized()
				if dir_to_t.length() > 0.05:
					world.player.look_direction = dir_to_t
		world.player.mobile_attack_queued = true
		return true

	if pt.distance_to(c_hook_l) <= _get_r(BASE_R_HOOK) + 4.0:
		trigger_btn_anim("hook_l")
		left_hook_touch_idx = idx
		world.build_mode_active = false
		world.player.fire_hook(true, get_aim_world_position(true))
		return true

	if pt.distance_to(c_hook_r) <= _get_r(BASE_R_HOOK) + 4.0:
		trigger_btn_anim("hook_r")
		right_hook_touch_idx = idx
		world.build_mode_active = false
		world.player.fire_hook(false, get_aim_world_position(true))
		return true

	if pt.distance_to(c_dash) <= _get_r(BASE_R_DASH) + 4.0:
		trigger_btn_anim("dash")
		gas_touch_idx = idx
		if not world.player.hook_left_active and not world.player.hook_right_active:
			world.player.mobile_jump_queued = true
		return true

	if joy_touch_idx == -1 and _is_in_joystick_touch_zone(pt):
		var vp: Vector2 = _get_safe_viewport_size()
		var total_hb_w: float = 10.0 * BuildSystem.HOTBAR_SLOT_W + 9.0 * BuildSystem.HOTBAR_GAP
		var hb_start_x: float = (vp.x - total_hb_w) * 0.5
		if pt.y >= vp.y - (BuildSystem.HOTBAR_HEIGHT + 12.0) and pt.x >= hb_start_x - 8.0:
			return false

		joy_touch_idx = idx
		trigger_btn_anim("joy")
		if floating_joystick:
			joy_center = Vector2(
				clampf(pt.x, joy_radius + 16.0, 260.0),
				clampf(pt.y, vp.y - 260.0, vp.y - joy_radius - 20.0)
			)
		else:
			joy_center = joy_default_center
		_update_joystick_knob(pt)
		return true

	return false

func _try_release_touch(idx: int) -> bool:
	var handled: bool = false
	if idx == joy_touch_idx:
		joy_touch_idx = -1
		joy_center = joy_default_center
		joy_knob_pos = joy_center
		joy_vector = Vector2.ZERO
		if world and is_instance_valid(world.player):
			world.player.mobile_move_vec = Vector2.ZERO
			world.player.mobile_run_toggle = false
		handled = true

	if idx == left_hook_touch_idx:
		left_hook_touch_idx = -1
		if world and is_instance_valid(world.player):
			world.player.hook_left_active = false
		handled = true

	if idx == right_hook_touch_idx:
		right_hook_touch_idx = -1
		if world and is_instance_valid(world.player):
			world.player.hook_right_active = false
		handled = true

	if idx == gas_touch_idx:
		gas_touch_idx = -1
		if world and is_instance_valid(world.player):
			world.player.mobile_gas_held = false
		handled = true

	return handled

func _reset_touches() -> void:
	joy_touch_idx = -1
	left_hook_touch_idx = -1
	right_hook_touch_idx = -1
	gas_touch_idx = -1
	joy_center = joy_default_center
	joy_knob_pos = joy_center
	joy_vector = Vector2.ZERO
	if world and is_instance_valid(world.player):
		world.player.mobile_move_vec = Vector2.ZERO
		world.player.mobile_gas_held = false

func _update_joystick_knob(pt: Vector2) -> void:
	var delta_v: Vector2 = pt - joy_center
	var dist_len: float = delta_v.length()
	if dist_len > joy_radius:
		delta_v = delta_v / dist_len * joy_radius
	joy_knob_pos = joy_center + delta_v
	var raw_vec: Vector2 = delta_v / joy_radius
	if raw_vec.length() < 0.10:
		joy_vector = Vector2.ZERO
	else:
		var norm_len: float = (raw_vec.length() - 0.10) / 0.90
		joy_vector = raw_vec.normalized() * clampf(norm_len, 0.0, 1.0)

func _get_spring_scale(anim_val: float) -> float:
	if anim_val <= 0.001:
		return 1.0
	if anim_val > 0.55:
		var t: float = (anim_val - 0.55) / 0.45
		return lerpf(1.06, 0.85, t)
	else:
		var t2: float = anim_val / 0.55
		return lerpf(1.0, 1.06, t2)

func _draw() -> void:
	if world == null or not is_instance_valid(world.player):
		return
	if world.inv_panel and world.inv_panel.visible:
		return

	var alpha_m: float = hud_opacity
	var joy_active: bool = (joy_touch_idx != -1)
	var j_anim: float = float(btn_anim["joy"])
	var j_r: float = joy_radius * (1.0 + j_anim * 0.04)

	draw_circle(joy_center + Vector2(0, 3), j_r + 2.0, Color(0.0, 0.0, 0.0, 0.42 * alpha_m))
	draw_circle(joy_center, j_r, Color(0.10, 0.12, 0.15, (0.86 if joy_active else 0.72) * alpha_m))
	draw_arc(joy_center, j_r + 1.0, 0.0, TAU, 48, Color(0.04, 0.05, 0.06, alpha_m), 2.0)
	var j_rim := Color("#788494") if joy_active else Color("#464e59")
	j_rim.a = alpha_m
	draw_arc(joy_center, j_r - 1.0, 0.0, TAU, 48, j_rim, 1.8 if joy_active else 1.5)
	draw_arc(joy_center, j_r * 0.55, 0.0, TAU, 36, Color(0.45, 0.50, 0.56, 0.18 * alpha_m), 1.0)

	var arrow_col := Color(0.72, 0.76, 0.82, (0.82 if joy_active else 0.58) * alpha_m)
	var d_off: float = j_r - 15.0
	_draw_triangle(joy_center + Vector2(0, -d_off - 5), joy_center + Vector2(-6, -d_off + 3), joy_center + Vector2(6, -d_off + 3), arrow_col)
	_draw_triangle(joy_center + Vector2(0, d_off + 5), joy_center + Vector2(-6, d_off - 3), joy_center + Vector2(6, d_off - 3), arrow_col)
	_draw_triangle(joy_center + Vector2(-d_off - 5, 0), joy_center + Vector2(-d_off + 3, -6), joy_center + Vector2(-d_off + 3, 6), arrow_col)
	_draw_triangle(joy_center + Vector2(d_off + 5, 0), joy_center + Vector2(d_off - 3, -6), joy_center + Vector2(d_off - 3, 6), arrow_col)

	var knob_r: float = 26.0 * joy_size_scale * (0.92 if joy_active else 1.0)
	draw_circle(joy_knob_pos + Vector2(0, 2), knob_r + 1.0, Color(0.0, 0.0, 0.0, 0.5 * alpha_m))
	draw_circle(joy_knob_pos, knob_r, Color(0.24, 0.28, 0.34, alpha_m) if joy_active else Color(0.16, 0.19, 0.23, alpha_m))
	draw_arc(joy_knob_pos, knob_r, 0.0, TAU, 32, Color(0.85, 0.62, 0.28, alpha_m) if joy_active else Color(0.42, 0.47, 0.53, alpha_m), 2.0)

	_draw_animated_medallion(c_attack, _get_r(BASE_R_ATTACK), "attack", false)
	_draw_sword_icon(c_attack, _get_spring_scale(float(btn_anim["attack"])) * button_scale)

	_draw_animated_medallion(c_dash, _get_r(BASE_R_DASH), "dash", false)
	_draw_runner_icon(c_dash, _get_spring_scale(float(btn_anim["dash"])) * button_scale)

	_draw_animated_medallion(c_bag, _get_r(BASE_R_BAG), "bag", false)
	_draw_backpack_icon(c_bag, _get_spring_scale(float(btn_anim["bag"])) * button_scale)

	_draw_animated_medallion(c_hook_l, _get_r(BASE_R_HOOK), "hook_l", false)
	_draw_grapple_icon(c_hook_l, true, _get_spring_scale(float(btn_anim["hook_l"])) * button_scale)

	_draw_animated_medallion(c_hook_r, _get_r(BASE_R_HOOK), "hook_r", false)
	_draw_grapple_icon(c_hook_r, false, _get_spring_scale(float(btn_anim["hook_r"])) * button_scale)

	_draw_animated_medallion(c_use, _get_r(BASE_R_USE), "use", false)
	_draw_hand_use_icon(c_use, _get_spring_scale(float(btn_anim["use"])) * button_scale)

	_draw_animated_medallion(c_autoaim, _get_r(BASE_R_TOOL), "autoaim", auto_aim_enabled)
	_draw_crosshair_icon(c_autoaim, auto_aim_enabled, _get_spring_scale(float(btn_anim["autoaim"])) * button_scale)

	_draw_animated_medallion(c_build, _get_r(BASE_R_TOOL), "build", world.build_mode_active)
	_draw_hammer_icon(c_build, world.build_mode_active, _get_spring_scale(float(btn_anim["build"])) * button_scale)

	_draw_animated_medallion(c_settings, _get_r(BASE_R_TOOL), "settings", world.settings_panel != null and world.settings_panel.visible)
	_draw_gear_icon(c_settings, _get_spring_scale(float(btn_anim["settings"])) * button_scale)

	if world.build_mode_active:
		_draw_animated_medallion(c_demolish, _get_r(BASE_R_TOOL), "demolish", demolish_mode, Color("#c94a4a"))
		_draw_demolish_icon(c_demolish, demolish_mode, _get_spring_scale(float(btn_anim["demolish"])) * button_scale)

func _draw_animated_medallion(center: Vector2, base_radius: float, anim_key: String, is_toggled_on: bool, custom_accent := Color("#d99136")) -> void:
	var a_val: float = float(btn_anim.get(anim_key, 0.0))
	var sp_scale: float = _get_spring_scale(a_val)
	var radius: float = base_radius * sp_scale
	var alpha_m: float = hud_opacity

	draw_circle(center + Vector2(0, 3), radius + 1.5, Color(0.0, 0.0, 0.0, 0.48 * alpha_m))

	var bg_col := Color(0.11, 0.13, 0.16, 0.86 * alpha_m)
	if is_toggled_on:
		bg_col = Color(0.20, 0.16, 0.12, 0.92 * alpha_m)
	if a_val > 0.05:
		bg_col = bg_col.lightened(a_val * 0.22)
	draw_circle(center, radius, bg_col)

	if a_val > 0.1:
		var pulse_r: float = base_radius + (1.0 - a_val) * 10.0
		draw_arc(center, pulse_r, 0.0, TAU, 36, Color(0.85, 0.68, 0.38, a_val * 0.55 * alpha_m), 2.0)

	draw_arc(center, radius + 1.0, 0.0, TAU, 36, Color(0.04, 0.05, 0.06, alpha_m), 2.0)
	var rim_col: Color = custom_accent if is_toggled_on else Color("#4b535e").lerp(Color("#d8e0e8"), a_val)
	rim_col.a = alpha_m
	draw_arc(center, radius - 1.0, 0.0, TAU, 36, rim_col, 2.0 if a_val > 0.2 else 1.5)

func _draw_triangle(p1: Vector2, p2: Vector2, p3: Vector2, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), col)

func _draw_sword_icon(c: Vector2, sc: float = 1.0) -> void:
	var col_blade := Color(0.82, 0.84, 0.87, hud_opacity)
	var col_shade := Color(0.59, 0.63, 0.67, hud_opacity)
	var col_guard := Color(0.68, 0.72, 0.76, hud_opacity)
	var p_tip := c + Vector2(14, -14) * sc
	var p_top := c + Vector2(8, -14) * sc
	var p_right := c + Vector2(14, -8) * sc
	var p_base_l := c + Vector2(-5, -1) * sc
	var p_base_r := c + Vector2(1, 5) * sc
	var p_base_m := c + Vector2(-2, 2) * sc
	draw_colored_polygon(PackedVector2Array([p_tip, p_top, p_base_l, p_base_m]), col_blade)
	draw_colored_polygon(PackedVector2Array([p_tip, p_right, p_base_r, p_base_m]), col_shade)
	draw_line(c + Vector2(-9, -3) * sc, c + Vector2(3, 9) * sc, col_guard, 3.5 * sc)
	draw_line(c + Vector2(-4, 4) * sc, c + Vector2(-11, 11) * sc, col_shade, 3.0 * sc)
	draw_circle(c + Vector2(-12, 12) * sc, 2.8 * sc, col_blade)

func _draw_runner_icon(c: Vector2, sc: float = 1.0) -> void:
	var col := Color(0.78, 0.82, 0.85, hud_opacity)
	draw_circle(c + Vector2(5, -10) * sc, 3.2 * sc, col)
	draw_line(c + Vector2(3, -6) * sc, c + Vector2(-4, 3) * sc, col, 3.8 * sc)
	draw_line(c + Vector2(2, -5) * sc, c + Vector2(10, -2) * sc, col, 2.5 * sc)
	draw_line(c + Vector2(10, -2) * sc, c + Vector2(12, -6) * sc, col, 2.2 * sc)
	draw_line(c + Vector2(1, -5) * sc, c + Vector2(-8, -3) * sc, col, 2.5 * sc)
	draw_line(c + Vector2(-3, 2) * sc, c + Vector2(6, 5) * sc, col, 3.0 * sc)
	draw_line(c + Vector2(6, 5) * sc, c + Vector2(3, 12) * sc, col, 2.6 * sc)
	draw_line(c + Vector2(-4, 3) * sc, c + Vector2(-11, 11) * sc, col, 2.8 * sc)

func _draw_backpack_icon(c: Vector2, sc: float = 1.0) -> void:
	var col := Color(0.78, 0.82, 0.85, hud_opacity)
	var dark := Color(0.09, 0.11, 0.13, hud_opacity)
	draw_arc(c + Vector2(0, -10) * sc, 4.0 * sc, PI, TAU, 12, col, 2.0 * sc)
	draw_rect(Rect2(c + Vector2(-9, -9) * sc, Vector2(18, 19) * sc), col, true)
	draw_line(c + Vector2(-9, -1) * sc, c + Vector2(9, -1) * sc, dark, 2.0 * sc)
	draw_rect(Rect2(c + Vector2(-6, -3) * sc, Vector2(3, 6) * sc), dark, true)
	draw_rect(Rect2(c + Vector2(3, -3) * sc, Vector2(3, 6) * sc), dark, true)
	draw_rect(Rect2(c + Vector2(-5, 3) * sc, Vector2(10, 5) * sc), dark, false, 1.5 * sc)

func _draw_grapple_icon(c: Vector2, is_left: bool, sc: float = 1.0) -> void:
	var col := Color(0.78, 0.82, 0.85, hud_opacity)
	var dir := Vector2(-1, -1).normalized() if is_left else Vector2(1, -1).normalized()
	var tip: Vector2 = c + dir * 10.0 * sc
	var base: Vector2 = c - dir * 9.0 * sc
	draw_line(base, tip, col, 2.2 * sc)
	var perp := Vector2(-dir.y, dir.x)
	draw_line(tip, tip - dir * 6.5 * sc + perp * 6.0 * sc, col, 2.2 * sc)
	draw_line(tip, tip - dir * 6.5 * sc - perp * 6.0 * sc, col, 2.2 * sc)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, c + Vector2(-4, 14) * sc, "L" if is_left else "R", HORIZONTAL_ALIGNMENT_CENTER, 8, maxi(8, int(9 * sc)), Color(0.55, 0.59, 0.64, hud_opacity))

func _draw_hand_use_icon(c: Vector2, sc: float = 1.0) -> void:
	var col := Color(0.78, 0.82, 0.85, hud_opacity)
	draw_rect(Rect2(c - Vector2(9, 9) * sc, Vector2(18, 18) * sc), col, false, 1.8 * sc)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, c + Vector2(-5, 5) * sc, "E", HORIZONTAL_ALIGNMENT_CENTER, 10, maxi(9, int(13 * sc)), col)

func _draw_crosshair_icon(c: Vector2, active: bool, sc: float = 1.0) -> void:
	var col := Color("#f0b24a") if active else Color("#9aa4b0")
	col.a = hud_opacity
	draw_arc(c, 8.0 * sc, 0.0, TAU, 24, col, 1.8 * sc)
	draw_circle(c, 2.0 * sc, col)
	draw_line(c + Vector2(0, -12) * sc, c + Vector2(0, -5) * sc, col, 1.8 * sc)
	draw_line(c + Vector2(0, 5) * sc, c + Vector2(0, 12) * sc, col, 1.8 * sc)
	draw_line(c + Vector2(-12, 0) * sc, c + Vector2(-5, 0) * sc, col, 1.8 * sc)
	draw_line(c + Vector2(5, 0) * sc, c + Vector2(12, 0) * sc, col, 1.8 * sc)

func _draw_hammer_icon(c: Vector2, active: bool, sc: float = 1.0) -> void:
	var col := Color("#f0b24a") if active else Color("#c8d0d8")
	col.a = hud_opacity
	draw_line(c + Vector2(-8, 8) * sc, c + Vector2(4, -4) * sc, col, 2.8 * sc)
	draw_line(c + Vector2(-1, -9) * sc, c + Vector2(9, 1) * sc, col, 5.0 * sc)

func _draw_demolish_icon(c: Vector2, active: bool, sc: float = 1.0) -> void:
	var col := Color("#ff6b6b") if active else Color("#c8d0d8")
	col.a = hud_opacity
	draw_line(c + Vector2(-7, -7) * sc, c + Vector2(7, 7) * sc, col, 2.8 * sc)
	draw_line(c + Vector2(7, -7) * sc, c + Vector2(-7, 7) * sc, col, 2.8 * sc)

func _draw_gear_icon(c: Vector2, sc: float = 1.0) -> void:
	var col := Color(0.78, 0.82, 0.85, hud_opacity)
	draw_arc(c, 6.5 * sc, 0.0, TAU, 20, col, 2.4 * sc)
	for i in range(8):
		var ang: float = float(i) * TAU / 8.0
		var d := Vector2(cos(ang), sin(ang))
		draw_line(c + d * 6.0 * sc, c + d * 10.5 * sc, col, 2.4 * sc)
