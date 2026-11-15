extends RefCounted

const CombatScript: Script = preload("res://sim/systems/combat.gd")
const MonsterScript: Script = preload("res://sim/entities/monster.gd")
const ItemScript: Script = preload("res://sim/entities/item.gd")
const ScoringScript: Script = preload("res://sim/systems/scoring.gd")

func run_all() -> bool:
	var combat: RefCounted = CombatScript.new()
	var scoring: RefCounted = ScoringScript.new()
	var monsters: Array[RefCounted] = []
	var m: RefCounted = MonsterScript.new(1, &"goblin")
	m.position = Vector2(14.4, 0.0)
	m.state = 7 # ENRAGED
	monsters.append(m)
	var origin: Vector2 = Vector2.ZERO
	var facing: Vector2 = Vector2.RIGHT
	if combat.strike(1, origin, facing, monsters).size() != 1:
		return false
	if combat.strike(1, origin, facing, monsters).size() != 0:
		return false
	combat.tick(0.4, monsters)
	if combat.strike(1, origin, facing, monsters).size() != 1:
		return false
	combat.tick(0.4, monsters)
	if combat.strike(1, origin, facing, monsters).size() != 1 or m.state != 10:
		return false
	var kuali: RefCounted = ItemScript.new(&"kuali", &"COOKWARE", &"cooked")
	kuali.components.clear()
	kuali.components.append(&"item_a")
	kuali.components.append(&"item_b")
	var m2: RefCounted = MonsterScript.new(2, &"goblin")
	m2.position = Vector2(20.0, 0.0)
	m2.state = 8 # ATTACKING
	var list2: Array[RefCounted] = [m2]
	if combat.strike(2, origin, facing, list2, kuali, scoring).size() != 1:
		return false
	if scoring.score != 0 or kuali.cookware_locked_timer != 4.0 or not kuali.components.is_empty():
		return false
	var seated: RefCounted = MonsterScript.new(3, &"goblin")
	seated.position = Vector2(14.0, 0.0)
	seated.state = 3
	if combat.strike(3, origin, facing, [seated]).size() != 0:
		return false
	var thief: RefCounted = MonsterScript.new(4, &"goblin")
	thief.position = Vector2(10.0, 0.0)
	thief.state = 9 # STEAL_RUN
	thief.stolen_item_id = &"item_x"
	if not combat.apply_cracker(thief, origin) or thief.stolen_item_id != &"":
		return false
	var waiting: RefCounted = MonsterScript.new(5, &"goblin")
	waiting.position = Vector2(10.0, 0.0)
	waiting.state = 3
	return combat.apply_cracker(waiting, origin) and waiting.cracker_timer == 8.0
