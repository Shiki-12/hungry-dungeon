extends Node

# Manajemen Pengaturan Pengguna (Audio, Input, Display, Aksesibilitas)

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var ui_volume: float = 1.0

var aim_assist: bool = false
var screen_shake_enabled: bool = true
var audio_offset_ms: float = 0.0
var current_locale: String = "id"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_default_input_map()
	_apply_settings()

func _apply_settings() -> void:
	Audio.set_bus_volume(Audio.BUS_MASTER, master_volume)
	Audio.set_bus_volume(Audio.BUS_MUSIC, music_volume)
	Audio.set_bus_volume(Audio.BUS_SFX, sfx_volume)
	Audio.set_bus_volume(Audio.BUS_UI, ui_volume)
	Audio.audio_offset_ms = audio_offset_ms
	TranslationServer.set_locale(current_locale)

func _setup_default_input_map() -> void:
	var default_actions: Dictionary = {
		"p1_move_left": [KEY_A],
		"p1_move_right": [KEY_D],
		"p1_move_up": [KEY_W],
		"p1_move_down": [KEY_S],
		"p1_interact": [KEY_E],
		"p1_work": [KEY_F],
		"p1_strike": [KEY_SPACE],
		"p1_skill_1": [KEY_Q],
		"p1_skill_2": [KEY_R],
		"p1_throw": [KEY_C],
		"p1_pause": [KEY_ESCAPE],

		"p2_move_left": [KEY_LEFT],
		"p2_move_right": [KEY_RIGHT],
		"p2_move_up": [KEY_UP],
		"p2_move_down": [KEY_DOWN],
		"p2_interact": [KEY_PERIOD],
		"p2_work": [KEY_COMMA],
		"p2_strike": [KEY_SLASH],
		"p2_skill_1": [KEY_SEMICOLON],
		"p2_skill_2": [KEY_APOSTROPHE],
		"p2_throw": [KEY_SHIFT],
		"p2_pause": [KEY_BACKSPACE]
	}

	for action_name: String in default_actions.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		var keys: Array = default_actions[action_name] as Array
		for k in keys:
			var key_code: Key = k as Key
			var ev: InputEventKey = InputEventKey.new()
			ev.physical_keycode = key_code
			ev.pressed = true
			if not InputMap.action_has_event(action_name, ev):
				InputMap.action_add_event(action_name, ev)
