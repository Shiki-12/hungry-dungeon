class_name SimScoring
extends RefCounted

const MAX_HEARTS: int = 5
var hearts: int = MAX_HEARTS
var score: int = 0
var jitu_streak: int = 0
var rare_drop_granted: bool = false

func reset() -> void:
	hearts = MAX_HEARTS
	score = 0
	jitu_streak = 0
	rare_drop_granted = false

func add_score(points: int) -> void:
	score = maxi(0, score + points)

func lose_heart(amount: int = 1) -> bool:
	hearts = maxi(0, hearts - maxi(0, amount))
	return hearts == 0

func gain_heart(amount: int = 1) -> void:
	hearts = mini(MAX_HEARTS, hearts + maxi(0, amount))

func stars_for(level: Resource) -> int:
	var thresholds: Vector3i = level.star_thresholds
	if score >= thresholds.z: return 3
	if score >= thresholds.y: return 2
	if score >= thresholds.x: return 1
	return 0

func record_jitu() -> void:
	jitu_streak += 1
	add_score(25)
	if jitu_streak >= 3:
		add_score(50)
		jitu_streak = 0

func record_non_jitu() -> void:
	jitu_streak = 0

func check_special_guest(satisfaction: float, drop_id: StringName) -> bool:
	if rare_drop_granted or satisfaction < 80.0 or drop_id.is_empty(): return false
	rare_drop_granted = true
	return true
