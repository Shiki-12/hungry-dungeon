class_name CookEntity
extends CharacterBody2D

# sim/entities/cook.gd
# Logika gerak & fisika koki tanpa komponen visual/audio (headless compatible)

const TILE_SIZE: float = 16.0
const DEFAULT_SPEED_TILES: float = 5.0 # 5 tile per detik (FR-MOV-01)
const ACCEL_TIME: float = 0.06 # 0.06 detik ke kecepatan penuh (FR-MOV-01)

@export var cook_id: int = 1 # 1 = Rangga (P1), 2 = Sekar (P2)
@export var cook_name: String = "Rangga"

var base_speed: float = DEFAULT_SPEED_TILES * TILE_SIZE # 80 px/s
var speed_multiplier: float = 1.0
var facing_direction: Vector2 = Vector2.DOWN
var is_aiming_throw: bool = false
var held_item_id: String = ""

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = _get_input_vector()
	
	if input_vector != Vector2.ZERO:
		facing_direction = _quantize_direction(input_vector)

	var target_speed: float = base_speed * speed_multiplier
	if is_aiming_throw:
		target_speed *= 0.5 # FR-THR-05: 50% lebih lambat saat membidik

	var target_velocity: Vector2 = input_vector * target_speed
	var accel_rate: float = (base_speed / ACCEL_TIME)
	velocity = velocity.move_toward(target_velocity, accel_rate * delta)

	move_and_slide()

func get_interaction_target_position() -> Vector2:
	# Area 1 tile di depan arah hadap (FR-MOV-04)
	return global_position + facing_direction * TILE_SIZE

func _get_input_vector() -> Vector2:
	var prefix: String = "p1_" if cook_id == 1 else "p2_"
	var x: float = Input.get_axis(prefix + "move_left", prefix + "move_right")
	var y: float = Input.get_axis(prefix + "move_up", prefix + "move_down")
	var dir: Vector2 = Vector2(x, y)
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	return dir

func _quantize_direction(dir: Vector2) -> Vector2:
	# Kunci arah hadap ke 8 arah diskrit
	var angle: float = dir.angle()
	var snapped_angle: float = snappedf(angle, PI / 4.0)
	return Vector2(cos(snapped_angle), sin(snapped_angle)).normalized()
