extends SceneTree
## Generate placeholder metadata and folders from manifest.

const MANIFEST: String = "res://data/assets/manifest.csv"
const INDEX: String = "res://data/assets/index.json"

func _initialize() -> void:
	var rows: Array[Dictionary] = _read_manifest()
	var index: Dictionary = {"version": 1, "assets": {}}
	for row: Dictionary in rows:
		var id: String = String(row["id"])
		index["assets"][id] = {"id": id, "width": int(row["width"]), "height": int(row["height"]), "prefix": String(row["prefix"]), "animations": String(row["animations"]).split("|", false)}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets"))
	var file: FileAccess = FileAccess.open(INDEX, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(index, "  "))
		file.close()
	quit(0)

func _read_manifest() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var file: FileAccess = FileAccess.open(MANIFEST, FileAccess.READ)
	if file == null:
		return result
	file.get_line()
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var p: PackedStringArray = line.split(",")
		if p.size() >= 5:
			result.append({"id": p[0], "width": p[1], "height": p[2], "prefix": p[3], "animations": p[4]})
	file.close()
	return result
