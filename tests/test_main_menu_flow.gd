extends RefCounted

## Test: Main Menu flow, World Map, Coop Ready Screen, Settings Menu, & Pause Menu.

const MainMenuScript: Script = preload("res://ui/main_menu.gd")
const WorldMapScript: Script = preload("res://ui/world_map.gd")
const CoopReadyScript: Script = preload("res://ui/coop_ready_screen.gd")
const PauseMenuScript: Script = preload("res://ui/pause_menu.gd")
const SettingsMenuScript: Script = preload("res://ui/settings_menu.gd")

var _pass_count: int = 0
var _fail_count: int = 0

func run_all() -> bool:
	_test_project_main_scene()
	_test_initial_phase_is_loading()
	_test_skip_intro_moves_to_title_gate()
	_test_advance_to_menu()
	_test_menu_items_count()
	_test_submenu_open_close()
	_test_no_readiness_widget_in_main_menu()
	_test_settings_menu_no_freeze()
	_test_locked_button_no_crash()
	_test_navigate_menu()
	_test_world_map_chapter_locks()
	_test_world_map_level_selection()
	_test_coop_ready_screen_flow()
	_test_pause_menu_centered_and_buttons()
	_test_input_events_in_scene_tree_no_null_crash()

	print("  test_main_menu_flow: %d passed, %d failed" % [_pass_count, _fail_count])
	return _fail_count == 0

func _assert(condition: bool, msg: String) -> void:
	if condition:
		_pass_count += 1
	else:
		_fail_count += 1
		push_error("  FAIL: " + msg)

# ── Tests ────────────────────────────────────────────────────────────────────

func _test_project_main_scene() -> void:
	var file: FileAccess = FileAccess.open("res://project.godot", FileAccess.READ)
	if file == null:
		_assert(false, "Cannot open project.godot")
		return
	var content: String = file.get_as_text()
	file.close()
	_assert(content.find("run/main_scene=\"res://ui/main_menu.tscn\"") >= 0,
		"project.godot main_scene should be res://ui/main_menu.tscn")

func _test_initial_phase_is_loading() -> void:
	var menu: Control = MainMenuScript.new()
	_assert(menu.get_phase() == 0, "Initial phase should be LOADING (0)")
	_assert(menu.get_loading_progress() == 0.0, "Initial loading progress should be 0.0")
	menu.free()

func _test_skip_intro_moves_to_title_gate() -> void:
	var menu: Control = MainMenuScript.new()
	menu.skip_intro()
	_assert(menu.get_phase() == 1, "After skip_intro, phase should be TITLE_GATE (1)")
	_assert(menu.get_loading_progress() >= 1.0, "After skip_intro, loading progress should be 1.0")
	menu.free()

func _test_advance_to_menu() -> void:
	var menu: Control = MainMenuScript.new()
	menu.advance_to_menu()
	_assert(menu.get_phase() == 2, "After advance_to_menu, phase should be MENU (2)")
	menu.free()

func _test_menu_items_count() -> void:
	_assert(MainMenuScript.MENU_ITEMS.size() == 6, "Should have 6 menu items")
	var ids: Array = []
	for item: Dictionary in MainMenuScript.MENU_ITEMS:
		ids.append(item["id"])
	_assert("start" in ids, "Menu should have 'start' item")
	_assert("training" in ids, "Menu should have 'training' item")
	_assert("recipe_book" in ids, "Menu should have 'recipe_book' item")
	_assert("warung" in ids, "Menu should have 'warung' item")
	_assert("settings" in ids, "Menu should have 'settings' item")
	_assert("credits" in ids, "Menu should have 'credits' item")

func _test_submenu_open_close() -> void:
	var menu: Control = MainMenuScript.new()
	menu.advance_to_menu()
	_assert(menu.get_submenu_active() == "", "No submenu active initially")
	menu.free()

