extends Node

# Manajemen Penyimpanan Progres & Pengaturan (Atomic Write & Migrasi Skema)

const SAVE_PATH: String = "user://save.json"
const SAVE_TEMP_PATH: String = "user://save.tmp"
const CURRENT_SCHEMA_VERSION: int = 1

var save_data: Dictionary = {
	"schema_version": CURRENT_SCHEMA_VERSION,
	"scores": {}, # level_id: String -> {"score": int, "stars": int}
	"rare_ingredients": [], # Array[String]
	"recipe_book": [], # Array[String]
	"unlocked_levels": ["1-1"],
	"tutorial_completed": false,
	"guest_id": ""
}

func _ready() -> void:
	load_game()

func save_game() -> bool:
	var json_string: String = JSON.stringify(save_data, "\t")
	var temp_file: FileAccess = FileAccess.open(SAVE_TEMP_PATH, FileAccess.WRITE)
	if not temp_file:
		push_error("Gagal membuka file penyimpanan sementara: %d" % FileAccess.get_open_error())
		return false
	
	temp_file.store_string(json_string)
	temp_file.close()

	var dir: DirAccess = DirAccess.open("user://")
	if not dir:
		push_error("Gagal mengakses direktori user://")
		return false

	if dir.file_exists(SAVE_PATH):
		var remove_err: Error = dir.remove(SAVE_PATH)
		if remove_err != OK:
			push_error("Gagal menghapus file penyimpanan lama: %d" % remove_err)
			return false

	var rename_err: Error = dir.rename(SAVE_TEMP_PATH, SAVE_PATH)
	if rename_err != OK:
		push_error("Gagal mengganti nama file penyimpanan sementara: %d" % rename_err)
		return false

	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		_generate_initial_save()
		save_game()
		return true

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("Gagal membuka file penyimpanan")
		return false

	var content: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(content)
	if parse_result != OK:
		push_error("Error membaca JSON save file: %s" % json.get_error_message())
		return false

	var loaded_dict: Variant = json.data
	if typeof(loaded_dict) != TYPE_DICTIONARY:
		push_error("Root data save file bukan Dictionary")
		return false

	save_data = _migrate_save_data(loaded_dict as Dictionary)
	return true

func _generate_initial_save() -> void:
	if not save_data.has("guest_id") or (save_data["guest_id"] as String).is_empty():
		save_data["guest_id"] = _generate_uuid_v4()

func _generate_uuid_v4() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var b: PackedByteArray = PackedByteArray()
	for i in range(16):
		b.append(rng.randi_range(0, 255))
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % [
		b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7],
		b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]
	]

func _migrate_save_data(loaded_dict: Dictionary) -> Dictionary:
	var version: int = loaded_dict.get("schema_version", 0) as int
	if version < CURRENT_SCHEMA_VERSION:
		loaded_dict["schema_version"] = CURRENT_SCHEMA_VERSION
	return loaded_dict

func record_level_result(level_id: String, score: int, stars: int) -> void:
	var scores_dict: Dictionary = save_data.get("scores", {}) as Dictionary
	if not scores_dict.has(level_id):
		scores_dict[level_id] = {"score": score, "stars": stars}
	else:
		var existing: Dictionary = scores_dict[level_id] as Dictionary
		existing["score"] = maxi(existing.get("score", 0) as int, score)
		existing["stars"] = maxi(existing.get("stars", 0) as int, stars)
	save_data["scores"] = scores_dict
	save_game()
