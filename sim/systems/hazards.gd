class_name SimHazardController
extends RefCounted

## Deterministic simulation hazard scheduler. No visual or scene dependencies.
const MUSHROOM_SPORES: StringName = &"MUSHROOM_SPORES"
const SPORE_PERIOD_SEC: float = 25.0
const SPORE_DURATION_SEC: float = 1.0

var level_id: StringName = &""
var elapsed_sec: float = 0.0
var active_hazard: StringName = &""
var active_remaining_sec: float = 0.0
var trigger_count: int = 0
var last_trigger_time_sec: float = -1.0

func _init(config_level_id: StringName = &"") -> void:
	level_id = config_level_id
	reset()

func configure(config_level_id: StringName) -> void:
	level_id = config_level_id
	reset()

func configure_from_level(level: RefCounted) -> void:
	level_id = level.id
	reset()

func reset() -> void:
	elapsed_sec = 0.0
	active_hazard = &""
	active_remaining_sec = 0.0
	trigger_count = 0
	last_trigger_time_sec = -1.0

func tick(delta_sec: float) -> void:
	if delta_sec <= 0.0:
		return
	var previous_time: float = elapsed_sec
	elapsed_sec += delta_sec
	if active_remaining_sec > 0.0:
		active_remaining_sec = maxf(0.0, active_remaining_sec - delta_sec)
		if active_remaining_sec <= 0.0:
			active_hazard = &""
	if not supports_mushroom_spores():
		return
	# Trigger on each period boundary, including boundaries crossed by large ticks.
	var previous_cycle: int = int(floor(previous_time / SPORE_PERIOD_SEC))
	var current_cycle: int = int(floor(elapsed_sec / SPORE_PERIOD_SEC))
	var new_triggers: int = current_cycle - previous_cycle
	if new_triggers > 0:
		for i: int in range(new_triggers):
			trigger_mushroom_spores()

func trigger_mushroom_spores() -> bool:
	if not supports_mushroom_spores():
		return false
	active_hazard = MUSHROOM_SPORES
	active_remaining_sec = SPORE_DURATION_SEC
	trigger_count += 1
	last_trigger_time_sec = elapsed_sec
	return true

func supports_mushroom_spores() -> bool:
	return level_id == &"1-3" or level_id == &"1-4" or level_id == &"level_1_3" or level_id == &"level_1_4"

func is_active(hazard_id: StringName = MUSHROOM_SPORES) -> bool:
	return active_hazard == hazard_id and active_remaining_sec > 0.0

func remaining_sec(hazard_id: StringName = MUSHROOM_SPORES) -> float:
	if active_hazard != hazard_id:
		return 0.0
	return active_remaining_sec

func phase() -> Dictionary:
	return {
		"elapsed_sec": elapsed_sec,
		"active_hazard": active_hazard,
		"remaining_sec": active_remaining_sec,
		"trigger_count": trigger_count
	}
