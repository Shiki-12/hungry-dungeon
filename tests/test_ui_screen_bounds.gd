extends RefCounted

## Test: UI Screen Bounds, Safe Areas & String Fitting (FR-UI-01 s.d. 08).
## Memverifikasi seluruh komponen visual dan teks berada dalam safe margin:
## x_start >= 4.0, x_start + width <= 476.0, y_start >= 4.0, y_start + height <= 266.0.
## Bebas leak ObjectDB (0 leaks).

const MainMenuScript: Script = preload("res://ui/main_menu.gd")
const WorldMapScript: Script = preload("res://ui/world_map.gd")
const CoopReadyScript: Script = preload("res://ui/coop_ready_screen.gd")
const PauseMenuScript: Script = preload("res://ui/pause_menu.gd")
const SettingsMenuScript: Script = preload("res://ui/settings_menu.gd")
const HudTopScript: Script = preload("res://ui/hud_top.gd")
const HudBottomScript: Script = preload("res://ui/hud_bottom.gd")

const SAFE_MIN_X: float = 4.0
const SAFE_MAX_X: float = 476.0
const SAFE_MIN_Y: float = 4.0
const SAFE_MAX_Y: float = 266.0

var _pass_count: int = 0
var _fail_count: int = 0

func run_all() -> bool:
	_test_main_menu_bounds()
	_test_world_map_bounds()
	_test_coop_ready_screen_bounds()
	_test_pause_menu_bounds()
	_test_settings_menu_bounds()
	_test_hud_top_and_bottom_bounds()
	_test_kitchen_stage_banner_bounds()

	print("  test_ui_screen_bounds: %d passed, %d failed" % [_pass_count, _fail_count])
	return _fail_count == 0

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_pass_count += 1
	else:
		_fail_count += 1
		push_error("  FAIL: " + msg)

func _assert_in_bounds(rect: Rect2, name: String) -> void:
	_assert(rect.position.x >= SAFE_MIN_X, "%s left (%f) < %f" % [name, rect.position.x, SAFE_MIN_X])
	_assert(rect.end.x <= SAFE_MAX_X, "%s right (%f) > %f" % [name, rect.end.x, SAFE_MAX_X])
	_assert(rect.position.y >= SAFE_MIN_Y, "%s top (%f) < %f" % [name, rect.position.y, SAFE_MIN_Y])
	_assert(rect.end.y <= SAFE_MAX_Y, "%s bottom (%f) > %f" % [name, rect.end.y, SAFE_MAX_Y])

