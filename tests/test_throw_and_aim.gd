class_name TestThrowAndAim
extends RefCounted

## Unit test komprehensif untuk M2.1: Sistem Lempar Cepat & Lempar Bidik Busur (FR-THR-01 s.d. 16).

const ThrowMathScript: Script = preload("res://sim/systems/throw_math.gd")
const ThrowSystemScript: Script = preload("res://sim/systems/throw_system.gd")
const CookScript: Script = preload("res://sim/entities/cook.gd")
const MonsterScript: Script = preload("res://sim/entities/monster.gd")
const ScoringScript: Script = preload("res://sim/systems/scoring.gd")
const PlatePoolScript: Script = preload("res://sim/systems/plate_pool.gd")

static func run_all() -> bool:
	if not _test_can_throw_rules():
		return false
	if not _test_quick_throw():
		return false
	if not _test_aimed_throw_and_flight():
		return false
	if not _test_aim_assist():
		return false
	if not _test_dish_landing_outcomes():
		return false
	if not _test_jitu_streak_bonus():
		return false
	if not _test_jitu_minimum_distance():
		return false
	if not _test_ingredient_landing():
		return false
	if not _test_plate_return_after_10s():
		return false
	return true

static func _test_can_throw_rules() -> bool:
	# Kuali & sutil tidak bisa dilempar (FR-THR-05)
	if ThrowMathScript.can_throw_item(&"COOKWARE", &"kuali", false, true):
		push_error("Kuali should not be throwable")
		return false
	if ThrowMathScript.can_throw_item(&"COOKWARE", &"sutil", false, false):
		push_error("Sutil should not be throwable")
		return false
	
	# Piring kotor tidak bisa dilempar (FR-WSH-09)
	if ThrowMathScript.can_throw_item(&"PLATE", &"plate_dirty", true, true):
		push_error("Dirty plate should not be throwable")
		return false
	
	# Hidangan jadi hanya bisa dilempar mode bidik (FR-THR-02)
	if ThrowMathScript.can_throw_item(&"DISH", &"dish_nasi_goreng_jamur", false, false):
		push_error("Dish should not be throwable via quick throw")
		return false
	if not ThrowMathScript.can_throw_item(&"DISH", &"dish_nasi_goreng_jamur", false, true):
		push_error("Dish should be throwable via aimed throw")
		return false

	# Bahan bisa dilempar cepat maupun bidik
	if not ThrowMathScript.can_throw_item(&"INGREDIENT", &"item_bawang_raw", false, false):
		return false
	if not ThrowMathScript.can_throw_item(&"INGREDIENT", &"item_bawang_raw", false, true):
		return false

	return true

static func _test_quick_throw() -> bool:
	var system: RefCounted = ThrowSystemScript.new()
	var origin: Vector2 = Vector2(50.0, 50.0)
	var facing: Vector2 = Vector2.RIGHT
	
	var proj: RefCounted = system.throw_quick(1, &"item_bawang_raw", origin, facing)
	if proj == null:
		push_error("Failed to spawn quick throw projectile")
		return false
	
	# Jarak tetap 4 tile (64 px) ke arah facing
	var expected_target: Vector2 = origin + Vector2(64.0, 0.0)
	if not proj.target.is_equal_approx(expected_target):
		push_error("Quick throw target mismatch: expected %s, got %s" % [expected_target, proj.target])
		return false
	
	# Cooldown 0.3s
	if system.can_throw(1):
		push_error("Cook should be on throw cooldown")
		return false
	
	system.tick(0.35)
	if not system.can_throw(1):
		push_error("Cook should be ready after cooldown")
		return false

	return true

