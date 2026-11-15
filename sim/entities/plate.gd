class_name SimPlate
extends RefCounted

const CLEAN: StringName = &"CLEAN"
const HELD: StringName = &"HELD"
const SERVED: StringName = &"SERVED"
const DIRTY: StringName = &"DIRTY"
const WASHING: StringName = &"WASHING"
const LOST: StringName = &"LOST"

var plate_id: int = 0
var state: StringName = CLEAN
var seat_id: int = -1
var timer: float = 0.0

func _init(id: int = 0) -> void:
	plate_id = id

func is_throwable() -> bool:
	return state == CLEAN or state == HELD or state == SERVED
