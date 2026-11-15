extends RefCounted

const HazardScript: Script = preload("res://sim/systems/hazards.gd")

func run_all() -> bool:
	var hazard: RefCounted = HazardScript.new(&"1-3")
	if not hazard.supports_mushroom_spores():
		printerr("FAIL: hazard 1-3 should support spores")
		return false
	if hazard.is_active():
		printerr("FAIL: should not be active initially")
		return false
	hazard.tick(24.99)
	if hazard.trigger_count != 0:
		printerr("FAIL: trigger_count should be 0 after 24.99s, got ", hazard.trigger_count)
		return false
	hazard.tick(0.01)
	if hazard.trigger_count != 1:
		printerr("FAIL: trigger_count should be 1 after 25s, got ", hazard.trigger_count)
		return false
	if not hazard.is_active():
		printerr("FAIL: should be active after trigger")
		return false
	hazard.tick(0.5)
	if not hazard.is_active():
		printerr("FAIL: should still be active after 0.5s")
		return false
	hazard.tick(0.5)
	if hazard.is_active():
		printerr("FAIL: should not be active after 1.0s duration")
		return false
	hazard.tick(49.0)
	if hazard.trigger_count != 3:
		printerr("FAIL: trigger_count should be 3 after 75s, got ", hazard.trigger_count)
		return false
	var unsupported: RefCounted = HazardScript.new(&"1-2")
	unsupported.tick(100.0)
	if unsupported.trigger_count != 0:
		printerr("FAIL: unsupported level should have 0 triggers")
		return false
	var level: Resource = load("res://data/levels/level_1_4.tres")
	if level == null:
		printerr("FAIL: could not load level_1_4.tres")
		return false
	var from_level: RefCounted = HazardScript.new()
	from_level.configure_from_level(level)
	from_level.tick(25.0)
	if from_level.trigger_count != 1:
		printerr("FAIL: from_level trigger_count should be 1, got ", from_level.trigger_count)
		return false
	if not from_level.is_active():
		printerr("FAIL: from_level should be active")
		return false
	return true
