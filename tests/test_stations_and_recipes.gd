extends RefCounted

const RecipeScript: Script = preload("res://data/recipe_data.gd")
const StationDataScript: Script = preload("res://data/station_data.gd")
const StationScript: Script = preload("res://sim/entities/station.gd")
const StepScript: Script = preload("res://data/step_data.gd")

static func run_all() -> bool:
	if not _test_basic_station():
		return false
	if not _test_manual_vs_auto():
		return false
	if not _test_attention_mechanism():
		return false
	return true

static func _test_basic_station() -> bool:
	var data: Resource = StationDataScript.new()
	data.capacity = 2
	data.accepted_steps.clear()
	data.accepted_steps.append(&"COOK")
	var station: RefCounted = StationScript.new(data)
	if not station.can_accept_step(&"COOK"):
		return false
	var recipe: Resource = RecipeScript.new()
	recipe.id = &"test"
	recipe.dish_item_id = &"dish"
	var step: Resource = StepScript.new()
	step.type = &"COOK"
	recipe.steps.clear()
	recipe.steps.append(step)
	if not station.begin_step(recipe, 0):
		return false
	station.tick(1.0)
	if not station.finish_step(&"dish"):
		return false
	return true

static func _test_manual_vs_auto() -> bool:
	# 1. Manual station (meja_potong) requires worker to progress
	var manual_data: Resource = StationDataScript.new()
	manual_data.id = &"meja_potong"
	manual_data.type = &"meja_potong"
	manual_data.accepted_steps.clear()
	manual_data.accepted_steps.append(&"CHOP")
	var manual_station: RefCounted = StationScript.new(manual_data)
	
	var chop_recipe: Resource = RecipeScript.new()
	chop_recipe.id = &"test_chop"
	var chop_step: Resource = StepScript.new()
	chop_step.type = &"CHOP"
	chop_step.duration = 3.0
	chop_recipe.steps.clear()
	chop_recipe.steps.append(chop_step)
	
	manual_station.begin_step(chop_recipe, 0)
	manual_station.tick(1.0)
	if manual_station.progress > 0.001:
		push_error("Manual station progressed without worker!")
		return false
	
	manual_station.add_worker(1)
	manual_station.tick(1.0)
	if not is_equal_approx(manual_station.progress, 1.0):
		push_error("Manual station did not progress with worker!")
		return false

	# 2. Auto station (tungku) progresses automatically
	var auto_data: Resource = StationDataScript.new()
	auto_data.id = &"tungku"
	auto_data.type = &"tungku"
	auto_data.auto_work = true
	auto_data.accepted_steps.clear()
	auto_data.accepted_steps.append(&"COOK")
	var auto_station: RefCounted = StationScript.new(auto_data)
	
	var cook_recipe: Resource = RecipeScript.new()
	cook_recipe.id = &"test_cook"
	var cook_step: Resource = StepScript.new()
	cook_step.type = &"COOK"
	cook_step.duration = 5.0
	cook_recipe.steps.clear()
	cook_recipe.steps.append(cook_step)
	
	auto_station.begin_step(cook_recipe, 0)
	auto_station.tick(1.0)
	if not is_equal_approx(auto_station.progress, 1.0):
		push_error("Auto station did not progress automatically!")
		return false

	return true

static func _test_attention_mechanism() -> bool:
	var tungku_data: Resource = StationDataScript.new()
	tungku_data.id = &"tungku"
	tungku_data.type = &"tungku"
	tungku_data.auto_work = true
	tungku_data.burn_duration = 10.0
	
	var recipe: Resource = RecipeScript.new()
	recipe.id = &"test_attention"
	recipe.burn_time = 10.0
	var step: Resource = StepScript.new()
	step.type = &"COOK"
	step.duration = 6.0
	step.attention_interval = 4.0
	step.attention_window = 1.5
	step.attention_miss_penalty = 0.3
	recipe.steps.clear()
	recipe.steps.append(step)

	# Case A: Attended properly
	var st_attended: RefCounted = StationScript.new(tungku_data)
	st_attended.begin_step(recipe, 0)
	st_attended.tick(3.9)
	if st_attended.needs_attention:
		push_error("Should not need attention yet at 3.9s")
		return false
	st_attended.tick(0.2) # total 4.1s
	if not st_attended.needs_attention:
		push_error("Should trigger needs_attention at 4.1s")
		return false
	var attended_success: bool = st_attended.attend()
	if not attended_success or st_attended.needs_attention or st_attended.missed_attention:
		push_error("Attend failed to resolve attention")
		return false
	# Finish cooking (remaining 1.9s)
	st_attended.tick(2.0)
	if st_attended.state != StationScript.State.READY:
		push_error("Station should be READY/DONE after duration reached")
		return false
	if not is_equal_approx(st_attended.burn_timer, 10.0):
		push_error("Burn timer should be 10.0s when attended properly, got: %f" % st_attended.burn_timer)
		return false

	# Case B: Missed attention -> burn time penalty 10.0 * 0.3 = 3.0s
	var st_missed: RefCounted = StationScript.new(tungku_data)
	st_missed.begin_step(recipe, 0)
	st_missed.tick(4.1) # enters needs_attention
	if not st_missed.needs_attention:
		return false
	st_missed.tick(1.6) # window (1.5s) expired!
	if st_missed.needs_attention or not st_missed.missed_attention:
		push_error("Attention should be marked as missed after window expired")
		return false
	# Finish cooking
	st_missed.tick(0.5)
	if st_missed.state != StationScript.State.READY:
		return false
	if not is_equal_approx(st_missed.burn_timer, 3.0):
		push_error("Burn timer should be penalized to 3.0s (10*0.3), got: %f" % st_missed.burn_timer)
		return false
	# Tick 3.0s in READY -> goes to BURNT!
	st_missed.tick(3.1)
	if st_missed.state != StationScript.State.BURNT:
		push_error("Station should become BURNT after burn_timer reaches 0")
		return false

	return true
