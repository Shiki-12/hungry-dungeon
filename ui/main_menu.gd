extends Control

## Menu Utama Koki Dungeon — Nusantara Fantasy Aesthetic (FR-UI-05 s.d. 08, FR-WEB-01).
## Fase: LOADING -> TITLE_GATE -> MENU.
## Navigasi: W/S/Panah untuk pindah, Enter/Klik untuk pilih, Esc untuk tutup submenu.
## TIDAK ada widget P1/P2 readiness — kesiapan pemain ada di coop_ready_screen.

# ══════════════════════════════════════════════════════════════════════════════
# CONSTANTS
# ══════════════════════════════════════════════════════════════════════════════

enum Phase { LOADING, TITLE_GATE, MENU }

const VIEWPORT_W: int = 480
const VIEWPORT_H: int = 270

const LOADING_DURATION: float = 2.0
const LOADING_TEXTS: Array = [
	"Memanaskan Kuali Leluhur...",
	"Meracik Bumbu Warisan Mbok Laras...",
	"Menata Kursi Pelanggan Goblin...",
	"Lapak Siap Dibuka!",
]

const MENU_ITEMS: Array = [
	{"label": "MULAI EKSPEDISI", "id": "start"},
	{"label": "LATIHAN (TUTORIAL)", "id": "training"},
	{"label": "BUKU RESEP & LORE", "id": "recipe_book"},
	{"label": "MODE WARUNG", "id": "warung", "locked": true},
	{"label": "PENGATURAN", "id": "settings"},
	{"label": "KREDIT & KELUAR", "id": "credits"},
]

const BUTTON_WIDTH: int = 150
const BUTTON_HEIGHT: int = 18
const BUTTON_SPACING: int = 4
const BUTTON_X: int = 16
const BUTTON_Y_START: int = 90

const SLIDE_OFFSET: float = 6.0
const SCALE_HOVER: float = 1.04
const TRANSITION_TIME: float = 0.35

# Colour palette
const COL_DUNGEON_TOP := Color(0.12, 0.08, 0.22, 1.0)
const COL_DUNGEON_BOT := Color(0.08, 0.14, 0.18, 1.0)
const COL_STALACTITE := Color(0.15, 0.1, 0.25, 0.7)
const COL_MUSHROOM_TEAL := Color(0.2, 0.75, 0.65, 1.0)
const COL_MUSHROOM_PURPLE := Color(0.6, 0.3, 0.75, 1.0)
const COL_SPORE_GOLD := Color(0.95, 0.85, 0.4, 0.6)
const COL_SPORE_GREEN := Color(0.4, 0.9, 0.5, 0.5)
const COL_FIRE_ORANGE := Color(1.0, 0.55, 0.15, 0.9)
const COL_FIRE_RED := Color(0.95, 0.25, 0.1, 0.8)
const COL_GOLD := Color(1.0, 0.82, 0.3, 1.0)
const COL_BUTTON_BG := Color(0.18, 0.12, 0.08, 0.92)
const COL_BUTTON_BORDER := Color(0.55, 0.38, 0.18, 1.0)
const COL_BUTTON_HOVER_BG := Color(0.28, 0.2, 0.12, 0.95)
const COL_BUTTON_HOVER_BORDER := Color(0.85, 0.65, 0.3, 1.0)
const COL_LOCKED_BG := Color(0.12, 0.12, 0.12, 0.7)
const COL_LOCKED_BORDER := Color(0.3, 0.3, 0.3, 0.6)
const COL_TEXT := Color(0.95, 0.95, 0.92, 1.0)
const COL_TEXT_LOCKED := Color(0.5, 0.5, 0.5, 0.7)
const COL_SUBTITLE := Color(0.75, 0.9, 0.8, 0.8)
const COL_KUALI_BODY := Color(0.2, 0.2, 0.22, 1.0)
const COL_KUALI_RIM := Color(0.35, 0.3, 0.25, 1.0)
const COL_TUNGKU_BODY := Color(0.55, 0.35, 0.2, 1.0)
const COL_TUNGKU_DARK := Color(0.4, 0.25, 0.12, 1.0)
const COL_SOUP := Color(0.85, 0.5, 0.2, 0.9)
const COL_GEROBAK_WOOD := Color(0.5, 0.35, 0.18, 1.0)
const COL_GEROBAK_DARK := Color(0.35, 0.22, 0.1, 1.0)
const COL_DAMAR := Color(1.0, 0.8, 0.3, 0.9)
const COL_RANGGA_BLUE := Color(0.3, 0.5, 0.85, 1.0)
const COL_SEKAR_ORANGE := Color(0.95, 0.6, 0.2, 1.0)
const COL_GOBLIN_RED := Color(0.85, 0.2, 0.15, 1.0)
const COL_FOOTER_BG := Color(0.06, 0.06, 0.08, 0.85)
const COL_VERSION := Color(0.5, 0.65, 0.55, 0.8)
const COL_HINT := Color(0.6, 0.6, 0.55, 0.6)

# ══════════════════════════════════════════════════════════════════════════════
# STATE
# ══════════════════════════════════════════════════════════════════════════════

var _phase: int = Phase.LOADING
var _time: float = 0.0
var _loading_progress: float = 0.0
var _loading_text_idx: int = 0
var _loading_skip_requested: bool = false
var _title_alpha: float = 0.0
var _title_pulse_time: float = 0.0
var _menu_visible: bool = false
var _selected_index: int = 0
var _hovered_index: int = -1
var _button_offsets: Array = []
var _button_scales: Array = []
var _submenu_active: String = ""
var _submenu_slide: float = 0.0
var _curtain_progress: float = 0.0
var _curtain_target_scene: String = ""

