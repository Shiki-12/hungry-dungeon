class_name SimStation
extends RefCounted

## Deterministic station state machine. No visual or physics nodes.
enum State {
	EMPTY = 0,
	OCCUPIED = 1,
	PROCESSING = 2,
	READY = 3,
	BURNING = 4,
	BURNT = 5,
}

const WORKING = State.PROCESSING
const DONE = State.READY

var station_data: Resource
var state: State = State.EMPTY
var held_item_id: StringName = &""
var recipe_id: StringName = &""
var step_index: int = -1
var current_step: Resource = null
var progress: float = 0.0
var step_duration: float = 0.0
var burn_timer: float = 0.0
var base_burn_time: float = 10.0
var disabled_timer: float = 0.0
var worker_ids: Array[int] = []

# Attention mechanism (FR-STA-04 s.d. 07)
var attention_interval: float = 0.0
var attention_window: float = 0.0
var attention_miss_penalty: float = 0.3
var attention_timer: float = 0.0
var attention_window_timer: float = 0.0
var needs_attention: bool = false
var missed_attention: bool = false

func _init(data: Resource = null) -> void:
	if data != null:
		station_data = data
	else:
		var sd: Resource = Resource.new()
		station_data = sd

func is_manual_station() -> bool:
	if station_data == null:
		return false
	if station_data.auto_work:
		return false
	var sid: String = String(station_data.id).to_lower()
	var stype: String = String(station_data.type).to_lower()
	if sid.begins_with("tungku") or sid.begins_with("dandang") or sid.begins_with("anglo") or sid.begins_with("panci"):
		return false
	if stype == "tungku" or stype == "dandang" or stype == "anglo" or stype == "panci":
		return false
	if not station_data.accepted_steps.is_empty():
		var first_step: String = String(station_data.accepted_steps[0]).to_upper()
		if first_step == "COOK" or first_step == "FRY" or first_step == "BOIL" or first_step == "STEAM":
			return false
	# Known manual station types
	if sid.begins_with("meja_potong") or sid.begins_with("meja_kerja") or sid.begins_with("cobek") or sid.begins_with("tempat_cuci"):
		return true
	if stype == "meja_potong" or stype == "meja_kerja" or stype == "cobek" or stype == "tempat_cuci":
		return true
	return false

func can_accept_step(step_type: StringName) -> bool:
	if station_data == null:
		return false
	return state == State.EMPTY or (state == State.OCCUPIED and station_data.accepted_steps.has(step_type))

func begin_step(recipe: Resource, index: int = 0) -> bool:
	if recipe == null or index < 0 or index >= recipe.steps.size():
		return false
	var step: Resource = recipe.steps[index]
	if station_data != null and not station_data.accepted_steps.is_empty() and not station_data.accepted_steps.has(step.type):
		return false
	if state != State.EMPTY and state != State.OCCUPIED:
		return false
	recipe_id = recipe.id
	step_index = index
	current_step = step
	progress = 0.0
	step_duration = step.duration if "duration" in step else 0.0
	base_burn_time = recipe.burn_time if ("burn_time" in recipe and recipe.burn_time > 0.0) else (station_data.burn_duration if ("burn_duration" in station_data and station_data.burn_duration > 0.0) else 10.0)
	burn_timer = base_burn_time
	
	# Attention setup
	attention_interval = step.attention_interval if "attention_interval" in step else 0.0
	attention_window = step.attention_window if "attention_window" in step else 0.0
	attention_miss_penalty = step.attention_miss_penalty if ("attention_miss_penalty" in step and step.attention_miss_penalty > 0.0) else 0.3
	attention_timer = attention_interval
	attention_window_timer = 0.0
	needs_attention = false
	missed_attention = false
	
	state = State.PROCESSING
	return true

func attend(_worker_id: int = 0) -> bool:
	if needs_attention:
		needs_attention = false
		attention_window_timer = 0.0
		attention_timer = attention_interval
		return true
	return false

func tick(delta: float) -> void:
	if disabled_timer > 0.0:
		disabled_timer = maxf(0.0, disabled_timer - delta)
	if delta <= 0.0 or disabled_timer > 0.0:
		return
	
	if state == State.PROCESSING:
		var can_progress: bool = true
		if is_manual_station():
			can_progress = worker_ids.size() > 0
		
		if can_progress:
			progress += delta
			
			# Handle attention interval & window
			if attention_interval > 0.0:
				if not needs_attention:
					attention_timer -= delta
					if attention_timer <= 0.0:
						needs_attention = true
						var win_len: float = attention_window
						var loop: MainLoop = Engine.get_main_loop()
						if loop is SceneTree and (loop as SceneTree).root:
							var settings_node: Node = (loop as SceneTree).root.get_node_or_null("Settings")
							if settings_node != null and "wide_attention_window" in settings_node and settings_node.wide_attention_window:
								win_len *= 1.5
						attention_window_timer = win_len
				else:
					attention_window_timer -= delta
					if attention_window_timer <= 0.0:
						# Attention missed!
						needs_attention = false
						missed_attention = true
						attention_timer = attention_interval
			
			# Check auto-finish step
			if step_duration > 0.0 and progress >= step_duration:
				var out_id: StringName = current_step.output if current_step != null and "output" in current_step else &""
				finish_step(out_id)
				
	elif state == State.READY or state == State.BURNING:
		if burn_timer > 0.0:
			burn_timer -= delta
			if burn_timer <= 0.0:
				state = State.BURNT
			elif burn_timer <= base_burn_time * 0.4:
				state = State.BURNING

func disable(duration: float) -> void:
	disabled_timer = maxf(disabled_timer, duration)

func is_disabled() -> bool:
	return disabled_timer > 0.0

func finish_step(output_id: StringName = &"") -> bool:
	if state != State.PROCESSING:
		return false
	if output_id != &"":
		held_item_id = output_id
	elif current_step != null and "output" in current_step and current_step.output != &"":
		held_item_id = current_step.output
	state = State.READY
	progress = 0.0
	needs_attention = false
	var penalty: float = attention_miss_penalty if missed_attention else 1.0
	burn_timer = base_burn_time * penalty
	return true

func take_item() -> StringName:
	var result: StringName = held_item_id
	held_item_id = &""
	recipe_id = &""
	step_index = -1
	current_step = null
	progress = 0.0
	burn_timer = 0.0
	needs_attention = false
	missed_attention = false
	state = State.EMPTY
	return result

func clear_contents() -> void:
	held_item_id = &""
	recipe_id = &""
	step_index = -1
	current_step = null
	progress = 0.0
	burn_timer = 0.0
	needs_attention = false
	missed_attention = false
	state = State.EMPTY

func add_worker(worker_id: int) -> bool:
	if worker_ids.has(worker_id) or worker_ids.size() >= station_data.capacity:
		return false
	worker_ids.append(worker_id)
	return true

func remove_worker(worker_id: int) -> void:
	worker_ids.erase(worker_id)

func is_full() -> bool:
	return worker_ids.size() >= station_data.capacity

func state_name() -> StringName:
	var names: Array[StringName] = [&"EMPTY", &"OCCUPIED", &"PROCESSING", &"READY", &"BURNING", &"BURNT"]
	if state >= 0 and state < names.size():
		return names[state]
	return &"UNKNOWN"

func snapshot() -> Dictionary:
	return {
		"state": state_name(),
		"item_id": held_item_id,
		"recipe_id": recipe_id,
		"step_index": step_index,
		"progress": progress,
		"burn_timer": burn_timer,
		"needs_attention": needs_attention,
		"missed_attention": missed_attention
	}
