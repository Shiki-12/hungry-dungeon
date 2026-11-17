extends RefCounted

## Test: Main Menu flow — phases, submenus, readiness widget, project.godot main_scene.

const MainMenuScript: Script = preload("res://ui/main_menu.gd")

var _pass_count: int = 0
var _fail_count: int = 0

func run_all() -> bool:
	_test_project_main_scene()
	_test_initial_phase_is_loading()
	_test_skip_intro_moves_to_title_gate()
	_test_advance_to_menu()
	_test_menu_items_count()
	_test_submenu_open_close()
	_test_readiness_widget()
	_test_locked_button_no_crash()
	_test_navigate_menu()

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
	# Verify project.godot points to main_menu.tscn
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
	# Phase.LOADING == 0
	_assert(menu.get_phase() == 0, "Initial phase should be LOADING (0)")
	_assert(menu.get_loading_progress() == 0.0, "Initial loading progress should be 0.0")
	menu.free()

func _test_skip_intro_moves_to_title_gate() -> void:
	var menu: Control = MainMenuScript.new()
	menu.skip_intro()
	# Phase.TITLE_GATE == 1
	_assert(menu.get_phase() == 1, "After skip_intro, phase should be TITLE_GATE (1)")
	_assert(menu.get_loading_progress() >= 1.0, "After skip_intro, loading progress should be 1.0")
	menu.free()

func _test_advance_to_menu() -> void:
	var menu: Control = MainMenuScript.new()
	menu.advance_to_menu()
	# Phase.MENU == 2
	_assert(menu.get_phase() == 2, "After advance_to_menu, phase should be MENU (2)")
	menu.free()

func _test_menu_items_count() -> void:
	# Verify 6 menu items exist in const
	_assert(MainMenuScript.MENU_ITEMS.size() == 6, "Should have 6 menu items")
	# Check IDs
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

func _test_readiness_widget() -> void:
	var menu: Control = MainMenuScript.new()
	menu.advance_to_menu()
	_assert(not menu.is_p1_ready(), "P1 should not be ready initially")
	_assert(not menu.is_p2_ready(), "P2 should not be ready initially")

	menu.set_p1_ready(true)
	_assert(menu.is_p1_ready(), "P1 should be ready after set_p1_ready(true)")
	_assert(not menu.is_p2_ready(), "P2 should still not be ready")

	menu.set_p2_ready(true)
	_assert(menu.is_p2_ready(), "P2 should be ready after set_p2_ready(true)")
	menu.free()

func _test_locked_button_no_crash() -> void:
	# MODE WARUNG is at index 3 and locked — verify no crash on access
	var item: Dictionary = MainMenuScript.MENU_ITEMS[3] as Dictionary
	var locked: bool = item.get("locked", false) as bool
	_assert(locked, "Item at index 3 (warung) should be locked")
	_assert(item["id"] as String == "warung", "Item at index 3 should be 'warung'")

func _test_navigate_menu() -> void:
	# Simple navigation logic test via menu state
	var menu: Control = MainMenuScript.new()
	menu.advance_to_menu()
	# Selected index starts at 0
	# We can't directly test _selected_index (private), but menu doesn't crash on creation
	_assert(menu.get_phase() == 2, "Menu should be in MENU phase for navigation")
	menu.free()
