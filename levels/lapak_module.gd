class_name LapakModule
extends Node

const TILE_SIZE: int = 16
const WIDTH_TILES: int = 30
const HEIGHT_TILES: int = 14
const LAPAK_WIDTH_TILES: int = 12
const LONG_TABLE_COLUMN: int = 12
const SEAT_COLUMN: int = 13

var long_table: SimSeatingTable
var small_tables: Array[SimSeatingTable] = []
var stations: Array[Dictionary] = []

func _init(long_seat_count: int = 5, small_table_count: int = 0) -> void:
	long_table = SimSeatingTable.new(0, SimSeatingTable.KIND_LONG)
	var count: int = clampi(long_seat_count, 5, 7)
	for index: int in count:
		var seat: SimSeat = SimSeat.new(index, 0, Vector2(SEAT_COLUMN * TILE_SIZE + 8, (index + 1) * 18))
		seat.facing = Vector2.LEFT
		seat.order_anchor_offset = Vector2(10.0, -8.0)
		long_table.add_seat(seat)
	for index: int in mini(small_table_count, 4):
		var table: SimSeatingTable = SimSeatingTable.new(index + 1, SimSeatingTable.KIND_SMALL)
		var near: bool = index < 2
		var x: int = 15 + (index % 2) * 3 if near else 23 + ((index - 2) % 2) * 3
		var y: int = 3 if index % 2 == 0 else 9
		var center: Vector2 = Vector2(x * TILE_SIZE + 16, y * TILE_SIZE + 8)
		var left: SimSeat = SimSeat.new(index * 2, table.table_id, center + Vector2(-16, 0))
		var right: SimSeat = SimSeat.new(index * 2 + 1, table.table_id, center + Vector2(16, 0))
		left.seat_type = SimSeat.TYPE_STOOL
		right.seat_type = SimSeat.TYPE_STOOL
		left.facing = Vector2.RIGHT
		right.facing = Vector2.LEFT
		table.add_seat(left)
		table.add_seat(right)
		small_tables.append(table)

func all_seats() -> Array[SimSeat]:
	var result: Array[SimSeat] = []
	result.append_array(long_table.seats)
	for table: SimSeatingTable in small_tables:
		result.append_array(table.seats)
	return result

func tick(dt: float) -> void:
	long_table.tick(dt)
	for table: SimSeatingTable in small_tables:
		table.tick(dt)

func is_inside(px: Vector2) -> bool:
	return px.x >= 0.0 and px.x < WIDTH_TILES * TILE_SIZE and px.y >= 0.0 and px.y < HEIGHT_TILES * TILE_SIZE

func long_table_blocks(px: Vector2) -> bool:
	return int(floor(px.x / TILE_SIZE)) == LONG_TABLE_COLUMN and int(floor(px.y / TILE_SIZE)) in range(1, 11)
