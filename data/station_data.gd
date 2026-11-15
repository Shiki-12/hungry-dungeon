class_name StationData
extends Resource

@export var id: StringName = &""
@export var type: StringName = &""
@export var size_tiles: Vector2i = Vector2i.ONE
@export var capacity: int = 1
@export var accepted_steps: Array[StringName] = []
@export var auto_work: bool = false
@export var burn_duration: float = 10.0
@export var linked_rack_id: StringName = &""