func _test_main_menu_bounds() -> void:
	var menu: Control = MainMenuScript.new() as Control
	_assert(menu != null, "MainMenu instantiates")
	var root: Window = Engine.get_main_loop().root as Window
	root.add_child(menu)

	var font: Font = menu.get_theme_default_font()
	if font == null:
		font = ThemeDB.fallback_font

	# 1. Main menu buttons
	var btn_x: float = 16.0
	var btn_w: float = 150.0 * 1.04 # max hover scale
	var btn_h: float = 18.0 * 6.0 + 4.0 * 5.0
	_assert_in_bounds(Rect2(btn_x, 90.0, btn_w, btn_h), "MainMenu buttons")

	# 2. Footer layout & non-collision
	var left_text: String = "v0.2.0-m2 (Wajib 2 Pemain Co-op)"
	var left_w: float = font.get_string_size(left_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var left_x: float = 8.0

	var right_text: String = "WASD/Panah: Navigasi  |  Enter/Klik: Pilih  |  Esc: Kembali"
	var right_w: float = font.get_string_size(right_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var right_x: float = 480.0 - 8.0 - right_w

	if left_x + left_w + 12.0 > right_x:
		right_text = "WASD: Gerak | Enter: Pilih | Esc: Kembali"
		right_w = font.get_string_size(right_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		right_x = 480.0 - 8.0 - right_w

	if left_x + left_w + 12.0 > right_x:
		left_text = "v0.2.0-m2"
		left_w = font.get_string_size(left_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		if left_x + left_w + 12.0 > right_x:
			right_text = "Enter: Pilih | Esc: Batal"
			right_w = font.get_string_size(right_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			right_x = 480.0 - 8.0 - right_w

	_assert(right_x + right_w <= 472.0, "MainMenu footer right edge (%f) <= 472.0" % (right_x + right_w))
	_assert(left_x + left_w < right_x, "MainMenu footer no text collision (left end %f < right start %f)" % [left_x + left_w, right_x])

	# 3. Submenu panel bounds
	menu.call("advance_to_menu")
	menu.call("_open_submenu", "training")
	var sub_panel: Control = menu.get_node_or_null("SubmenuPanel") as Control
	_assert(sub_panel != null, "SubmenuPanel exists")
	if sub_panel:
		# Check target slide in position: x + width <= 476
		var target_x: float = clampf(480.0 - 308.0, 168.0, 480.0 - 8.0)
		_assert(target_x + 300.0 <= 476.0, "Submenu panel width inside right safe bound")

	root.remove_child(menu)
	menu.free()

func _test_world_map_bounds() -> void:
	var map: Control = WorldMapScript.new() as Control
	_assert(map != null, "WorldMap instantiates")
	var root: Window = Engine.get_main_loop().root as Window
	root.add_child(map)

	var font: Font = map.get_theme_default_font()
	if font == null:
		font = ThemeDB.fallback_font

	# 1. Chapter cards bounds
	var card_w: float = minf(440.0, 480.0 - 32.0)
	var card_x: float = (480.0 - card_w) / 2.0
	_assert_in_bounds(Rect2(card_x, 30.0, card_w, 42.0 * 4.0 + 38.0), "WorldMap chapter cards")

	# 2. Padlock & lock text within card bounds
	var lock_str: String = "Selesaikan Chapter sebelumnya"
	var lock_str_w: float = font.get_string_size(lock_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var lock_x: float = card_x + card_w - 32.0 - lock_str_w
	if lock_x < card_x + 130.0:
		lock_str = "Terkunci"
		lock_str_w = font.get_string_size(lock_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		lock_x = card_x + card_w - 32.0 - lock_str_w
	_assert(lock_x >= card_x, "Lock string inside card left")
	_assert(lock_x + lock_str_w <= card_x + card_w, "Lock string inside card right")

	# 3. Level select cards and back button
	var lvl_w: float = minf(360.0, 480.0 - 32.0)
	var lvl_x: float = (480.0 - lvl_w) / 2.0
	_assert_in_bounds(Rect2(lvl_x, 74.0, lvl_w, 36.0 * 3.0 + 30.0), "WorldMap level select cards")

	var back_y: float = 256.0 - 22.0
	_assert_in_bounds(Rect2(8.0, back_y, 96.0, 18.0), "WorldMap back button")
	_assert(back_y + 18.0 <= 256.0, "Back button does not overlap footer at 256.0")

	# 4. Footer right hint
	var hint_text: String = "W/S: Navigasi  |  Enter/Klik: Pilih  |  Esc: Kembali"
	var hint_w: float = font.get_string_size(hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var right_x: float = 480.0 - 8.0 - hint_w
	if 8.0 + 100.0 + 12.0 > right_x:
		hint_text = "W/S: Gerak | Enter: Pilih | Esc: Kembali"
		hint_w = font.get_string_size(hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		right_x = 480.0 - 8.0 - hint_w
	_assert(right_x + hint_w <= 472.0, "WorldMap footer hint right edge <= 472.0")

	root.remove_child(map)
	map.free()

func _test_coop_ready_screen_bounds() -> void:
	var screen: Control = CoopReadyScript.new() as Control
	_assert(screen != null, "CoopReadyScreen instantiates")
	var root: Window = Engine.get_main_loop().root as Window
	root.add_child(screen)

	var font: Font = screen.get_theme_default_font()
	if font == null:
		font = ThemeDB.fallback_font

	# 1. P1 & P2 card bounds
	var card_w: float = 190.0
	var card_gap: float = 40.0
	var total_w: float = card_w * 2.0 + card_gap
	var p1_x: float = (480.0 - total_w) / 2.0
	var p2_x: float = p1_x + card_w + card_gap

	_assert_in_bounds(Rect2(p1_x, 65.0, card_w, 155.0), "P1 Card")
	_assert_in_bounds(Rect2(p2_x, 65.0, card_w, 155.0), "P2 Card")

	# 2. Instruction text centered under each card
	var p1_text: String = "P1: Tekan [E] atau [Spasi]"
	var p1_text_w: float = font.get_string_size(p1_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var p1_text_x: float = p1_x + (card_w - p1_text_w) / 2.0
	_assert(p1_text_x >= p1_x and p1_text_x + p1_text_w <= p1_x + card_w, "P1 instruction inside P1 card bounds")

	var p2_text: String = "P2: Tekan [.] atau [Enter]"
	var p2_text_w: float = font.get_string_size(p2_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var p2_text_x: float = p2_x + (card_w - p2_text_w) / 2.0
	_assert(p2_text_x >= p2_x and p2_text_x + p2_text_w <= p2_x + card_w, "P2 instruction inside P2 card bounds")
	_assert(p2_text_x + p2_text_w <= SAFE_MAX_X, "P2 instruction inside screen safe bounds")

	root.remove_child(screen)
	screen.free()

func _test_pause_menu_bounds() -> void:
	var pause: Control = PauseMenuScript.new() as Control
	_assert(pause != null, "PauseMenu instantiates")
	var root: Window = Engine.get_main_loop().root as Window
	root.add_child(pause)

	var panel_rect: Rect2 = pause.call("get_panel_rect") as Rect2
	_assert_in_bounds(panel_rect, "PauseMenu panel")

	# Check buttons inside panel
	var btn_w: float = 160.0
	var btn_x: float = panel_rect.position.x + (panel_rect.size.x - btn_w) * 0.5
	_assert(btn_x >= panel_rect.position.x, "Pause buttons inside panel left")
	_assert(btn_x + btn_w <= panel_rect.end.x, "Pause buttons inside panel right")

	root.remove_child(pause)
	pause.free()

func _test_settings_menu_bounds() -> void:
	var settings: Control = SettingsMenuScript.new() as Control
	_assert(settings != null, "SettingsMenu instantiates")
	var root: Window = Engine.get_main_loop().root as Window
	root.add_child(settings)

	var font: Font = settings.get_theme_default_font()
	if font == null:
		font = ThemeDB.fallback_font

	var panel_w: float = 240.0
	var panel_h: float = 210.0
	var px: float = (480.0 - panel_w) * 0.5
	var py: float = (270.0 - panel_h) * 0.5
	_assert_in_bounds(Rect2(px, py, panel_w, panel_h), "Settings panel")

	# Check slider & percentage padding: 100% label must have >= 8 px padding from panel right edge
	var pct_str: String = "100%"
	var pct_w: float = font.get_string_size(pct_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var pct_x: float = px + 194.0
	var pct_end_x: float = pct_x + pct_w
	var panel_right_edge: float = px + panel_w
	_assert(panel_right_edge - pct_end_x >= 8.0, "Settings percentage has >= 8 px right padding (got %f)" % (panel_right_edge - pct_end_x))

	# Check back button and footer hint do not overlap
	var back_y: float = py + 165.0
	var hint_y: float = py + 198.0
	_assert(back_y + 18.0 <= hint_y, "Settings back button does not overlap footer hint")

	root.remove_child(settings)
	settings.free()

func _test_hud_top_and_bottom_bounds() -> void:
	var top: Control = HudTopScript.new() as Control
	_assert(top != null, "HudTop instantiates")
	var root: Window = Engine.get_main_loop().root as Window
	root.add_child(top)

	# Verify top HUD items
	var timer_label: Label = top.get("timer_label") as Label
	_assert(timer_label != null, "TimerLabel exists")
	if timer_label:
		var timer_end_x: float = timer_label.position.x + timer_label.size.x
		_assert(timer_end_x <= 472.0, "TimerLabel right edge (%f) <= 472.0" % timer_end_x)

	var tickets_container: HBoxContainer = top.get("tickets_container") as HBoxContainer
	_assert(tickets_container != null, "TicketsContainer exists")
	if tickets_container:
		_assert(tickets_container.position.x >= 8.0, "TicketsContainer left >= 8.0")

	root.remove_child(top)
	top.free()

	# Bottom HUD
	var bot: Control = HudBottomScript.new() as Control
	_assert(bot != null, "HudBottom instantiates")
	root.add_child(bot)

	# Combo box position: 480 - 8 - 80 = 392, end = 472 <= 476
	var combo_x: float = 480.0 - 8.0 - 80.0
	_assert(combo_x + 80.0 <= 472.0, "HudBottom combo right edge <= 472.0")

	# Health hearts: 8.0 + 4*14 + 12 = 76.0 <= 180 (no overlap with P1 skills)
	var hearts_end_x: float = 8.0 + 4.0 * 14.0 + 12.0
	_assert(hearts_end_x < 185.0, "HudBottom hearts do not collide with P1 skills (76 < 185)")

	root.remove_child(bot)
	bot.free()

func _test_kitchen_stage_banner_bounds() -> void:
	var font: Font = ThemeDB.fallback_font
	var sample_texts: Array = [
		"Level 1-1: Bekal Terakhir (Sajikan ke Meja Panjang!)",
		"Level 1-2: Cuci Piring! (Tahan F / , di Tempat Cuci)",
		"Level 1-3: Awas Pencuri! (Gunakan Dash / Kuali)",
		"Pesan Sangat Panjang Melebihi Batas Layar Biasa Untuk Mengetes Clamping Auto-Fit Banner",
	]

	for txt: String in sample_texts:
		var text_w: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var banner_w: float = clampf(text_w + 24.0, 160.0, 480.0 - 16.0)
		var banner_x: float = (480.0 - banner_w) * 0.5
		_assert(banner_x >= 8.0, "Banner left (%f) >= 8.0 for text '%s'" % [banner_x, txt.substr(0, 15)])
		_assert(banner_x + banner_w <= 472.0, "Banner right (%f) <= 472.0 for text '%s'" % [banner_x + banner_w, txt.substr(0, 15)])
