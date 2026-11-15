class_name StationView
extends Node2D

## Visual station shell. Simulation state remains in SimStation.
var station: RefCounted
@export var asset_id: StringName = &"station"

func _process(_delta: float) -> void:
	if station == null:
		return
	queue_redraw()

func _draw() -> void:
	if station == null:
		return
	var color: Color = Color("#795548")
	var size: Vector2 = Vector2(16.0, 16.0)
	draw_rect(Rect2(-size * 0.5, size), color)
