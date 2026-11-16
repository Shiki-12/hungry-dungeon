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
var theme_variant: StringName = &"lapak" # lapak atau halaman (FR-TUT-09)
var has_river: bool = false # Khusus T-4 seberang sungai kecil

func setup_t4_layout() -> void:
	# FR-TUT-09: T-4 punya tiga meja: dekat (3 petak), 6 petak, dan seberang sungai kecil (8 petak)
	theme_variant = &"halaman"
	has_river = true
	small_tables.clear()
	
	# Meja 1: Dekat (jarak 3 petak dari koki x=5 -> meja x=8..14)
	var t1: SimSeatingTable = SimSeatingTable.new(1, SimSeatingTable.KIND_SMALL)
	var s1: SimSeat = SimSeat.new(10, t1.table_id, Vector2(14.0 * TILE_SIZE + 8.0, 3.0 * TILE_SIZE + 8.0))
	s1.seat_type = SimSeat.TYPE_STOOL
	t1.add_seat(s1)
	small_tables.append(t1)

	# Meja 2: 6 Petak (jarak 6 petak dari batas lapak x=12 -> meja x=18)
	var t2: SimSeatingTable = SimSeatingTable.new(2, SimSeatingTable.KIND_SMALL)
	var s2: SimSeat = SimSeat.new(11, t2.table_id, Vector2(18.0 * TILE_SIZE + 8.0, 6.0 * TILE_SIZE + 8.0))
	s2.seat_type = SimSeat.TYPE_STOOL
	t2.add_seat(s2)
	small_tables.append(t2)

	# Meja 3: Seberang Sungai Kecil (sungai di x=21..22, meja di x=24)
	var t3: SimSeatingTable = SimSeatingTable.new(3, SimSeatingTable.KIND_SMALL)
	var s3: SimSeat = SimSeat.new(12, t3.table_id, Vector2(24.0 * TILE_SIZE + 8.0, 9.0 * TILE_SIZE + 8.0))
	s3.seat_type = SimSeat.TYPE_STOOL
	t3.add_seat(s3)
	small_tables.append(t3)

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