static func _test_aimed_throw_and_flight() -> bool:
	var system: RefCounted = ThrowSystemScript.new()
	var origin: Vector2 = Vector2(100.0, 100.0)
	var facing: Vector2 = Vector2.DOWN
	
	system.start_aim(1, origin, facing)
	# Ramp bidik: 1.2 detik mencapai 8 tile
	var aim_info: Dictionary = system.update_aim(1, origin, facing, 1.2)
	if not is_equal_approx(aim_info["r_tiles"], 8.0):
		push_error("Aim hold time 1.2s should yield 8.0 tiles, got: %f" % aim_info["r_tiles"])
		return false
	
	var proj: RefCounted = system.throw_aimed(1, &"dish_nasi_goreng_jamur", true, &"recipe_nasi_goreng_jamur", origin, facing, [], [], false)
	if proj == null:
		return false
	if not is_equal_approx(proj.flight_time, 0.9):
		push_error("Flight time for 8.0 tiles should be 0.9s, got: %f" % proj.flight_time)
		return false
	
	# Tick flight
	system.tick(0.45)
	if proj.is_finished:
		push_error("Projectile finished too early")
		return false
	system.tick(0.5)
	if not proj.is_finished:
		push_error("Projectile should have finished after total 0.95s")
		return false

	return true

static func _test_aim_assist() -> bool:
	# Dummy seat with matching order at (100, 100)
	var seat: RefCounted = RefCounted.new()
	seat.set_meta("seat_id", 1)
	seat.set_meta("requested_recipe", &"recipe_nasi_goreng_jamur")
	# Mock properties
	var seat_pos: Vector2 = Vector2(100.0, 100.0)
	var mock_seat: Dictionary = {
		"position": seat_pos,
		"requested_recipe": &"recipe_nasi_goreng_jamur"
	}
	# Convert to object with position and requested_recipe
	var seat_obj: MockSeat = MockSeat.new(seat_pos, &"recipe_nasi_goreng_jamur")
	
	# Case A: Keyboard assist within 20 px (e.g. 15 px away)
	var raw_pt: Vector2 = Vector2(115.0, 100.0)
	var assist_info: Dictionary = ThrowMathScript.assist_aim(raw_pt, 4.0, &"recipe_nasi_goreng_jamur", [seat_obj], true)
	if not assist_info["is_assisted"] or not assist_info["landing"].is_equal_approx(seat_pos):
		push_error("Aim assist failed to snap to seat within 20 px")
		return false
	# Because raw was 15 px away (> 6 px), would_be_jitu must be false (Tersaji)
	if assist_info["would_be_jitu"]:
		push_error("Assisted landing with raw distance 15 px should not be Jitu")
		return false

	# Case B: Keyboard assist within 6 px and r_tiles >= 3.0 -> would_be_jitu is true
	var raw_jitu: Vector2 = Vector2(104.0, 100.0) # 4 px away
	var jitu_info: Dictionary = ThrowMathScript.assist_aim(raw_jitu, 4.0, &"recipe_nasi_goreng_jamur", [seat_obj], true)
	if not jitu_info["would_be_jitu"]:
		push_error("Assisted landing with raw distance 4 px and >= 3 tiles should remain Jitu")
		return false

	# Case C: Beyond 20 px (e.g. 25 px away) -> no snap
	var far_pt: Vector2 = Vector2(125.0, 100.0)
	var far_info: Dictionary = ThrowMathScript.assist_aim(far_pt, 4.0, &"recipe_nasi_goreng_jamur", [seat_obj], true)
	if far_info["is_assisted"] or not far_info["landing"].is_equal_approx(far_pt):
		push_error("Aim assist snapped beyond 20 px")
		return false

	return true

