class_name RecipeData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var steps: Array[StepData] = []
@export var base_points: int = 100
@export var burn_timer_seconds: float = 10.0
@export var required_plate: bool = true
