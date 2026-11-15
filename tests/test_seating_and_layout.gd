extends RefCounted

func run_all() -> bool:
	var module: LapakModule = LapakModule.new(5, 2)
	if not module.is_inside(Vector2(479, 223)):
		module.free()
		return false
	if module.is_inside(Vector2(480, 224)):
		module.free()
		return false
	if module.long_table.seats.size() != 5:
		module.free()
		return false
	for seat: SimSeat in module.long_table.seats:
		if int(seat.position.x / 16.0) != 13:
			module.free()
			return false
		if seat.order_anchor_offset.x <= 0.0:
			module.free()
			return false
	var first: SimSeat = module.long_table.seats[0]
	first.plate_state = SimSeat.PLATE_SERVED
	first.occupy(7)
	first.vacate()
	module.tick(1.9)
	if first.plate_state != SimSeat.PLATE_SERVED:
		module.free()
		return false
	module.tick(0.1)
	if first.plate_state != SimSeat.PLATE_DIRTY:
		module.free()
		return false
	module.free()
	return true