static func _test_dish_landing_outcomes() -> bool:
	var seat_target: MockSeat = MockSeat.new(Vector2(200.0, 100.0), &"recipe_nasi_goreng_jamur")
	var seat_wrong: MockSeat = MockSeat.new(Vector2(200.0, 150.0), &"recipe_tempe_mendoan")
	var seats: Array = [seat_target, seat_wrong]
	
	# 1. Jitu: <= 6 px from matching seat and >= 3 tiles
	var res_jitu: Dictionary = ThrowMathScript.evaluate_dish_landing(
		Vector2(203.0, 100.0), Vector2(203.0, 100.0), 4.0, &"recipe_nasi_goreng_jamur", seats, []
	)
	if res_jitu["result"] != &"JITU" or res_jitu["score_delta"] != 25 or not is_equal_approx(res_jitu["satisfaction_bonus"], 5.0):
		push_error("Jitu evaluation failed: %s" % str(res_jitu))
		return false

	# 2. Tersaji: <= 12 px (e.g. 10 px away)
	var res_tersaji: Dictionary = ThrowMathScript.evaluate_dish_landing(
		Vector2(210.0, 100.0), Vector2(210.0, 100.0), 4.0, &"recipe_nasi_goreng_jamur", seats, []
	)
	if res_tersaji["result"] != &"TERSAJI" or res_tersaji["score_delta"] != 0:
		push_error("Tersaji evaluation failed: %s" % str(res_tersaji))
		return false

	# 3. Wrong table: <= 12 px from wrong seat (e.g. 4 px away)
	var res_wrong: Dictionary = ThrowMathScript.evaluate_dish_landing(
		Vector2(200.0, 154.0), Vector2(200.0, 154.0), 4.0, &"recipe_nasi_goreng_jamur", seats, []
	)
	if res_wrong["result"] != &"WRONG_TABLE" or res_wrong["score_delta"] != -50 or not is_equal_approx(res_wrong["patience_delta"], -10.0):
		push_error("Wrong table evaluation failed: %s" % str(res_wrong))
		return false

	# 4. Hit non-seated monster
	var monster: RefCounted = MonsterScript.new(1, &"goblin")
	monster.position = Vector2(300.0, 100.0)
	monster.state = 7 # ENRAGED
	var res_monster: Dictionary = ThrowMathScript.evaluate_dish_landing(
		Vector2(302.0, 100.0), Vector2(302.0, 100.0), 4.0, &"recipe_nasi_goreng_jamur", seats, [monster]
	)
	if res_monster["result"] != &"HIT_MONSTER" or res_monster["score_delta"] != -25 or not is_equal_approx(res_monster["patience_delta"], -25.0):
		push_error("Hit monster evaluation failed: %s" % str(res_monster))
		return false

	# 5. Missed on floor (nearby matching seat within 40 px receives -15 patience)
	var res_missed: Dictionary = ThrowMathScript.evaluate_dish_landing(
		Vector2(230.0, 100.0), Vector2(230.0, 100.0), 4.0, &"recipe_nasi_goreng_jamur", seats, []
	)
	if res_missed["result"] != &"MISSED" or res_missed["score_delta"] != -25 or not is_equal_approx(res_missed["patience_delta"], -15.0):
		push_error("Missed evaluation failed: %s" % str(res_missed))
		return false

	return true

