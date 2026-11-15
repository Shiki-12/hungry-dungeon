class_name CookEntity
extends RefCounted

const CollisionScript: Script = preload("res://sim/systems/collision.gd")
const TILE_SIZE: float = 16.0
const DEFAULT_SPEED_TILES: float = 5.0
const ACCEL_TIME: float = 0.06

var cook_id: int = 1
var cook_name: String = "Rangga"
var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var base_speed: float = DEFAULT_SPEED_TILES * TILE_SIZE
var speed_multiplier: float = 1.0
var facing_direction: Vector2 = Vector2.DOWN
var is_aiming_throw: bool = false
var held_item_id: String = ""

func step(input_vector: Vector2, delta: float, blocked_cells: Array[Vector2i] = [], obstacles: Array[Rect2] = []) -> void:
	var direction: Vector2 = input_vector
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	if direction != Vector2.ZERO:
		facing_direction = quantize_direction(direction)
	var target_speed: float = base_speed * speed_multiplier
	if is_aiming_throw:
		target_speed *= 0.5
	var target_velocity: Vector2 = direction * target_speed
	var accel_rate: float = base_speed / ACCEL_TIME
	velocity = velocity.move_toward(target_velocity, accel_rate * delta)
	position = CollisionScript.move_circle(position, velocity * delta, CollisionScript.COOK_RADIUS, blocked_cells, obstacles)

func get_interaction_target_position() -> Vector2:
	return position + facing_direction * TILE_SIZE

static func quantize_direction(direction: Vector2) -> Vector2:
	var snapped_angle: float = snappedf(direction.angle(), PI / 4.0)
	return Vector2(cos(snapped_angle), sin(snapped_angle)).normalized()
