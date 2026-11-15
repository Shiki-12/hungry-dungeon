extends Control
## Manifest animation gallery.
var debug_overlay: bool = false
func _ready() -> void:
	queue_redraw()
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F3: debug_overlay = not debug_overlay; queue_redraw()
		elif event.keycode == KEY_F5: get_tree().reload_current_scene()
func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(8, 18), "Animation Gallery  F3 debug  F5 reload", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	if debug_overlay: draw_rect(Rect2(4, 24, 220, 20), Color(0.8, 0.1, 0.1, 0.7))
