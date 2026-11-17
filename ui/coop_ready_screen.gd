extends Control

## Layar Persiapan & Kesiapan 2 Pemain sebelum masuk dapur (FR-UI-06).
## P1 tekan E/Spasi untuk SIAP, P2 tekan ./Enter untuk SIAP.
## Kedua pemain SIAP -> hitung mundur singkat -> transisi ke kitchen_stage.

const VIEWPORT_W: int = 480
const VIEWPORT_H: int = 270

const COL_BG := Color(0.06, 0.05, 0.08, 1.0)
const COL_GOLD := Color(1.0, 0.82, 0.3, 1.0)
const COL_TEXT := Color(0.95, 0.95, 0.92, 1.0)
const COL_HINT := Color(0.6, 0.6, 0.55, 0.6)
const COL_RANGGA := Color(0.3, 0.5, 0.85, 1.0)
const COL_SEKAR := Color(0.95, 0.6, 0.2, 1.0)
const COL_READY := Color(0.3, 0.9, 0.4, 1.0)
const COL_NOT_READY := Color(0.5, 0.5, 0.5, 0.7)
const COL_CARD_BG := Color(0.12, 0.1, 0.07, 0.9)
const COL_CARD_BORDER := Color(0.55, 0.38, 0.18, 1.0)
const COL_COUNTDOWN := Color(1.0, 0.95, 0.5, 1.0)

