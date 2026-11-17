extends Control

## Layar Pengaturan (FR-UI-06, FR-STA-21, FR-CRD-03).
## Panel terpusat 480x270 px. Navigasi: W/S untuk pindah opsi, A/D/Enter/Klik
## untuk ubah nilai, Esc untuk kembali.

const VIEWPORT_W: int = 480
const VIEWPORT_H: int = 270
const PANEL_W: float = 240.0
const PANEL_H: float = 200.0

const COL_OVERLAY := Color(0, 0, 0, 0.65)
const COL_PANEL_BG := Color(0.12, 0.1, 0.07, 0.95)
const COL_PANEL_BORDER := Color(0.55, 0.38, 0.18, 1.0)
const COL_GOLD := Color(1.0, 0.82, 0.3, 1.0)
const COL_TEXT := Color(0.95, 0.95, 0.92, 1.0)
const COL_HINT := Color(0.6, 0.6, 0.55, 0.6)
const COL_SEL := Color(0.28, 0.2, 0.12, 0.95)
const COL_ROW := Color(0.16, 0.12, 0.08, 0.6)
const COL_BAR_BG := Color(0.15, 0.15, 0.18, 0.85)
const COL_BAR_FILL := Color(0.3, 0.75, 0.5, 1.0)
const COL_CHECK_ON := Color(0.3, 0.9, 0.4, 1.0)
const COL_CHECK_OFF := Color(0.5, 0.5, 0.5, 0.6)

# Options — each has: label, prop (name on Settings autoload), type ("slider" or "toggle")
const OPTIONS: Array = [
	{"label": "Volume Master", "prop": "master_volume", "type": "slider"},
	{"label": "Volume Musik", "prop": "music_volume", "type": "slider"},
	{"label": "Volume SFX", "prop": "sfx_volume", "type": "slider"},
	{"label": "Bantuan Bidik", "prop": "aim_assist", "type": "toggle"},
	{"label": "Tekan utk Bekerja", "prop": "toggle_work", "type": "toggle"},
	{"label": "Jendela Aduk Lebar", "prop": "wide_attention_window", "type": "toggle"},
	{"label": "Kurangi Animasi", "prop": "reduce_motion", "type": "toggle"},
]

