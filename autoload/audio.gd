extends Node

# Manajemen Audio Bus & Pemutaran Musik/SFX

const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"
const BUS_UI: String = "UI"

var audio_offset_ms: float = 0.0
var music_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.bus = BUS_MUSIC
	add_child(music_player)

func play_music(stream: AudioStream, _loop: bool = true) -> void:
	if not stream:
		return
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = BUS_SFX
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func set_bus_volume(bus_name: String, volume_linear: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		var db: float = linear_to_db(clampf(volume_linear, 0.0001, 1.0)) if volume_linear > 0.0 else -80.0
		AudioServer.set_bus_volume_db(bus_index, db)
		AudioServer.set_bus_mute(bus_index, volume_linear <= 0.0)
