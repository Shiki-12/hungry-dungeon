class_name MonsterView
extends Node2D

## View-only monster representation. Asset access stays ID-based.
var monster: RefCounted
var asset_id: StringName = &"monster_goblin"

func _process(_delta: float) -> void:
	if monster == null:
		return
	position = monster.position
	queue_redraw()

func _draw() -> void:
	if monster == null:
		return
	var color: Color = Color("#8e44ad")
	if monster.state == 7 or monster.state == 8: # ENRAGED or ATTACKING
		color = Color("#e74c3c")
	elif monster.state == 9: # STEAL_RUN
		color = Color("#f39c12")
	draw_rect(Rect2(-6.0, -7.0, 12.0, 14.0), color)
