extends RefCounted

const CollisionScript: Script = preload("res://sim/systems/collision.gd")
const CookScript: Script = preload("res://sim/entities/cook.gd")

static func run_all() -> bool:
	var blocked: Array[Vector2i] = [Vector2i(1, 0)]
	var result: Vector2 = CollisionScript.move_circle(Vector2(8, 8), Vector2(16, 0), 6.0, blocked)
	if result.x >= 16.0:
		return false
	var cook: RefCounted = CookScript.new()
	cook.position = Vector2(8, 8)
	cook.step(Vector2(1, 1), 0.1, blocked)
	return cook.position.y > 8.0
