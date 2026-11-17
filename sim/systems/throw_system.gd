class_name SimThrowSystem
extends RefCounted

## Sistem Lempar Cepat & Lempar Bidik Busur (FR-THR-01 s.d. FR-THR-16).
## Deterministic, runs in sim layer.

const ThrowMathScript: Script = preload("res://sim/systems/throw_math.gd")
const ProjectileScript: Script = preload("res://sim/entities/projectile.gd")

var active_projectiles: Array = []
var cook_aim_states: Dictionary = {} # cook_id -> { hold_time, origin, facing }
var throw_cooldowns: Dictionary = {} # cook_id -> float
var returning_plates: Array = [] # Array of { timer: float }
var consecutive_bullseyes: int = 0

func can_throw(cook_id: int) -> bool:
	return float(throw_cooldowns.get(cook_id, 0.0)) <= 0.0

func get_aim_state(cook_id: int) -> Dictionary:
	return cook_aim_states.get(cook_id, {})

func is_aiming(cook_id: int) -> bool:
	return cook_aim_states.has(cook_id)

func start_aim(cook_id: int, origin: Vector2, facing: Vector2) -> void:
	cook_aim_states[cook_id] = {
		"hold_time": 0.0,
		"origin": origin,
		"facing": facing
	}

func update_aim(cook_id: int, origin: Vector2, facing: Vector2, delta: float, target_recipe: StringName = &"", seats: Array = [], is_keyboard: bool = true) -> Dictionary:
	if not cook_aim_states.has(cook_id):
		start_aim(cook_id, origin, facing)
	var state: Dictionary = cook_aim_states[cook_id]
	state["hold_time"] = float(state["hold_time"]) + delta
	state["origin"] = origin
	state["facing"] = facing
	
	var r_tiles: float = ThrowMathScript.range_at(float(state["hold_time"]))
	var raw_landing: Vector2 = ThrowMathScript.landing_point(origin, facing, r_tiles)
	var assist_info: Dictionary = ThrowMathScript.assist_aim(raw_landing, r_tiles, target_recipe, seats, is_keyboard)
	
	return {
		"r_tiles": r_tiles,
		"raw_landing": raw_landing,
		"landing": assist_info["landing"],
		"is_assisted": assist_info["is_assisted"],
		"would_be_jitu": assist_info["would_be_jitu"],
		"target_seat": assist_info["target_seat"]
	}

func stop_aim(cook_id: int) -> void:
	cook_aim_states.erase(cook_id)

func throw_aimed(
	cook_id: int,
	item_id: StringName,
	is_dish: bool,
	recipe_id: StringName,
	origin: Vector2,
	facing: Vector2,
	seats: Array,
	_monsters: Array = [],
	is_keyboard: bool = true
) -> RefCounted:
	if not can_throw(cook_id):
		return null
	var state: Dictionary = cook_aim_states.get(cook_id, {"hold_time": 0.0})
	var r_tiles: float = ThrowMathScript.range_at(float(state["hold_time"]))
	var raw_landing: Vector2 = ThrowMathScript.landing_point(origin, facing, r_tiles)
	var assist_info: Dictionary = ThrowMathScript.assist_aim(raw_landing, r_tiles, recipe_id, seats, is_keyboard)
	var final_landing: Vector2 = assist_info["landing"]
	var is_assisted: bool = assist_info["is_assisted"]
	
	stop_aim(cook_id)
	throw_cooldowns[cook_id] = ThrowMathScript.THROW_COOLDOWN
	
	var proj: RefCounted = ProjectileScript.new(
		cook_id,
		item_id,
		origin,
		final_landing,
		raw_landing,
		r_tiles,
		is_dish,
		recipe_id,
		is_assisted
	)
	active_projectiles.append(proj)
	return proj

func throw_quick(
	cook_id: int,
	item_id: StringName,
	origin: Vector2,
	facing: Vector2
) -> RefCounted:
	if not can_throw(cook_id):
		return null
	var r_tiles: float = ThrowMathScript.QUICK_THROW_RANGE # 4 tile (FR-THR-01)
	var landing: Vector2 = ThrowMathScript.landing_point(origin, facing, r_tiles)
	throw_cooldowns[cook_id] = ThrowMathScript.THROW_COOLDOWN
	
	var proj: RefCounted = ProjectileScript.new(
		cook_id,
		item_id,
		origin,
		landing,
		landing,
		r_tiles,
		false,
		&"",
		false
	)
	active_projectiles.append(proj)
	return proj

