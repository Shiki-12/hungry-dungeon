extends Control

## Menu Jeda Hungry Dungeon — terpusat di 480x270 px (FR-UI-06).
## Navigasi: W/S/Panah untuk pindah, Enter/Klik untuk pilih, Esc untuk lanjutkan.

const VIEWPORT_W: int = 480
const VIEWPORT_H: int = 270
const PANEL_W: float = 200.0
const PANEL_H: float = 160.0
const BTN_W: float = 160.0
const BTN_H: float = 18.0
const BTN_SPACING: float = 4.0

const COL_OVERLAY := Color(0, 0, 0, 0.65)
const COL_PANEL_BG := Color(0.14, 0.1, 0.07, 0.95)
const COL_PANEL_BORDER := Color(0.55, 0.38, 0.18, 1.0)
const COL_BTN_BG := Color(0.18, 0.12, 0.08, 0.92)
const COL_BTN_SEL := Color(0.28, 0.2, 0.12, 0.95)
const COL_BTN_BORDER := Color(0.55, 0.38, 0.18, 1.0)
const COL_BTN_SEL_BORDER := Color(0.85, 0.65, 0.3, 1.0)
const COL_TEXT := Color(0.95, 0.95, 0.92, 1.0)
const COL_GOLD := Color(1.0, 0.82, 0.3, 1.0)

const BUTTONS: Array = [
	{"label": "Lanjutkan", "id": "resume"},
	{"label": "Ulang Level", "id": "restart"},
	{"label": "Pengaturan", "id": "settings"},
	{"label": "Pilih Chapter", "id": "chapter"},
	{"label": "Menu Utama", "id": "main_menu"},
]

