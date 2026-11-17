extends Control

## Peta Pemilihan Chapter & Level — Penampang Dungeon Nusantara 5 Chapter (§16, FR-UI-06).
## Navigasi: W/S/Panah, Enter/Klik untuk pilih, Esc untuk kembali ke Main Menu.

const VIEWPORT_W: int = 480
const VIEWPORT_H: int = 270

const CHAPTERS: Array = [
	{"name": "Chapter 1: Gua Jamur", "id": 1, "levels": ["1-1", "1-2", "1-3", "1-4"], "color": Color(0.2, 0.75, 0.65), "unlock_after": "", "monster": "Goblin"},
	{"name": "Chapter 2: Rawa Terendam", "id": 2, "levels": ["2-1", "2-2", "2-3", "2-4"], "color": Color(0.3, 0.55, 0.75), "unlock_after": "1-4", "monster": "Manusia Kadal"},
	{"name": "Chapter 3: Tambang Magma", "id": 3, "levels": ["3-1", "3-2", "3-3", "3-4"], "color": Color(0.85, 0.4, 0.15), "unlock_after": "2-4", "monster": "Ogre Api"},
	{"name": "Chapter 4: Kripta Beku", "id": 4, "levels": ["4-1", "4-2", "4-3", "4-4"], "color": Color(0.5, 0.7, 0.9), "unlock_after": "3-4", "monster": "Hantu"},
	{"name": "Chapter 5: Sarang Naga", "id": 5, "levels": ["5-1", "5-2", "5-3"], "color": Color(0.85, 0.25, 0.2), "unlock_after": "4-4", "monster": "Sang Ageng"},
]

const LEVEL_NAMES: Dictionary = {
	"1-1": "Bekal Terakhir", "1-2": "Cuci & Sajikan", "1-3": "Awas Pencuri!", "1-4": "Pesta Goblin",
	"2-1": "Rawa Awal", "2-2": "Kolam Lumpur", "2-3": "Jembatan Runtuh", "2-4": "Sarang Kadal",
	"3-1": "Lorong Panas", "3-2": "Dapur Lava", "3-3": "Gerbang Ogre", "3-4": "Kawah Api",
	"4-1": "Ruang Dingin", "4-2": "Koridor Beku", "4-3": "Aula Hantu", "4-4": "Singgasana Es",
	"5-1": "Gerbang Naga", "5-2": "Labirin Sang Ageng", "5-3": "Perjamuan Terakhir",
}

const COL_BG := Color(0.08, 0.06, 0.12, 1.0)
const COL_GOLD := Color(1.0, 0.82, 0.3, 1.0)
const COL_TEXT := Color(0.95, 0.95, 0.92, 1.0)
const COL_HINT := Color(0.6, 0.6, 0.55, 0.6)
const COL_LOCKED := Color(0.35, 0.35, 0.35, 0.6)
const COL_LOCKED_BG := Color(0.12, 0.12, 0.12, 0.7)
const COL_CARD_BORDER := Color(0.55, 0.38, 0.18, 1.0)
const COL_CARD_SEL := Color(0.85, 0.65, 0.3, 1.0)
const COL_STAR := Color(1.0, 0.85, 0.2, 1.0)
const COL_STAR_EMPTY := Color(0.4, 0.4, 0.4, 0.5)
const COL_PADLOCK := Color(0.5, 0.5, 0.5, 0.8)
const COL_HEADER_BG := Color(0.06, 0.06, 0.08, 0.9)

enum ViewMode { CHAPTER_SELECT, LEVEL_SELECT }

