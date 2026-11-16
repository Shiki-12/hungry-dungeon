extends Control

## Layar Pengaturan (FR-UI-06, FR-STA-21, FR-CRD-03).
## Mengatur audio, bantuan bidik, tekan untuk bekerja, jendela aduk lebar, dan kepadatan kerumunan.

func _ready() -> void:
	_load_current_settings()
	$Panel/VBox/BtnSave.pressed.connect(_on_save)

func _load_current_settings() -> void:
	var s: Node = _get_settings()
	if s == null:
		return
	
	if "master_volume" in s:
		$Panel/VBox/Grid/SliderMaster.value = s.master_volume * 100.0
	if "music_volume" in s:
		$Panel/VBox/Grid/SliderMusic.value = s.music_volume * 100.0
	if "sfx_volume" in s:
		$Panel/VBox/Grid/SliderSFX.value = s.sfx_volume * 100.0
	if "aim_assist" in s:
		$Panel/VBox/Grid/CheckAimAssist.button_pressed = s.aim_assist
	if "toggle_work" in s:
		$Panel/VBox/Grid/CheckToggleWork.button_pressed = s.toggle_work
	if "wide_attention_window" in s:
		$Panel/VBox/Grid/CheckWideAttention.button_pressed = s.wide_attention_window

func _on_save() -> void:
	var s: Node = _get_settings()
	if s != null:
		s.master_volume = $Panel/VBox/Grid/SliderMaster.value / 100.0
		s.music_volume = $Panel/VBox/Grid/SliderMusic.value / 100.0
		s.sfx_volume = $Panel/VBox/Grid/SliderSFX.value / 100.0
		s.aim_assist = $Panel/VBox/Grid/CheckAimAssist.button_pressed
		if "toggle_work" in s:
			s.toggle_work = $Panel/VBox/Grid/CheckToggleWork.button_pressed
		if "wide_attention_window" in s:
			s.wide_attention_window = $Panel/VBox/Grid/CheckWideAttention.button_pressed
		if s.has_method("_apply_settings"):
			s.call("_apply_settings")
	queue_free()

func _get_settings() -> Node:
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree and (loop as SceneTree).root:
		return (loop as SceneTree).root.get_node_or_null("Settings")
	return null
