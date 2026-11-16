class_name TestTutorialRunner
extends RefCounted

## Unit test untuk M2.5: Sistem TutorialRunner & 5 Level Latihan T-1 s.d. T-5 (FR-TUT-01 s.d. 10).

const TutorialRunnerScript: Script = preload("res://sim/systems/tutorial_runner.gd")
const TutorialDataScript: Script = preload("res://data/tutorial_data.gd")

static func run_all() -> bool:
	if not _test_load_all_5_tutorial_resources():
		return false
	if not _test_coop_event_counting_progression():
		return false
	if not _test_blocked_actions():
		return false
	if not _test_t4_adaptive_radius():
		return false
	if not _test_skip_tutorial():
		return false
	return true

static func _test_load_all_5_tutorial_resources() -> bool:
	for i: int in range(1, 6):
		var path: String = "res://data/levels/tutorial_%d.tres" % i
		var res: Resource = load(path)
		if res == null:
			push_error("Failed to load tutorial resource: %s" % path)
			return false
		var runner: RefCounted = TutorialRunnerScript.new(res)
		var step: Dictionary = runner.get_current_step()
		if step.is_empty():
			push_error("Tutorial %d has empty initial step" % i)
			return false

	return true

static func _test_coop_event_counting_progression() -> bool:
	var tut: Resource = load("res://data/levels/tutorial_1.tres")
	var runner: RefCounted = TutorialRunnerScript.new(tut)

	# Langkah 1 T-1: prep_ingredient (target: 3)
	if runner.current_step_index != 0:
		return false

	# Pemain 1 menyumbang 1 hitungan
	var step_done: bool = runner.record_event(&"prep_ingredient", 1)
	if step_done or runner.current_step_index != 0:
		push_error("Step 1 finished prematurely with 1/3")
		return false

	# Pemain 2 menyumbang 2 hitungan (gabungan P1 + P2 = 3) (FR-TUT-05)
	step_done = runner.record_event(&"prep_ingredient", 2)
	if not step_done or runner.current_step_index != 1:
		push_error("Step 1 should complete when combined count reaches 3")
		return false

	# Langkah 2 T-1: served_samperin (target: 3)
	runner.record_event(&"served_samperin", 3)
	if not runner.is_completed:
		push_error("Tutorial 1 should be marked completed after last step")
		return false

	return true

static func _test_blocked_actions() -> bool:
	var tut: Resource = load("res://data/levels/tutorial_1.tres")
	var runner: RefCounted = TutorialRunnerScript.new(tut)

	# Langkah 1 T-1 memblokir throw dan strike
	if not runner.is_action_blocked(&"throw"):
		push_error("Throw should be blocked in T-1 step 1")
		return false
	if not runner.is_action_blocked(&"strike"):
		push_error("Strike should be blocked in T-1 step 1")
		return false
	if runner.is_action_blocked(&"work"):
		push_error("Work should NOT be blocked in T-1 step 1")
		return false

	return true

static func _test_t4_adaptive_radius() -> bool:
	var tut4: Resource = load("res://data/levels/tutorial_4.tres")
	var runner: RefCounted = TutorialRunnerScript.new(tut4)

	# Awalnya radius multiplier 1.0
	if not is_equal_approx(runner.serve_radius_multiplier, 1.0):
		return false

	# Meleset 1x dan 2x -> belum melebar
	runner.record_miss()
	runner.record_miss()
	if not is_equal_approx(runner.serve_radius_multiplier, 1.0):
		push_error("Radius should not expand before 3 misses")
		return false

	# Meleset ke-3 beruntun -> FR-TUT-08: radius membesar +25% (1.25)
	runner.record_miss()
	if not is_equal_approx(runner.serve_radius_multiplier, 1.25):
		push_error("Radius should expand to 1.25 after 3 consecutive misses, got: %f" % runner.serve_radius_multiplier)
		return false

	# Saat berhasil mendaratkan lemparan (hit), reset consecutive misses
	runner.record_hit()
	if runner.consecutive_misses != 0:
		push_error("Consecutive misses should reset after hit")
		return false

	return true

static func _test_skip_tutorial() -> bool:
	var tut: Resource = load("res://data/levels/tutorial_5.tres")
	var runner: RefCounted = TutorialRunnerScript.new(tut)

	if runner.is_completed:
		return false

	# Tombol Lewati Tutorial (FR-TUT-04)
	runner.skip()
	if not runner.is_completed:
		push_error("Tutorial should be completed after skip()")
		return false

	return true
