class_name SimCollision
extends RefCounted

const TILE_SIZE: float = 16.0
const COOK_RADIUS: float = 6.0

static func move_circle(position: Vector2, displacement: Vector2, radius: float, blocked_cells: Array[Vector2i], obstacles: Array[Rect2] = []) -> Vector2:
	var result: Vector2 = position
	result = _axis_move(result, Vector2(displacement.x, 0.0), radius, blocked_cells, obstacles)
	result = _axis_move(result, Vector2(0.0, displacement.y), radius, blocked_cells, obstacles)
	return result

static func _axis_move(position: Vector2, displacement: Vector2, radius: float, blocked_cells: Array[Vector2i], obstacles: Array[Rect2]) -> Vector2:
	var candidate: Vector2 = position + displacement
	if not is_circle_blocked(candidate, radius, blocked_cells, obstacles):
		return candidate
	return position

static func is_circle_blocked(position: Vector2, radius: float, blocked_cells: Array[Vector2i], obstacles: Array[Rect2]) -> bool:
	for cell: Vector2i in blocked_cells:
		var rect: Rect2 = Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
		if _circle_intersects_rect(position, radius, rect):
			return true
	for rect: Rect2 in obstacles:
		if _circle_intersects_rect(position, radius, rect):
			return true
	return false

static func _circle_intersects_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest: Vector2 = Vector2(clampf(center.x, rect.position.x, rect.end.x), clampf(center.y, rect.position.y, rect.end.y))
	return center.distance_squared_to(closest) < radius * radius
