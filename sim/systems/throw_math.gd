class_name ThrowMath
extends RefCounted

# sim/systems/throw_math.gd
# Rumus lempar bersama: Klien (pratinjau) dan Simulasi/Server (hasil)

const TILE: float = 16.0
const MIN_R: float = 2.0
const MAX_R: float = 8.0
const RAMP_TIME: float = 1.2 # detik dari 2 ke 8 tile

static func range_at(hold_time: float) -> float:
	var phase: float = fposmod(hold_time / RAMP_TIME, 2.0)
	var t: float = phase if phase <= 1.0 else 2.0 - phase # gelombang segitiga 0..1
	return lerpf(MIN_R, MAX_R, t)

static func flight_time(r_tiles: float) -> float:
	return 0.4 + (r_tiles - MIN_R) / (MAX_R - MIN_R) * 0.5

static func landing_point(origin: Vector2, dir: Vector2, r_tiles: float, wind: Vector2 = Vector2.ZERO) -> Vector2:
	return origin + dir.normalized() * (r_tiles * TILE) + wind

static func arc_height(r_tiles: float) -> float:
	return r_tiles * 4.0

static func parabola_y(peak_height: float, s: float) -> float:
	# s adalah waktu terbang ternormalisasi 0..1
	return 4.0 * peak_height * s * (1.0 - s)
