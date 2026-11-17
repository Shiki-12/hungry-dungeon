class_name TestAssetsSystem
extends RefCounted

const CookViewScript: Script = preload("res://view/cook_view.gd")
const CookScript: Script = preload("res://sim/entities/cook.gd")

static func run_all() -> bool:
	Assets.reload()
	if Assets.status(&"cook_rangga") != &"FINAL":
		push_error("cook_rangga status expected FINAL, got %s" % Assets.status(&"cook_rangga"))
		return false
	if not Assets.status(&"cook_sekar").begins_with("box_"):
		push_error("cook_sekar status expected placeholder box_, got %s" % Assets.status(&"cook_sekar"))
		return false
	var texture_result: Texture2D = Assets.texture(&"item_bawang_raw")
	if texture_result == null:
		push_error("Asset texture missing")
		return false
	var rangga_tex: Texture2D = Assets.texture(&"cook_rangga")
	if rangga_tex == null:
		push_error("Rangga texture missing")
		return false
	var frame_result: SpriteFrames = Assets.frames(&"cook_rangga")
	if frame_result == null or frame_result.get_frame_count(&"default") < 1:
		push_error("Asset frames missing")
		return false

	# Verify core animation tags for Rangga
	var core_tags: Array[StringName] = [
		&"idle_down", &"idle_up", &"idle_side_left", &"idle_side_right",
		&"idle_battle_down", &"idle_battle_up", &"idle_battle_side_left", &"idle_battle_side_right",
		&"walk_down", &"walk_up", &"walk_side_left", &"walk_side_right",
		&"walk_battle_down", &"walk_battle_up", &"walk_battle_side_left", &"walk_battle_side_right",
		&"work",
		&"dash_down", &"dash_up", &"dash_side_left", &"dash_side_right",
		&"dash_battle_down", &"dash_battle_up", &"dash_battle_side_left", &"dash_battle_side_right",
		&"strike_1_down", &"strike_1_up", &"strike_1_side_left", &"strike_1_side_right",
		&"strike_2_down", &"strike_2_up", &"strike_2_side_left", &"strike_2_side_right",
		&"throw_side_left", &"throw_side_right",
		&"shield_down", &"shield_up", &"shield_side_left", &"shield_side_right",
		&"knocked_down", &"knocked_up", &"knocked_side_left", &"knocked_side_right"
	]
	for tag: StringName in core_tags:
		if not frame_result.has_animation(tag):
			push_error("Missing core Rangga animation tag: %s" % tag)
			return false
		if frame_result.get_frame_count(tag) <= 0:
			push_error("Animation tag %s has 0 frames" % tag)
			return false

	if Assets.status(&"unknown_id") != StringName("MISSING:unknown_id"):
		push_error("Missing asset status invalid")
		return false

	# CookView integration test
	var cook: RefCounted = CookScript.new()
	cook.cook_id = 1
	cook.cook_name = "Rangga"
	cook.position = Vector2(100, 100)
	cook.facing_direction = Vector2.RIGHT

	var cv: Node2D = CookViewScript.new()
	cv.setup(cook, &"cook_rangga")
	cv._ready()

	if not cv.anim_sprite.visible:
		push_error("CookView AnimatedSprite2D expected visible for Rangga")
		cv.free()
		return false

	if cv.get_dir_string(Vector2(-1, 0)) != "side_left":
		push_error("Direction mapping failed for left")
		cv.free()
		return false

	if cv.get_dir_string(Vector2(1, 0)) != "side_right":
		push_error("Direction mapping failed for right")
		cv.free()
		return false

	if cv.get_dir_string(Vector2(0, -1)) != "up":
		push_error("Direction mapping failed for up")
		cv.free()
		return false

	if cv.get_dir_string(Vector2(0, 1)) != "down":
		push_error("Direction mapping failed for down")
		cv.free()
		return false

	cv.trigger_strike()
	if not cv.is_battle_mode():
		push_error("Battle mode should be active after strike")
		cv.free()
		return false

	cv._process(0.016)
	cv.free()

	return true
