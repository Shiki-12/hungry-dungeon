extends RefCounted

func run_all() -> bool:
	var module: LapakModule = LapakModule.new(5, 2)
	if not module.is_inside(Vector2(479, 223)):
		return false
	if module.is_inside(Vector2(480, 224)):
		return false
	if module.long_table.seats.size() != 5:
		return false
	for seat: SimSeat in module.long_table.seats:
		if int(seat.position.x / 16.0) != 13:
			return false
		if seat.order_anchor_offset.x <= 0.0:
			return false
	var first: SimSeat = module.long_table.seats[0]
	first.plate_state = SimSeat.PLATE_SERVED
	first.occupy(7)
	first.vacate()
	module.tick(1.9)
	if first.plate_state != SimSeat.PLATE_SERVED:
		return false
	module.tick(0.1)
	if first.plate_state != SimSeat.PLATE_DIRTY:
		return false
	return true
