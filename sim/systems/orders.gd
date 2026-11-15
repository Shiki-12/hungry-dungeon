class_name SimOrderSystem
extends RefCounted

var max_open_tickets: int = 2
var long_table_bias: float = 0.6
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var active_orders: Array = []

func _init(seed_val: int = 1) -> void:
	rng.seed = seed_val

func open_ticket_count() -> int:
	var count: int = 0
	for monster: RefCounted in active_orders:
		if monster.state == 3 or monster.state == 4: # WAITING or EATING
			count += 1
	return count

func register(monster: RefCounted, has_small_tables: bool = true) -> bool:
	if monster == null:
		return false
	var tickets_before: int = open_ticket_count()
	active_orders.append(monster)
	if monster.state == 0 or monster.state == 1: # ARRIVING or SEATED
		if tickets_before >= max_open_tickets:
			monster.state = 2 # BROWSING
		else:
			monster.begin_waiting()
	return true

func release(monster: RefCounted) -> void:
	active_orders.erase(monster)

func tick(delta: float) -> void:
	for monster: RefCounted in active_orders:
		monster.tick(delta)

func serve_nearby(recipe: StringName, pos: Vector2, radius: float = 14.0, sambal_bonus: float = 0.0, jitu_bonus: float = 0.0) -> RefCounted:
	var best: RefCounted = null
	var best_distance: float = INF
	for monster: RefCounted in active_orders:
		if monster.state != 3 or monster.requested_recipe != recipe: # not WAITING
			continue
		var distance: float = monster.position.distance_to(pos)
		if distance <= radius and distance < best_distance:
			best = monster
			best_distance = distance
	if best != null:
		best.serve(recipe, sambal_bonus, jitu_bonus)
	return best
