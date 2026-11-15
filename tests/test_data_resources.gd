const SeatingDataScript: Script = preload("res://data/seating_data.gd")
const SpriteSetDataScript: Script = preload("res://data/sprite_set_data.gd")
const SkillDataScript: Script = preload("res://data/skill_data.gd")
const HazardDataScript: Script = preload("res://data/hazard_data.gd")
const TutorialDataScript: Script = preload("res://data/tutorial_data.gd")
const WorldMapDataScript: Script = preload("res://data/world_map_data.gd")
const EmoteMapDataScript: Script = preload("res://data/emote_map_data.gd")
const FacingMapDataScript: Script = preload("res://data/facing_map_data.gd")

static func run_all() -> bool:
	var item: ItemData = ItemData.new()
	if item.category != &"INGREDIENT" or item.form != &"raw" or not item.can_throw:
		return false
	var step: StepData = StepData.new()
	if not is_equal_approx(step.attention_miss_penalty, 0.3):
		return false
	var recipe: RecipeData = RecipeData.new()
	if recipe.base_points != 150 or not is_equal_approx(recipe.burn_time, 10.0):
		return false
	var station: StationData = StationData.new()
	if station.size_tiles != Vector2i.ONE or not is_equal_approx(station.burn_duration, 10.0):
		return false
	var monster: MonsterData = MonsterData.new()
	if monster.attack_pattern != &"NONE" or not is_equal_approx(monster.cracker_pause_sec, 8.0):
		return false
	var seating: Resource = SeatingDataScript.new()
	if not is_equal_approx(seating.seat_patience_scale_small, 0.85):
		return false
	var level: LevelData = LevelData.new()
	level.seating = seating
	if level.star_thresholds != Vector3i(300, 600, 900) or level.plate_count != 3:
		return false
	var sprite_set: Resource = SpriteSetDataScript.new()
	if (sprite_set.get("frame_size") as Vector2i) != Vector2i(16, 16):
		return false
	var skill: Resource = SkillDataScript.new()
	var hazard: Resource = HazardDataScript.new()
	var tutorial: Resource = TutorialDataScript.new()
	var world: Resource = WorldMapDataScript.new()
	var emote: Resource = EmoteMapDataScript.new()
	var facing: Resource = FacingMapDataScript.new()
	if skill == null or hazard == null or tutorial == null or world == null or emote == null or facing == null:
		return false
	return true
