class_name SimCombatSystem
extends RefCounted

const SUTIL_COOLDOWN: float = 0.4
const KUALI_COOLDOWN: float = 0.8
const SUTIL_RANGE: float = 19.2
const KUALI_RANGE: float = 25.6
const HIT_ACTIVE_TIME: float = 0.12
const KUALI_LOCK_TIME: float = 4.0
const CRACKER_RADIUS: float = 24.0
const CRACKER_WAIT_TIME: float = 8.0
const CRACKER_STEAL_TIME: float = 2.0

var _cooldowns: Dictionary = {}
var _attack_elapsed: Dictionary = {}

func tick(delta: float, monsters: Array, scoring: RefCounted = null, station: RefCounted = null) -> void:
	if delta <= 0.0:
		return
	for key: Variant in _cooldowns.keys():
		_cooldowns[key] = maxf(0.0, float(_cooldowns[key]) - delta)
	for monster: RefCounted in monsters:
		if monster.state == 8: # ATTACKING
			var elapsed: float = float(_attack_elapsed.get(monster.monster_id, 0.0)) + delta
			_attack_elapsed[monster.monster_id] = elapsed
			if elapsed >= 10.0:
				if scoring != null:
					scoring.lose_heart()
				if station != null:
					station.disable(8.0)
				monster.state = 6 # LEAVING
				_attack_elapsed.erase(monster.monster_id)

func strike(cook_id: int, origin: Vector2, facing: Vector2, monsters: Array, cookware: RefCounted = null, scoring: RefCounted = null) -> Array:
	var has_kuali: bool = cookware != null and cookware.category == &"COOKWARE" and cookware.item_id == &"kuali"
	var cooldown_val: float = KUALI_COOLDOWN if has_kuali else SUTIL_COOLDOWN
	if float(_cooldowns.get(cook_id, 0.0)) > 0.0:
		return []
	_cooldowns[cook_id] = cooldown_val
	var range_px: float = KUALI_RANGE if has_kuali else SUTIL_RANGE
	var center: Vector2 = origin + facing.normalized() * 14.4
	var hit_list: Array = []
	for monster: RefCounted in monsters:
		# Only hit ENRAGED(7), ATTACKING(8), STEAL_RUN(9)
		if monster.state != 7 and monster.state != 8 and monster.state != 9:
			continue
		if monster.position.distance_to(center) > range_px:
			continue
		if monster.hit(has_kuali):
			hit_list.append(monster)
	if has_kuali and cookware != null:
		if not cookware.components.is_empty() or (cookware.form != &"" and cookware.form != &"clean"):
			cookware.clear_contents()
			if scoring != null:
				scoring.add_score(-25)
		cookware.cookware_locked_timer = KUALI_LOCK_TIME
	return hit_list

func apply_cracker(monster: RefCounted, source: Vector2) -> bool:
	if monster.position.distance_to(source) > CRACKER_RADIUS:
		return false
	if monster.state == 3: # WAITING
		monster.cracker_timer = CRACKER_WAIT_TIME
		return true
	if monster.state == 9: # STEAL_RUN
		monster.stolen_item_id = &""
		monster.cracker_timer = CRACKER_STEAL_TIME
		return true
	return false

func reset_cooldown(cook_id: int) -> void:
	_cooldowns.erase(cook_id)

func cooldown(cook_id: int) -> float:
	return float(_cooldowns.get(cook_id, 0.0))