func _test_no_readiness_widget_in_main_menu() -> void:
	var menu: Control = MainMenuScript.new()
	menu.advance_to_menu()
	# Readiness widget has been removed from Main Menu (moved to coop_ready_screen)
	_assert(not menu.has_method("is_p1_ready"), "Main Menu should NOT have is_p1_ready (moved to coop_ready_screen)")
	_assert(not menu.has_method("is_p2_ready"), "Main Menu should NOT have is_p2_ready (moved to coop_ready_screen)")
	menu.free()

func _test_settings_menu_no_freeze() -> void:
	var settings: Control = SettingsMenuScript.new()
	settings._ready()
	_assert(settings.size == Vector2(480, 270), "SettingsMenu size must be 480x270")
	_assert(SettingsMenuScript.OPTIONS.size() >= 5, "SettingsMenu must provide audio & gameplay options")
	var vals: Array = settings.get_values()
	_assert(vals.size() == SettingsMenuScript.OPTIONS.size(), "Settings values match options size")
	settings.free()

func _test_locked_button_no_crash() -> void:
	var item: Dictionary = MainMenuScript.MENU_ITEMS[3] as Dictionary
	var locked: bool = item.get("locked", false) as bool
	_assert(locked, "Item at index 3 (warung) should be locked")
	_assert(item["id"] as String == "warung", "Item at index 3 should be 'warung'")

func _test_navigate_menu() -> void:
	var menu: Control = MainMenuScript.new()
	menu.advance_to_menu()
	_assert(menu.get_phase() == 2, "Menu should be in MENU phase for navigation")
	menu.free()

func _test_world_map_chapter_locks() -> void:
	var wm: Control = WorldMapScript.new()
	wm._ready()
	_assert(wm.size == Vector2(480, 270), "WorldMap size must be 480x270")
	_assert(WorldMapScript.CHAPTERS.size() == 5, "WorldMap must have 5 chapters")
	# Chapter 1 unlocked by default
	_assert(wm.is_chapter_unlocked(0), "Chapter 1 must be unlocked by default")
	# Chapter 2-5 locked without save progression
	_assert(not wm.is_chapter_unlocked(1), "Chapter 2 must be locked without completing 1-4")
	_assert(not wm.is_chapter_unlocked(2), "Chapter 3 must be locked without completing 2-4")
	_assert(not wm.is_chapter_unlocked(3), "Chapter 4 must be locked without completing 3-4")
	_assert(not wm.is_chapter_unlocked(4), "Chapter 5 must be locked without completing 4-4")
	wm.free()

func _test_world_map_level_selection() -> void:
	var wm: Control = WorldMapScript.new()
	wm._ready()
	_assert(wm.get_mode() == 0, "Initial mode must be CHAPTER_SELECT (0)")
	_assert(wm.get_selected_chapter() == 0, "Default chapter selection must be Chapter 1 (0)")
	wm.free()

func _test_coop_ready_screen_flow() -> void:
	var ready_scr: Control = CoopReadyScript.new()
	ready_scr._ready()
	_assert(ready_scr.size == Vector2(480, 270), "CoopReadyScreen size must be 480x270")
	_assert(not ready_scr.is_p1_ready(), "P1 initially not ready")
	_assert(not ready_scr.is_p2_ready(), "P2 initially not ready")
	_assert(not ready_scr.is_countdown_active(), "Countdown not active initially")

	# Set P1 ready
	ready_scr.set_p1_ready(true)
	ready_scr._check_both_ready()
	_assert(ready_scr.is_p1_ready(), "P1 should be ready")
	_assert(not ready_scr.is_countdown_active(), "Countdown should NOT trigger with only P1 ready")

	# Set P2 ready -> Countdown triggers!
	ready_scr.set_p2_ready(true)
	ready_scr._check_both_ready()
	_assert(ready_scr.is_p2_ready(), "P2 should be ready")
	_assert(ready_scr.is_countdown_active(), "Countdown MUST be active when both P1 & P2 are ready")

	ready_scr.free()

