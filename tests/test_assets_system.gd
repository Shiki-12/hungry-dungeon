class_name TestAssetsSystem
extends RefCounted

static func run_all() -> bool:
	if not Assets.status(&"cook_rangga").begins_with("box_"):
		push_error("Asset status invalid")
		return false
	var texture_result: Texture2D = Assets.texture(&"item_bawang_raw")
	if texture_result == null:
		push_error("Asset texture missing")
		return false
	var frame_result: SpriteFrames = Assets.frames(&"cook_rangga")
	if frame_result == null or frame_result.get_frame_count(&"default") < 1:
		push_error("Asset frames missing")
		return false
	if Assets.status(&"unknown_id") != StringName("MISSING:unknown_id"):
		push_error("Missing asset status invalid")
		return false
	return true
