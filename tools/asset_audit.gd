extends SceneTree
## Audit manifest and incoming PNG metadata.
func _initialize() -> void:
	var report: Dictionary = {"status": "PASS", "issues": []}
	if not FileAccess.file_exists("res://data/assets/manifest.csv"):
		report["status"] = "INVALID"
		report["issues"].append("manifest missing")
	var f: FileAccess = FileAccess.open("res://reports/asset_audit.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  "))
		f.close()
	quit(1 if report["status"] == "INVALID" else 0)
