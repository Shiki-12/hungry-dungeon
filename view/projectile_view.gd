class_name ProjectileView
extends Node2D

## Tampilan proyektil terbang dan label hasil lemparan (FR-THR-15).

const AssetsScript: Script = preload("res://autoload/assets.gd")

var projectiles: Array = [] # Referensi ke SimProjectile
var floating_labels: Array = [] # Array of { text: String, pos: Vector2, color: Color, life: float, max_life: float }

func update_projectiles(active_list: Array) -> void:
	projectiles = active_list
	queue_redraw()

func add_floating_label(text: String, pos: Vector2, color: Color) -> void:
	floating_labels.append({
		"text": text,
		"pos": pos,
		"color": color,
		"life": 0.0,
		"max_life": 0.8
	})

func _process(delta: float) -> void:
	if not floating_labels.is_empty():
		var remaining: Array = []
		for lbl: Dictionary in floating_labels:
			lbl["life"] = float(lbl["life"]) + delta
			lbl["pos"] = Vector2(lbl["pos"]) - Vector2(0.0, 15.0 * delta)
			if float(lbl["life"]) < float(lbl["max_life"]):
				remaining.append(lbl)
		floating_labels = remaining
		queue_redraw()

func _draw() -> void:
	# 1. Gambar proyektil yang sedang terbang
	for proj: RefCounted in projectiles:
		if proj == null or proj.is_finished:
			continue
		var g_pos: Vector2 = proj.current_position
		var h: float = proj.current_height
		var fly_pos: Vector2 = g_pos - Vector2(0.0, h)
		
		# Bayangan tanah
		var shadow_radius: float = maxf(2.0, 5.0 - h * 0.1)
		draw_circle(g_pos, shadow_radius, Color(0.0, 0.0, 0.0, 0.4))
		
		# Item box placeholder / texture
		var item_color: Color = Color(0.95, 0.65, 0.2)
		if proj.is_dish:
			item_color = Color(0.9, 0.4, 0.1)
		draw_rect(Rect2(fly_pos - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), item_color)
		draw_rect(Rect2(fly_pos - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), Color.WHITE, false, 1.0)

	# 2. Gambar label melayang
	for lbl: Dictionary in floating_labels:
		var alpha: float = 1.0 - (float(lbl["life"]) / float(lbl["max_life"]))
		var c: Color = Color(lbl["color"].r, lbl["color"].g, lbl["color"].b, alpha)
		var p: Vector2 = lbl["pos"]
		draw_string(ThemeDB.fallback_font, p + Vector2(-15.0, 0.0), String(lbl["text"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 7, c)