# Diorama animation state
var _spore_positions: Array = []
var _spore_speeds: Array = []
var _stalactite_xs: Array = []
var _stalactite_heights: Array = []
var _mushroom_data: Array = []
var _sutil_angle: float = 0.0
var _rangga_bob: float = 0.0
var _sekar_bob: float = 0.0
var _goblin_peek: float = 0.0
var _goblin_emote_timer: float = 0.0
var _goblin_showing_emote: bool = false
var _bubble_positions: Array = []
var _bubble_timers: Array = []

# Submenu + Curtain nodes
var _submenu_panel: Control = null
var _curtain_rect: ColorRect = null
var _curtain_tween: Tween = null
var _reduce_motion: bool = false

# ══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	var settings_node: Node = _get_autoload("Settings")
	if settings_node and "reduce_motion" in settings_node:
		_reduce_motion = settings_node.reduce_motion

	_init_diorama_data()
	_init_button_state()
	_create_curtain_node()
	_create_submenu_panel()

	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	set_process_input(true)

func _init_diorama_data() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 42
	for i: int in range(12):
		_stalactite_xs.append(rng.randf_range(0.0, float(VIEWPORT_W)))
		_stalactite_heights.append(rng.randf_range(10.0, 40.0))
	for i: int in range(6):
		_mushroom_data.append({
			"x": rng.randf_range(180.0, 460.0),
			"y": rng.randf_range(200.0, 250.0),
			"col": COL_MUSHROOM_TEAL if i % 2 == 0 else COL_MUSHROOM_PURPLE,
			"size": rng.randf_range(4.0, 8.0),
			"phase": rng.randf_range(0.0, TAU),
		})
	for i: int in range(20):
		_spore_positions.append(Vector2(rng.randf_range(0.0, float(VIEWPORT_W)), rng.randf_range(0.0, float(VIEWPORT_H))))
		_spore_speeds.append(rng.randf_range(5.0, 15.0))
	for i: int in range(5):
		_bubble_positions.append(Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-2.0, 2.0)))
		_bubble_timers.append(rng.randf_range(0.0, 2.0))

func _init_button_state() -> void:
	for i: int in range(MENU_ITEMS.size()):
		_button_offsets.append(0.0)
		_button_scales.append(1.0)

func _create_curtain_node() -> void:
	_curtain_rect = ColorRect.new()
	_curtain_rect.color = Color(0.06, 0.04, 0.02, 1.0)
	_curtain_rect.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	_curtain_rect.visible = false
	_curtain_rect.z_index = 100
	_curtain_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_curtain_rect)

func _create_submenu_panel() -> void:
	_submenu_panel = Control.new()
	_submenu_panel.name = "SubmenuPanel"
	_submenu_panel.position = Vector2(float(VIEWPORT_W), 0.0)
	_submenu_panel.size = Vector2(float(VIEWPORT_W), float(VIEWPORT_H))
	_submenu_panel.z_index = 10
	_submenu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_submenu_panel)

# ══════════════════════════════════════════════════════════════════════════════
# INPUT — Uses Enter/Klik for confirm, W/S/Arrow for nav, Esc for back
# ══════════════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if _curtain_progress > 0.0:
		return

	if _phase == Phase.LOADING:
		if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
			if event.is_pressed():
				_loading_skip_requested = true
		return

	if _phase == Phase.TITLE_GATE:
		if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
			if event.is_pressed():
				_enter_menu_phase()
		return

	if _phase == Phase.MENU:
		_handle_menu_input(event)

func _handle_menu_input(event: InputEvent) -> void:
	# If submenu overlay (settings) is open, let it handle input
	if _submenu_active == "settings_overlay":
		return

	if _submenu_active != "":
		if event is InputEventKey and event.pressed:
			var kc: int = (event as InputEventKey).keycode
			if kc == KEY_ESCAPE:
				_close_submenu()
				get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed:
		var kc: int = (event as InputEventKey).keycode
		match kc:
			KEY_W, KEY_UP:
				_navigate_menu(-1)
				get_viewport().set_input_as_handled()
			KEY_S, KEY_DOWN:
				_navigate_menu(1)
				get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_KP_ENTER:
				_activate_menu_item(_selected_index)
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				pass # Already on main menu

	if event is InputEventMouseMotion:
		var mpos: Vector2 = (event as InputEventMouseMotion).position
		_hovered_index = _get_button_at(mpos)
		if _hovered_index >= 0:
			_selected_index = _hovered_index

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var idx: int = _get_button_at(mb.position)
			if idx >= 0:
				_activate_menu_item(idx)

func _get_button_at(pos: Vector2) -> int:
	for i: int in range(MENU_ITEMS.size()):
		var by: float = float(BUTTON_Y_START + i * (BUTTON_HEIGHT + BUTTON_SPACING))
		var bx: float = float(BUTTON_X) + (_button_offsets[i] as float)
		if pos.x >= bx and pos.x <= bx + float(BUTTON_WIDTH) and pos.y >= by and pos.y <= by + float(BUTTON_HEIGHT):
			return i
	return -1

func _navigate_menu(direction: int) -> void:
	var new_idx: int = _selected_index + direction
	if new_idx < 0:
		new_idx = MENU_ITEMS.size() - 1
	elif new_idx >= MENU_ITEMS.size():
		new_idx = 0
	_selected_index = new_idx

