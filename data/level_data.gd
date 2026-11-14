class_name LevelData
extends Resource

@export var id: String = ""
@export var stage_number: int = 1
@export var display_name: String = ""
@export var duration_seconds: float = 180.0
@export var kitchen_scene_path: String = ""
@export var p1_spawn_pos: Vector2 = Vector2(160, 140)
@export var p2_spawn_pos: Vector2 = Vector2(320, 140)
@export var available_recipes: Array[RecipeData] = []
@export var target_stars: Array[int] = [300, 600, 900]
@export var max_concurrent_monsters: int = 3
@export var skills_unlocked: Array[String] = []
@export var is_tutorial: bool = false
@export var has_hazards: bool = false
