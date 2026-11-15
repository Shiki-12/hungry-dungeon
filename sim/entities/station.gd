class_name SimStation
extends RefCounted

## Deterministic station state machine. No visual or physics nodes.
enum State { EMPTY, OCCUPIED, PROCESSING, READY, BURNT }

var station_data: Resource
var state: State = State.EMPTY
var held_item_id: StringName = &""
var recipe_id: StringName = &""
var step_index: int = -1
var progress: float = 0.0
var burn_timer: float = 0.0
var disabled_timer: float = 0.0
var worker_ids: Array[int] = []

func _init(data: Resource = null) -> void:
	if data != null:
		station_data = data
	else:
		var sd: Resource = Resource.new()
		station_data = sd

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
	progress = 0.0
	burn_timer = recipe.burn_time if recipe.burn_time > 0.0 else station_data.burn_duration
	state = State.PROCESSING
	return true

func tick(delta: float) -> void:
	if disabled_timer > 0.0:
		disabled_timer = maxf(0.0, disabled_timer - delta)
	if delta <= 0.0 or state != State.PROCESSING or disabled_timer > 0.0:
		return
	progress += delta
	if burn_timer > 0.0:
		burn_timer -= delta
		if burn_timer <= 0.0:
			state = State.BURNT

func disable(duration: float) -> void:
	disabled_timer = maxf(disabled_timer, duration)

func is_disabled() -> bool:
	return disabled_timer > 0.0

func finish_step(output_id: StringName) -> bool:
	if state != State.PROCESSING:
		return false
	held_item_id = output_id
	state = State.READY
	progress = 0.0
	burn_timer = 0.0
	return true

func take_item() -> StringName:
	var result: StringName = held_item_id
	held_item_id = &""
	recipe_id = &""
	step_index = -1
	progress = 0.0
	burn_timer = 0.0
	state = State.EMPTY
	return result

func clear_contents() -> void:
	held_item_id = &""
	recipe_id = &""
	step_index = -1
	progress = 0.0
	burn_timer = 0.0
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
	return [&"EMPTY", &"OCCUPIED", &"PROCESSING", &"READY", &"BURNT"][state]

func snapshot() -> Dictionary:
	return {"state": state_name(), "item_id": held_item_id, "recipe_id": recipe_id, "step_index": step_index, "progress": progress, "burn_timer": burn_timer}
