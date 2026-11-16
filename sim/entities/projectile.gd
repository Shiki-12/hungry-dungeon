class_name SimProjectile
extends RefCounted

## Proyektil terbang simulasi deterministik (FR-THR-01 s.d. FR-THR-16).
## Tidak memuat visual/node rendering.

const ThrowMathScript: Script = preload("res://sim/systems/throw_math.gd")

var cook_id: int = 1
var item_id: StringName = &""
var is_dish: bool = false
var recipe_id: StringName = &""
var origin: Vector2 = Vector2.ZERO
var target: Vector2 = Vector2.ZERO
var raw_target: Vector2 = Vector2.ZERO
var r_tiles: float = 4.0
var flight_time: float = 0.5
var elapsed_time: float = 0.0
var peak_height: float = 16.0
var current_position: Vector2 = Vector2.ZERO
var current_height: float = 0.0
var is_finished: bool = false
var was_assisted: bool = false
var evaluation: Dictionary = {}

func _init(
	p_cook_id: int,
	p_item_id: StringName,
	p_origin: Vector2,
	p_target: Vector2,
	p_raw_target: Vector2,
	p_r_tiles: float,
	p_is_dish: bool = false,
	p_recipe_id: StringName = &"",
	p_assisted: bool = false
) -> void:
	cook_id = p_cook_id
	item_id = p_item_id
	origin = p_origin
	target = p_target
	raw_target = p_raw_target
	r_tiles = p_r_tiles
	is_dish = p_is_dish
	recipe_id = p_recipe_id
	was_assisted = p_assisted
	flight_time = ThrowMathScript.flight_time(r_tiles)
	peak_height = ThrowMathScript.arc_height(r_tiles)
	current_position = origin
	current_height = 0.0
	elapsed_time = 0.0
	is_finished = false

func tick(delta: float) -> bool:
	if is_finished:
		return true
	elapsed_time = minf(flight_time, elapsed_time + delta)
	var s: float = 0.0
	if flight_time > 0.0:
		s = clampf(elapsed_time / flight_time, 0.0, 1.0)
	current_position = origin.lerp(target, s)
	current_height = ThrowMathScript.parabola_y(peak_height, s)
	if elapsed_time >= flight_time:
		is_finished = true
		current_position = target
		current_height = 0.0
		return true
	return false
