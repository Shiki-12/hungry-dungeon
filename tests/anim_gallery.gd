extends Control
## Galeri Animasi Interaktif Rangga & Manifest Aset.
## Menampilkan seluruh animasi Rangga dalam kategori, detail frame, pivot, dan kontrol interaktif.

const CATEGORIES: Array[Dictionary] = [
	{
		"name": "Diam",
		"anims": [
			"idle_down", "idle_up", "idle_side_left", "idle_side_right",
			"idle_battle_down", "idle_battle_up", "idle_battle_side_left", "idle_battle_side_right"
		]
	},
	{
		"name": "Jalan",
		"anims": [
			"walk_down", "walk_up", "walk_side_left", "walk_side_right",
			"walk_battle_down", "walk_battle_up", "walk_battle_side_left", "walk_battle_side_right"
		]
	},
	{
		"name": "Dash",
		"anims": [
			"dash_down", "dash_up", "dash_side_left", "dash_side_right",
			"dash_battle_down", "dash_battle_up", "dash_battle_side_left", "dash_battle_side_right"
		]
	},
	{
		"name": "Pukul 1",
		"anims": ["strike_1_down", "strike_1_up", "strike_1_side_left", "strike_1_side_right"]
	},
	{
		"name": "Pukul 2",
		"anims": ["strike_2_down", "strike_2_up", "strike_2_side_left", "strike_2_side_right"]
	},
	{
		"name": "Aksi",
		"anims": [
			"work", "throw_side_left", "throw_side_right",
			"shield_down", "shield_up", "shield_side_left", "shield_side_right",
			"knocked_down", "knocked_up", "knocked_side_left", "knocked_side_right"
		]
	}
]

var debug_overlay: bool = false
var is_playing: bool = true
var current_category_idx: int = 0
var current_anim_idx: int = 0
var _anim_time: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(480, 270)
	size = Vector2(480, 270)
	queue_redraw()