func tick(
	delta: float,
	seats: Array = [],
	other_cook: RefCounted = null,
	stations: Array = [],
	monsters: Array = [],
	plate_pool: RefCounted = null,
	scoring: RefCounted = null
) -> Array[Dictionary]:
	var resolved_events: Array[Dictionary] = []
	if delta <= 0.0:
		return resolved_events
	
	# 1. Update cooldowns
	for cid: Variant in throw_cooldowns.keys():
		var cd: float = float(throw_cooldowns[cid]) - delta
		if cd <= 0.0:
			throw_cooldowns.erase(cid)
		else:
			throw_cooldowns[cid] = cd

	# 2. Update returning plates (FR-THR-13: 10s)
	var remaining_plates: Array = []
	for p_info: Dictionary in returning_plates:
		var t: float = float(p_info["timer"]) - delta
		if t <= 0.0:
			if plate_pool != null and plate_pool.has_method("return_plate"):
				plate_pool.return_plate()
			elif plate_pool != null and "plates_at_rack" in plate_pool:
				plate_pool.plates_at_rack += 1
		else:
			p_info["timer"] = t
			remaining_plates.append(p_info)
	returning_plates = remaining_plates

	# 3. Update projectiles
	var remaining_projectiles: Array = []
	for proj: RefCounted in active_projectiles:
		var finished: bool = proj.tick(delta)
		if finished:
			var res: Dictionary = _resolve_projectile_landing(proj, seats, other_cook, stations, monsters, scoring)
			proj.evaluation = res
			resolved_events.append(res)
			if res.get("broken_plate", false):
				returning_plates.append({"timer": ThrowMathScript.PLATE_RETURN_TIME})
		else:
			remaining_projectiles.append(proj)
	active_projectiles = remaining_projectiles

	return resolved_events

func _resolve_projectile_landing(
	proj: RefCounted,
	seats: Array,
	other_cook: RefCounted,
	stations: Array,
	monsters: Array,
	scoring: RefCounted
) -> Dictionary:
	var landing_pos: Vector2 = proj.target
	var res: Dictionary = {}
	
	if proj.is_dish:
		res = ThrowMathScript.evaluate_dish_landing(
			landing_pos,
			proj.raw_target,
			proj.r_tiles,
			proj.recipe_id,
			seats,
			monsters,
			proj.was_assisted
		)
		var r_type: StringName = res.get("result", &"MISSED")
		
		# Streak tracking (FR-THR-09)
		if r_type == &"JITU":
			consecutive_bullseyes += 1
			if scoring != null:
				scoring.add_score(res.get("score_delta", 25))
			if consecutive_bullseyes >= 3:
				if scoring != null:
					scoring.add_score(50) # +50 poin bonus 3x Jitu
				consecutive_bullseyes = 0
		else:
			consecutive_bullseyes = 0
			if scoring != null and res.get("score_delta", 0) != 0:
				scoring.add_score(res.get("score_delta", 0))

		# Apply patience delta to target seat / monster
		if res.has("target_seat") and res["target_seat"] != null:
			var seat: RefCounted = res["target_seat"]
			if res.has("satisfaction_bonus") and res["satisfaction_bonus"] > 0.0:
				if "satisfaction" in seat:
					seat.satisfaction += res["satisfaction_bonus"]
			if res.has("patience_delta") and res["patience_delta"] < 0.0:
				if "patience" in seat:
					seat.patience = maxf(0.0, seat.patience + res["patience_delta"])
					
		if res.has("target_monster") and res["target_monster"] != null:
			var m: RefCounted = res["target_monster"]
			if "patience" in m and res.has("patience_delta"):
				m.patience = maxf(0.0, m.patience + res["patience_delta"])
				
	else:
		# Ingredient landing
		res = ThrowMathScript.evaluate_ingredient_landing(landing_pos, other_cook, stations)
		var ing_res: StringName = res.get("result", &"FLOOR")
		if ing_res == &"AUTOCATCH":
			var cook: RefCounted = res["target_cook"]
			if cook != null:
				cook.held_item_id = String(proj.item_id)
		elif ing_res == &"STATION":
			var st: RefCounted = res.get("station", null)
			if st != null and st.has_method("accept_item"):
				st.accept_item(proj.item_id)
				
	res["cook_id"] = proj.cook_id
	res["item_id"] = proj.item_id
	res["landing_pos"] = landing_pos
	return res
