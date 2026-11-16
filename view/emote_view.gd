class_name EmoteView
extends Node2D

## Tampilan Emoticon 16x16 px di atas entitas (FR-EMO-01 s.d. FR-EMO-06).
## Satu emoticon per entitas, jangkar sesuai jenis meja/posisi.

const AssetsScript: Script = preload("res://autoload/assets.gd")
const EmoteMapDataScript: Script = preload("res://data/emote_map_data.gd")

const WORK_EMOTE_LINGER: float = 0.3 # Tetap tampil 0.3s setelah work dilepas (FR-EMO-03)

var current_emote_id: StringName = &""
var is_visible_emote: bool = false
var linger_timer: float = 0.0
var anim_timer: float = 0.0
var current_frame: int = 0
var is_long_table_seat: bool = false

# Offset jangkar (FR-EMO-04)
# Default: kanan-atas kepala. Meja panjang: tepat di atas kepala agar tidak bentrok dengan balon pesanan di kanan
const OFFSET_DEFAULT: Vector2 = Vector2(8.0, -14.0)
const OFFSET_LONG_TABLE: Vector2 = Vector2(0.0, -16.0)

func set_long_table(is_long: bool) -> void:
	is_long_table_seat = is_long

func show_emote(emote_id: StringName, duration: float = 0.0) -> void:
	if not EmoteMapDataScript.is_valid_emote_id(emote_id):
		return
	current_emote_id = emote_id
	is_visible_emote = true
	linger_timer = duration
	anim_timer = 0.0
	current_frame = 0
	queue_redraw()

func update_cook_work(is_working: bool, station_type: StringName, delta: float) -> void:
	if is_working:
		var emote: StringName = EmoteMapDataScript.get_cook_work_emote(station_type)
		if emote != &"":
			current_emote_id = emote
			is_visible_emote = true
			linger_timer = WORK_EMOTE_LINGER
	else:
		if linger_timer > 0.0:
			linger_timer -= delta
			if linger_timer <= 0.0:
				is_visible_emote = false
				current_emote_id = &""
		else:
			is_visible_emote = false
			current_emote_id = &""

func update_monster(state: int, stage: int) -> void:
	var emote: StringName = EmoteMapDataScript.get_monster_emote(state, stage)
	if emote != &"":
		current_emote_id = emote
		is_visible_emote = true
	else:
		is_visible_emote = false
		current_emote_id = &""

func hide_emote() -> void:
	is_visible_emote = false
	current_emote_id = &""
	linger_timer = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if is_visible_emote:
		anim_timer += delta
		# 6 FPS loop animasi 3 frame (FR-AST-04)
		current_frame = int(anim_timer * 6.0) % 3
		queue_redraw()

func get_anchor_offset() -> Vector2:
	return OFFSET_LONG_TABLE if is_long_table_seat else OFFSET_DEFAULT

func _draw() -> void:
	if not is_visible_emote or current_emote_id == &"":
		return
	var offset: Vector2 = get_anchor_offset()
	var rect_pos: Vector2 = offset - Vector2(8.0, 8.0)
	
	# Ambil tekstur dari Assets jika tersedia
	var loop: MainLoop = Engine.get_main_loop()
	var tex: Texture2D = null
	if loop is SceneTree and (loop as SceneTree).root:
		var assets_node: Node = (loop as SceneTree).root.get_node_or_null("Assets")
		if assets_node != null and assets_node.has_method("texture"):
			tex = assets_node.call("texture", current_emote_id)

	if tex != null:
		draw_texture(tex, rect_pos)
	else:
		# Fallback placeholder box_pink 16x16
		draw_rect(Rect2(rect_pos, Vector2(16.0, 16.0)), Color(0.95, 0.45, 0.75, 0.95))
		draw_rect(Rect2(rect_pos, Vector2(16.0, 16.0)), Color.WHITE, false, 1.0)
		var short_tag: String = String(current_emote_id).trim_prefix("emote_").substr(0, 3)
		draw_string(ThemeDB.fallback_font, rect_pos + Vector2(2.0, 11.0), short_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color.WHITE)