func _process(delta: float) -> void:
	if is_playing:
		_anim_time += delta
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return

	var key: int = (event as InputEventKey).keycode
	match key:
		KEY_F3:
			debug_overlay = not debug_overlay
		KEY_F5:
			get_tree().reload_current_scene()
		KEY_SPACE:
			is_playing = not is_playing
		KEY_TAB:
			current_category_idx = (current_category_idx + 1) % CATEGORIES.size()
			current_anim_idx = 0
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
			var idx: int = key - KEY_1
			if idx < CATEGORIES.size():
				current_category_idx = idx
				current_anim_idx = 0
		KEY_LEFT:
			var anim_list: Array = CATEGORIES[current_category_idx]["anims"] as Array
			current_anim_idx = (current_anim_idx - 1 + anim_list.size()) % anim_list.size()
		KEY_RIGHT:
			var anim_list: Array = CATEGORIES[current_category_idx]["anims"] as Array
			current_anim_idx = (current_anim_idx + 1) % anim_list.size()
		KEY_UP:
			current_category_idx = (current_category_idx - 1 + CATEGORIES.size()) % CATEGORIES.size()
			current_anim_idx = 0
		KEY_DOWN:
			current_category_idx = (current_category_idx + 1) % CATEGORIES.size()
			current_anim_idx = 0

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var vp: Vector2 = Vector2(480, 270)
	if is_inside_tree() and get_viewport() != null:
		var s: Vector2 = get_viewport_rect().size
		if s.x > 0.0:
			vp = s

	# Background
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.1, 0.12, 0.15))

	# Header (480x24)
	draw_rect(Rect2(0, 0, vp.x, 22), Color(0.16, 0.2, 0.25))
	draw_string(font, Vector2(8, 15), "GALERI ANIMASI RANGGA", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.85, 0.4))
	draw_string(font, Vector2(170, 15), "Space: Jeda/Play | Tab/1-6: Kategori | Panah: Pilih | F3: Pivot/Box", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.8, 0.8, 0.8))

	# Category Tabs (y = 24..38)
	var tab_x: float = 8.0
	for i: int in range(CATEGORIES.size()):
		var cat: Dictionary = CATEGORIES[i]
		var is_sel: bool = (i == current_category_idx)
		var cat_name: String = "%d. %s" % [i + 1, cat["name"]]
		var tab_w: float = font.get_string_size(cat_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 12.0
		var tab_col: Color = Color(0.25, 0.45, 0.7) if is_sel else Color(0.18, 0.22, 0.27)
		draw_rect(Rect2(tab_x, 26, tab_w, 14), tab_col)
		if is_sel:
			draw_rect(Rect2(tab_x, 26, tab_w, 14), Color(0.5, 0.8, 1.0), false, 1.0)
		draw_string(font, Vector2(tab_x + 6, 37), cat_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE if is_sel else Color(0.7, 0.7, 0.7))
		tab_x += tab_w + 4.0

	# Current category anims grid
	var cur_cat: Dictionary = CATEGORIES[current_category_idx]
	var anim_list: Array = cur_cat["anims"] as Array
	if current_anim_idx >= anim_list.size():
		current_anim_idx = 0

	var sf: SpriteFrames = Assets.frames(&"cook_rangga")
	if sf == null:
		draw_string(font, Vector2(8, 60), "SpriteFrames cook_rangga belum dimuat!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.RED)
		return

	# Grid area: Left side (cols of cards)
	var card_w: float = 72.0
	var card_h: float = 52.0
	var cols: int = 4
	var start_x: float = 8.0
	var start_y: float = 44.0

	for i: int in range(anim_list.size()):
		var a_name: String = anim_list[i] as String
		var s_name: StringName = StringName(a_name)
		var col: int = i % cols
		var row: int = i / cols
		var cx: float = start_x + col * (card_w + 4.0)
		var cy: float = start_y + row * (card_h + 4.0)

		var is_selected: bool = (i == current_anim_idx)
		var bg_col: Color = Color(0.2, 0.28, 0.38) if is_selected else Color(0.14, 0.16, 0.2)
		draw_rect(Rect2(cx, cy, card_w, card_h), bg_col)
		if is_selected:
			draw_rect(Rect2(cx, cy, card_w, card_h), Color(1.0, 0.85, 0.3), false, 1.5)

		if sf.has_animation(s_name):
			var fc: int = sf.get_frame_count(s_name)
			var fps: float = sf.get_animation_speed(s_name)
			var loop: bool = sf.get_animation_loop(s_name)
			var frame_idx: int = 0
			if fc > 0:
				if loop:
					frame_idx = int(_anim_time * fps) % fc
				else:
					frame_idx = mini(fc - 1, int(_anim_time * fps) % fc)
			var tex: Texture2D = sf.get_frame_texture(s_name, frame_idx) if fc > 0 else null

			# Render sprite in card
			if tex != null:
				var spr_scale: float = 0.2
				var spr_w: float = 160.0 * spr_scale
				var spr_h: float = 160.0 * spr_scale
				var spr_x: float = cx + (card_w - spr_w) * 0.5
				var spr_y: float = cy + card_h - spr_h - 10.0
				draw_texture_rect(tex, Rect2(spr_x, spr_y, spr_w, spr_h), false)

				if debug_overlay:
					# Pivot at bottom center
					var pivot_pt: Vector2 = Vector2(cx + card_w * 0.5, cy + card_h - 10.0)
					draw_line(pivot_pt - Vector2(3, 0), pivot_pt + Vector2(3, 0), Color.RED, 1.0)
					draw_line(pivot_pt - Vector2(0, 3), pivot_pt + Vector2(0, 3), Color.RED, 1.0)

			# Label below sprite
			var short_name: String = a_name.replace("strike_", "st_").replace("battle_", "b_")
			draw_string(font, Vector2(cx + 2, cy + card_h - 2), short_name, HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 4), 6, Color.WHITE)

	# Inspector Panel on the Right Side (x = 316..472, y = 44..262)
	var insp_x: float = 316.0
	var insp_w: float = vp.x - insp_x - 8.0
	draw_rect(Rect2(insp_x, start_y, insp_w, 218), Color(0.14, 0.17, 0.22))
	draw_rect(Rect2(insp_x, start_y, insp_w, 218), Color(0.3, 0.38, 0.48), false, 1.0)

	var sel_anim: String = anim_list[current_anim_idx] as String
	var sel_sname: StringName = StringName(sel_anim)

	draw_string(font, Vector2(insp_x + 8, start_y + 14), "INSPEKTOR ANIMASI", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.85, 0.4))
	draw_string(font, Vector2(insp_x + 8, start_y + 26), sel_anim, HORIZONTAL_ALIGNMENT_LEFT, int(insp_w - 16), 8, Color.WHITE)

	if sf.has_animation(sel_sname):
		var fc: int = sf.get_frame_count(sel_sname)
		var fps: float = sf.get_animation_speed(sel_sname)
		var loop: bool = sf.get_animation_loop(sel_sname)
		var frame_idx: int = 0
		if fc > 0:
			if loop:
				frame_idx = int(_anim_time * fps) % fc
			else:
				frame_idx = mini(fc - 1, int(_anim_time * fps) % fc)

		# Big Preview Canvas (x = insp_x + 8, y = start_y + 32, w = insp_w - 16, h = 90)
		var p_rect: Rect2 = Rect2(insp_x + 8, start_y + 32, insp_w - 16, 90)
		draw_rect(p_rect, Color(0.08, 0.1, 0.12))
		draw_rect(p_rect, Color(0.2, 0.25, 0.3), false, 1.0)

		# Ground line
		var ground_y: float = p_rect.position.y + 75.0
		draw_line(Vector2(p_rect.position.x, ground_y), Vector2(p_rect.end.x, ground_y), Color(0.25, 0.3, 0.35), 1.0)

		var big_tex: Texture2D = sf.get_frame_texture(sel_sname, frame_idx) if fc > 0 else null
		if big_tex != null:
			var scale_big: float = 0.45
			var bw: float = 160.0 * scale_big
			var bh: float = 160.0 * scale_big
			var bx: float = p_rect.position.x + (p_rect.size.x - bw) * 0.5
			var by: float = ground_y - bh
			draw_texture_rect(big_tex, Rect2(bx, by, bw, bh), false)

			if debug_overlay:
				# Bounding box
				draw_rect(Rect2(bx, by, bw, bh), Color(0.2, 0.9, 0.3, 0.5), false, 1.0)
				# Pivot at bottom-center
				var pivot_big: Vector2 = Vector2(p_rect.position.x + p_rect.size.x * 0.5, ground_y)
				draw_circle(pivot_big, 3.0, Color.RED)

		# Animation details
		var info_y: float = start_y + 134.0
		draw_string(font, Vector2(insp_x + 8, info_y), "Frame: %d / %d" % [frame_idx + 1, fc], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
		draw_string(font, Vector2(insp_x + 8, info_y + 12), "Speed: %.1f FPS" % fps, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.8, 0.8, 0.8))
		draw_string(font, Vector2(insp_x + 8, info_y + 24), "Loop: %s" % ("Ya (Loop)" if loop else "Tidak (Sekali)"), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.8, 0.8, 0.8))
		draw_string(font, Vector2(insp_x + 8, info_y + 36), "Status: FINAL (Resmi)", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.3, 0.9, 0.4))
		draw_string(font, Vector2(insp_x + 8, info_y + 48), "Dimensi: 160x160 px", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.7, 0.7, 0.7))
		draw_string(font, Vector2(insp_x + 8, info_y + 60), "Skala Dapur: 0.25 (40x40)", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.7, 0.7, 0.7))
		draw_string(font, Vector2(insp_x + 8, info_y + 72), "Status Play: %s" % ("JALAN" if is_playing else "JEDA"), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.YELLOW if not is_playing else Color.WHITE)