static func _test_jitu_streak_bonus() -> bool:
	var system: RefCounted = ThrowSystemScript.new()
	var scoring: RefCounted = ScoringScript.new()
	var seat: MockSeat = MockSeat.new(Vector2(200.0, 100.0), &"recipe_nasi_goreng_jamur")
	
	# Lemparan 1: Jitu (+25) -> total 25
	var proj1: RefCounted = system.throw_aimed(1, &"dish_nasi_goreng_jamur", true, &"recipe_nasi_goreng_jamur", Vector2(100.0, 100.0), Vector2.RIGHT, [seat], [], false)
	# Override target to exact seat for test
	proj1.target = seat.position
	proj1.raw_target = seat.position
	proj1.r_tiles = 4.0
	system.tick(proj1.flight_time + 0.1, [seat], null, [], [], null, scoring)
	if scoring.score != 25:
		push_error("Streak 1 score expected 25, got: %d" % scoring.score)
		return false
	
	# Lemparan 2: Jitu (+25) -> total 50
	system.throw_cooldowns.clear()
	var proj2: RefCounted = system.throw_aimed(1, &"dish_nasi_goreng_jamur", true, &"recipe_nasi_goreng_jamur", Vector2(100.0, 100.0), Vector2.RIGHT, [seat], [], false)
	proj2.target = seat.position
	proj2.raw_target = seat.position
	proj2.r_tiles = 4.0
	system.tick(proj2.flight_time + 0.1, [seat], null, [], [], null, scoring)
	if scoring.score != 50:
		push_error("Streak 2 score expected 50, got: %d" % scoring.score)
		return false

	# Lemparan 3: Jitu (+25) + Bonus 3x Streak (+50) -> total 125
	system.throw_cooldowns.clear()
	var proj3: RefCounted = system.throw_aimed(1, &"dish_nasi_goreng_jamur", true, &"recipe_nasi_goreng_jamur", Vector2(100.0, 100.0), Vector2.RIGHT, [seat], [], false)
	proj3.target = seat.position
	proj3.raw_target = seat.position
	proj3.r_tiles = 4.0
	system.tick(proj3.flight_time + 0.1, [seat], null, [], [], null, scoring)
	if scoring.score != 125:
		push_error("Streak 3 score expected 125 (+50 bonus), got: %d" % scoring.score)
		return false

	return true

static func _test_jitu_minimum_distance() -> bool:
	var seat: MockSeat = MockSeat.new(Vector2(120.0, 100.0), &"recipe_nasi_goreng_jamur")
	# Jarak < 3 tile (misal 2.0 tile), landing tepat di kursi -> dihitung Tersaji (FR-THR-14)
	var res: Dictionary = ThrowMathScript.evaluate_dish_landing(
		seat.position, seat.position, 2.0, &"recipe_nasi_goreng_jamur", [seat], []
	)
	if res["result"] != &"TERSAJI":
		push_error("Distance < 3 tiles should not be awarded Jitu, got: %s" % res["result"])
		return false
	return true

static func _test_ingredient_landing() -> bool:
	var cook2: RefCounted = CookScript.new()
	cook2.position = Vector2(100.0, 100.0)
	cook2.held_item_id = ""
	
	# 1. Autocatch: within 16 px of empty-handed cook
	var res_catch: Dictionary = ThrowMathScript.evaluate_ingredient_landing(Vector2(110.0, 100.0), cook2, [])
	if res_catch["result"] != &"AUTOCATCH":
		push_error("Ingredient should be autocaught by nearby teammate")
		return false
	
	# 2. Floor: far away
	var res_floor: Dictionary = ThrowMathScript.evaluate_ingredient_landing(Vector2(150.0, 100.0), cook2, [])
	if res_floor["result"] != &"FLOOR":
		push_error("Ingredient should land on floor")
		return false

	return true

static func _test_plate_return_after_10s() -> bool:
	var system: RefCounted = ThrowSystemScript.new()
	var plate_pool: RefCounted = PlatePoolScript.new(3)
	# Take 1 clean plate and break it (moves to LOST)
	var taken: RefCounted = plate_pool.take_clean()
	plate_pool.break_plate(taken)
	if plate_pool.clean_count() != 2:
		push_error("Clean plate count should be 2 after breaking one")
		return false
	
	# Simulate broken dish queued in system
	system.returning_plates.append({"timer": 10.0})
	
	system.tick(5.0, [], null, [], [], plate_pool)
	if plate_pool.clean_count() != 2:
		push_error("Plate returned prematurely before 10s")
		return false
	
	system.tick(5.1, [], null, [], [], plate_pool)
	if plate_pool.clean_count() != 3:
		push_error("Plate should return to rack (clean) after 10s")
		return false

	return true

class MockSeat extends RefCounted:
	var position: Vector2
	var requested_recipe: StringName
	var satisfaction: float = 0.0
	var patience: float = 100.0
	func _init(p_pos: Vector2, p_recipe: StringName) -> void:
		position = p_pos
		requested_recipe = p_recipe
