extends Node

# Pengendali Alur Game, Level, Pause, dan Siklus Hidup

enum GameMode {
	LOCAL_2P,
	ONLINE_2P
}

const MAX_KITCHEN_HEALTH: int = 5

var current_mode: GameMode = GameMode.LOCAL_2P
var is_game_paused: bool = false

# State Level Aktif
var current_level_id: String = ""
var current_score: int = 0
var kitchen_health: int = MAX_KITCHEN_HEALTH
var consecutive_bullseyes: int = 0
var time_remaining: float = 0.0
var total_duration: float = 0.0
var is_level_active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _physics_process(delta: float) -> void:
	if not is_level_active or is_game_paused:
		return
	
	if total_duration > 0.0:
		time_remaining = maxf(0.0, time_remaining - delta)
		Events.level_time_updated.emit(time_remaining, total_duration)
		if time_remaining <= 0.0:
			end_level(true, _calculate_stars(current_score))

func start_level(level_id: String, duration: float) -> void:
	current_level_id = level_id
	current_score = 0
	kitchen_health = MAX_KITCHEN_HEALTH
	consecutive_bullseyes = 0
	total_duration = duration
	time_remaining = duration
	is_level_active = true
	
	Events.level_started.emit(level_id)
	Events.kitchen_health_changed.emit(kitchen_health, MAX_KITCHEN_HEALTH)
	Events.score_changed.emit(current_score, 0)
	Events.level_time_updated.emit(time_remaining, total_duration)

func add_score(delta: int) -> void:
	current_score += delta
	Events.score_changed.emit(current_score, delta)

func reduce_kitchen_health(amount: int = 1) -> void:
	kitchen_health = maxi(0, kitchen_health - amount)
	Events.kitchen_health_changed.emit(kitchen_health, MAX_KITCHEN_HEALTH)
	if kitchen_health <= 0:
		end_level(false, 0)

func register_bullseye() -> void:
	consecutive_bullseyes += 1
	add_score(25) # Bonus Jitu FR-THR-08
	if consecutive_bullseyes >= 3:
		add_score(50) # Bonus 3 Jitu beruntun FR-THR-09
		consecutive_bullseyes = 0

func reset_bullseye_streak() -> void:
	consecutive_bullseyes = 0

func toggle_pause() -> void:
	set_paused(!is_game_paused)

func set_paused(paused: bool) -> void:
	is_game_paused = paused
	get_tree().paused = paused
	Events.game_paused.emit(is_game_paused)

func end_level(is_win: bool, stars: int) -> void:
	is_level_active = false
	if is_win and not current_level_id.is_empty():
		Save.record_level_result(current_level_id, current_score, stars)
	Events.level_completed.emit(current_level_id, current_score, stars, is_win)

func restart_current_level() -> void:
	set_paused(false)
	get_tree().reload_current_scene()

func change_scene(scene_path: String) -> void:
	set_paused(false)
	get_tree().change_scene_to_file(scene_path)

func _calculate_stars(score: int) -> int:
	# Bintang default sebelum ada resource LevelData spesifik
	if score >= 900:
		return 3
	elif score >= 600:
		return 2
	elif score >= 300:
		return 1
	return 0
