class_name ThrowPreviewView
extends Node2D

## Pratinjau bidik busur putus-putus dan penanda titik jatuh (FR-THR-03, FR-THR-15).
## Menggunakan bentuk berbeda untuk aksesibilitas buta warna (NFR-ACC-02):
## - Lingkaran penuh: Jitu
## - Setengah lingkaran: Tersaji
## - Silang (X): Meleset / Meja Salah

const ThrowMathScript: Script = preload("res://sim/systems/throw_math.gd")

var is_active: bool = false
var origin: Vector2 = Vector2.ZERO
var landing: Vector2 = Vector2.ZERO
var r_tiles: float = 4.0
var marker_type: StringName = &"MISSED" # JITU, TERSAJI, MISSED

func update_preview(
	p_active: bool,
	p_origin: Vector2,
	p_landing: Vector2,
	p_r_tiles: float,
	p_marker_type: StringName
) -> void:
	is_active = p_active
	origin = p_origin
	landing = p_landing
	r_tiles = p_r_tiles
	marker_type = p_marker_type
	queue_redraw()

func _draw() -> void:
	if not is_active:
		return
	
	var peak_h: float = ThrowMathScript.arc_height(r_tiles)
	var steps: int = 16
	var prev_pt: Vector2 = origin
	var color: Color = Color(1.0, 1.0, 1.0, 0.7)
	
	match marker_type:
		&"JITU":
			color = Color(0.2, 0.9, 0.3, 0.9) # Hijau
		&"TERSAJI":
			color = Color(1.0, 0.85, 0.2, 0.9) # Kuning
		_:
			color = Color(0.9, 0.3, 0.3, 0.8) # Merah

	# Gambar garis busur putus-putus
	for i: int in range(1, steps + 1):
		var s: float = float(i) / float(steps)
		var ground_pt: Vector2 = origin.lerp(landing, s)
		var h: float = ThrowMathScript.parabola_y(peak_h, s)
		var arc_pt: Vector2 = ground_pt - Vector2(0.0, h)
		
		# Gambar segmen genap saja (putus-putus)
		if i % 2 == 1:
			draw_line(prev_pt, arc_pt, color, 1.0)
		prev_pt = arc_pt
		
	# Bayangan di titik jatuh
	draw_circle(landing, 4.0, Color(0.0, 0.0, 0.0, 0.35))
	
	# FR-UI-04: Indikator bidik - bar jarak kecil dekat koki saat throw ditahan
	var bar_w: float = 16.0
	var bar_h: float = 3.0
	var bar_pos: Vector2 = origin + Vector2(-8.0, -20.0)
	var r_pct: float = clampf((r_tiles - ThrowMathScript.MIN_R) / (ThrowMathScript.MAX_R - ThrowMathScript.MIN_R), 0.0, 1.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.1, 0.12, 0.15, 0.85))
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color.WHITE, false, 1.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_w * r_pct, bar_h)), color)

	# Penanda titik jatuh berdasarkan bentuk (NFR-ACC-02)
	match marker_type:
		&"JITU":
			# Lingkaran penuh
			draw_circle(landing, 5.0, color)
			draw_arc(landing, 6.0, 0, TAU, 16, Color.WHITE, 1.0)
		&"TERSAJI":
			# Setengah lingkaran (busur 0 s.d. PI)
			draw_arc(landing, 5.0, 0, PI, 12, color, 2.0)
			draw_line(landing - Vector2(5.0, 0.0), landing + Vector2(5.0, 0.0), color, 1.5)
		_:
			# Silang (X)
			var sz: float = 4.0
			draw_line(landing - Vector2(sz, sz), landing + Vector2(sz, sz), color, 1.5)
			draw_line(landing - Vector2(sz, -sz), landing + Vector2(sz, -sz), color, 1.5)
