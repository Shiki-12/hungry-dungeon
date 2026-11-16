extends Control

## Menu Utama Koki Dungeon (FR-UI-06).

func _ready() -> void:
	var btn_start: Button = $VBox/BtnStart
	var btn_training: Button = $VBox/BtnTraining
	var btn_settings: Button = $VBox/BtnSettings
	var btn_quit: Button = $VBox/BtnQuit

	btn_start.pressed.connect(_on_start_pressed)
	btn_training.pressed.connect(_on_training_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/kitchen_stage.tscn")

func _on_training_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/training_menu.tscn")

func _on_settings_pressed() -> void:
	var settings_scn: PackedScene = load("res://ui/settings_menu.tscn")
	if settings_scn:
		var dlg: Node = settings_scn.instantiate()
		add_child(dlg)

func _on_quit_pressed() -> void:
	get_tree().quit()
