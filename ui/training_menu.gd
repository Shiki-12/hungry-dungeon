extends Control

## Menu Latihan / Tutorial Hungry Dungeon (FR-UI-06, FR-TUT-04).
## Mengakses ulang level T-1 s.d. T-5.

func _ready() -> void:
	$VBox/BtnT1.pressed.connect(func(): _load_tutorial(1))
	$VBox/BtnT2.pressed.connect(func(): _load_tutorial(2))
	$VBox/BtnT3.pressed.connect(func(): _load_tutorial(3))
	$VBox/BtnT4.pressed.connect(func(): _load_tutorial(4))
	$VBox/BtnT5.pressed.connect(func(): _load_tutorial(5))
	$BtnBack.pressed.connect(_on_back_pressed)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var kc: int = (event as InputEventKey).keycode
		if kc == KEY_ESCAPE:
			if is_inside_tree() and get_viewport() != null:
				get_viewport().set_input_as_handled()
			_on_back_pressed()

func _load_tutorial(idx: int) -> void:
	var _path: String = "res://data/levels/tutorial_%d.tres" % idx
	# Ubah level aktif di Game autoload dan muat stage
	if Engine.has_singleton("Game") or (Engine.get_main_loop() is SceneTree and Engine.get_main_loop().root.has_node("Game")):
		var game_node: Node = Engine.get_main_loop().root.get_node("Game")
		if game_node:
			game_node.set("current_level_id", "tutorial_%d" % idx)
	if is_inside_tree() and get_tree():
		get_tree().change_scene_to_file.call_deferred("res://levels/kitchen_stage.tscn")

func _on_back_pressed() -> void:
	if is_inside_tree() and get_tree():
		get_tree().change_scene_to_file.call_deferred("res://ui/main_menu.tscn")
