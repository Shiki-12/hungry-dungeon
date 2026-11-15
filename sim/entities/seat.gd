class_name SimSeat
extends RefCounted

const TYPE_BENCH: StringName = &"BENCH"
const TYPE_STOOL: StringName = &"STOOL"
const TYPE_MAT: StringName = &"MAT"
const PLATE_NONE: StringName = &"NONE"
const PLATE_SERVED: StringName = &"SERVED"
const PLATE_DIRTY: StringName = &"DIRTY"

var seat_id: int = 0
var table_id: int = 0
var table_kind: StringName = &"LONG"
var position: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.LEFT
var seat_type: StringName = TYPE_BENCH
var serve_radius: float = 12.0
var plate_state: StringName = PLATE_NONE
var occupant_monster_id: int = -1
var order_anchor_offset: Vector2 = Vector2(10.0, -8.0)
var emote_anchor_offset: Vector2 = Vector2(0.0, -16.0)
var _vacated_time: float = -1.0

func _init(id: int = 0, table: int = 0, at: Vector2 = Vector2.ZERO) -> void:
	seat_id = id
	table_id = table
	position = at

func occupy(monster_id: int) -> void:
	occupant_monster_id = monster_id
	_vacated_time = -1.0

func vacate() -> void:
	occupant_monster_id = -1
	_vacated_time = 0.0

func tick(dt: float) -> void:
	if occupant_monster_id < 0 and _vacated_time >= 0.0:
		_vacated_time += maxf(dt, 0.0)
		if _vacated_time >= 2.0 and plate_state == PLATE_SERVED:
			plate_state = PLATE_DIRTY
			_vacated_time = -1.0

func is_free() -> bool:
	return occupant_monster_id < 0

func can_serve(at: Vector2) -> bool:
	return is_free() == false and position.distance_to(at) <= serve_radius

func order_anchor() -> Vector2:
	return position + order_anchor_offset

func emote_anchor() -> Vector2:
	return position + emote_anchor_offset
