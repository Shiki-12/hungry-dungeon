extends Control

## Menu Jeda Koki Dungeon (FR-UI-06).

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$VBox/BtnResume.pressed.connect(_on_resume)
	$VBox/BtnRestart.pressed.connect(_on_restart)
	$VBox/BtnSettings.pressed.connect(_on_settings)
	$VBox/BtnMainMenu.pressed.connect(_on_main_menu)

func _on_resume() -> void:
	if Engine.has_singleton("Game") or (Engine.get_main_loop() is SceneTree and Engine.get_main_loop().root.has_node("Game")):
		var game_node: Node = Engine.get_main_loop().root.get_node("Game")
		if game_node:
			game_node.call("set_paused", false)
	queue_free()

func _on_restart() -> void:
	if Engine.has_singleton("Game") or (Engine.get_main_loop() is SceneTree and Engine.get_main_loop().root.has_node("Game")):
		var game_node: Node = Engine.get_main_loop().root.get_node("Game")
		if game_node:
			game_node.call("restart_current_level")
	queue_free()

func _on_settings() -> void:
	var settings_scn: PackedScene = load("res://ui/settings_menu.tscn")
	if settings_scn:
		var dlg: Node = settings_scn.instantiate()
		add_child(dlg)

func _on_main_menu() -> void:
	if Engine.has_singleton("Game") or (Engine.get_main_loop() is SceneTree and Engine.get_main_loop().root.has_node("Game")):
		var game_node: Node = Engine.get_main_loop().root.get_node("Game")
		if game_node:
			game_node.call("set_paused", false)
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
