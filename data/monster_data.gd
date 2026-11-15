class_name MonsterData
extends Resource

@export var id: StringName = &""
@export var size_px: Vector2i = Vector2i(16, 16)
@export var base_patience_sec: float = 40.0
@export var favorite_recipes: Array[StringName] = []
@export var attack_pattern: StringName = &"NONE"
@export var allowed_seat_types: Array[StringName] = []
@export var cracker_pause_sec: float = 8.0
@export var rare_drop_id: StringName = &""
@export var variants: Array[StringName] = []
