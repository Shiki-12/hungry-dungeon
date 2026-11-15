class_name SimPlatePool
extends RefCounted

const AUTO_RETURN_SECONDS: float = 6.0
const WASH_SECONDS_PER_PLATE: float = 2.0
const MAX_DIRTY_STACK: int = 3

var plate_count: int = 0
var washing_enabled: bool = true
var plates: Array[SimPlate] = []
var dirty_stack: Array[int] = []
var washing_count: int = 0
var washing_queue: Array[SimPlate] = []

func _init(count: int = 0, enabled: bool = true) -> void:
	plate_count = maxi(0, count)
	washing_enabled = enabled
	for i: int in range(plate_count):
		plates.append(SimPlate.new(i))

func clean_count() -> int:
	var total: int = 0
	for plate: SimPlate in plates:
		if plate.state == SimPlate.CLEAN:
			total += 1
	return total

func held_count() -> int:
	var total: int = 0
	for plate: SimPlate in plates:
		if plate.state == SimPlate.HELD:
			total += 1
	return total

func dirty_count() -> int:
	var total: int = 0
	for plate: SimPlate in plates:
		if plate.state == SimPlate.DIRTY:
			total += 1
	return total

func take_clean() -> SimPlate:
	for plate: SimPlate in plates:
		if plate.state == SimPlate.CLEAN:
			plate.state = SimPlate.HELD
			return plate
	return null

func serve(plate: SimPlate, seat_id: int) -> bool:
	if plate == null or plate.state != SimPlate.HELD:
		return false
	plate.state = SimPlate.SERVED
	plate.seat_id = seat_id
	return true

func monster_left(plate: SimPlate) -> bool:
	if plate == null or plate.state != SimPlate.SERVED:
		return false
	if not washing_enabled:
		plate.state = SimPlate.LOST
		plate.timer = AUTO_RETURN_SECONDS
		return true
	plate.state = SimPlate.DIRTY
	plate.timer = 0.0
	return true

func take_dirty(max_count: int = MAX_DIRTY_STACK) -> Array[SimPlate]:
	var result: Array[SimPlate] = []
	var limit: int = mini(max_count, MAX_DIRTY_STACK)
	for plate: SimPlate in plates:
		if result.size() >= limit:
			break
		if plate.state == SimPlate.DIRTY:
			plate.state = SimPlate.HELD
			result.append(plate)
	return result

func put_for_washing(stack: Array[SimPlate]) -> bool:
	if not washing_enabled or stack.is_empty() or stack.size() > MAX_DIRTY_STACK or washing_count > 0 or not washing_queue.is_empty():
		return false
	for plate: SimPlate in stack:
		if plate == null or plate.state != SimPlate.HELD:
			return false
	washing_queue = stack.duplicate()
	washing_count = washing_queue.size()
	var first: SimPlate = washing_queue[0]
	first.state = SimPlate.WASHING
	first.timer = WASH_SECONDS_PER_PLATE
	return true

func tick(delta: float) -> void:
	for plate: SimPlate in plates:
		if plate.state == SimPlate.LOST:
			plate.timer -= delta
			if plate.timer <= 0.0:
				plate.state = SimPlate.CLEAN
				plate.timer = 0.0
		elif plate.state == SimPlate.WASHING and plate == washing_queue[0]:
			plate.timer -= delta
			if plate.timer <= 0.0:
				plate.state = SimPlate.CLEAN
				plate.timer = 0.0
				washing_queue.remove_at(0)
				if not washing_queue.is_empty():
					washing_queue[0].state = SimPlate.WASHING
					washing_queue[0].timer = WASH_SECONDS_PER_PLATE
	washing_count = washing_queue.size()

func invariant_holds() -> bool:
	var active: int = 0
	for plate: SimPlate in plates:
		if plate.state != SimPlate.LOST:
			active += 1
	return active <= plate_count