var _selected: int = 0

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(VIEWPORT_W, VIEWPORT_H)
	custom_minimum_size = Vector2(VIEWPORT_W, VIEWPORT_H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	set_process_input(true)

func _mark_input_handled() -> void:
	if is_inside_tree() and get_viewport() != null:
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	# Esc -> resume
	if event is InputEventKey and event.pressed:
		var kc: int = (event as InputEventKey).keycode
		if kc == KEY_ESCAPE:
			_mark_input_handled()
			_do_resume()
			return
		if kc == KEY_ENTER or kc == KEY_KP_ENTER:
			_mark_input_handled()
			_activate(_selected)
			return
		if kc == KEY_W or kc == KEY_UP:
			_mark_input_handled()
			_selected = (_selected - 1 + BUTTONS.size()) % BUTTONS.size()
			queue_redraw()
			return
		if kc == KEY_S or kc == KEY_DOWN:
			_mark_input_handled()
			_selected = (_selected + 1) % BUTTONS.size()
			queue_redraw()
			return

	if event is InputEventMouseButton and event.pressed:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var idx: int = _get_button_at(mb.position)
			if idx >= 0:
				_mark_input_handled()
				_activate(idx)

	if event is InputEventMouseMotion:
		var idx: int = _get_button_at((event as InputEventMouseMotion).position)
		if idx >= 0 and idx != _selected:
			_selected = idx
			queue_redraw()

func _get_button_at(pos: Vector2) -> int:
	var vp: Vector2 = _get_vp_size()
	var panel_x: float = (vp.x - PANEL_W) * 0.5
	var panel_y: float = (vp.y - PANEL_H) * 0.5
	var btn_x: float = panel_x + (PANEL_W - BTN_W) * 0.5
	var btn_start_y: float = panel_y + 28.0
	for i: int in range(BUTTONS.size()):
		var by: float = btn_start_y + float(i) * (BTN_H + BTN_SPACING)
		if pos.x >= btn_x and pos.x <= btn_x + BTN_W and pos.y >= by and pos.y <= by + BTN_H:
			return i
	return -1

func _activate(index: int) -> void:
	if index < 0 or index >= BUTTONS.size():
		return
	var btn_id: String = BUTTONS[index]["id"] as String
	match btn_id:
		"resume":
			_do_resume()
		"restart":
			_do_restart()
		"settings":
			_do_settings()
		"chapter":
			_do_chapter()
		"main_menu":
			_do_main_menu()

func _do_resume() -> void:
	var game_node: Node = _get_autoload("Game")
	if game_node:
		game_node.call("set_paused", false)
	queue_free()

func _do_restart() -> void:
	var game_node: Node = _get_autoload("Game")
	if game_node:
		game_node.call("restart_current_level")
	queue_free()

func _do_settings() -> void:
	var settings_scn: PackedScene = load("res://ui/settings_menu.tscn")
	if settings_scn:
		var dlg: Node = settings_scn.instantiate()
		add_child(dlg)

func _do_chapter() -> void:
	var game_node: Node = _get_autoload("Game")
	if game_node:
		game_node.call("set_paused", false)
	if is_inside_tree() and get_tree():
		get_tree().change_scene_to_file.call_deferred("res://ui/world_map.tscn")

func _do_main_menu() -> void:
	var game_node: Node = _get_autoload("Game")
	if game_node:
		game_node.call("set_paused", false)
	if is_inside_tree() and get_tree():
		get_tree().change_scene_to_file.call_deferred("res://ui/main_menu.tscn")

func _draw() -> void:
	var vp: Vector2 = _get_vp_size()
	# Overlay gelap penuh
	draw_rect(Rect2(0, 0, vp.x, vp.y), COL_OVERLAY)

	# Panel tengah
	var panel_x: float = (vp.x - PANEL_W) * 0.5
	var panel_y: float = (vp.y - PANEL_H) * 0.5
	draw_rect(Rect2(panel_x, panel_y, PANEL_W, PANEL_H), COL_PANEL_BG)
	# Border
	draw_rect(Rect2(panel_x, panel_y, PANEL_W, 1.0), COL_PANEL_BORDER)
	draw_rect(Rect2(panel_x, panel_y + PANEL_H - 1.0, PANEL_W, 1.0), COL_PANEL_BORDER)
	draw_rect(Rect2(panel_x, panel_y, 1.0, PANEL_H), COL_PANEL_BORDER)
	draw_rect(Rect2(panel_x + PANEL_W - 1.0, panel_y, 1.0, PANEL_H), COL_PANEL_BORDER)

	# Title
	var font: Font = get_theme_default_font()
	var title: String = "JEDA"
	var title_sz: Vector2 = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	draw_string(font, Vector2(panel_x + (PANEL_W - title_sz.x) * 0.5, panel_y + 16.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COL_GOLD)

	# Buttons
	var btn_x: float = panel_x + (PANEL_W - BTN_W) * 0.5
	var btn_start_y: float = panel_y + 28.0
	for i: int in range(BUTTONS.size()):
		var by: float = btn_start_y + float(i) * (BTN_H + BTN_SPACING)
		var is_sel: bool = (i == _selected)
		var bg: Color = COL_BTN_SEL if is_sel else COL_BTN_BG
		var border: Color = COL_BTN_SEL_BORDER if is_sel else COL_BTN_BORDER
		draw_rect(Rect2(btn_x, by, BTN_W, BTN_H), bg)
		draw_rect(Rect2(btn_x, by, BTN_W, 1.0), border)
		draw_rect(Rect2(btn_x, by + BTN_H - 1.0, BTN_W, 1.0), border)
		draw_rect(Rect2(btn_x, by, 1.0, BTN_H), border)
		draw_rect(Rect2(btn_x + BTN_W - 1.0, by, 1.0, BTN_H), border)

		# Cursor sutil
		if is_sel:
			draw_circle(Vector2(btn_x - 6.0, by + BTN_H / 2.0), 2.0, COL_GOLD)

		var label: String = BUTTONS[i]["label"] as String
		draw_string(font, Vector2(btn_x + 8.0, by + BTN_H - 5.0), label, HORIZONTAL_ALIGNMENT_LEFT, int(BTN_W - 14.0), 8, COL_TEXT)

	# Footer hint
	var hint_text: String = "W/S: Navigasi | Enter: Pilih | Esc: Lanjut"
	var hint_w: float = font.get_string_size(hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	if hint_w > PANEL_W - 16.0:
		hint_text = "W/S: Gerak | Enter: Pilih | Esc: Lanjut"
		hint_w = font.get_string_size(hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var hint_x: float = panel_x + (PANEL_W - hint_w) * 0.5
	draw_string(font, Vector2(hint_x, panel_y + PANEL_H - 8.0), hint_text, HORIZONTAL_ALIGNMENT_LEFT, int(PANEL_W - 16.0), 8, Color(0.6, 0.6, 0.55, 0.6))

func _get_vp_size() -> Vector2:
	if is_inside_tree() and get_viewport() != null:
		var s: Vector2 = get_viewport_rect().size
		if s.x > 0.0 and s.y > 0.0:
			return s
	return Vector2(float(VIEWPORT_W), float(VIEWPORT_H))

func _get_autoload(autoload_name: String) -> Node:
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree and (loop as SceneTree).root:
		return (loop as SceneTree).root.get_node_or_null(autoload_name)
	return null

## Test-only helpers
func get_selected() -> int:
	return _selected

func get_panel_rect() -> Rect2:
	var vp: Vector2 = _get_vp_size()
	var px: float = (vp.x - PANEL_W) * 0.5
	var py: float = (vp.y - PANEL_H) * 0.5
	return Rect2(px, py, PANEL_W, PANEL_H)