var _selected: int = 0
var _values: Array = [] # mirrors OPTIONS — float for slider (0.0-1.0), bool for toggle

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(VIEWPORT_W, VIEWPORT_H)
	custom_minimum_size = Vector2(VIEWPORT_W, VIEWPORT_H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_values()
	set_process_input(true)

func _load_values() -> void:
	_values.clear()
	var settings_node: Node = _get_autoload("Settings")
	for opt: Dictionary in OPTIONS:
		var prop: String = opt["prop"] as String
		var opt_type: String = opt["type"] as String
		if settings_node and prop in settings_node:
			if opt_type == "slider":
				_values.append(float(settings_node.get(prop)))
			else:
				_values.append(bool(settings_node.get(prop)))
		else:
			if opt_type == "slider":
				_values.append(0.8)
			else:
				_values.append(false)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var kc: int = (event as InputEventKey).keycode
		if kc == KEY_ESCAPE:
			_save_and_close()
			get_viewport().set_input_as_handled()
			return
		if kc == KEY_W or kc == KEY_UP:
			_selected = (_selected - 1 + OPTIONS.size()) % OPTIONS.size()
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if kc == KEY_S or kc == KEY_DOWN:
			_selected = (_selected + 1) % OPTIONS.size()
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		# Adjust value
		var opt: Dictionary = OPTIONS[_selected] as Dictionary
		var opt_type: String = opt["type"] as String
		if kc == KEY_ENTER or kc == KEY_KP_ENTER:
			if opt_type == "toggle":
				_values[_selected] = not (_values[_selected] as bool)
				_apply_value(_selected)
				queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if kc == KEY_A or kc == KEY_LEFT:
			if opt_type == "slider":
				_values[_selected] = maxf(0.0, (_values[_selected] as float) - 0.1)
				_apply_value(_selected)
				queue_redraw()
			elif opt_type == "toggle":
				_values[_selected] = false
				_apply_value(_selected)
				queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if kc == KEY_D or kc == KEY_RIGHT:
			if opt_type == "slider":
				_values[_selected] = minf(1.0, (_values[_selected] as float) + 0.1)
				_apply_value(_selected)
				queue_redraw()
			elif opt_type == "toggle":
				_values[_selected] = true
				_apply_value(_selected)
				queue_redraw()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton and event.pressed:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var idx: int = _get_row_at(mb.position)
			if idx >= 0:
				_selected = idx
				var opt: Dictionary = OPTIONS[idx] as Dictionary
				if opt["type"] as String == "toggle":
					_values[idx] = not (_values[idx] as bool)
					_apply_value(idx)
				elif opt["type"] as String == "slider":
					# Click on slider bar to set value
					var panel_x: float = (float(VIEWPORT_W) - PANEL_W) / 2.0
					var bar_x: float = panel_x + 140.0
					var bar_w: float = 80.0
					var click_pct: float = clampf((mb.position.x - bar_x) / bar_w, 0.0, 1.0)
					_values[idx] = click_pct
					_apply_value(idx)
				queue_redraw()
			# Check KEMBALI button
			var panel_x2: float = (float(VIEWPORT_W) - PANEL_W) / 2.0
			var panel_y2: float = (float(VIEWPORT_H) - PANEL_H) / 2.0
			var back_y: float = panel_y2 + PANEL_H - 24.0
			if mb.position.x >= panel_x2 + 10.0 and mb.position.x <= panel_x2 + 110.0 and mb.position.y >= back_y and mb.position.y <= back_y + 18.0:
				_save_and_close()
			get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion:
		var idx: int = _get_row_at((event as InputEventMouseMotion).position)
		if idx >= 0 and idx != _selected:
			_selected = idx
			queue_redraw()

func _get_row_at(pos: Vector2) -> int:
	var panel_x: float = (float(VIEWPORT_W) - PANEL_W) / 2.0
	var panel_y: float = (float(VIEWPORT_H) - PANEL_H) / 2.0
	var row_start_y: float = panel_y + 28.0
	for i: int in range(OPTIONS.size()):
		var ry: float = row_start_y + float(i) * 20.0
		if pos.x >= panel_x + 8.0 and pos.x <= panel_x + PANEL_W - 8.0 and pos.y >= ry and pos.y <= ry + 18.0:
			return i
	return -1

func _apply_value(index: int) -> void:
	var opt: Dictionary = OPTIONS[index] as Dictionary
	var prop: String = opt["prop"] as String
	var settings_node: Node = _get_autoload("Settings")
	if settings_node and prop in settings_node:
		settings_node.set(prop, _values[index])
		if settings_node.has_method("_apply_settings"):
			settings_node.call("_apply_settings")

func _save_and_close() -> void:
	# Apply all values before closing
	for i: int in range(OPTIONS.size()):
		_apply_value(i)
	queue_free()

func _draw() -> void:
	# Overlay
	draw_rect(Rect2(0, 0, VIEWPORT_W, VIEWPORT_H), COL_OVERLAY)

	# Panel
	var px: float = (float(VIEWPORT_W) - PANEL_W) / 2.0
	var py: float = (float(VIEWPORT_H) - PANEL_H) / 2.0
	draw_rect(Rect2(px, py, PANEL_W, PANEL_H), COL_PANEL_BG)
	# Border
	draw_rect(Rect2(px, py, PANEL_W, 1.0), COL_PANEL_BORDER)
	draw_rect(Rect2(px, py + PANEL_H - 1.0, PANEL_W, 1.0), COL_PANEL_BORDER)
	draw_rect(Rect2(px, py, 1.0, PANEL_H), COL_PANEL_BORDER)
	draw_rect(Rect2(px + PANEL_W - 1.0, py, 1.0, PANEL_H), COL_PANEL_BORDER)

	var font: Font = get_theme_default_font()

	# Title
	var title: String = "PENGATURAN"
	var title_sz: Vector2 = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	draw_string(font, Vector2(px + (PANEL_W - title_sz.x) / 2.0, py + 16.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COL_GOLD)

	# Options rows
	var row_y: float = py + 28.0
	for i: int in range(OPTIONS.size()):
		var opt: Dictionary = OPTIONS[i] as Dictionary
		var is_sel: bool = (i == _selected)
		var ry: float = row_y + float(i) * 20.0

		# Row background
		draw_rect(Rect2(px + 4.0, ry, PANEL_W - 8.0, 18.0), COL_SEL if is_sel else COL_ROW)

		# Selection indicator
		if is_sel:
			draw_circle(Vector2(px + 10.0, ry + 9.0), 2.0, COL_GOLD)

		# Label
		draw_string(font, Vector2(px + 16.0, ry + 12.0), opt["label"] as String, HORIZONTAL_ALIGNMENT_LEFT, 120, 8, COL_TEXT)

		# Value
		if opt["type"] as String == "slider":
			var val: float = _values[i] as float
			var bar_x: float = px + 140.0
			var bar_w: float = 80.0
			# Bar BG
			draw_rect(Rect2(bar_x, ry + 5.0, bar_w, 8.0), COL_BAR_BG)
			# Bar fill
			draw_rect(Rect2(bar_x, ry + 5.0, bar_w * val, 8.0), COL_BAR_FILL)
			# Percentage
			var pct_str: String = "%d%%" % int(val * 100.0)
			draw_string(font, Vector2(bar_x + bar_w + 4.0, ry + 12.0), pct_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_HINT)
		else: # toggle
			var toggled: bool = _values[i] as bool
			var check_x: float = px + 155.0
			var check_col: Color = COL_CHECK_ON if toggled else COL_CHECK_OFF
			draw_rect(Rect2(check_x, ry + 4.0, 10.0, 10.0), check_col)
			if toggled:
				draw_string(font, Vector2(check_x + 2.0, ry + 12.0), "V", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
			var state_str: String = "YA" if toggled else "TIDAK"
			draw_string(font, Vector2(check_x + 14.0, ry + 12.0), state_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_TEXT)

	# KEMBALI button
	var back_y: float = py + PANEL_H - 24.0
	draw_rect(Rect2(px + 10.0, back_y, 100.0, 18.0), COL_PANEL_BG.lightened(0.1))
	draw_rect(Rect2(px + 10.0, back_y, 100.0, 1.0), COL_PANEL_BORDER)
	draw_rect(Rect2(px + 10.0, back_y + 17.0, 100.0, 1.0), COL_PANEL_BORDER)
	draw_string(font, Vector2(px + 18.0, back_y + 12.0), "KEMBALI [Esc]", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_GOLD)

	# Footer hint
	draw_string(font, Vector2(px + 10.0, py + PANEL_H - 6.0), "W/S: Pindah  A/D: Ubah  Enter: Toggle  Esc: Tutup", HORIZONTAL_ALIGNMENT_LEFT, int(PANEL_W - 20.0), 8, COL_HINT)

func _get_autoload(autoload_name: String) -> Node:
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree and (loop as SceneTree).root:
		return (loop as SceneTree).root.get_node_or_null(autoload_name)
	return null

## Test-only helpers
func get_selected() -> int:
	return _selected

func get_values() -> Array:
	return _values.duplicate()
