extends Node2D

# Script untuk test_kitchen.tscn
# Layout 480x270: HUD Atas (30px), Dapur (224px), HUD Bawah (16px)

@onready var score_label: Label = $HUDTop/Margin/HBox/ScoreLabel
@onready var timer_label: Label = $HUDTop/Margin/HBox/TimerLabel
@onready var health_label: Label = $HUDBottom/Margin/HBox/HealthLabel

func _ready() -> void:
	Events.score_changed.connect(_on_score_changed)
	Events.kitchen_health_changed.connect(_on_kitchen_health_changed)
	Events.level_time_updated.connect(_on_level_time_updated)
	
	Game.start_level("TEST_01", 180.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("p1_pause") or event.is_action_pressed("p2_pause"):
		Game.toggle_pause()

func _on_score_changed(current_score: int, _delta: int) -> void:
	if score_label:
		score_label.text = "SKOR: %d" % current_score

func _on_kitchen_health_changed(current_health: int, max_health: int) -> void:
	if health_label:
		var hearts: String = ""
		for i in range(max_health):
			hearts += "♥ " if i < current_health else "♡ "
		health_label.text = "HATI DAPUR: %s(%d/%d)" % [hearts, current_health, max_health]

func _on_level_time_updated(time_remaining: float, _total: float) -> void:
	if timer_label:
		var mins: int = int(time_remaining) / 60
		var secs: int = int(time_remaining) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