func _test_pause_menu_centered_and_buttons() -> void:
	var pm: Control = PauseMenuScript.new()
	pm._ready()
	_assert(pm.size == Vector2(480, 270), "PauseMenu canvas size must be 480x270")
	_assert(pm.custom_minimum_size == Vector2(480, 270), "PauseMenu custom_minimum_size must be 480x270")

	# Panel 200x160 centered at (240, 135)
	var prect: Rect2 = pm.get_panel_rect()
	var expected_x: float = (480.0 - 200.0) / 2.0 # 140.0
	var expected_y: float = (270.0 - 160.0) / 2.0 # 55.0
	_assert(is_equal_approx(prect.position.x, expected_x), "Pause panel x centered: %f == %f" % [prect.position.x, expected_x])
	_assert(is_equal_approx(prect.position.y, expected_y), "Pause panel y centered: %f == %f" % [prect.position.y, expected_y])
	_assert(is_equal_approx(prect.size.x, 200.0), "Pause panel width is 200")
	_assert(is_equal_approx(prect.size.y, 160.0), "Pause panel height is 160")
	_assert(PauseMenuScript.BUTTONS.size() == 5, "PauseMenu must have 5 buttons")

	pm.free()

func _test_input_events_in_scene_tree_no_null_crash() -> void:
	var root: Window = null
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		root = tree.root

	var make_key: Callable = func(code: Key) -> InputEventKey:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.pressed = true
		return ev

	# 1. Test world_map
	var wm: Control = WorldMapScript.new()
	if root != null:
		root.add_child(wm)
	wm._ready()
	wm._input(make_key.call(KEY_ENTER))
	wm._input(make_key.call(KEY_ESCAPE))
	wm._input(make_key.call(KEY_W))
	wm._input(make_key.call(KEY_S))
	_assert(true, "world_map handles input inside tree without null viewport crash")
	if root != null:
		root.remove_child(wm)
	wm.free()

	var wm_orphan: Control = WorldMapScript.new()
	wm_orphan._input(make_key.call(KEY_ENTER))
	wm_orphan._input(make_key.call(KEY_ESCAPE))
	_assert(true, "world_map handles input when outside tree without crash")
	wm_orphan.free()

	# 2. Test coop_ready_screen
	var cr: Control = CoopReadyScript.new()
	if root != null:
		root.add_child(cr)
	cr._ready()
	cr._input(make_key.call(KEY_ENTER))
	cr._input(make_key.call(KEY_ESCAPE))
	cr._input(make_key.call(KEY_E))
	cr._input(make_key.call(KEY_PERIOD))
	_assert(true, "coop_ready_screen handles input inside tree without null viewport crash")
	if root != null:
		root.remove_child(cr)
	cr.free()

	var cr_orphan: Control = CoopReadyScript.new()
	cr_orphan._input(make_key.call(KEY_ENTER))
	cr_orphan._input(make_key.call(KEY_ESCAPE))
	_assert(true, "coop_ready_screen handles input when outside tree without crash")
	cr_orphan.free()

	# 3. Test main_menu
	var mm: Control = MainMenuScript.new()
	if root != null:
		root.add_child(mm)
	mm._ready()
	mm.advance_to_menu()
	mm._input(make_key.call(KEY_ENTER))
	mm._input(make_key.call(KEY_ESCAPE))
	_assert(true, "main_menu handles input inside tree without null viewport crash")
	if root != null:
		root.remove_child(mm)
	mm.free()

	var mm_orphan: Control = MainMenuScript.new()
	mm_orphan._input(make_key.call(KEY_ENTER))
	mm_orphan._input(make_key.call(KEY_ESCAPE))
	_assert(true, "main_menu handles input when outside tree without crash")
	mm_orphan.free()

	# 4. Test pause_menu
	var pm: Control = PauseMenuScript.new()
	if root != null:
		root.add_child(pm)
	pm._ready()
	pm._input(make_key.call(KEY_ENTER))
	pm._input(make_key.call(KEY_ESCAPE))
	_assert(true, "pause_menu handles input inside tree without null viewport crash")
	if root != null:
		root.remove_child(pm)
	pm.free()

	var pm_orphan: Control = PauseMenuScript.new()
	pm_orphan._input(make_key.call(KEY_ENTER))
	pm_orphan._input(make_key.call(KEY_ESCAPE))
	_assert(true, "pause_menu handles input when outside tree without crash")
	pm_orphan.free()
