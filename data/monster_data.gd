class_name MonsterData
extends Resource

enum MonsterType {
	GOBLIN,
	LIZARD,
	OGRE,
	GHOST,
	HUMAN,
	DRAGON
}

@export var id: String = ""
@export var display_name: String = ""
@export var monster_type: MonsterType = MonsterType.GOBLIN
@export var base_patience_seconds: float = 40.0
@export var favored_recipes: Array[String] = []
@export var snack_stun_seconds: float = 8.0
@export var rare_drop_id: String = ""
@export var attack_duration_seconds: float = 10.0
@export var station_disable_seconds: float = 8.0
