class_name TutorialRunner
extends RefCounted

## Sistem pengelola alur tutorial dan syarat selesai gabungan P1+P2 (FR-TUT-01 s.d. 10).
## Murni logika simulasi deterministik tanpa dependensi visual.

var tutorial_data: Resource
var current_step_index: int = 0
var current_event_count: int = 0
var consecutive_misses: int = 0
var serve_radius_multiplier: float = 1.0
var is_completed: bool = false
var event_counts: Dictionary = {}

func _init(data: Resource = null) -> void:
	tutorial_data = data
	current_step_index = 0
	current_event_count = 0
	consecutive_misses = 0
	serve_radius_multiplier = 1.0
	is_completed = false
	event_counts.clear()

func get_current_step() -> Dictionary:
	if tutorial_data != null and "steps" in tutorial_data:
		var steps_arr: Array = tutorial_data.steps
		if current_step_index >= 0 and current_step_index < steps_arr.size():
			return steps_arr[current_step_index] as Dictionary
	return {}

func get_instruction_text() -> String:
	var step: Dictionary = get_current_step()
	return String(step.get("instruction_text", ""))

func get_progress_string() -> String:
	var step: Dictionary = get_current_step()
	if step.is_empty():
		return "Selesai"
	var target: int = int(step.get("target_count", 1))
	return "%d/%d" % [current_event_count, target]

func is_action_blocked(action: StringName) -> bool:
	var step: Dictionary = get_current_step()
	var blocked: Array = step.get("blocked_actions", [])
	return blocked.has(action)

func record_event(event_name: StringName, count: int = 1) -> bool:
	# Catat total hitungan event gabungan kedua pemain (FR-TUT-05)
	var prev_cnt: int = int(event_counts.get(event_name, 0))
	event_counts[event_name] = prev_cnt + count

	if is_completed:
		return false

	var step: Dictionary = get_current_step()
	if step.is_empty():
		return false

	var trigger: StringName = step.get("event_trigger", &"")
	if trigger == event_name:
		current_event_count += count
		var target: int = int(step.get("target_count", 1))
		if current_event_count >= target:
			current_step_index += 1
			current_event_count = 0
			var total_steps: int = tutorial_data.steps.size() if ("steps" in tutorial_data) else 0
			if current_step_index >= total_steps:
				is_completed = true
			return true # Langkah selesai / lanjut ke langkah berikutnya
	return false

func record_miss() -> void:
	consecutive_misses += 1
	var is_adaptive: bool = false
	if tutorial_data != null and "is_adaptive_radius_enabled" in tutorial_data:
		is_adaptive = tutorial_data.is_adaptive_radius_enabled
	# FR-TUT-08: Setelah 3 kali meleset beruntun di T-4, radius membesar +25%
	if is_adaptive and consecutive_misses >= 3:
		serve_radius_multiplier = 1.25

func record_hit() -> void:
	consecutive_misses = 0

func skip() -> void:
	# FR-TUT-04: Lewati Tutorial
	is_completed = true
	if tutorial_data != null and "steps" in tutorial_data:
		current_step_index = tutorial_data.steps.size()
