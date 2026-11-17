extends Control

## Layar Hasil Level (FR-UI-06).
## Menampilkan status kemenangan, skor akhir, bintang 1–3, dan tombol navigasi.

var is_win: bool = true
var final_score: int = 0
var stars_earned: int = 0

func setup(p_win: bool, p_score: int, p_stars: int) -> void:
	is_win = p_win
	final_score = p_score
	stars_earned = p_stars
	_update_display()

func _ready() -> void:
	$Panel/VBox/BtnNext.pressed.connect(_on_next)
	$Panel/VBox/BtnRetry.pressed.connect(_on_retry)
	$Panel/VBox/BtnMenu.pressed.connect(_on_menu)
	_update_display()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var kc: int = (event as InputEventKey).keycode
		if kc == KEY_ESCAPE:
			if is_inside_tree() and get_viewport() != null:
				get_viewport().set_input_as_handled()
			_on_menu()
		elif kc == KEY_ENTER or kc == KEY_KP_ENTER:
			if is_inside_tree() and get_viewport() != null:
				get_viewport().set_input_as_handled()
			if is_win:
				_on_next()
			else:
				_on_retry()

func _update_display() -> void:
	if not is_inside_tree():
		return
	var title_lbl: Label = $Panel/Title
	var score_lbl: Label = $Panel/ScoreLabel
	var stars_lbl: Label = $Panel/StarsLabel
	
	if is_win:
		title_lbl.text = "LEVEL SELESAI!"
		title_lbl.modulate = Color(0.3, 0.9, 0.4)
	else:
		title_lbl.text = "DAPUR RUNTUH!"
		title_lbl.modulate = Color(0.95, 0.3, 0.3)

	score_lbl.text = "Skor Akhir: %d" % final_score
	
	var s_text: String = ""
	for i: int in range(3):
		s_text += "★" if i < stars_earned else "☆"
	stars_lbl.text = s_text

func _on_next() -> void:
	if is_inside_tree() and get_tree():
		get_tree().change_scene_to_file.call_deferred("res://levels/kitchen_stage.tscn")

func _on_retry() -> void:
	if Engine.has_singleton("Game") or (Engine.get_main_loop() is SceneTree and Engine.get_main_loop().root.has_node("Game")):
		var game_node: Node = Engine.get_main_loop().root.get_node("Game")
		if game_node:
			game_node.call("restart_current_level")
			return
	if is_inside_tree() and get_tree():
		get_tree().reload_current_scene.call_deferred()

func _on_menu() -> void:
	if is_inside_tree() and get_tree():
		get_tree().change_scene_to_file.call_deferred("res://ui/main_menu.tscn")
