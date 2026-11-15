class_name AssetsRegistry
extends Node

const PF: Script = preload("res://view/placeholder_factory.gd")

var _manifest: Dictionary = {}
var _textures: Dictionary = {}
var _frames: Dictionary = {}
var _statuses: Dictionary = {}
var _factory: RefCounted = PF.new()

func _ready() -> void:
	reload()

func reload() -> void:
	_manifest.clear(); _textures.clear(); _frames.clear(); _statuses.clear()
	if OS.has_feature("dedicated_server"):
		return
	var file: FileAccess = FileAccess.open("res://data/assets/manifest.csv", FileAccess.READ)
	if file == null:
		return
	var header: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < 6 or row[0].is_empty():
			continue
		var id: StringName = StringName(row[0])
		_manifest[id] = {"w": int(row[1]), "h": int(row[2]), "placeholder": StringName(row[5]), "anims": row[4]}

func _entry(id: StringName) -> Dictionary:
	return _manifest.get(id, {}) as Dictionary

func texture(id: StringName) -> Texture2D:
	if _textures.has(id):
		return _textures[id] as Texture2D
	var entry: Dictionary = _entry(id)
	if entry.is_empty():
		push_warning("Missing asset: %s" % id)
		var missing: Texture2D = PF.texture(Vector2i(32, 32), &"MISSING")
		_textures[id] = missing
		return missing
	var size: Vector2i = Vector2i(int(entry["w"]), int(entry["h"]))
	var result: Texture2D = PF.texture(size, entry["placeholder"] as StringName)
	_textures[id] = result
	_statuses[id] = entry["placeholder"]
	return result

func frames(id: StringName) -> SpriteFrames:
	if _frames.has(id):
		return _frames[id] as SpriteFrames
	var entry: Dictionary = _entry(id)
	if entry.is_empty():
		var missing: SpriteFrames = PF.frames(Vector2i(32, 32), &"MISSING")
		_frames[id] = missing
		return missing
	var anim_text: String = String(entry["anims"])
	var count: int = 1
	if not anim_text.is_empty():
		var first: String = anim_text.split("|")[0]
		count = int(first.split(":")[1])
	var result: SpriteFrames = PF.frames(Vector2i(int(entry["w"]), int(entry["h"])), entry["placeholder"] as StringName, count)
	_frames[id] = result
	_statuses[id] = entry["placeholder"]
	return result

func audio(id: StringName) -> AudioStream:
	return PF.audio()

func status(id: StringName, anim: StringName = &"") -> StringName:
	if not _manifest.has(id):
		return StringName("MISSING:%s" % id)
	if not _statuses.has(id):
		texture(id)
	return _statuses.get(id, &"MISSING") as StringName
