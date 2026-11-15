class_name StepData
extends Resource

@export var type: StringName = &"CHOP"
@export var inputs: Array[StringName] = []
@export var output: StringName = &""
@export var station_type: StringName = &""
@export var duration: float = 0.0
@export var rhythm_bpm: int = 0
@export var rhythm_beats: int = 0
@export var attention_interval: float = 0.0
@export var attention_window: float = 0.0
@export var attention_miss_penalty: float = 0.3
