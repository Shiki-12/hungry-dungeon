class_name CrowdController
extends Node2D

## Kerumunan monster latar murni di view/ layer (FR-CRD-01 s.d. 04).
## Tidak memiliki collision, state sim, maupun pesanan.
## Menggunakan RNG tampilan lokal dan mematuhi pengaturan kepadatan.

const AssetsScript: Script = preload("res://autoload/assets.gd")
const EmoteMapDataScript: Script = preload("res://data/emote_map_data.gd")

enum Density { OFF = 0, LOW = 1, NORMAL = 2 }

var density: Density = Density.NORMAL
var crowd_members: Array = []
var view_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var tunnel_origin: Vector2 = Vector2(21.0 * 16.0, 10.0) # Terowongan D

func _ready() -> void:
	view_rng.randomize()
	_refresh_crowd()

func set_density(new_density: int) -> void:
	density = clamp(new_density, 0, 2) as Density
	_refresh_crowd()

func _refresh_crowd() -> void:
	crowd_members.clear()
	if density == Density.OFF:
		queue_redraw()
		return

	var count: int = 3 if density == Density.LOW else 6
	for i: int in range(count):
		# Posisi awal di sekitar dungeon / kanan lapak (kolom 22 s.d. 28, baris 1 s.d. 12)
		var rx: float = view_rng.randf_range(22.0 * 16.0, 28.0 * 16.0)
		var ry: float = view_rng.randf_range(20.0, 200.0)
		crowd_members.append({
			"pos": Vector2(rx, ry),
			"target": Vector2(rx, ry),
			"speed": view_rng.randf_range(15.0, 30.0),
			"anim_tag": &"walk",
			"emote_id": &"",
			"emote_timer": 0.0,
			"idle_timer": view_rng.randf_range(1.0, 4.0),
			"color": Color(0.7, 0.35, 0.45, 0.85)
		})
	queue_redraw()

func trigger_reaction(reaction_type: StringName) -> void:
	# FR-CRD-02: Bereaksi lewat emoticon pada event
	var emote_to_show: StringName = &"emote_happy"
	match reaction_type:
		&"served", &"jitu":
			var opts: Array[StringName] = [&"emote_happy", &"emote_yum", &"emote_cheer", &"emote_music"]
			emote_to_show = opts[view_rng.randi() % opts.size()]
		&"rage", &"attacking":
			emote_to_show = &"emote_scared"
		&"enraged":
			emote_to_show = &"emote_grumble"
		&"steal":
			emote_to_show = &"emote_panic"
		_:
			emote_to_show = &"emote_chat"

	for member: Dictionary in crowd_members:
		if view_rng.randf() < 0.7: # 70% kerumunan bereaksi
			member["emote_id"] = emote_to_show
			member["emote_timer"] = view_rng.randf_range(1.5, 2.5)
	queue_redraw()

func _process(delta: float) -> void:
	if density == Density.OFF or crowd_members.is_empty():
		return

	for member: Dictionary in crowd_members:
		# Update timer emoticon
		if float(member["emote_timer"]) > 0.0:
			member["emote_timer"] = float(member["emote_timer"]) - delta
			if float(member["emote_timer"]) <= 0.0:
				member["emote_id"] = &""

		# Update pergerakan latar
		var idle: float = float(member["idle_timer"]) - delta
		if idle <= 0.0:
			# Pilih target jalan santai baru
			var nx: float = view_rng.randf_range(22.0 * 16.0, 28.0 * 16.0)
			var ny: float = view_rng.randf_range(20.0, 200.0)
			member["target"] = Vector2(nx, ny)
			member["idle_timer"] = view_rng.randf_range(3.0, 6.0)
		else:
			member["idle_timer"] = idle
			var cur: Vector2 = member["pos"]
			var tgt: Vector2 = member["target"]
			if cur.distance_to(tgt) > 1.0:
				member["pos"] = cur.move_toward(tgt, float(member["speed"]) * delta)

	queue_redraw()

func _draw() -> void:
	if density == Density.OFF:
		return

	for member: Dictionary in crowd_members:
		var p: Vector2 = member["pos"]
		var c: Color = member["color"]
		
		# Gambar siluet/placeholder monster latar (32x32 atau 16x16)
		draw_circle(p, 6.0, c)
		draw_rect(Rect2(p - Vector2(5.0, 2.0), Vector2(10.0, 10.0)), c)
		
		# Gambar balon emoticon jika ada reaksi aktif
		var emote: StringName = member["emote_id"]
		if emote != &"":
			var ep: Vector2 = p + Vector2(6.0, -14.0)
			draw_circle(ep, 6.0, Color(0.95, 0.45, 0.75, 0.9))
			draw_arc(ep, 6.0, 0, TAU, 12, Color.WHITE, 1.0)
			var short_txt: String = String(emote).trim_prefix("emote_").substr(0, 3)
			draw_string(ThemeDB.fallback_font, ep + Vector2(-4.0, 3.0), short_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color.WHITE)