var _p1_ready: bool = false
var _p2_ready: bool = false
var _p1_bounce: float = 0.0
var _p2_bounce: float = 0.0
var _time: float = 0.0
var _countdown_active: bool = false
var _countdown_timer: float = 0.0
var _countdown_text: String = ""
var _level_id: String = ""

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(VIEWPORT_W, VIEWPORT_H)
	custom_minimum_size = Vector2(VIEWPORT_W, VIEWPORT_H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	set_process_input(true)

	# Read level from Game autoload
	var game_node: Node = _get_autoload("Game")
	if game_node and "current_level_id" in game_node:
		_level_id = String(game_node.current_level_id)

func _process(delta: float) -> void:
	_time += delta
	_p1_bounce = maxf(0.0, _p1_bounce - delta * 3.0)
	_p2_bounce = maxf(0.0, _p2_bounce - delta * 3.0)

	if _countdown_active:
		_countdown_timer -= delta
		if _countdown_timer > 2.0:
			_countdown_text = "3.."
		elif _countdown_timer > 1.0:
			_countdown_text = "2.."
		elif _countdown_timer > 0.0:
			_countdown_text = "1.."
		else:
			_countdown_text = "BUKA LAPAK!"
			_go_to_kitchen()
			_countdown_active = false

	queue_redraw()

func _input(event: InputEvent) -> void:
	if _countdown_active:
		return

	if event is InputEventKey and event.pressed:
		var kc: int = (event as InputEventKey).keycode
		# Esc -> cancel ready or go back
		if kc == KEY_ESCAPE:
			if _p1_ready or _p2_ready:
				_p1_ready = false
				_p2_ready = false
			else:
				get_tree().change_scene_to_file("res://ui/world_map.tscn")
			get_viewport().set_input_as_handled()
			return

		# P1: E or Space
		if kc == KEY_E or kc == KEY_SPACE:
			_p1_ready = true
			_p1_bounce = 1.0
			_check_both_ready()
			get_viewport().set_input_as_handled()
			return

		# P2: Period or Enter
		if kc == KEY_PERIOD or kc == KEY_ENTER or kc == KEY_KP_ENTER:
			_p2_ready = true
			_p2_bounce = 1.0
			_check_both_ready()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton and event.pressed:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			# Click on P1 card
			if mb.position.x >= 30.0 and mb.position.x <= 220.0 and mb.position.y >= 90.0 and mb.position.y <= 220.0:
				_p1_ready = true
				_p1_bounce = 1.0
				_check_both_ready()
			# Click on P2 card
			elif mb.position.x >= 260.0 and mb.position.x <= 450.0 and mb.position.y >= 90.0 and mb.position.y <= 220.0:
				_p2_ready = true
				_p2_bounce = 1.0
				_check_both_ready()
			get_viewport().set_input_as_handled()

func _check_both_ready() -> void:
	if _p1_ready and _p2_ready and not _countdown_active:
		_countdown_active = true
		_countdown_timer = 3.0

func _go_to_kitchen() -> void:
	var game_node: Node = _get_autoload("Game")
	if game_node and "current_level_id" in game_node:
		game_node.set("current_level_id", _level_id)
	get_tree().change_scene_to_file("res://levels/kitchen_stage.tscn")

# ══════════════════════════════════════════════════════════════════════════════
# DRAWING
# ══════════════════════════════════════════════════════════════════════════════

func _draw() -> void:
	draw_rect(Rect2(0, 0, VIEWPORT_W, VIEWPORT_H), COL_BG)
	var font: Font = get_theme_default_font()

	# Level info header
	var display_id: String = _level_id.replace("_", "-") if not _level_id.is_empty() else "1-1"
	var chapter_num: String = display_id.substr(0, 1)
	draw_string(font, Vector2(16.0, 24.0), "CHAPTER %s — LEVEL %s" % [chapter_num, display_id.to_upper()], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COL_GOLD)
	draw_string(font, Vector2(16.0, 40.0), "Siapkan Kedua Koki Sebelum Memasuki Dapur!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_HINT)

	# Separator
	draw_rect(Rect2(16.0, 50.0, float(VIEWPORT_W) - 32.0, 1.0), COL_CARD_BORDER)

	# P1 Card (left)
	_draw_player_card(30.0, 65.0, "PEMAIN 1 — RANGGA", COL_RANGGA, "P1: WASD + E/F/Spasi/C", _p1_ready, _p1_bounce, "R")

	# P2 Card (right)
	_draw_player_card(260.0, 65.0, "PEMAIN 2 — SEKAR", COL_SEKAR, "P2: Panah + ./,//Shift", _p2_ready, _p2_bounce, "S")

	# VS / Ampersand
	draw_string(font, Vector2(230.0, 160.0), "&", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COL_GOLD)

	# Readiness instructions
	var inst_y: float = 230.0
	if not _countdown_active:
		draw_string(font, Vector2(60.0, inst_y), "P1: Tekan [E] atau [Spasi]", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_RANGGA if not _p1_ready else COL_READY)
		draw_string(font, Vector2(280.0, inst_y), "P2: Tekan [.] atau [Enter]", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_SEKAR if not _p2_ready else COL_READY)
	else:
		# Countdown display
		var cd_text: String = "DAPUR DIBUKA DALAM %s" % _countdown_text
		var cd_w: Vector2 = font.get_string_size(cd_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		draw_string(font, Vector2(float(VIEWPORT_W) / 2.0 - cd_w.x / 2.0, inst_y + 5.0), cd_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COL_COUNTDOWN)

	# Footer
	draw_rect(Rect2(0, VIEWPORT_H - 14, VIEWPORT_W, 14), Color(0.06, 0.06, 0.08, 0.9))
	draw_string(font, Vector2(4.0, float(VIEWPORT_H) - 4.0), "Esc: Batalkan / Kembali", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_HINT)

func _draw_player_card(cx: float, cy: float, title: String, col: Color, controls: String, ready: bool, bounce: float, letter: String) -> void:
	var font: Font = get_theme_default_font()
	var card_w: float = 190.0
	var card_h: float = 155.0
	var bounce_offset: float = -bounce * 4.0

	# Card BG
	draw_rect(Rect2(cx, cy + bounce_offset, card_w, card_h), COL_CARD_BG)
	var border: Color = COL_READY if ready else COL_CARD_BORDER
	draw_rect(Rect2(cx, cy + bounce_offset, card_w, 1.0), border)
	draw_rect(Rect2(cx, cy + bounce_offset + card_h - 1.0, card_w, 1.0), border)
	draw_rect(Rect2(cx, cy + bounce_offset, 1.0, card_h), border)
	draw_rect(Rect2(cx + card_w - 1.0, cy + bounce_offset, 1.0, card_h), border)

	# Title
	draw_string(font, Vector2(cx + 8.0, cy + bounce_offset + 14.0), title, HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 16.0), 8, col)

	# Character box (placeholder idle bobbing)
	var char_cx: float = cx + card_w / 2.0
	var char_cy: float = cy + bounce_offset + 65.0 + sin(_time * 2.5) * 2.0
	draw_rect(Rect2(char_cx - 16.0, char_cy - 20.0, 32.0, 32.0), col)
	draw_circle(Vector2(char_cx, char_cy - 24.0), 8.0, col.lightened(0.2))
	draw_string(font, Vector2(char_cx - 4.0, char_cy - 5.0), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)

	# Controls
	draw_string(font, Vector2(cx + 8.0, cy + bounce_offset + 110.0), controls, HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 16.0), 8, COL_HINT)

	# Ready status
	var status: String = "SIAP!" if ready else "BELUM SIAP"
	var status_col: Color = COL_READY if ready else COL_NOT_READY
	var status_w: Vector2 = font.get_string_size(status, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	draw_string(font, Vector2(cx + (card_w - status_w.x) / 2.0, cy + bounce_offset + card_h - 16.0), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, status_col)

	# Glow border if ready
	if ready:
		var glow_alpha: float = 0.15 + 0.1 * sin(_time * 4.0)
		draw_rect(Rect2(cx - 1.0, cy + bounce_offset - 1.0, card_w + 2.0, card_h + 2.0), Color(COL_READY.r, COL_READY.g, COL_READY.b, glow_alpha))

func _get_autoload(autoload_name: String) -> Node:
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree and (loop as SceneTree).root:
		return (loop as SceneTree).root.get_node_or_null(autoload_name)
	return null

## Test-only helpers
func is_p1_ready() -> bool:
	return _p1_ready

func is_p2_ready() -> bool:
	return _p2_ready

func set_p1_ready(val: bool) -> void:
	_p1_ready = val

func set_p2_ready(val: bool) -> void:
	_p2_ready = val

func is_countdown_active() -> bool:
	return _countdown_active

func get_level_id() -> String:
	return _level_id

func set_level_id(val: String) -> void:
	_level_id = val
