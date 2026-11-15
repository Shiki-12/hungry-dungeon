class_name LevelData
extends Resource

@export var id: StringName = &""
@export var stage: int = 1
@export var duration_sec: float = 180.0
@export var lapak_module_id: StringName = &""
@export var stations_layout: Array[Dictionary] = []
@export var seating: Resource
@export var active_recipes: Array[StringName] = []
@export var monster_waves: Array[Dictionary] = []
@export var hazards: Array[StringName] = []
@export var star_thresholds: Vector3i = Vector3i(300, 600, 900)
@export var special_guest_id: StringName = &""
@export var unlocked_skills: Array[StringName] = []
@export var plate_count: int = 3
@export var washing_enabled: bool = false
@export var is_tutorial: bool = false
@export var max_open_tickets: int = 2
@export var max_active_monsters: int = 4
@export var long_table_bias: float = 0.6
@export var seat_patience_scale_long: float = 1.0
@export var seat_patience_scale_small: float = 0.85
