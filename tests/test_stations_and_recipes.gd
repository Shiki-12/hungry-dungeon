extends RefCounted

const RecipeScript: Script = preload("res://data/recipe_data.gd")
const StationDataScript: Script = preload("res://data/station_data.gd")
const StationScript: Script = preload("res://sim/entities/station.gd")
const StepScript: Script = preload("res://data/step_data.gd")

static func run_all() -> bool:
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
