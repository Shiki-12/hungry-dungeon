class_name TestThrowMath
extends RefCounted

# tests/test_throw_math.gd
# Unit test headless untuk sim/systems/throw_math.gd

static func run_all() -> bool:
	var passed: bool = true
	passed = passed and _test_range_at()
	passed = passed and _test_flight_time()
	passed = passed and _test_landing_point()
	passed = passed and _test_arc_height()
	passed = passed and _test_parabola()
	return passed

static func _test_range_at() -> bool:
	var r_min: float = ThrowMath.range_at(0.0)
	if not is_equal_approx(r_min, 2.0):
		push_error("Test failed: range_at(0.0) expected 2.0, got %f" % r_min)
		return false
	
	var r_max: float = ThrowMath.range_at(1.2)
	if not is_equal_approx(r_max, 8.0):
		push_error("Test failed: range_at(1.2) expected 8.0, got %f" % r_max)
		return false

	var r_cycle: float = ThrowMath.range_at(2.4)
	if not is_equal_approx(r_cycle, 2.0):
		push_error("Test failed: range_at(2.4) expected 2.0, got %f" % r_cycle)
		return false
	
	return true

static func _test_flight_time() -> bool:
	var t_min: float = ThrowMath.flight_time(2.0)
	if not is_equal_approx(t_min, 0.4):
		push_error("Test failed: flight_time(2.0) expected 0.4, got %f" % t_min)
		return false

	var t_max: float = ThrowMath.flight_time(8.0)
	if not is_equal_approx(t_max, 0.9):
		push_error("Test failed: flight_time(8.0) expected 0.9, got %f" % t_max)
		return false

	return true

static func _test_landing_point() -> bool:
	var origin: Vector2 = Vector2(100.0, 100.0)
	var dir: Vector2 = Vector2.RIGHT
	var pt: Vector2 = ThrowMath.landing_point(origin, dir, 4.0, Vector2.ZERO)
	var expected: Vector2 = Vector2(100.0 + 4.0 * 16.0, 100.0) # 164.0, 100.0
	if not pt.is_equal_approx(expected):
		push_error("Test failed: landing_point expected %s, got %s" % [expected, pt])
		return false
	return true

static func _test_arc_height() -> bool:
	var h: float = ThrowMath.arc_height(4.0)
	if not is_equal_approx(h, 16.0):
		push_error("Test failed: arc_height expected 16.0, got %f" % h)
		return false
	return true

static func _test_parabola() -> bool:
	var peak: float = 20.0
	var at_start: float = ThrowMath.parabola_y(peak, 0.0)
	var at_mid: float = ThrowMath.parabola_y(peak, 0.5)
	var at_end: float = ThrowMath.parabola_y(peak, 1.0)
	if not is_equal_approx(at_start, 0.0) or not is_equal_approx(at_mid, 20.0) or not is_equal_approx(at_end, 0.0):
		push_error("Test failed: parabola calculation mismatch")
		return false
	return true
