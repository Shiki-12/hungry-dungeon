extends SceneTree
## Validate incoming assets, build index and reports.

const MANIFEST: String = "res://data/assets/manifest.csv"
const INCOMING: String = "res://assets/_incoming"
const INDEX: String = "res://data/assets/index.json"
const REPORT_JSON: String = "res://reports/asset_status.json"
const REPORT_MD: String = "res://reports/asset_status.md"

func _initialize() -> void:
	var manifest: Dictionary = _manifest()
	var statuses: Array[Dictionary] = []
	var invalid: bool = false
	var dir: DirAccess = DirAccess.open(INCOMING)
	if dir != null:
		dir.list_dir_begin()
		var name: String = dir.get_next()
		while not name.is_empty():
			if not dir.current_is_dir() and name.to_lower().ends_with(".png"):
				var base: String = name.trim_suffix(".png")
				var id: String = base.split("__")[0]
				var ok: bool = manifest.has(id)
				statuses.append({"file": name, "id": id, "status": "VALID" if ok else "INVALID"})
				invalid = invalid or not ok
			name = dir.get_next()
		dir.list_dir_end()
	var index: Dictionary = {"version": 1, "assets": manifest}
	_write(INDEX, JSON.stringify(index, "  "))
	_write(REPORT_JSON, JSON.stringify({"assets": statuses, "invalid": invalid}, "  "))
	var md: String = "# Asset Status\n\n| File | ID | Status |\n|---|---|---|\n"
	for item: Dictionary in statuses:
		md += "| %s | %s | %s |\n" % [item["file"], item["id"], item["status"]]
	_write(REPORT_MD, md)
	quit(1 if invalid else 0)

func _manifest() -> Dictionary:
	var out: Dictionary = {}
	var f: FileAccess = FileAccess.open(MANIFEST, FileAccess.READ)
	if f == null:
		return out
	f.get_line()
	while not f.eof_reached():
		var p: PackedStringArray = f.get_line().strip_edges().split(",")
		if p.size() >= 5 and not p[0].is_empty():
			out[p[0]] = {"id": p[0], "width": int(p[1]), "height": int(p[2]), "prefix": p[3], "animations": p[4].split("|", false)}
	f.close()
	return out

func _write(path: String, text: String) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()
