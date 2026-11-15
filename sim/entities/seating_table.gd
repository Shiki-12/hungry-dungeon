class_name SimSeatingTable
extends RefCounted

const KIND_LONG: StringName = &"LONG"
const KIND_SMALL: StringName = &"SMALL"
const KIND_ALTAR: StringName = &"ALTAR"

var table_id: int = 0
var kind: StringName = KIND_LONG
var seats: Array[SimSeat] = []

func _init(id: int = 0, table_kind: StringName = KIND_LONG) -> void:
	table_id = id
	kind = table_kind

func add_seat(seat: SimSeat) -> void:
	seat.table_id = table_id
	seat.table_kind = kind
	seats.append(seat)

func free_seats() -> Array[SimSeat]:
	var result: Array[SimSeat] = []
	for seat: SimSeat in seats:
		if seat.is_free():
			result.append(seat)
	return result

func tick(dt: float) -> void:
	for seat: SimSeat in seats:
		seat.tick(dt)