var _mode: int = ViewMode.CHAPTER_SELECT
var _selected_chapter: int = 0
var _selected_level: int = 0
var _time: float = 0.0
var _shake_timer: float = 0.0
var _shake_target: int = -1

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(VIEWPORT_W, VIEWPORT_H)
	custom_minimum_size = Vector2(VIEWPORT_W, VIEWPORT_H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	set_process_input(true)

func _process(delta: float) -> void:
	_time += delta
	if _shake_timer > 0.0:
		_shake_timer -= delta
		if _shake_timer <= 0.0:
			_shake_target = -1
	queue_redraw()

func _mark_input_handled() -> void:
	if is_inside_tree() and get_viewport() != null:
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var kc: int = (event as InputEventKey).keycode
		_mark_input_handled()
		if _mode == ViewMode.CHAPTER_SELECT:
			_handle_chapter_input(kc)
		else:
			_handle_level_input(kc)

	elif event is InputEventMouseButton and event.pressed:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_mark_input_handled()
			if _mode == ViewMode.CHAPTER_SELECT:
				var idx: int = _get_chapter_at(mb.position)
				if idx >= 0:
					_selected_chapter = idx
					_try_enter_chapter()
			else:
				var idx: int = _get_level_at(mb.position)
				if idx >= 0:
					_selected_level = idx
					_try_select_level()
				# Check back button
				if mb.position.x >= 10.0 and mb.position.x <= 110.0 and mb.position.y >= float(VIEWPORT_H) - 24.0 and mb.position.y <= float(VIEWPORT_H) - 6.0:
					_mode = ViewMode.CHAPTER_SELECT

	elif event is InputEventMouseMotion:
		if _mode == ViewMode.CHAPTER_SELECT:
			var idx: int = _get_chapter_at((event as InputEventMouseMotion).position)
			if idx >= 0:
				_selected_chapter = idx
		else:
			var idx: int = _get_level_at((event as InputEventMouseMotion).position)
			if idx >= 0:
				_selected_level = idx

func _handle_chapter_input(kc: int) -> void:
	match kc:
		KEY_W, KEY_UP:
			_selected_chapter = (_selected_chapter - 1 + CHAPTERS.size()) % CHAPTERS.size()
		KEY_S, KEY_DOWN:
			_selected_chapter = (_selected_chapter + 1) % CHAPTERS.size()
		KEY_ENTER, KEY_KP_ENTER:
			_try_enter_chapter()
		KEY_ESCAPE:
			if is_inside_tree() and get_tree():
				get_tree().change_scene_to_file.call_deferred("res://ui/main_menu.tscn")

func _handle_level_input(kc: int) -> void:
	var chapter: Dictionary = CHAPTERS[_selected_chapter] as Dictionary
	var levels: Array = chapter["levels"] as Array
	match kc:
		KEY_W, KEY_UP:
			_selected_level = (_selected_level - 1 + levels.size()) % levels.size()
		KEY_S, KEY_DOWN:
			_selected_level = (_selected_level + 1) % levels.size()
		KEY_ENTER, KEY_KP_ENTER:
			_try_select_level()
		KEY_ESCAPE:
			_mode = ViewMode.CHAPTER_SELECT

func _try_enter_chapter() -> void:
	if not _is_chapter_unlocked(_selected_chapter):
		_shake_timer = 0.3
		_shake_target = _selected_chapter
		return
	_mode = ViewMode.LEVEL_SELECT
	_selected_level = 0

func _try_select_level() -> void:
	var chapter: Dictionary = CHAPTERS[_selected_chapter] as Dictionary
	var levels: Array = chapter["levels"] as Array
	if _selected_level < 0 or _selected_level >= levels.size():
		return
	var level_id: String = levels[_selected_level] as String
	if not _is_level_unlocked(level_id, _selected_level):
		_shake_timer = 0.3
		_shake_target = 100 + _selected_level
		return
	# Set level and go to coop ready
	var game_node: Node = _get_autoload("Game")
	if game_node:
		game_node.set("current_level_id", level_id.replace("-", "_"))
	if is_inside_tree() and get_tree():
		get_tree().change_scene_to_file.call_deferred("res://ui/coop_ready_screen.tscn")

func _is_chapter_unlocked(chapter_idx: int) -> bool:
	if chapter_idx == 0:
		return true
	var chapter: Dictionary = CHAPTERS[chapter_idx] as Dictionary
	var unlock_after: String = chapter["unlock_after"] as String
	if unlock_after.is_empty():
		return true
	return _has_completed_level(unlock_after)

func _is_level_unlocked(_level_id: String, level_idx: int) -> bool:
	if level_idx == 0:
		return true
	var chapter: Dictionary = CHAPTERS[_selected_chapter] as Dictionary
	var levels: Array = chapter["levels"] as Array
	if level_idx > 0:
		var prev_level: String = levels[level_idx - 1] as String
		return _has_completed_level(prev_level)
	return true

func _has_completed_level(level_id: String) -> bool:
	var save_node: Node = _get_autoload("Save")
	if save_node and "save_data" in save_node:
		var sd: Dictionary = save_node.save_data as Dictionary
		var scores: Dictionary = sd.get("scores", {}) as Dictionary
		# Check both formats: "1-1" and "1_1"
		if scores.has(level_id):
			return true
		var alt: String = level_id.replace("-", "_")
		if scores.has(alt):
			return true
	return false

func _get_level_stars(level_id: String) -> int:
	var save_node: Node = _get_autoload("Save")
	if save_node and "save_data" in save_node:
		var sd: Dictionary = save_node.save_data as Dictionary
		var scores: Dictionary = sd.get("scores", {}) as Dictionary
		var entry: Dictionary = scores.get(level_id, scores.get(level_id.replace("-", "_"), {})) as Dictionary
		return entry.get("stars", 0) as int
	return 0

func _get_chapter_at(pos: Vector2) -> int:
	var card_w: float = 440.0
	var card_x: float = 20.0
	var card_start_y: float = 32.0
	for i: int in range(CHAPTERS.size()):
		var cy: float = card_start_y + float(i) * 42.0
		if pos.x >= card_x and pos.x <= card_x + card_w and pos.y >= cy and pos.y <= cy + 38.0:
			return i
	return -1

func _get_level_at(pos: Vector2) -> int:
	var chapter: Dictionary = CHAPTERS[_selected_chapter] as Dictionary
	var levels: Array = chapter["levels"] as Array
	var card_x: float = 60.0
	var card_w: float = 360.0
	var start_y: float = 80.0
	for i: int in range(levels.size()):
		var ly: float = start_y + float(i) * 36.0
		if pos.x >= card_x and pos.x <= card_x + card_w and pos.y >= ly and pos.y <= ly + 30.0:
			return i
	return -1

# ══════════════════════════════════════════════════════════════════════════════
# DRAWING
# ══════════════════════════════════════════════════════════════════════════════

func _draw() -> void:
	draw_rect(Rect2(0, 0, VIEWPORT_W, VIEWPORT_H), COL_BG)
	var font: Font = get_theme_default_font()

	# Header
	draw_rect(Rect2(0, 0, VIEWPORT_W, 24), COL_HEADER_BG)
	draw_string(font, Vector2(8.0, 16.0), "PILIH CHAPTER & LEVEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COL_GOLD)

	# Rare ingredient slots (placeholder)
	for i: int in range(4):
		var rx: float = float(VIEWPORT_W) - 100.0 + float(i) * 22.0
		draw_rect(Rect2(rx, 4.0, 16.0, 16.0), Color(0.15, 0.15, 0.18, 0.8))
		draw_rect(Rect2(rx, 4.0, 16.0, 1.0), COL_CARD_BORDER)
		draw_rect(Rect2(rx, 19.0, 16.0, 1.0), COL_CARD_BORDER)
		draw_string(font, Vector2(rx + 4.0, 16.0), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_LOCKED)

	if _mode == ViewMode.CHAPTER_SELECT:
		_draw_chapter_select(font)
	else:
		_draw_level_select(font)

func _draw_chapter_select(font: Font) -> void:
	var card_w: float = 440.0
	var card_x: float = 20.0
	var card_start_y: float = 32.0

	for i: int in range(CHAPTERS.size()):
		var ch: Dictionary = CHAPTERS[i] as Dictionary
		var cy: float = card_start_y + float(i) * 42.0
		var unlocked: bool = _is_chapter_unlocked(i)
		var is_sel: bool = (i == _selected_chapter)
		var ch_col: Color = ch["color"] as Color

		# Shake offset
		var shake_x: float = 0.0
		if _shake_target == i and _shake_timer > 0.0:
			shake_x = sin(_shake_timer * 40.0) * 4.0

		# Card BG
		var bg_col: Color = COL_LOCKED_BG if not unlocked else Color(ch_col.r * 0.15, ch_col.g * 0.15, ch_col.b * 0.15, 0.85)
		draw_rect(Rect2(card_x + shake_x, cy, card_w, 38.0), bg_col)
		# Border
		var border: Color = COL_CARD_SEL if is_sel else (COL_LOCKED if not unlocked else COL_CARD_BORDER)
		draw_rect(Rect2(card_x + shake_x, cy, card_w, 1.0), border)
		draw_rect(Rect2(card_x + shake_x, cy + 37.0, card_w, 1.0), border)
		draw_rect(Rect2(card_x + shake_x, cy, 1.0, 38.0), border)
		draw_rect(Rect2(card_x + shake_x + card_w - 1.0, cy, 1.0, 38.0), border)

		# Color stripe
		if unlocked:
			draw_rect(Rect2(card_x + shake_x + 2.0, cy + 2.0, 4.0, 34.0), ch_col)

		# Selection cursor
		if is_sel and unlocked:
			draw_circle(Vector2(card_x + shake_x - 6.0, cy + 19.0), 2.0, COL_GOLD)

		# Chapter name
		var text_col: Color = COL_TEXT if unlocked else COL_LOCKED
		draw_string(font, Vector2(card_x + shake_x + 12.0, cy + 14.0), ch["name"] as String, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, text_col)
		# Monster type
		draw_string(font, Vector2(card_x + shake_x + 12.0, cy + 26.0), "Pelanggan: " + (ch["monster"] as String), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_HINT if unlocked else COL_LOCKED)

		# Stars total
		var total_stars: int = 0
		var max_stars: int = (ch["levels"] as Array).size() * 3
		for lvl: String in ch["levels"] as Array:
			total_stars += _get_level_stars(lvl)
		var star_text: String = "%d/%d" % [total_stars, max_stars]
		draw_string(font, Vector2(card_x + shake_x + card_w - 60.0, cy + 14.0), star_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_STAR if unlocked else COL_LOCKED)

		# Padlock icon for locked chapters
		if not unlocked:
			_draw_padlock(card_x + shake_x + card_w - 24.0, cy + 10.0)
			draw_string(font, Vector2(card_x + shake_x + 200.0, cy + 32.0), "Selesaikan Chapter sebelumnya", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_LOCKED)

	# Gerobak icon on selected chapter (if unlocked)
	if _is_chapter_unlocked(_selected_chapter):
		var sel_y: float = card_start_y + float(_selected_chapter) * 42.0
		draw_rect(Rect2(card_x + card_w - 40.0, sel_y + 20.0, 16.0, 10.0), COL_GOLD.darkened(0.3))
		draw_string(font, Vector2(card_x + card_w - 38.0, sel_y + 28.0), "GRB", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, COL_GOLD)

	# Footer
	_draw_map_footer(font)

func _draw_level_select(font: Font) -> void:
	var chapter: Dictionary = CHAPTERS[_selected_chapter] as Dictionary
	var ch_col: Color = chapter["color"] as Color
	var levels: Array = chapter["levels"] as Array

	# Chapter header
	draw_rect(Rect2(0, 24, VIEWPORT_W, 44), Color(ch_col.r * 0.12, ch_col.g * 0.12, ch_col.b * 0.12, 0.9))
	draw_string(font, Vector2(16.0, 42.0), chapter["name"] as String, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ch_col)
	draw_string(font, Vector2(16.0, 58.0), "Pelanggan: " + (chapter["monster"] as String), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_HINT)

	# Level cards
	var card_x: float = 60.0
	var card_w: float = 360.0
	var start_y: float = 80.0
	for i: int in range(levels.size()):
		var level_id: String = levels[i] as String
		var ly: float = start_y + float(i) * 36.0
		var unlocked: bool = _is_level_unlocked(level_id, i)
		var is_sel: bool = (i == _selected_level)

		# Shake
		var shake_x: float = 0.0
		if _shake_target == 100 + i and _shake_timer > 0.0:
			shake_x = sin(_shake_timer * 40.0) * 4.0

		var bg: Color = COL_LOCKED_BG if not unlocked else Color(ch_col.r * 0.1, ch_col.g * 0.1, ch_col.b * 0.1, 0.85)
		draw_rect(Rect2(card_x + shake_x, ly, card_w, 30.0), bg)
		var border: Color = COL_CARD_SEL if is_sel else (COL_LOCKED if not unlocked else COL_CARD_BORDER)
		draw_rect(Rect2(card_x + shake_x, ly, card_w, 1.0), border)
		draw_rect(Rect2(card_x + shake_x, ly + 29.0, card_w, 1.0), border)
		draw_rect(Rect2(card_x + shake_x, ly, 1.0, 30.0), border)
		draw_rect(Rect2(card_x + shake_x + card_w - 1.0, ly, 1.0, 30.0), border)

		if is_sel and unlocked:
			draw_circle(Vector2(card_x + shake_x - 6.0, ly + 15.0), 2.0, COL_GOLD)

		var text_col2: Color = COL_TEXT if unlocked else COL_LOCKED
		var level_name: String = LEVEL_NAMES.get(level_id, level_id) as String
		draw_string(font, Vector2(card_x + shake_x + 10.0, ly + 14.0), "Level %s: %s" % [level_id, level_name], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, text_col2)

		# Stars
		var stars: int = _get_level_stars(level_id)
		for s: int in range(3):
			var sx: float = card_x + shake_x + card_w - 50.0 + float(s) * 14.0
			var s_col: Color = COL_STAR if s < stars else COL_STAR_EMPTY
			draw_string(font, Vector2(sx, ly + 20.0), "*", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, s_col)

		if not unlocked:
			_draw_padlock(card_x + shake_x + card_w - 20.0, ly + 8.0)

	# Back button
	var back_y: float = float(VIEWPORT_H) - 24.0
	draw_rect(Rect2(10.0, back_y, 100.0, 18.0), Color(0.14, 0.1, 0.07, 0.95))
	draw_rect(Rect2(10.0, back_y, 100.0, 1.0), COL_CARD_BORDER)
	draw_rect(Rect2(10.0, back_y + 17.0, 100.0, 1.0), COL_CARD_BORDER)
	draw_string(font, Vector2(18.0, back_y + 12.0), "< KEMBALI [Esc]", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_GOLD)

	_draw_map_footer(font)

func _draw_padlock(px: float, py: float) -> void:
	# Padlock body
	draw_rect(Rect2(px, py + 4.0, 12.0, 10.0), COL_PADLOCK)
	# Shackle arc
	draw_rect(Rect2(px + 2.0, py, 8.0, 2.0), COL_PADLOCK)
	draw_rect(Rect2(px + 2.0, py, 2.0, 6.0), COL_PADLOCK)
	draw_rect(Rect2(px + 8.0, py, 2.0, 6.0), COL_PADLOCK)
	# Keyhole
	draw_circle(Vector2(px + 6.0, py + 9.0), 1.5, Color(0.2, 0.2, 0.2, 1.0))

func _draw_map_footer(font: Font) -> void:
	var fy: float = float(VIEWPORT_H) - 14.0
	draw_rect(Rect2(0, fy, VIEWPORT_W, 14), COL_HEADER_BG)
	draw_string(font, Vector2(4.0, fy + 10.0), "v0.2.0-m2 (Wajib 2 Pemain Co-op)", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.5, 0.65, 0.55, 0.8))
	draw_string(font, Vector2(280.0, fy + 10.0), "W/S: Navigasi  |  Enter/Klik: Pilih  |  Esc: Kembali", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_HINT)

func _get_autoload(autoload_name: String) -> Node:
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree and (loop as SceneTree).root:
		return (loop as SceneTree).root.get_node_or_null(autoload_name)
	return null

## Test-only helpers
func get_mode() -> int:
	return _mode

func get_selected_chapter() -> int:
	return _selected_chapter

func is_chapter_unlocked(idx: int) -> bool:
	return _is_chapter_unlocked(idx)
