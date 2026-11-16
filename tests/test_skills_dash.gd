class_name TestSkillsDash
extends RefCounted

## Unit test untuk M2.2: Skill Dash Rangga (FR-SKL-01, FR-SKL-09, FR-MON-13).

const SkillSystemScript: Script = preload("res://sim/systems/skills.gd")
const CookScript: Script = preload("res://sim/entities/cook.gd")
const MonsterScript: Script = preload("res://sim/entities/monster.gd")
const LevelDataScript: Script = preload("res://data/level_data.gd")

static func run_all() -> bool:
	if not _test_skill_unlock_and_cooldown():
		return false
	if not _test_dash_distance_and_direction():
		return false
	if not _test_dash_wall_collision():
		return false
	if not _test_item_retention_during_dash():
		return false
	if not _test_dash_stops_steal_run():
		return false
	return true

static func _test_skill_unlock_and_cooldown() -> bool:
	var system: RefCounted = SkillSystemScript.new()
	var cook: RefCounted = CookScript.new()
	cook.cook_id = 1
	cook.position = Vector2(100.0, 100.0)
	cook.facing_direction = Vector2.RIGHT

	# 1. Sebelum dibuka: Dash gagal
	var res_locked: Dictionary = system.trigger_dash(cook)
	if res_locked["success"]:
		push_error("Dash should fail when locked")
		return false

	# 2. Buka skill dash
	system.unlock_skill(&"dash")
	if not system.is_skill_unlocked(&"dash"):
		return false

	# 3. Eksekusi pertama berhasil
	var res_success: Dictionary = system.trigger_dash(cook)
	if not res_success["success"]:
		push_error("Dash should succeed after unlocking")
		return false
	
	# Cooldown harus 6.0 detik
	var cd: float = system.get_cooldown(1, 1)
	if not is_equal_approx(cd, 6.0):
		push_error("Cooldown should be 6.0s, got: %f" % cd)
		return false

	# 4. Saat cooldown: Dash gagal
	var res_cd: Dictionary = system.trigger_dash(cook)
	if res_cd["success"]:
		push_error("Dash should not trigger during cooldown")
		return false

	# 5. Tick 6.0s cooldown selesai
	system.tick(6.1)
	if not system.can_use_skill(1, 1, &"dash"):
		push_error("Dash should be available after 6.0s cooldown")
		return false

	return true

static func _test_dash_distance_and_direction() -> bool:
	var system: RefCounted = SkillSystemScript.new()
	system.unlock_skill(&"dash")
	
	var cook: RefCounted = CookScript.new()
	cook.cook_id = 1
	cook.position = Vector2(100.0, 100.0)
	cook.facing_direction = Vector2.DOWN # arah ke bawah

	var res: Dictionary = system.trigger_dash(cook)
	if not res["success"]:
		return false
	
	# Melesat 4 tile (64.0 px) ke bawah -> Y bertambah 64 px
	var expected_pos: Vector2 = Vector2(100.0, 164.0)
	if not cook.position.is_equal_approx(expected_pos):
		push_error("Dash position mismatch: expected %s, got %s" % [expected_pos, cook.position])
		return false

	return true

static func _test_dash_wall_collision() -> bool:
	var system: RefCounted = SkillSystemScript.new()
	system.unlock_skill(&"dash")
	
	var cook: RefCounted = CookScript.new()
	cook.cook_id = 1
	cook.position = Vector2(100.0, 100.0)
	cook.facing_direction = Vector2.RIGHT

	# Dinding di depan koki pada x = 120 (jarak 20 px, kurang dari 64 px)
	var blocked_cells: Array[Vector2i] = [Vector2i(int(120.0 / 16.0), int(100.0 / 16.0))]
	var obstacles: Array[Rect2] = [Rect2(120.0, 80.0, 16.0, 40.0)]

	var res: Dictionary = system.trigger_dash(cook, blocked_cells, obstacles)
	if not res["success"]:
		return false

	# Koki harus tertahan sebelum x = 120 dan tidak menembus dinding
	if cook.position.x >= 120.0:
		push_error("Cook dashed through obstacle! Position x = %f" % cook.position.x)
		return false

	return true

static func _test_item_retention_during_dash() -> bool:
	var system: RefCounted = SkillSystemScript.new()
	system.unlock_skill(&"dash")
	
	var cook: RefCounted = CookScript.new()
	cook.cook_id = 1
	cook.position = Vector2(100.0, 100.0)
	cook.facing_direction = Vector2.LEFT
	cook.held_item_id = "dish_nasi_goreng_jamur"

	var res: Dictionary = system.trigger_dash(cook)
	if not res["success"]:
		return false
	
	# Item di tangan TIDAK jatuh (FR-SKL-01)
	if cook.held_item_id != "dish_nasi_goreng_jamur":
		push_error("Held item was dropped during dash!")
		return false

	return true

static func _test_dash_stops_steal_run() -> bool:
	var system: RefCounted = SkillSystemScript.new()
	system.unlock_skill(&"dash")
	
	var cook: RefCounted = CookScript.new()
	cook.cook_id = 1
	cook.position = Vector2(100.0, 100.0)
	cook.facing_direction = Vector2.RIGHT

	# Goblin sedang STEAL_RUN di lintasan dash (x = 130, y = 100)
	var goblin: RefCounted = MonsterScript.new(10, &"goblin")
	goblin.position = Vector2(130.0, 100.0)
	goblin.state = 9 # STEAL_RUN
	goblin.stolen_item_id = &"item_bawang_raw"

	var res: Dictionary = system.trigger_dash(cook, [], [], [goblin])
	if not res["success"]:
		return false
	
	# Goblin STEAL_RUN harus terhenti, barang dijatuhkan, status EXPELLED (FR-MON-13)
	if not res["stopped_goblin"]:
		push_error("Dash did not stop steal run goblin")
		return false
	if res["dropped_item_id"] != &"item_bawang_raw":
		push_error("Dropped item mismatch: expected item_bawang_raw, got %s" % res["dropped_item_id"])
		return false
	if goblin.state != 10: # EXPELLED
		push_error("Goblin state should be EXPELLED after dash hit")
		return false
	if goblin.stolen_item_id != &"":
		push_error("Goblin should no longer hold stolen item")
		return false

	return true