func _activate_menu_item(index: int) -> void:
	if index < 0 or index >= MENU_ITEMS.size():
		return
	var item: Dictionary = MENU_ITEMS[index] as Dictionary
	var locked: bool = item.get("locked", false) as bool
	if locked:
		_shake_locked_button(index)
		return
	var item_id: String = item["id"] as String
	match item_id:
		"start":
			_play_curtain_transition("res://ui/world_map.tscn")
		"training":
			_open_submenu("training")
		"recipe_book":
			_open_submenu("recipe_book")
		"warung":
			_shake_locked_button(index)
		"settings":
			_open_settings_overlay()
		"credits":
			_open_submenu("credits")

# ══════════════════════════════════════════════════════════════════════════════
# PHASE TRANSITIONS
# ══════════════════════════════════════════════════════════════════════════════

func _enter_menu_phase() -> void:
	_phase = Phase.MENU
	_menu_visible = true
	queue_redraw()

func _play_curtain_transition(target_scene: String) -> void:
	if _curtain_progress > 0.0:
		return
	_curtain_target_scene = target_scene
	_curtain_rect.visible = true
	_curtain_rect.color.a = 0.0
	_curtain_progress = 0.001
	if _curtain_tween:
		_curtain_tween.kill()
	_curtain_tween = create_tween()
	_curtain_tween.tween_method(_set_curtain_alpha, 0.0, 1.0, TRANSITION_TIME)
	_curtain_tween.tween_callback(_on_curtain_covered)

func _set_curtain_alpha(alpha: float) -> void:
	_curtain_progress = alpha
	if _curtain_rect:
		_curtain_rect.color.a = alpha

func _on_curtain_covered() -> void:
	if not _curtain_target_scene.is_empty():
		get_tree().change_scene_to_file(_curtain_target_scene)

# ══════════════════════════════════════════════════════════════════════════════
# SUBMENU MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

func _open_submenu(submenu_id: String) -> void:
	if _submenu_active == submenu_id:
		return
	_submenu_active = submenu_id
	_clear_submenu_content()
	_build_submenu_content(submenu_id)
	_submenu_slide = 0.0
	var tw: Tween = create_tween()
	tw.tween_method(_set_submenu_slide, 0.0, 1.0, 0.25)

func _close_submenu() -> void:
	var tw: Tween = create_tween()
	tw.tween_method(_set_submenu_slide, _submenu_slide, 0.0, 0.2)
	tw.tween_callback(_on_submenu_closed)

func _on_submenu_closed() -> void:
	_submenu_active = ""
	_clear_submenu_content()
	queue_redraw()

func _set_submenu_slide(val: float) -> void:
	_submenu_slide = val
	_submenu_panel.position.x = lerpf(float(VIEWPORT_W), 170.0, val)
	queue_redraw()

func _clear_submenu_content() -> void:
	for child: Node in _submenu_panel.get_children():
		child.queue_free()

func _build_submenu_content(submenu_id: String) -> void:
	match submenu_id:
		"training":
			_build_training_submenu()
		"recipe_book":
			_build_recipe_submenu()
		"credits":
			_build_credits_submenu()

func _open_settings_overlay() -> void:
	# Open settings as overlay child — it handles its own input and queue_free on close
	_submenu_active = "settings_overlay"
	var settings_scn: PackedScene = load("res://ui/settings_menu.tscn")
	if settings_scn:
		var dlg: Control = settings_scn.instantiate() as Control
		dlg.z_index = 50
		dlg.tree_exiting.connect(func() -> void:
			_submenu_active = ""
			queue_redraw()
		)
		add_child(dlg)

func _build_training_submenu() -> void:
	var panel_bg: ColorRect = ColorRect.new()
	panel_bg.color = Color(0.1, 0.08, 0.14, 0.92)
	panel_bg.position = Vector2.ZERO
	panel_bg.size = Vector2(300.0, float(VIEWPORT_H))
	_submenu_panel.add_child(panel_bg)

	var title_lbl: Label = Label.new()
	title_lbl.text = "LATIHAN"
	title_lbl.position = Vector2(16.0, 12.0)
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", COL_GOLD)
	_submenu_panel.add_child(title_lbl)

	var tutorials: Array = [
		"T-1: Sajikan 3 Hidangan",
		"T-2: Nasi Goreng Jamur",
		"T-3: Lempar Cepat 5 Bahan",
		"T-4: Lempar Bidik 5 Hidangan",
		"T-5: Usir Orang-orangan Sawah",
	]
	for i: int in range(tutorials.size()):
		var btn: Button = Button.new()
		btn.text = tutorials[i] as String
		btn.position = Vector2(16.0, 40.0 + float(i) * 26.0)
		btn.custom_minimum_size = Vector2(260.0, 22.0)
		btn.size = Vector2(260.0, 22.0)
		var idx: int = i + 1
		btn.pressed.connect(func() -> void: _load_tutorial(idx))
		_submenu_panel.add_child(btn)

	var back_btn: Button = Button.new()
	back_btn.text = "< KEMBALI [Esc]"
	back_btn.position = Vector2(16.0, 40.0 + float(tutorials.size()) * 26.0 + 10.0)
	back_btn.custom_minimum_size = Vector2(120.0, 22.0)
	back_btn.size = Vector2(120.0, 22.0)
	back_btn.pressed.connect(_close_submenu)
	_submenu_panel.add_child(back_btn)

