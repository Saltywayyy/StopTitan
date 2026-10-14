class_name SurvivalSystem
extends Node

var hp: float = 100.0
var max_hp: float = 100.0
var hunger: float = 88.0
var thirst: float = 85.0
var energy: float = 92.0
var body_temp: float = 36.6
var stress: float = 10.0
var bleeding_rate: float = 0.0
# Заражение спорами «Тихого корня» (0..100%, Раздел 4.6)
var root_infection: float = 0.0

var is_sleeping: bool = false

var inventory: Dictionary = {
	"canned_food": 1,
	"clean_water": 1,
	"bandage": 2,
	"wood": 4,
	"stone": 3,
	"cloth": 2
}

var items_db: Dictionary = {}
var recipes_db: Array = []
var surv_cfg: Dictionary = {}

func setup(cfg: Dictionary) -> void:
	surv_cfg = cfg.get("survival", {})
	items_db = cfg.get("items", {})
	recipes_db = cfg.get("recipes", [])
	max_hp = float(surv_cfg.get("max_hp", 100.0))
	hp = max_hp

func get_total_weight() -> float:
	var total: float = 0.0
	for k in inventory.keys():
		var cnt: int = int(inventory[k])
		if cnt > 0 and items_db.has(k):
			total += float(items_db[k].get("weight", 0.5)) * float(cnt)
	return total

func get_max_weight() -> float:
	return float(surv_cfg.get("max_weight_kg", 30.0))

func get_warmth_bonus() -> float:
	var bonus: float = 0.0
	for k in inventory.keys():
		if int(inventory[k]) > 0 and items_db.has(k):
			bonus += float(items_db[k].get("warmth_bonus", 0.0))
	return bonus

func has_spore_mask() -> bool:
	return int(inventory.get("charcoal_mask", 0)) > 0

func add_item(item_id: String, count: int = 1) -> void:
	if count <= 0:
		return
	inventory[item_id] = int(inventory.get(item_id, 0)) + count

func remove_item(item_id: String, count: int = 1) -> bool:
	var cur: int = int(inventory.get(item_id, 0))
	if cur < count:
		return false
	cur -= count
	if cur <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = cur
	return true

func has_items(cost: Dictionary) -> bool:
	for k in cost.keys():
		if int(inventory.get(k, 0)) < int(cost[k]):
			return false
	return true

func update_survival(delta: float, game_hours_passed: float, is_night: bool, near_campfire: bool, inside_shelter: bool, near_titan: bool, activity_mult: float, weather_temp_mod: float = 0.0, in_spores: bool = false) -> void:
	var h_rate: float = float(surv_cfg.get("hunger_per_hour", 4.0)) * activity_mult
	var w_rate: float = float(surv_cfg.get("thirst_per_hour", 5.0)) * activity_mult
	var s_rate: float = float(surv_cfg.get("sleep_per_hour", 4.0))

	if is_sleeping:
		h_rate *= 0.5
		w_rate *= 0.5
		energy = minf(100.0, energy + game_hours_passed * 16.0)
		stress = maxf(0.0, stress - game_hours_passed * 8.0)
		if hunger > 40.0 and bleeding_rate <= 0.01:
			hp = minf(max_hp, hp + game_hours_passed * 6.0)
	else:
		energy = maxf(0.0, energy - game_hours_passed * s_rate)

	hunger = maxf(0.0, hunger - game_hours_passed * h_rate)
	thirst = maxf(0.0, thirst - game_hours_passed * w_rate)

	var env_temp: float = float(surv_cfg.get("night_temp_c", 2.0)) if is_night else float(surv_cfg.get("day_temp_c", 14.0))
	env_temp += weather_temp_mod
	if inside_shelter:
		env_temp += 6.0
	if near_campfire:
		env_temp += 16.0
	env_temp += get_warmth_bonus()

	var target_body: float = 36.6
	if env_temp < 10.0:
		target_body = 36.6 - (10.0 - env_temp) * 0.35
	elif env_temp > 22.0 and near_campfire:
		target_body = 37.0

	body_temp = move_toward(body_temp, target_body, delta * 0.18)

	# Споры «Тихого корня» (Раздел 4.6)
	if in_spores:
		var mult: float = 0.15 if has_spore_mask() else 1.0
		root_infection = minf(100.0, root_infection + 4.5 * mult * delta)
		stress = minf(100.0, stress + 1.5 * mult * delta)
	elif root_infection > 0.0 and root_infection < 25.0 and near_campfire:
		root_infection = maxf(0.0, root_infection - 0.5 * delta)

	if root_infection >= 50.0:
		hp -= 0.8 * delta
	if root_infection >= 100.0:
		hp = 0.0

	if near_titan:
		stress = minf(100.0, stress + float(surv_cfg.get("stress_near_titan_per_sec", 3.5)) * delta)
	elif is_night and not near_campfire and not inside_shelter:
		stress = minf(100.0, stress + 0.6 * delta)
	elif near_campfire:
		stress = maxf(0.0, stress - 2.5 * delta)

	if bleeding_rate > 0.0:
		hp -= (bleeding_rate / 60.0) * delta * 8.0
		stress = minf(100.0, stress + 1.2 * delta)

	if hunger <= 0.0:
		hp -= 1.5 * delta
	elif hunger >= 70.0 and bleeding_rate <= 0.0 and body_temp >= 35.5:
		hp = minf(max_hp, hp + 0.4 * delta)

	if thirst <= 0.0:
		hp -= 2.2 * delta

	if body_temp < 33.0:
		hp -= 2.0 * delta

	hp = clampf(hp, 0.0, max_hp)
