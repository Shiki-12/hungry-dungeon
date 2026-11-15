const PoolScript: Script = preload("res://sim/systems/plate_pool.gd")
const PlateScript: Script = preload("res://sim/entities/plate.gd")

func run_all() -> bool:
	var pool: RefCounted = PoolScript.new(4, true)
	assert(pool.clean_count() == 4)
	var plate: RefCounted = pool.take_clean()
	assert(plate != null)
	assert(pool.serve(plate, 7))
	assert(pool.monster_left(plate))
	assert(plate.state == &"DIRTY")
	var stack: Array = pool.take_dirty(3)
	assert(stack.size() == 1)
	assert(pool.put_for_washing(stack))
	assert(not plate.is_throwable())
	pool.tick(2.0)
	assert(plate.state == &"CLEAN")
	return true