func _build_recipe_submenu() -> void:
	var panel_bg: ColorRect = ColorRect.new()
	panel_bg.color = Color(0.1, 0.08, 0.14, 0.92)
	panel_bg.position = Vector2.ZERO
	panel_bg.size = Vector2(300.0, float(VIEWPORT_H))
	_submenu_panel.add_child(panel_bg)

	var title_lbl: Label = Label.new()
	title_lbl.text = "BUKU RESEP & LORE"
	title_lbl.position = Vector2(16.0, 12.0)
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", COL_GOLD)
	_submenu_panel.add_child(title_lbl)

	var recipes: Array = ["Nasi Goreng Jamur", "Nasi Kuning", "Soto Lamongan", "Rawon", "Pecel Lele", "Gado-Gado"]
	var y_pos: float = 40.0
	for r: String in recipes:
		var lbl: Label = Label.new()
		lbl.text = "  " + r
		lbl.position = Vector2(20.0, y_pos)
		lbl.add_theme_color_override("font_color", COL_SUBTITLE)
		_submenu_panel.add_child(lbl)
		y_pos += 16.0

	var info_lbl: Label = Label.new()
	info_lbl.text = "Resep lengkap terbuka seiring\nprogres ekspedisi bersama."
	info_lbl.position = Vector2(20.0, y_pos + 10.0)
	info_lbl.add_theme_color_override("font_color", COL_HINT)
	_submenu_panel.add_child(info_lbl)

	var back_btn: Button = Button.new()
	back_btn.text = "< KEMBALI [Esc]"
	back_btn.position = Vector2(16.0, 220.0)
	back_btn.custom_minimum_size = Vector2(120.0, 22.0)
	back_btn.size = Vector2(120.0, 22.0)
	back_btn.pressed.connect(_close_submenu)
	_submenu_panel.add_child(back_btn)

func _build_credits_submenu() -> void:
	var panel_bg: ColorRect = ColorRect.new()
	panel_bg.color = Color(0.1, 0.08, 0.14, 0.92)
	panel_bg.position = Vector2.ZERO
	panel_bg.size = Vector2(300.0, float(VIEWPORT_H))
	_submenu_panel.add_child(panel_bg)

	var title_lbl: Label = Label.new()
	title_lbl.text = "KREDIT & KELUAR"
	title_lbl.position = Vector2(16.0, 12.0)
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", COL_GOLD)
	_submenu_panel.add_child(title_lbl)

	var credits_text: String = "Koki Dungeon\nSedekah Dapur Dungeon Rahayu\n\nDesain & Pemrograman:\nTim Koki Dungeon\n\nEngine: Godot 4.7\n\nTerima kasih telah bermain!"
	var txt_lbl: Label = Label.new()
	txt_lbl.text = credits_text
	txt_lbl.position = Vector2(20.0, 40.0)
	txt_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt_lbl.size = Vector2(260.0, 150.0)
	txt_lbl.add_theme_color_override("font_color", COL_SUBTITLE)
	_submenu_panel.add_child(txt_lbl)

	var quit_btn: Button = Button.new()
	quit_btn.text = "KELUAR GAME"
	quit_btn.position = Vector2(16.0, 200.0)
	quit_btn.custom_minimum_size = Vector2(120.0, 22.0)
	quit_btn.size = Vector2(120.0, 22.0)
	quit_btn.pressed.connect(func() -> void: get_tree().quit())
	_submenu_panel.add_child(quit_btn)

	var back_btn: Button = Button.new()
	back_btn.text = "< KEMBALI [Esc]"
	back_btn.position = Vector2(150.0, 200.0)
	back_btn.custom_minimum_size = Vector2(120.0, 22.0)
	back_btn.size = Vector2(120.0, 22.0)
	back_btn.pressed.connect(_close_submenu)
	_submenu_panel.add_child(back_btn)

func _load_tutorial(idx: int) -> void:
	var game_node: Node = _get_autoload("Game")
	if game_node:
		game_node.set("current_level_id", "tutorial_%d" % idx)
	_play_curtain_transition("res://levels/kitchen_stage.tscn")

func _shake_locked_button(index: int) -> void:
	var tw: Tween = create_tween()
	for s: int in range(6):
		var captured_index: int = index
		var captured_offset: float = 4.0 if s % 2 == 0 else -4.0
		tw.tween_callback(func() -> void:
			if captured_index < _button_offsets.size():
				_button_offsets[captured_index] = captured_offset
			queue_redraw()
		)
		tw.tween_interval(0.04)
	var final_index: int = index
	tw.tween_callback(func() -> void:
		if final_index < _button_offsets.size():
			_button_offsets[final_index] = 0.0
		queue_redraw()
	)

# ══════════════════════════════════════════════════════════════════════════════
# PROCESS (Animation Loop)
# ══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	_time += delta
	if _phase == Phase.LOADING:
		_update_loading(delta)
	elif _phase == Phase.TITLE_GATE:
		_update_title_gate(delta)
	elif _phase == Phase.MENU:
		_update_menu(delta)
	queue_redraw()

func _update_loading(delta: float) -> void:
	var speed: float = 2.0 if _loading_skip_requested else 1.0
	_loading_progress = minf(_loading_progress + delta * speed / LOADING_DURATION, 1.0)
	_loading_text_idx = mini(int(_loading_progress * float(LOADING_TEXTS.size())), LOADING_TEXTS.size() - 1)
	_sutil_angle += delta * 2.5 * speed
	for i: int in range(_bubble_timers.size()):
		_bubble_timers[i] = (_bubble_timers[i] as float) + delta * speed
	if _loading_progress >= 1.0:
		_phase = Phase.TITLE_GATE
		_title_alpha = 0.0

