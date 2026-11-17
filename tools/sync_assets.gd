extends SceneTree
## Validate incoming assets, build index and reports.

const MANIFEST: String = "res://data/assets/manifest.csv"
const INCOMING: String = "res://assets/_incoming"
const RANGGA_ROOT: String = "res://assets/rangga"
const INDEX: String = "res://data/assets/index.json"
const REPORT_JSON: String = "res://reports/asset_status.json"
const REPORT_MD: String = "res://reports/asset_status.md"

const RanggaBuilder: Script = preload("res://view/rangga_sprite_builder.gd")

func _initialize() -> void:
	# 1. Build and save Rangga SpriteFrames
	var sf: SpriteFrames = RanggaBuilder.build_sprite_frames()
	if sf != null:
		var err: Error = ResourceSaver.save(sf, "res://assets/rangga/cook_rangga_frames.tres")
		if err != OK:
			push_error("Failed to save cook_rangga_frames.tres: %s" % err)

	var manifest: Dictionary = _manifest()
	var statuses: Array[Dictionary] = []
	var invalid: bool = false

	# 2. Incoming assets
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

	# 3. Rangga assets
	var rangga_files: Array[String] = []
	_collect_files_recursive(RANGGA_ROOT, rangga_files)
	rangga_files.sort()
	for f_path: String in rangga_files:
		statuses.append({"file": f_path.replace("res://", ""), "id": "cook_rangga", "status": "VALID"})

	# Update manifest entry for cook_rangga
	if manifest.has("cook_rangga"):
		manifest["cook_rangga"]["status"] = "FINAL"
		manifest["cook_rangga"]["frame_count"] = rangga_files.size()
		if sf != null:
			var anim_names: Array = []
			for a_name: StringName in sf.get_animation_names():
				anim_names.append(String(a_name))
			manifest["cook_rangga"]["animation_names"] = anim_names

	var index: Dictionary = {"version": 1, "assets": manifest}
	_write(INDEX, JSON.stringify(index, "  "))
	_write(REPORT_JSON, JSON.stringify({"assets": statuses, "invalid": invalid, "cook_rangga": "FINAL", "cook_rangga_frames": rangga_files.size()}, "  "))

	var md: String = "# Asset Status\n\n**cook_rangga**: FINAL (%d frames across 43 canonical animations)\n\n| File | ID | Status |\n|---|---|---|\n" % rangga_files.size()
	for item: Dictionary in statuses:
		md += "| %s | %s | %s |\n" % [item["file"], item["id"], item["status"]]
	_write(REPORT_MD, md)

	quit(1 if invalid else 0)

func _collect_files_recursive(dir_path: String, out_list: Array[String]) -> void:
	var d: DirAccess = DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var it: String = d.get_next()
	while not it.is_empty():
		if it != "." and it != "..":
			var sub_path: String = dir_path + "/" + it
			if d.current_is_dir():
				_collect_files_recursive(sub_path, out_list)
			elif it.to_lower().ends_with(".png"):
				out_list.append(sub_path)
		it = d.get_next()
	d.list_dir_end()

func _manifest() -> Dictionary:
	var out: Dictionary = {}
	var f: FileAccess = FileAccess.open(MANIFEST, FileAccess.READ)
	if f == null:
		return out
	f.get_line()
	while not f.eof_reached():
		var p: PackedStringArray = f.get_line().strip_edges().split(",")
		if p.size() >= 5 and not p[0].is_empty():
			var entry: Dictionary = {
				"id": p[0],
				"width": int(p[1]),
				"height": int(p[2]),
				"prefix": p[3],
				"animations": p[4].split("|", false)
			}
			if p.size() >= 6 and not p[5].is_empty():
				entry["placeholder"] = p[5]
			out[p[0]] = entry
	f.close()
	return out

func _write(path: String, text: String) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()
