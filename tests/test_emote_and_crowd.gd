class_name TestEmoteAndCrowd
extends RefCounted

## Unit test untuk M2.3: Sistem 19 Emoticon & CrowdController (FR-EMO-01 s.d. 06, FR-CRD-01 s.d. 04).

const EmoteMapDataScript: Script = preload("res://data/emote_map_data.gd")
const EmoteViewScript: Script = preload("res://view/emote_view.gd")
const CrowdControllerScript: Script = preload("res://view/crowd_controller.gd")
const AssetsScript: Script = preload("res://autoload/assets.gd")

static func run_all() -> bool:
	if not _test_all_19_emotes_registered():
		return false
	if not _test_cook_and_monster_mappings():
		return false
	if not _test_emote_view_anchors_and_linger():
		return false
	if not _test_crowd_controller_density_and_reaction():
		return false
	return true

static func _test_all_19_emotes_registered() -> bool:
	if EmoteMapDataScript.ALL_EMOTES.size() != 19:
		push_error("Expected exactly 19 emotes, got %d" % EmoteMapDataScript.ALL_EMOTES.size())
		return false
	
	if EmoteMapDataScript.COOK_EMOTES.size() != 9:
		push_error("Expected 9 cook emotes, got %d" % EmoteMapDataScript.COOK_EMOTES.size())
		return false
		
	if EmoteMapDataScript.MONSTER_EMOTES.size() != 10:
		push_error("Expected 10 monster emotes, got %d" % EmoteMapDataScript.MONSTER_EMOTES.size())
		return false

	# Verifikasi setiap ID bisa dipanggil lewat Assets tanpa crash
	var loop: MainLoop = Engine.get_main_loop()
	var assets_node: Node = null
	if loop is SceneTree and (loop as SceneTree).root:
		assets_node = (loop as SceneTree).root.get_node_or_null("Assets")

	for emote_id: StringName in EmoteMapDataScript.ALL_EMOTES:
		if not EmoteMapDataScript.is_valid_emote_id(emote_id):
			push_error("Invalid emote ID: %s" % emote_id)
			return false
		if assets_node != null and assets_node.has_method("frames"):
			var sf: SpriteFrames = assets_node.call("frames", emote_id)
			if sf == null:
				push_error("Assets.frames returned null for %s" % emote_id)
				return false

	return true

static func _test_cook_and_monster_mappings() -> bool:
	# 1. Cook work mappings
	if EmoteMapDataScript.get_cook_work_emote(&"meja_potong") != &"emote_chop":
		return false
	if EmoteMapDataScript.get_cook_work_emote(&"meja_kerja") != &"emote_mix":
		return false
	if EmoteMapDataScript.get_cook_work_emote(&"cobek") != &"emote_pound":
		return false
	if EmoteMapDataScript.get_cook_work_emote(&"stir") != &"emote_stir":
		return false
	if EmoteMapDataScript.get_cook_work_emote(&"tempat_cuci") != &"emote_wash":
		return false
	if EmoteMapDataScript.get_cook_work_emote(&"burn") != &"emote_burn":
		return false
	if EmoteMapDataScript.get_cook_work_emote(&"panic") != &"emote_panic":
		return false
	if EmoteMapDataScript.get_cook_work_emote(&"cheer") != &"emote_cheer":
		return false
	if EmoteMapDataScript.get_cook_work_emote(&"no") != &"emote_no":
		return false

	# 2. Monster state mappings
	# BROWSING (2)
	if EmoteMapDataScript.get_monster_emote(2, 1) != &"emote_menu":
		return false
	# WAITING (3) Stage 1 -> hungry, Stage 2 -> grumble, Stage 3 -> rage
	if EmoteMapDataScript.get_monster_emote(3, 1) != &"emote_hungry":
		return false
	if EmoteMapDataScript.get_monster_emote(3, 2) != &"emote_grumble":
		return false
	if EmoteMapDataScript.get_monster_emote(3, 3) != &"emote_rage":
		return false
	# EATING (4)
	if EmoteMapDataScript.get_monster_emote(4, 1) != &"emote_yum":
		return false
	# SATISFIED (5)
	if EmoteMapDataScript.get_monster_emote(5, 1) != &"emote_happy":
		return false
	# EXPELLED (10)
	if EmoteMapDataScript.get_monster_emote(10, 1) != &"emote_scared":
		return false

	return true

static func _test_emote_view_anchors_and_linger() -> bool:
	var view: Node = EmoteViewScript.new()
	
	# Default anchor: kanan-atas kepala (8, -14)
	view.set_long_table(false)
	var def_offset: Vector2 = view.get_anchor_offset()
	if not def_offset.is_equal_approx(Vector2(8.0, -14.0)):
		push_error("Default emote anchor mismatch: %s" % def_offset)
		view.free()
		return false

	# Long table seat anchor: tepat di atas kepala (0, -16) FR-EMO-04
	view.set_long_table(true)
	var long_offset: Vector2 = view.get_anchor_offset()
	if not long_offset.is_equal_approx(Vector2(0.0, -16.0)):
		push_error("Long table emote anchor mismatch: %s" % long_offset)
		view.free()
		return false

	# Work emote linger: 0.3s sesudah work dilepas (FR-EMO-03)
	view.update_cook_work(true, &"meja_potong", 0.0)
	if view.current_emote_id != &"emote_chop" or not view.is_visible_emote:
		push_error("EmoteView did not show emote_chop during work")
		view.free()
		return false

	# Lepas work (is_working = false)
	view.update_cook_work(false, &"meja_potong", 0.1) # 0.1s berlalu, sisa linger 0.2s
	if not view.is_visible_emote:
		push_error("Emote should linger after work released")
		view.free()
		return false

	view.update_cook_work(false, &"meja_potong", 0.25) # total 0.35s berlalu (> 0.3s linger)
	if view.is_visible_emote:
		push_error("Emote should hide after linger expired")
		view.free()
		return false

	view.free()
	return true

static func _test_crowd_controller_density_and_reaction() -> bool:
	var crowd: Node = CrowdControllerScript.new()
	
	# 1. Density NORMAL: 6 members
	crowd.set_density(CrowdControllerScript.Density.NORMAL)
	if crowd.crowd_members.size() != 6:
		push_error("NORMAL density should have 6 members, got: %d" % crowd.crowd_members.size())
		crowd.free()
		return false

	# 2. Density LOW: 3 members
	crowd.set_density(CrowdControllerScript.Density.LOW)
	if crowd.crowd_members.size() != 3:
		push_error("LOW density should have 3 members, got: %d" % crowd.crowd_members.size())
		crowd.free()
		return false

	# 3. Density OFF: 0 members
	crowd.set_density(CrowdControllerScript.Density.OFF)
	if crowd.crowd_members.size() != 0:
		push_error("OFF density should have 0 members")
		crowd.free()
		return false

	# 4. Reaction triggering (NORMAL density)
	crowd.set_density(CrowdControllerScript.Density.NORMAL)
	crowd.trigger_reaction(&"served")
	
	crowd.free()
	return true