func _update_title_gate(delta: float) -> void:
	_title_alpha = minf(_title_alpha + delta * 2.0, 1.0)
	_title_pulse_time += delta

func _update_menu(delta: float) -> void:
	if not _reduce_motion:
		for i: int in range(_spore_positions.size()):
			var pos: Vector2 = _spore_positions[i] as Vector2
			pos.y -= (_spore_speeds[i] as float) * delta
			if pos.y < -5.0:
				pos.y = float(VIEWPORT_H) + 5.0
				pos.x = fmod(pos.x + 73.0, float(VIEWPORT_W))
			_spore_positions[i] = pos
	_rangga_bob = sin(_time * 2.5) * 2.0
	_sekar_bob = sin(_time * 2.5 + 1.0) * 2.0
	_sutil_angle += delta * 1.0
	_goblin_emote_timer += delta
	if _goblin_emote_timer > 5.0:
		_goblin_showing_emote = not _goblin_showing_emote
		_goblin_emote_timer = 0.0
	_goblin_peek = lerpf(_goblin_peek, 1.0 if _goblin_showing_emote else 0.0, delta * 3.0)
	for i: int in range(MENU_ITEMS.size()):
		var target_offset: float = SLIDE_OFFSET if i == _selected_index else 0.0
		var target_scale: float = SCALE_HOVER if i == _selected_index else 1.0
		if _reduce_motion:
			_button_offsets[i] = target_offset
			_button_scales[i] = target_scale
		else:
			_button_offsets[i] = lerpf(_button_offsets[i] as float, target_offset, delta * 10.0)
			_button_scales[i] = lerpf(_button_scales[i] as float, target_scale, delta * 10.0)
	for i: int in range(_bubble_timers.size()):
		_bubble_timers[i] = (_bubble_timers[i] as float) + delta

# ══════════════════════════════════════════════════════════════════════════════
# DRAWING
# ══════════════════════════════════════════════════════════════════════════════

func _draw() -> void:
	if _phase == Phase.LOADING:
		_draw_loading()
	elif _phase == Phase.TITLE_GATE:
		_draw_title_gate()
	elif _phase == Phase.MENU:
		_draw_diorama_bg()
		_draw_menu_buttons()
		_draw_footer()

# ── Loading Phase ────────────────────────────────────────────────────────────

