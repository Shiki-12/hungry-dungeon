extends RefCounted

static func run_all() -> bool:
	var paths: Array[String] = ["1_1", "1_2", "1_3", "1_4"]
	for suffix: String in paths:
		var level: LevelData = load("res://data/levels/level_%s.tres" % suffix) as LevelData
		if level == null or level.stage != 1 or level.plate_count < level.max_open_tickets + 1:
			return false
	var scoring: SimScoring = SimScoring.new()
	var level_4: LevelData = load("res://data/levels/level_1_4.tres") as LevelData
	scoring.add_score(600)
	if scoring.stars_for(level_4) != 1:
		return false
	if scoring.hearts != 5 or scoring.lose_heart(5) != true:
		return false
	return scoring.check_special_guest(80.0, &"item_truffle_gua")
