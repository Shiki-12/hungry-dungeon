class_name SimSkillSystem
extends RefCounted

## Sistem Skill Koki dan Cooldown (FR-SKL-01 s.d. 09, FR-MON-13).
## Murni logika simulasi deterministik tanpa visual.

const CollisionScript: Script = preload("res://sim/systems/collision.gd")

const DASH_COOLDOWN: float = 6.0
const DASH_DISTANCE_TILES: float = 4.0
const DASH_PX: float = DASH_DISTANCE_TILES * 16.0 # 64.0 px
const DASH_DURATION: float = 0.15

var cooldowns: Dictionary = {} # "cook_id_slot" -> float
var unlocked_skills: Array[StringName] = []

func configure_from_level(level_data: Resource) -> void:
	unlocked_skills.clear()
	if level_data != null and "unlocked_skills" in level_data:
		for s: StringName in level_data.unlocked_skills:
			unlocked_skills.append(s)

func unlock_skill(skill_id: StringName) -> void:
	if not unlocked_skills.has(skill_id):
		unlocked_skills.append(skill_id)

func is_skill_unlocked(skill_id: StringName) -> bool:
	if unlocked_skills.has(skill_id):
		return true
	if (skill_id == &"dash" or skill_id == &"dash_rangga") and (unlocked_skills.has(&"dash") or unlocked_skills.has(&"dash_rangga")):
		return true
	return false

func get_cooldown(cook_id: int, slot: int) -> float:
	var key: String = "%d_%d" % [cook_id, slot]
	return float(cooldowns.get(key, 0.0))

func can_use_skill(cook_id: int, slot: int, skill_id: StringName) -> bool:
	if not is_skill_unlocked(skill_id):
		return false
	var key: String = "%d_%d" % [cook_id, slot]
	return float(cooldowns.get(key, 0.0)) <= 0.0

func trigger_dash(
	cook: RefCounted,
	blocked_cells: Array = [],
	obstacles: Array = [],
	monsters: Array = []
) -> Dictionary:
	var cook_id: int = cook.cook_id if "cook_id" in cook else 1
	var key: String = "%d_1" % cook_id
	
	if not is_skill_unlocked(&"dash"):
		return {"success": false, "reason": "locked"}
	if float(cooldowns.get(key, 0.0)) > 0.0:
		return {"success": false, "reason": "cooldown"}

	# Set cooldown 6.0s (FR-SKL-01)
	cooldowns[key] = DASH_COOLDOWN

	var facing: Vector2 = cook.facing_direction if "facing_direction" in cook else Vector2.DOWN
	if facing == Vector2.ZERO:
		facing = Vector2.DOWN
	var dir: Vector2 = facing.normalized()
	
	# Melesat 4 tile (64 px) dengan resolusi tabrakan step-by-step
	var total_dist: float = DASH_PX
	var step_size: float = 4.0
	var steps_count: int = int(total_dist / step_size)
	var current_pos: Vector2 = cook.position
	
	var stopped_goblin: bool = false
	var dropped_item_id: StringName = &""
	var dropped_item_pos: Vector2 = Vector2.ZERO
	var pushed_monsters: Array = []
	
	var typed_blocked: Array[Vector2i] = []
	for c: Variant in blocked_cells:
		typed_blocked.append(c as Vector2i)
	var typed_obstacles: Array[Rect2] = []
	for o: Variant in obstacles:
		typed_obstacles.append(o as Rect2)

	for i: int in range(steps_count):
		var prev_pos: Vector2 = current_pos
		var candidate_move: Vector2 = dir * step_size
		current_pos = CollisionScript.move_circle(
			current_pos,
			candidate_move,
			CollisionScript.COOK_RADIUS,
			typed_blocked,
			typed_obstacles
		)
		
		# Jika tertahan dinding / rintangan (tidak bergerak)
		if current_pos.distance_to(prev_pos) < 0.01:
			break
			
		# Periksa interaksi monster sepanjang lintasan dash (FR-MON-13)
		for monster: RefCounted in monsters:
			if monster == null:
				continue
			if monster.position.distance_to(current_pos) <= 14.0:
				# FR-MON-13: Goblin STEAL_RUN dihentikan oleh Dash
				var m_state: int = monster.state if "state" in monster else -1
				if m_state == 9: # STEAL_RUN
					stopped_goblin = true
					dropped_item_id = monster.stolen_item_id if "stolen_item_id" in monster else &""
					dropped_item_pos = monster.position
					if "stolen_item_id" in monster:
						monster.stolen_item_id = &""
					if "state" in monster:
						monster.state = 10 # EXPELLED
				else:
					# Dorong monster kecil
					if not pushed_monsters.has(monster):
						pushed_monsters.append(monster)
						if "position" in monster:
							monster.position += dir * 8.0

	cook.position = current_pos
	# Item di tangan tidak jatuh (cook.held_item_id dipertahankan)
	
	# Emit event global jika bus Events tersedia
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree and (loop as SceneTree).root:
		var events_node: Node = (loop as SceneTree).root.get_node_or_null("Events")
		if events_node != null and events_node.has_signal("skill_activated"):
			events_node.emit_signal("skill_activated", cook_id, "dash")

	return {
		"success": true,
		"stopped_goblin": stopped_goblin,
		"dropped_item_id": dropped_item_id,
		"dropped_item_pos": dropped_item_pos,
		"final_position": current_pos
	}

func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	for key: Variant in cooldowns.keys():
		var cd: float = float(cooldowns[key]) - delta
		if cd <= 0.0:
			cooldowns.erase(key)
		else:
			cooldowns[key] = cd
