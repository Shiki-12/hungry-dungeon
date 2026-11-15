class_name RecipeData
extends Resource

@export var id: StringName = &""
@export var display_name_key: StringName = &""
@export var steps: Array[StepData] = []
@export var final_components: Array[StringName] = []
@export var container_type: StringName = &""
@export var dish_item_id: StringName = &""
@export var icon_id: StringName = &""
@export var base_points: int = 150
@export var burn_time: float = 10.0
