class_name EmoteMapData
extends Resource

## Data dan pemetaan 19 Emoticon Koki dan Monster (§10.2, §13.2, FR-EMO-01 s.d. 06).

const COOK_EMOTES: Array[StringName] = [
	&"emote_chop",
	&"emote_mix",
	&"emote_pound",
	&"emote_stir",
	&"emote_wash",
	&"emote_burn",
	&"emote_panic",
	&"emote_cheer",
	&"emote_no",
]

const MONSTER_EMOTES: Array[StringName] = [
	&"emote_menu",
	&"emote_hungry",
	&"emote_grumble",
	&"emote_rage",
	&"emote_yum",
	&"emote_happy",
	&"emote_scared",
	&"emote_chat",
	&"emote_music",
	&"emote_envy",
]

const ALL_EMOTES: Array[StringName] = [
	&"emote_chop",
	&"emote_mix",
	&"emote_pound",
	&"emote_stir",
	&"emote_wash",
	&"emote_burn",
	&"emote_panic",
	&"emote_cheer",
	&"emote_no",
	&"emote_menu",
	&"emote_hungry",
	&"emote_grumble",
	&"emote_rage",
	&"emote_yum",
	&"emote_happy",
	&"emote_scared",
	&"emote_chat",
	&"emote_music",
	&"emote_envy",
]

@export var id: StringName = &""
@export var emotes: Dictionary = {}

static func get_cook_work_emote(action_or_station: StringName) -> StringName:
	var key: String = String(action_or_station).to_lower()
	if key == "chop" or key.begins_with("meja_potong"):
		return &"emote_chop"
	if key == "mix" or key.begins_with("meja_kerja"):
		return &"emote_mix"
	if key == "pound" or key.begins_with("cobek"):
		return &"emote_pound"
	if key == "stir" or key == "aduk":
		return &"emote_stir"
	if key == "wash" or key.begins_with("tempat_cuci"):
		return &"emote_wash"
	if key == "burn" or key == "burnt":
		return &"emote_burn"
	if key == "panic":
		return &"emote_panic"
	if key == "cheer" or key == "success" or key == "jitu":
		return &"emote_cheer"
	if key == "no" or key == "wrong" or key == "fail":
		return &"emote_no"
	return &""

static func get_monster_emote(state: int, stage: int = 1) -> StringName:
	# Enum SimMonster: ARRIVING(0), SEATED(1), BROWSING(2), WAITING(3), EATING(4), SATISFIED(5), LEAVING(6), ENRAGED(7), ATTACKING(8), STEAL_RUN(9), EXPELLED(10)
	match state:
		2: # BROWSING
			return &"emote_menu"
		3: # WAITING
			if stage == 1:
				return &"emote_hungry"
			elif stage == 2:
				return &"emote_grumble"
			else:
				return &"emote_rage"
		4: # EATING
			return &"emote_yum"
		5: # SATISFIED
			return &"emote_happy"
		7, 8, 9: # ENRAGED, ATTACKING, STEAL_RUN
			return &"emote_rage"
		10: # EXPELLED
			return &"emote_scared"
		_:
			return &""

static func is_valid_emote_id(emote_id: StringName) -> bool:
	return ALL_EMOTES.has(emote_id)
