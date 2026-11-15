extends RefCounted

const MonsterScript: Script = preload("res://sim/entities/monster.gd")
const OrdersScript: Script = preload("res://sim/systems/orders.gd")

func run_all() -> bool:
	var monster: RefCounted = MonsterScript.new(1, &"goblin")
	monster.seat(&"LONG", 1, &"recipe_a")
	monster.begin_waiting()
	monster.tick(20.0)
	if monster.patience < 49.9 or monster.patience > 50.1:
		return false
	var small: RefCounted = MonsterScript.new(2, &"goblin")
	small.seat(&"SMALL", 2, &"recipe_a")
	small.begin_waiting()
	small.tick(17.0)
	if small.patience > 50.1 or small.patience < 49.9:
		return false
	var orders: RefCounted = OrdersScript.new(7)
	orders.max_open_tickets = 1
	var mon_a: RefCounted = MonsterScript.new(10, &"goblin")
	mon_a.seat(&"LONG", 10, &"recipe_a")
	if not orders.register(mon_a):
		return false
	# mon_a should go to WAITING since tickets_before=0 < 1
	if mon_a.state != MonsterScript.State.WAITING:
		return false
	var mon_b: RefCounted = MonsterScript.new(11, &"goblin")
	mon_b.seat(&"LONG", 11, &"recipe_a")
	if not orders.register(mon_b):
		return false
	# mon_b should BROWSE since tickets_before=1 >= 1
	if mon_b.state != MonsterScript.State.BROWSING:
		return false
	monster.state = MonsterScript.State.ENRAGED
	if not monster.hit(false) or not monster.hit(false) or not monster.hit(false):
		return false
	if monster.state != MonsterScript.State.EXPELLED:
		return false
	var served: RefCounted = MonsterScript.new(3, &"goblin")
	served.position = Vector2(10.0, 10.0)
	served.seat(&"LONG", 3, &"recipe_a")
	served.begin_waiting()
	orders.register(served)
	var found: RefCounted = orders.serve_nearby(&"recipe_a", Vector2(20.0, 10.0))
	return found == served and served.state == MonsterScript.State.EATING
