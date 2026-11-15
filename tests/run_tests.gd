extends SceneTree

var _failed: bool = false

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var dir: DirAccess = DirAccess.open("res://tests")
	if dir == null:
		push_error("Cannot open tests directory")
		_failed = true
	else:
		dir.list_dir_begin()
		var filename: String = dir.get_next()
		while filename != "":
			if filename.begins_with("test_") and filename.ends_with(".gd"):
				_run_test_script("res://tests/" + filename)
			filename = dir.get_next()
		dir.list_dir_end()
	quit(1 if _failed else 0)

func _run_test_script(path: String) -> void:
	var script: Script = load(path) as Script
	if script == null:
		push_error("Failed load: " + path)
		_failed = true
		return
	if not script.can_instantiate():
		push_error("Cannot instantiate: " + path)
		_failed = true
		return
	var instance: Object = script.new()
	if instance == null:
		push_error("Instantiation failed: " + path)
		_failed = true
		return
	if not instance.has_method("run_all"):
		push_error("Missing run_all: " + path)
		_failed = true
		return
	var result: Variant = instance.call("run_all")
	if result is bool and not (result as bool):
		_failed = true
		push_error("FAILED: " + path)
	else:
		print("PASS: " + path)