func _draw_loading() -> void:
	draw_rect(Rect2(0, 0, VIEWPORT_W, VIEWPORT_H), Color(0.05, 0.04, 0.06, 1.0))
	var cx: float = float(VIEWPORT_W) / 2.0
	var cy: float = float(VIEWPORT_H) / 2.0 - 10.0
	_draw_tungku(cx, cy + 20.0)
	_draw_fire(cx, cy + 14.0)
	_draw_kuali(cx, cy)
	_draw_soup(cx, cy - 2.0)
	_draw_bubbles(cx, cy - 5.0)
	_draw_steam(cx, cy - 20.0)
	_draw_sutil(cx, cy - 5.0, _sutil_angle)
	# Progress bar
	var bar_x: float = cx - 60.0
	var bar_y: float = cy + 55.0
	draw_rect(Rect2(bar_x - 1.0, bar_y - 1.0, 122.0, 10.0), Color(0.3, 0.22, 0.1, 1.0))
	draw_rect(Rect2(bar_x, bar_y, 120.0, 8.0), Color(0.55, 0.42, 0.22, 1.0))
	draw_rect(Rect2(bar_x, bar_y, 120.0 * _loading_progress, 8.0), Color(0.85, 0.65, 0.2, 1.0))
	for seg: int in range(1, 4):
		var sx: float = bar_x + 120.0 * float(seg) / 4.0
		draw_line(Vector2(sx, bar_y), Vector2(sx, bar_y + 8.0), Color(0.3, 0.22, 0.1, 0.5), 1.0)
	var txt: String = LOADING_TEXTS[_loading_text_idx] as String
	var font: Font = get_theme_default_font()
	var txt_size: Vector2 = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
	draw_string(font, Vector2(cx - txt_size.x / 2.0, bar_y + 22.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_SUBTITLE)

func _draw_tungku(cx: float, cy: float) -> void:
	var points: PackedVector2Array = PackedVector2Array([Vector2(cx - 18.0, cy - 4.0), Vector2(cx + 18.0, cy - 4.0), Vector2(cx + 22.0, cy + 12.0), Vector2(cx - 22.0, cy + 12.0)])
	draw_colored_polygon(points, COL_TUNGKU_BODY)
	draw_rect(Rect2(cx - 8.0, cy + 2.0, 16.0, 10.0), COL_TUNGKU_DARK)
	draw_rect(Rect2(cx - 20.0, cy - 6.0, 40.0, 3.0), COL_TUNGKU_BODY.lightened(0.15))

func _draw_fire(cx: float, cy: float) -> void:
	var t: float = _time * 8.0
	for i: int in range(5):
		var fi: float = float(i)
		var fx: float = cx + sin(t + fi * 1.3) * 6.0 - 6.0 + fi * 3.0
		var fy: float = cy - abs(sin(t * 1.1 + fi)) * 6.0
		var fsize: float = 3.0 + sin(t + fi * 0.7) * 1.5
		draw_circle(Vector2(fx, fy), fsize, COL_FIRE_ORANGE if i % 2 == 0 else COL_FIRE_RED)

func _draw_kuali(cx: float, cy: float) -> void:
	var kuali_points: PackedVector2Array = PackedVector2Array()
	for i: int in range(17):
		var angle: float = PI + PI * float(i) / 16.0
		kuali_points.append(Vector2(cx + cos(angle) * 20.0, cy + sin(angle) * 10.0))
	draw_colored_polygon(kuali_points, COL_KUALI_BODY)
	draw_line(Vector2(cx - 20.0, cy), Vector2(cx + 20.0, cy), COL_KUALI_RIM, 2.0)
	draw_line(Vector2(cx - 20.0, cy), Vector2(cx - 24.0, cy - 2.0), COL_KUALI_RIM, 2.0)
	draw_line(Vector2(cx + 20.0, cy), Vector2(cx + 24.0, cy - 2.0), COL_KUALI_RIM, 2.0)

func _draw_soup(cx: float, cy: float) -> void:
	var soup_points: PackedVector2Array = PackedVector2Array()
	for i: int in range(13):
		var angle: float = PI + PI * float(i) / 12.0
		soup_points.append(Vector2(cx + cos(angle) * 17.0, cy + sin(angle) * 4.0 + 2.0))
	if soup_points.size() >= 3:
		draw_colored_polygon(soup_points, COL_SOUP)

func _draw_bubbles(cx: float, cy: float) -> void:
	for i: int in range(_bubble_positions.size()):
		var bp: Vector2 = _bubble_positions[i] as Vector2
		var bt: float = _bubble_timers[i] as float
		var bx: float = cx + bp.x + sin(bt * 3.0) * 2.0
		var by: float = cy + bp.y - fmod(bt * 4.0, 8.0)
		draw_circle(Vector2(bx, by), 1.5, Color(1.0, 0.95, 0.8, (1.0 - fmod(bt * 0.5, 1.0)) * 0.5))

func _draw_steam(cx: float, cy: float) -> void:
	if _reduce_motion:
		return
	for i: int in range(4):
		var fi: float = float(i)
		var t: float = _time * 1.5 + fi * 0.8
		var sx: float = cx + sin(t) * 8.0 - 4.0 + fi * 4.0
		var sy: float = cy - fmod(t * 6.0, 25.0)
		draw_circle(Vector2(sx, sy), 2.5, Color(1.0, 1.0, 1.0, maxf(0.0, 0.3 * (1.0 - fmod(t * 0.3, 1.0)))))

func _draw_sutil(cx: float, cy: float, angle: float) -> void:
	var sa: float = angle * 0.5
	var hx: float = cx + cos(sa) * 14.0
	var hy: float = cy + sin(sa) * 3.0 - 8.0
	draw_line(Vector2(cx, cy), Vector2(hx, hy), Color(0.6, 0.45, 0.2, 0.9), 2.0)
	draw_circle(Vector2(hx, hy), 3.0, Color(0.5, 0.4, 0.15, 0.8))

# ── Title Gate Phase ─────────────────────────────────────────────────────────

func _draw_title_gate() -> void:
	draw_rect(Rect2(0, 0, VIEWPORT_W, VIEWPORT_H), Color(0.05, 0.04, 0.06, 1.0))
	var cx: float = float(VIEWPORT_W) / 2.0
	var font: Font = get_theme_default_font()
	var title: String = "KOKI DUNGEON"
	var title_w: Vector2 = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	var tx: float = cx - title_w.x / 2.0
	draw_string(font, Vector2(tx + 1.0, 91.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.3, 0.15, 0.0, _title_alpha * 0.5))
	draw_string(font, Vector2(tx, 90.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, _title_alpha))
	# Kuali silhouette
	var sil_cy: float = 110.0
	for i: int in range(8):
		var a1: float = PI + PI * float(i) / 7.0
		var a2: float = PI + PI * float(i + 1) / 7.0
		draw_line(Vector2(cx + cos(a1) * 10.0, sil_cy + sin(a1) * 5.0), Vector2(cx + cos(a2) * 10.0, sil_cy + sin(a2) * 5.0), Color(0.8, 0.6, 0.2, _title_alpha * 0.4), 1.0)
	draw_line(Vector2(cx - 8.0, sil_cy - 10.0), Vector2(cx + 4.0, sil_cy + 4.0), Color(0.8, 0.6, 0.2, _title_alpha * 0.4), 1.0)
	draw_line(Vector2(cx + 8.0, sil_cy - 10.0), Vector2(cx - 4.0, sil_cy + 4.0), Color(0.8, 0.6, 0.2, _title_alpha * 0.4), 1.0)
	var sub: String = "Sedekah Dapur Dungeon Rahayu"
	var sub_w: Vector2 = font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
	draw_string(font, Vector2(cx - sub_w.x / 2.0, sil_cy + 18.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(COL_SUBTITLE.r, COL_SUBTITLE.g, COL_SUBTITLE.b, _title_alpha * 0.8))
	var pulse: float = 0.5 + 0.5 * sin(_title_pulse_time * 3.0)
	var prompt: String = "KLIK ATAU TEKAN TOMBOL APA SAJA UNTUK MEMBUKA LAPAK"
	var prompt_w: Vector2 = font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
	draw_string(font, Vector2(cx - prompt_w.x / 2.0, 200.0), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.95, 0.85, pulse * _title_alpha))

# ── Menu Phase — Diorama Background ─────────────────────────────────────────

func _draw_diorama_bg() -> void:
	# Gradient
	var steps: int = 16
	var step_h: float = float(VIEWPORT_H) / float(steps)
	for i: int in range(steps):
		var t: float = float(i) / float(steps)
		draw_rect(Rect2(0, t * float(VIEWPORT_H), VIEWPORT_W, step_h + 1.0), COL_DUNGEON_TOP.lerp(COL_DUNGEON_BOT, t))
	# Stalactites
	for i: int in range(_stalactite_xs.size()):
		var sx: float = _stalactite_xs[i] as float
		var sh: float = _stalactite_heights[i] as float
		var sway: float = sin(_time * 0.3 + float(i)) * 1.0 if not _reduce_motion else 0.0
		draw_colored_polygon(PackedVector2Array([Vector2(sx - 3.0 + sway, 0.0), Vector2(sx + 3.0 + sway, 0.0), Vector2(sx + sway, sh)]), COL_STALACTITE)
	# Ground
	draw_rect(Rect2(0, VIEWPORT_H - 20, VIEWPORT_W, 20), Color(0.08, 0.1, 0.07, 1.0))
	draw_rect(Rect2(0, VIEWPORT_H - 22, VIEWPORT_W, 3), Color(0.15, 0.2, 0.12, 1.0))
	# Mushrooms
	for m: Dictionary in _mushroom_data:
		var mx: float = m["x"] as float
		var my: float = m["y"] as float
		var mcol: Color = m["col"] as Color
		var msize: float = m["size"] as float
		var glow: float = 0.6 + 0.4 * sin(_time * 1.5 + (m["phase"] as float))
		draw_line(Vector2(mx, my), Vector2(mx, my + msize), Color(0.4, 0.35, 0.25, 0.8), 1.0)
		draw_circle(Vector2(mx, my), msize * 0.6, Color(mcol.r, mcol.g, mcol.b, glow))
		if not _reduce_motion:
			draw_circle(Vector2(mx, my), msize * 1.2, Color(mcol.r, mcol.g, mcol.b, glow * 0.15))
	# Spores
	if not _reduce_motion:
		for pos: Vector2 in _spore_positions:
			draw_circle(pos, 1.0, COL_SPORE_GOLD if int(pos.x) % 2 == 0 else COL_SPORE_GREEN)
	# Gerobak
	_draw_gerobak(370.0, float(VIEWPORT_H) - 55.0)
	# Characters
	_draw_cook_char(340.0, float(VIEWPORT_H) - 38.0 + _rangga_bob, COL_RANGGA_BLUE, "R")
	_draw_cook_char(360.0, float(VIEWPORT_H) - 38.0 + _sekar_bob, COL_SEKAR_ORANGE, "S")
	# Goblin
	_draw_goblin_peek(465.0, float(VIEWPORT_H) - 40.0)

func _draw_gerobak(gx: float, gy: float) -> void:
	draw_rect(Rect2(gx, gy, 60.0, 30.0), COL_GEROBAK_WOOD)
	draw_rect(Rect2(gx + 1.0, gy + 1.0, 58.0, 28.0), COL_GEROBAK_DARK)
	draw_rect(Rect2(gx + 2.0, gy + 2.0, 56.0, 26.0), COL_GEROBAK_WOOD)
	draw_rect(Rect2(gx - 2.0, gy - 3.0, 64.0, 4.0), COL_GEROBAK_WOOD.lightened(0.2))
	draw_circle(Vector2(gx + 10.0, gy + 32.0), 4.0, Color(0.3, 0.2, 0.1, 1.0))
	draw_circle(Vector2(gx + 50.0, gy + 32.0), 4.0, Color(0.3, 0.2, 0.1, 1.0))
	draw_circle(Vector2(gx + 10.0, gy + 32.0), 2.0, COL_GEROBAK_WOOD)
	draw_circle(Vector2(gx + 50.0, gy + 32.0), 2.0, COL_GEROBAK_WOOD)
	var roof_pts: PackedVector2Array = PackedVector2Array([Vector2(gx - 4.0, gy - 3.0), Vector2(gx + 30.0, gy - 20.0), Vector2(gx + 64.0, gy - 3.0)])
	draw_colored_polygon(roof_pts, Color(0.65, 0.2, 0.15, 0.9))
	draw_line(Vector2(gx - 4.0, gy - 3.0), Vector2(gx + 30.0, gy - 20.0), Color(0.8, 0.3, 0.2, 1.0), 1.0)
	draw_line(Vector2(gx + 30.0, gy - 20.0), Vector2(gx + 64.0, gy - 3.0), Color(0.8, 0.3, 0.2, 1.0), 1.0)
	var lamp_x: float = gx + 55.0 + sin(_time * 1.5) * 2.0
	draw_line(Vector2(gx + 55.0, gy - 20.0), Vector2(lamp_x, gy - 14.0), Color(0.4, 0.3, 0.15, 0.8), 1.0)
	draw_circle(Vector2(lamp_x, gy - 14.0), 3.0, COL_DAMAR)
	if not _reduce_motion:
		draw_circle(Vector2(lamp_x, gy - 14.0), 20.0, Color(1.0, 0.85, 0.5, 0.1 + 0.05 * sin(_time * 2.0)))
		for i: int in range(3):
			var st: float = _time * 1.0 + float(i) * 1.2
			draw_circle(Vector2(gx + 20.0 + float(i) * 10.0 + sin(st) * 3.0, gy - 5.0 - fmod(st * 5.0, 20.0)), 2.0, Color(1.0, 1.0, 1.0, maxf(0.0, 0.25 * (1.0 - fmod(st * 0.3, 1.0)))))

func _draw_cook_char(cx: float, cy: float, col: Color, letter: String) -> void:
	draw_rect(Rect2(cx - 6.0, cy - 12.0, 12.0, 12.0), col)
	draw_circle(Vector2(cx, cy - 15.0), 4.0, col.lightened(0.2))
	draw_string(get_theme_default_font(), Vector2(cx - 3.0, cy - 3.0), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

func _draw_goblin_peek(gx: float, gy: float) -> void:
	var peek_x: float = gx + (1.0 - _goblin_peek) * 12.0
	draw_rect(Rect2(peek_x, gy, 10.0, 14.0), COL_GOBLIN_RED)
	draw_circle(Vector2(peek_x + 3.0, gy + 4.0), 1.5, Color.WHITE)
	draw_circle(Vector2(peek_x + 7.0, gy + 4.0), 1.5, Color.WHITE)
	draw_circle(Vector2(peek_x + 3.0, gy + 4.0), 0.8, Color.BLACK)
	draw_circle(Vector2(peek_x + 7.0, gy + 4.0), 0.8, Color.BLACK)
	if _goblin_showing_emote and _goblin_peek > 0.5:
		draw_rect(Rect2(peek_x - 12.0, gy - 10.0, 14.0, 10.0), Color(1.0, 1.0, 1.0, 0.9))
		draw_string(get_theme_default_font(), Vector2(peek_x - 10.0, gy - 2.0), "?!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.BLACK)

# ── Menu Buttons ─────────────────────────────────────────────────────────────

func _draw_menu_buttons() -> void:
	var font: Font = get_theme_default_font()
	draw_rect(Rect2(0, 75, 185, float(MENU_ITEMS.size()) * float(BUTTON_HEIGHT + BUTTON_SPACING) + 30.0), Color(0.0, 0.0, 0.0, 0.35))
	draw_string(font, Vector2(16.0, 85.0), "KOKI DUNGEON", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COL_GOLD)

	for i: int in range(MENU_ITEMS.size()):
		var item: Dictionary = MENU_ITEMS[i] as Dictionary
		var label: String = item["label"] as String
		var locked: bool = item.get("locked", false) as bool
		var bx: float = float(BUTTON_X) + (_button_offsets[i] as float)
		var by: float = float(BUTTON_Y_START + i * (BUTTON_HEIGHT + BUTTON_SPACING))
		var bw: float = float(BUTTON_WIDTH) * (_button_scales[i] as float)
		var bh: float = float(BUTTON_HEIGHT)
		var is_selected: bool = (i == _selected_index)
		var bg_col: Color = COL_LOCKED_BG if locked else (COL_BUTTON_HOVER_BG if is_selected else COL_BUTTON_BG)
		var border_col: Color = COL_LOCKED_BORDER if locked else (COL_BUTTON_HOVER_BORDER if is_selected else COL_BUTTON_BORDER)
		var text_col: Color = COL_TEXT_LOCKED if locked else COL_TEXT
		draw_rect(Rect2(bx, by, bw, bh), bg_col)
		draw_rect(Rect2(bx, by, bw, 1.0), border_col)
		draw_rect(Rect2(bx, by + bh - 1.0, bw, 1.0), border_col)
		draw_rect(Rect2(bx, by, 1.0, bh), border_col)
		draw_rect(Rect2(bx + bw - 1.0, by, 1.0, bh), border_col)
		if is_selected and not locked:
			draw_circle(Vector2(bx - 9.0, by + bh / 2.0), 2.0, COL_GOLD)
			draw_line(Vector2(bx - 8.0, by + bh / 2.0), Vector2(bx - 2.0, by + bh / 2.0), COL_GOLD, 1.0)
		if locked:
			label = label + " [SEGERA]"
		draw_string(font, Vector2(bx + 6.0, by + bh - 5.0), label, HORIZONTAL_ALIGNMENT_LEFT, int(bw - 10.0), 8, text_col)

# ── Footer Bar ───────────────────────────────────────────────────────────────

func _draw_footer() -> void:
	var font: Font = get_theme_default_font()
	var fy: float = float(VIEWPORT_H) - 14.0
	draw_rect(Rect2(0, fy, VIEWPORT_W, 14), COL_FOOTER_BG)
	draw_string(font, Vector2(4.0, fy + 10.0), "v0.2.0-m2 (Wajib 2 Pemain Co-op)", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_VERSION)
	draw_string(font, Vector2(280.0, fy + 10.0), "WASD/Panah: Navigasi  |  Enter/Klik: Pilih  |  Esc: Kembali", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_HINT)

# ══════════════════════════════════════════════════════════════════════════════
# UTILITY
# ══════════════════════════════════════════════════════════════════════════════

func _get_autoload(autoload_name: String) -> Node:
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree and (loop as SceneTree).root:
		return (loop as SceneTree).root.get_node_or_null(autoload_name)
	return null

## Test-only helpers
func get_phase() -> int:
	return _phase

func get_loading_progress() -> float:
	return _loading_progress

func get_submenu_active() -> String:
	return _submenu_active

func skip_intro() -> void:
	_loading_skip_requested = true
	_loading_progress = 1.0
	_phase = Phase.TITLE_GATE
	_title_alpha = 1.0

func advance_to_menu() -> void:
	skip_intro()
	_enter_menu_phase()
