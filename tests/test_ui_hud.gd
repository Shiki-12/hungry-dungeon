class_name TestUiHud
extends RefCounted

## Unit test untuk M2.4: UI Theme, HUD Top (480x30), HUD Bottom (480x16), dan Balon Pesanan (FR-UI-01 s.d. 08).

const HudTopScript: Script = preload("res://ui/hud_top.gd")
const HudBottomScript: Script = preload("res://ui/hud_bottom.gd")
const OrderBubbleScript: Script = preload("res://view/order_bubble_view.gd")
const PauseMenuScript: Script = preload("res://ui/pause_menu.gd")

static func run_all() -> bool:
	if not _test_theme_resource():
		return false
	if not _test_hud_top_dimensions_and_updates():
		return false
	if not _test_hud_bottom_dimensions_and_cooldown():
		return false
	if not _test_order_bubble_offsets_and_patience():
		return false
	if not _test_pause_menu_centered():
		return false
	return true

static func _test_theme_resource() -> bool:
	var theme: Theme = load("res://ui/theme.tres") as Theme
	if theme == null:
		push_error("Theme res://ui/theme.tres could not be loaded")
		return false
	if theme.default_font_size != 8:
		push_error("Theme default font size should be 8 px (FR-UI-05), got: %d" % theme.default_font_size)
		return false
	return true

static func _test_hud_top_dimensions_and_updates() -> bool:
	var hud: Control = HudTopScript.new()
	# Verifikasi ukuran 480x30 px (FR-UI-01)
	if not hud.custom_minimum_size.is_equal_approx(Vector2(480.0, 30.0)):
		push_error("HUD Top size mismatch: %s" % hud.custom_minimum_size)
		hud.free()
		return false

	hud._ready()

	# Test set skor dan timer
	hud.set_score(1500)
	if hud.score_label.text != "SKOR: 1500":
		push_error("Score label text mismatch: %s" % hud.score_label.text)
		hud.free()
		return false

	hud.set_time(125.0) # 2 menit 5 detik -> 02:05
	if hud.timer_label.text != "02:05":
		push_error("Timer label text mismatch: %s" % hud.timer_label.text)
		hud.free()
		return false

	# Test maksimal 6 tiket pesanan
	var mock_tickets: Array = [
		{"order_id": 1, "recipe_id": &"recipe_nasi_goreng_jamur", "patience_pct": 0.8},
		{"order_id": 2, "recipe_id": &"recipe_tempe_mendoan", "patience_pct": 0.4},
		{"order_id": 3, "recipe_id": &"recipe_bubur_singkong", "patience_pct": 0.0},
	]
	hud.update_tickets(mock_tickets)
	if hud.active_tickets.size() != 3:
		push_error("HUD Top active tickets size mismatch")
		hud.free()
		return false

	hud.free()
	return true

static func _test_hud_bottom_dimensions_and_cooldown() -> bool:
	var hud: Control = HudBottomScript.new()
	# Verifikasi ukuran 480x16 px (FR-UI-02)
	if not hud.custom_minimum_size.is_equal_approx(Vector2(480.0, 16.0)):
		push_error("HUD Bottom size mismatch: %s" % hud.custom_minimum_size)
		hud.free()
		return false

	hud._ready()

	# Test Hati Dapur
	hud.set_hearts(4, 5)
	if hud.current_health != 4 or hud.max_health != 5:
		push_error("Hearts data mismatch")
		hud.free()
		return false

	# Test Cooldown Skill Rangga P1 Dash
	hud.set_cooldown(1, 1, 4.0, 6.0)
	var cd_data: Dictionary = hud.skill_cooldowns.get("1_1", {})
	if not is_equal_approx(cd_data.get("remaining", 0.0), 4.0):
		push_error("Cooldown remaining mismatch")
		hud.free()
		return false

	# Process 2.0s cooldown reduction
	hud._process(2.0)
	cd_data = hud.skill_cooldowns.get("1_1", {})
	if not is_equal_approx(cd_data.get("remaining", 0.0), 2.0):
		push_error("Cooldown reduction mismatch after 2.0s: %f" % cd_data.get("remaining", 0.0))
		hud.free()
		return false

	hud.free()
	return true

static func _test_order_bubble_offsets_and_patience() -> bool:
	var bubble: Node2D = OrderBubbleScript.new()
	
	# Meja Panjang: offset di kanan monster (14, -4) (FR-SEAT-09)
	bubble.set_order(&"recipe_nasi_goreng_jamur", 0.75, true)
	var long_offset: Vector2 = bubble.get_bubble_offset()
	if not long_offset.is_equal_approx(Vector2(14.0, -4.0)):
		push_error("Long table bubble offset mismatch: %s" % long_offset)
		bubble.free()
		return false

	# Meja Kecil: offset di atas kepala monster (0, -18)
	bubble.set_order(&"recipe_nasi_goreng_jamur", 0.35, false)
	var small_offset: Vector2 = bubble.get_bubble_offset()
	if not small_offset.is_equal_approx(Vector2(0.0, -18.0)):
		push_error("Small table bubble offset mismatch: %s" % small_offset)
		bubble.free()
		return false

	bubble.free()
	return true

static func _test_pause_menu_centered() -> bool:
	var pm: Control = PauseMenuScript.new()
	pm._ready()
	if not pm.size.is_equal_approx(Vector2(480.0, 270.0)):
		push_error("Pause menu canvas size mismatch: %s" % pm.size)
		pm.free()
		return false
	var prect: Rect2 = pm.get_panel_rect()
	if not is_equal_approx(prect.position.x, 140.0) or not is_equal_approx(prect.position.y, 55.0):
		push_error("Pause menu panel not centered at (240, 135): %s" % prect)
		pm.free()
		return false
	pm.free()
	return true
