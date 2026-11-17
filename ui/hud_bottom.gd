extends Control

## HUD Bawah (480x16 px) — FR-UI-02.
## Menampilkan 5 ikon Hati Dapur (12x12 px), slot ikon skill P1 Rangga dan P2 Sekar (16x16 px)
## dengan sapuan cooldown yang digambar kode, serta indikator Combo.

const HUD_W: float = 480.0
const HUD_H: float = 16.0

var current_health: int = 5
var max_health: int = 5
var combo_active: bool = false

# Cooldowns: { "cook_slot": { "remaining": float, "max": float } }
var skill_cooldowns: Dictionary = {
	"1_1": {"remaining": 0.0, "max": 6.0},
	"1_2": {"remaining": 0.0, "max": 15.0},
	"2_1": {"remaining": 0.0, "max": 8.0},
	"2_2": {"remaining": 0.0, "max": 20.0},
}

func _init() -> void:
	custom_minimum_size = Vector2(HUD_W, HUD_H)

func _ready() -> void:
	_connect_events()

func _connect_events() -> void:
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree and (loop as SceneTree).root:
		var events_node: Node = (loop as SceneTree).root.get_node_or_null("Events")
		if events_node != null:
			if events_node.has_signal("kitchen_health_changed"):
				events_node.connect("kitchen_health_changed", Callable(self, "_on_health_changed"))
			if events_node.has_signal("skill_activated"):
				events_node.connect("skill_activated", Callable(self, "_on_skill_activated"))
			if events_node.has_signal("combo_triggered"):
				events_node.connect("combo_triggered", Callable(self, "_on_combo_triggered"))

func _on_health_changed(hp: int, max_hp: int) -> void:
	set_hearts(hp, max_hp)

func _on_skill_activated(cook_id: int, skill_id: String) -> void:
	if skill_id == "dash":
		set_cooldown(cook_id, 1, 6.0, 6.0)

func _on_combo_triggered(_combo_id: String, _bonus: int) -> void:
	combo_active = true
	queue_redraw()

func set_hearts(hp: int, max_hp: int = 5) -> void:
	current_health = hp
	max_health = max_hp
	queue_redraw()

func set_cooldown(cook_id: int, slot: int, cd_remaining: float, cd_max: float) -> void:
	var key: String = "%d_%d" % [cook_id, slot]
	skill_cooldowns[key] = {"remaining": cd_remaining, "max": cd_max}
	queue_redraw()

func _process(delta: float) -> void:
	var needs_redraw: bool = false
	for key: String in skill_cooldowns.keys():
		var data: Dictionary = skill_cooldowns[key]
		if float(data["remaining"]) > 0.0:
			data["remaining"] = maxf(0.0, float(data["remaining"]) - delta)
			needs_redraw = true
	if needs_redraw:
		queue_redraw()

func _draw() -> void:
	var vp: Vector2 = _get_vp_size()
	# Latar belakang gelap
	draw_rect(Rect2(0, 0, vp.x, HUD_H), Color(0.1, 0.12, 0.15, 0.95))
	# Garis pembatas atas 1 px
	draw_line(Vector2(0, 0), Vector2(vp.x, 0), Color(0.2, 0.3, 0.25, 0.8), 1.0)

	# 1. 5 Ikon Hati Dapur (12x12 px) di kiri (FR-UI-02) — safe margin 8 px
	for i: int in range(max_health):
		var h_pos: Vector2 = Vector2(8.0 + float(i) * 14.0, 2.0)
		var is_full: bool = i < current_health
		var c: Color = Color(0.9, 0.2, 0.25) if is_full else Color(0.35, 0.35, 0.4)
		# Gambar hati sederhana 12x12
		draw_rect(Rect2(h_pos, Vector2(12.0, 12.0)), c)
		draw_rect(Rect2(h_pos, Vector2(12.0, 12.0)), Color.WHITE, false, 1.0)
		var char_h: String = "♥" if is_full else "♡"
		draw_string(ThemeDB.fallback_font, h_pos + Vector2(2.0, 9.0), char_h, HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color.WHITE)

	# 2. Ikon Skill P1 (Rangga) di posisi x = 185..236
	draw_string(ThemeDB.fallback_font, Vector2(185.0, 11.0), "P1:", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.3, 0.7, 1.0))
	_draw_skill_slot(Vector2(202.0, 1.0), "1_1", "Q", "DSH")
	_draw_skill_slot(Vector2(222.0, 1.0), "1_2", "R", "SPD")

	# 3. Ikon Skill P2 (Sekar) di posisi x = 273..324
	draw_string(ThemeDB.fallback_font, Vector2(273.0, 11.0), "P2:", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1.0, 0.6, 0.2))
	_draw_skill_slot(Vector2(290.0, 1.0), "2_1", ";", "TEL")
	_draw_skill_slot(Vector2(310.0, 1.0), "2_2", "'", "FIR")

	# 4. Indikator Combo di kanan (safe margin 8 px dari kanan)
	var combo_w: float = 80.0
	var combo_x: float = vp.x - 8.0 - combo_w
	var combo_color: Color = Color(1.0, 0.85, 0.2) if combo_active else Color(0.4, 0.4, 0.45)
	draw_rect(Rect2(combo_x, 2.0, combo_w, 12.0), Color(0.15, 0.18, 0.22, 0.9))
	draw_rect(Rect2(combo_x, 2.0, combo_w, 12.0), combo_color, false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(combo_x + 6.0, 11.0), "COMBO SIAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, combo_color)

func _get_vp_size() -> Vector2:
	if is_inside_tree() and get_viewport() != null:
		var s: Vector2 = get_viewport_rect().size
		if s.x > 0.0 and s.y > 0.0:
			return s
	return Vector2(HUD_W, HUD_H)

func _draw_skill_slot(pos: Vector2, key: String, shortcut_txt: String, name_txt: String) -> void:
	# Kotak slot 16x16 px
	draw_rect(Rect2(pos, Vector2(14.0, 14.0)), Color(0.2, 0.24, 0.28, 0.95))
	draw_rect(Rect2(pos, Vector2(14.0, 14.0)), Color(0.45, 0.55, 0.6), false, 1.0)
	
	# Nama skill singkat
	draw_string(ThemeDB.fallback_font, pos + Vector2(1.0, 9.0), name_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color.WHITE)
	draw_string(ThemeDB.fallback_font, pos + Vector2(1.0, 13.0), shortcut_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color(0.8, 0.8, 0.5))

	# Cooldown sweep (FR-UI-02: cooldown yang digambar kode)
	var cd_data: Dictionary = skill_cooldowns.get(key, {"remaining": 0.0, "max": 1.0})
	var rem: float = float(cd_data["remaining"])
	var mx: float = float(cd_data["max"])
	if rem > 0.0 and mx > 0.0:
		var pct: float = clampf(rem / mx, 0.0, 1.0)
		# Kotak gelap transparan sesuai sisa persentase cooldown (sapuan vertikal)
		draw_rect(Rect2(pos.x, pos.y, 14.0, 14.0 * pct), Color(0.0, 0.0, 0.0, 0.65))
