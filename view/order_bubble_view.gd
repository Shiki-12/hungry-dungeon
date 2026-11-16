class_name OrderBubbleView
extends Node2D

## Balon pesanan monster (FR-UI-03, FR-SEAT-09).
## Ikon hidangan 24x24 px + bar kesabaran 16x3 px (hijau/kuning/merah).
## Berjangkar di sisi kanan monster (meja panjang) atau di atas kepala (meja kecil).

const OFFSET_LONG_TABLE: Vector2 = Vector2(14.0, -4.0)
const OFFSET_SMALL_TABLE: Vector2 = Vector2(0.0, -18.0)

var is_long_table: bool = false
var recipe_id: StringName = &""
var patience_pct: float = 1.0 # 0.0 s.d. 1.0
var is_active: bool = false

func set_order(p_recipe_id: StringName, p_patience_pct: float, p_is_long_table: bool) -> void:
	recipe_id = p_recipe_id
	patience_pct = clampf(p_patience_pct, 0.0, 1.0)
	is_long_table = p_is_long_table
	is_active = (recipe_id != &"")
	queue_redraw()

func clear_order() -> void:
	recipe_id = &""
	is_active = false
	queue_redraw()

func get_bubble_offset() -> Vector2:
	return OFFSET_LONG_TABLE if is_long_table else OFFSET_SMALL_TABLE

func _draw() -> void:
	if not is_active:
		return

	var offset: Vector2 = get_bubble_offset()
	var box_sz: Vector2 = Vector2(24.0, 24.0)
	var box_pos: Vector2 = offset - Vector2(12.0, 12.0)

	# 1. Balon putih/terang dengan border gelap
	draw_rect(Rect2(box_pos, box_sz), Color(0.95, 0.95, 0.95, 0.95))
	draw_rect(Rect2(box_pos, box_sz), Color(0.15, 0.18, 0.2), false, 1.0)

	# 2. Ikon hidangan (placeholder teks pendek)
	var short_name: String = String(recipe_id).trim_prefix("recipe_").substr(0, 3).to_upper()
	draw_string(ThemeDB.fallback_font, box_pos + Vector2(2.0, 12.0), short_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 6, Color(0.1, 0.1, 0.1))

	# 3. Bar kesabaran 16x3 px di bawah ikon
	var bar_w: float = 16.0
	var bar_h: float = 3.0
	var bar_pos: Vector2 = box_pos + Vector2(4.0, 19.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.2, 0.2, 0.2, 0.8))

	var fill_color: Color = Color(0.2, 0.85, 0.3) # Hijau (>50%)
	if patience_pct <= 0.0:
		fill_color = Color(0.9, 0.2, 0.2) # Merah (0%)
	elif patience_pct <= 0.5:
		fill_color = Color(0.95, 0.75, 0.15) # Kuning (0..50%)

	draw_rect(Rect2(bar_pos, Vector2(bar_w * patience_pct, bar_h)), fill_color)
