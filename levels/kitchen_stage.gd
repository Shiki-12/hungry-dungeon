extends Node2D

## Kitchen Stage — Integration scene for Stage 1.
## Connects sim systems to view layer, handles input routing for 2P co-op.

const CookScript: Script = preload("res://sim/entities/cook.gd")
const CollisionScript: Script = preload("res://sim/systems/collision.gd")
const OrdersScript: Script = preload("res://sim/systems/orders.gd")
const ScoringScript: Script = preload("res://sim/systems/scoring.gd")
const CombatScript: Script = preload("res://sim/systems/combat.gd")
const HazardScript: Script = preload("res://sim/systems/hazards.gd")
const MonsterScript: Script = preload("res://sim/entities/monster.gd")
const StationScript: Script = preload("res://sim/entities/station.gd")
const StationDataScript: Script = preload("res://data/station_data.gd")
const ItemScript: Script = preload("res://sim/entities/item.gd")
const PlatePoolScript: Script = preload("res://sim/systems/plate_pool.gd")
const LevelDataScript: Script = preload("res://data/level_data.gd")
const ThrowSystemScript: Script = preload("res://sim/systems/throw_system.gd")
const ThrowPreviewScript: Script = preload("res://view/throw_preview_view.gd")
const ProjectileViewScript: Script = preload("res://view/projectile_view.gd")
const SkillSystemScript: Script = preload("res://sim/systems/skills.gd")
const EmoteViewScript: Script = preload("res://view/emote_view.gd")
const CrowdControllerScript: Script = preload("res://view/crowd_controller.gd")
const OrderBubbleViewScript: Script = preload("res://view/order_bubble_view.gd")
const LapakModuleScript: Script = preload("res://levels/lapak_module.gd")
const SeatScript: Script = preload("res://sim/entities/seat.gd")
const CookViewScript: Script = preload("res://view/cook_view.gd")

const HudTopScene: PackedScene = preload("res://ui/hud_top.tscn")
const HudBottomScene: PackedScene = preload("res://ui/hud_bottom.tscn")
const PauseMenuScene: PackedScene = preload("res://ui/pause_menu.tscn")

const TILE: float = 16.0
const HUD_TOP_H: float = 30.0
const KITCHEN_H: float = 224.0
const HUD_BOT_H: float = 16.0
const KITCHEN_W: float = 480.0
const KITCHEN_OFFSET: Vector2 = Vector2(0.0, HUD_TOP_H)

# --- Sim State ---
var cook_p1: RefCounted
var cook_p2: RefCounted
var lapak: Node
var orders: RefCounted
var scoring: RefCounted
var combat: RefCounted
var hazards: RefCounted
var plate_pool: RefCounted
var throw_system: RefCounted
var skills: RefCounted
var level_data: Resource
var monsters: Array = []
var stations: Array = []
var floor_items: Array = []
var static_obstacles: Array[Rect2] = []
var level_timer: float = 0.0
var level_active: bool = false
var monster_spawn_timer: float = 0.0
var next_monster_id: int = 100
var throw_hold_times: Dictionary = {"p1": 0.0, "p2": 0.0}
var eating_timers: Dictionary = {}
var raw_ingredient_toggle: bool = false

# --- View Nodes ---
var kitchen_layer: Node2D
var hud_top: Control
var hud_bot: Control
var banner_panel: Control
var banner_label: Label
var banner_timer: float = 0.0

var throw_preview_p1: Node2D
var throw_preview_p2: Node2D
var projectile_view: Node2D
var emote_view_p1: Node2D
var emote_view_p2: Node2D
var crowd_controller: Node2D
var monster_bubbles: Dictionary = {}
var cook_view_p1: Node2D
var cook_view_p2: Node2D

# --- Level paths for debug switching ---
const LEVEL_PATHS: Array[String] = [
	"res://data/levels/level_1_1.tres",
	"res://data/levels/level_1_2.tres",
	"res://data/levels/level_1_3.tres",
	"res://data/levels/level_1_4.tres",
]

func _ready() -> void:
	_build_ui()
	var target_path: String = LEVEL_PATHS[0]
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree and (loop as SceneTree).root:
		var game_node: Node = (loop as SceneTree).root.get_node_or_null("Game")
		if game_node and not String(game_node.get("current_level_id")).is_empty():
			var cur_id: String = String(game_node.get("current_level_id")).replace("-", "_")
			if not cur_id.begins_with("level_") and not cur_id.begins_with("tutorial_"):
				cur_id = "level_" + cur_id
			var test_path: String = "res://data/levels/%s.tres" % cur_id
			if ResourceLoader.exists(test_path):
				target_path = test_path
	load_level(target_path)

func _build_ui() -> void:
	# HUD Top (480x30 px) — FR-UI-01
	hud_top = HudTopScene.instantiate()
	add_child(hud_top)

	# Kitchen layer
	kitchen_layer = Node2D.new()
	kitchen_layer.position = KITCHEN_OFFSET
	kitchen_layer.y_sort_enabled = true
	add_child(kitchen_layer)

	# HUD Bottom (480x16 px) — FR-UI-02
	hud_bot = HudBottomScene.instantiate()
	hud_bot.position = Vector2(0, HUD_TOP_H + KITCHEN_H)
	add_child(hud_bot)

	# Banner Notifikasi Sementara di bagian atas area dapur (FR-UI-01 / pembersihan HUD bawah)
	banner_panel = Control.new()
	banner_panel.position = Vector2(120.0, HUD_TOP_H + 4.0)
	banner_panel.size = Vector2(240.0, 16.0)
	banner_panel.visible = false
	add_child(banner_panel)

	var bg_rect: ColorRect = ColorRect.new()
	bg_rect.size = Vector2(240.0, 16.0)
	bg_rect.color = Color(0.12, 0.15, 0.18, 0.88)
	banner_panel.add_child(bg_rect)

	banner_label = Label.new()
	banner_label.size = Vector2(240.0, 16.0)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", 8)
	banner_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	banner_label.text = ""
	banner_panel.add_child(banner_label)

func show_banner(text: String, duration: float = 3.5) -> void:
	if banner_label != null and banner_panel != null:
		banner_label.text = text
		banner_timer = duration

		var vp_x: float = 480.0
		if is_inside_tree() and get_viewport() != null:
			var s: Vector2 = get_viewport_rect().size
			if s.x > 0.0:
				vp_x = s.x
		var font: Font = banner_label.get_theme_font("font")
		if font == null:
			font = ThemeDB.fallback_font
		var text_w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var banner_w: float = clampf(text_w + 24.0, 160.0, vp_x - 16.0)
		banner_panel.size = Vector2(banner_w, 16.0)
		banner_panel.position = Vector2((vp_x - banner_w) * 0.5, HUD_TOP_H + 4.0)
		for child: Node in banner_panel.get_children():
			if child is Control:
				(child as Control).size = Vector2(banner_w, 16.0)
		banner_panel.visible = true

func _show_popup_for_level(id: StringName) -> void:
	match id:
		&"level_1_1":
			show_banner("Level 1-1: Bekal Terakhir (Sajikan ke Meja Panjang!)", 4.0)
		&"level_1_2":
			show_banner("Level 1-2: Cuci Piring! (Tahan F / , di Tempat Cuci)", 4.0)
		&"level_1_3":
			show_banner("Level 1-3: Awas Pencuri! (Gunakan Dash / Kuali)", 4.0)
		&"level_1_4":
			show_banner("Level 1-4: Pesta Goblin! (Jaga Dapur & Masak)", 4.0)
		_:
			show_banner(String(id), 3.0)

func load_level(path: String) -> void:
	_clear_level()
	level_data = load(path)
	if level_data == null:
		push_error("Cannot load level: " + path)
		return

	# Init sim systems
	scoring = ScoringScript.new()
	combat = CombatScript.new()
	hazards = HazardScript.new()
	hazards.configure_from_level(level_data)
	orders = OrdersScript.new(42)
	orders.max_open_tickets = level_data.max_open_tickets if "max_open_tickets" in level_data else 2
	var p_count: int = level_data.plate_count if "plate_count" in level_data else 4
	var w_enabled: bool = level_data.washing_enabled if "washing_enabled" in level_data else false
	plate_pool = PlatePoolScript.new(p_count, w_enabled)
	throw_system = ThrowSystemScript.new()
	skills = SkillSystemScript.new()
	skills.configure_from_level(level_data)

	# Lapak Seating
	var small_count: int = 0
	if level_data.seating != null and level_data.seating.has_method("get"):
		small_count = level_data.seating.small_tables if "small_tables" in level_data.seating else 0
	elif "seating" in level_data and level_data.seating != null:
		small_count = level_data.seating.small_tables if level_data.seating.get("small_tables") != null else 0
	lapak = LapakModuleScript.new(5, small_count)
	kitchen_layer.add_child(lapak)

	# Cooks initial placement (FR-MOV-01)
	cook_p1 = CookScript.new()
	cook_p1.cook_id = 1
	cook_p1.cook_name = "Rangga"
	cook_p1.position = Vector2(5 * TILE, 7 * TILE)
	cook_p2 = CookScript.new()
	cook_p2.cook_id = 2
	cook_p2.cook_name = "Sekar"
	cook_p2.position = Vector2(7 * TILE, 7 * TILE)

	# Cook Views (FR-AST-01, AnimatedSprite2D / placeholder)
	cook_view_p1 = CookViewScript.new()
	cook_view_p1.setup(cook_p1, &"cook_rangga")
	kitchen_layer.add_child(cook_view_p1)

	cook_view_p2 = CookViewScript.new()
	cook_view_p2.setup(cook_p2, &"cook_sekar")
	kitchen_layer.add_child(cook_view_p2)

	# Stations & Obstacles
	_spawn_stations()
	_build_obstacles()

	# Crowd controller
	crowd_controller = CrowdControllerScript.new()
	kitchen_layer.add_child(crowd_controller)

	# Throw views
	throw_preview_p1 = ThrowPreviewScript.new()
	throw_preview_p2 = ThrowPreviewScript.new()
	projectile_view = ProjectileViewScript.new()
	kitchen_layer.add_child(throw_preview_p1)
	kitchen_layer.add_child(throw_preview_p2)
	kitchen_layer.add_child(projectile_view)

	# Emote views for cooks
	emote_view_p1 = EmoteViewScript.new()
	emote_view_p2 = EmoteViewScript.new()
	kitchen_layer.add_child(emote_view_p1)
	kitchen_layer.add_child(emote_view_p2)

	# Redraw BG
	_draw_kitchen_bg()

	# Start level
	var dur: float = level_data.duration_sec if "duration_sec" in level_data else 180.0
	level_timer = dur
	level_active = true
	monster_spawn_timer = 2.0
	var lid: StringName = level_data.id if "id" in level_data else &"level_1_1"
	Game.start_level(lid, dur)
	_show_popup_for_level(lid)

func _clear_level() -> void:
	level_active = false
	monsters.clear()
	stations.clear()
	floor_items.clear()
	static_obstacles.clear()
	eating_timers.clear()
	monster_bubbles.clear()
	cook_view_p1 = null
	cook_view_p2 = null
	throw_hold_times["p1"] = 0.0
	throw_hold_times["p2"] = 0.0
	if kitchen_layer != null:
		for child: Node in kitchen_layer.get_children():
			child.queue_free()

func _spawn_stations() -> void:
	var station_defs: Array[Dictionary] = [
		{"id": &"peti_bahan", "pos": Vector2(1, 1), "color": Color("#8d6e63")},
		{"id": &"peti_nasi", "pos": Vector2(1, 3), "color": Color("#a1887f")},
		{"id": &"meja_potong", "pos": Vector2(3, 2), "color": Color("#78909c")},
		{"id": &"meja_kerja", "pos": Vector2(5, 2), "color": Color("#90a4ae")},
		{"id": &"cobek", "pos": Vector2(3, 4), "color": Color("#8d6e63")},
		{"id": &"tungku", "pos": Vector2(5, 4), "color": Color("#ff5722")},
		{"id": &"meja_alas", "pos": Vector2(7, 2), "color": Color("#bcaaa4")},
		{"id": &"rak_piring", "pos": Vector2(9, 1), "color": Color("#d7ccc8")},
		{"id": &"tempat_cuci", "pos": Vector2(9, 3), "color": Color("#4fc3f7")},
		{"id": &"tempat_sampah", "pos": Vector2(9, 5), "color": Color("#616161")},
	]
	for def: Dictionary in station_defs:
		var sd: Resource = StationDataScript.new()
		sd.id = def["id"]
		sd.capacity = 1
		if def["id"] == &"tungku":
			sd.auto_work = true
			sd.burn_duration = 10.0
		var sim: RefCounted = StationScript.new(sd)
		stations.append({
			"sim": sim,
			"pos": def["pos"],
			"color": def["color"],
			"id": def["id"],
			"held_item": "",
			"components": []
		})
		var view: Node2D = Node2D.new()
		view.position = Vector2(def["pos"].x * TILE + 8, def["pos"].y * TILE + 8)
		view.set_meta(&"station_id", def["id"])
		kitchen_layer.add_child(view)

func _build_obstacles() -> void:
	static_obstacles.clear()
	# 1. Dinding atas (r0: y 0..16) & Dinding bawah (r13: y 208..224) — FR-LAY-04
	static_obstacles.append(Rect2(0.0, 0.0, KITCHEN_W, TILE))
	static_obstacles.append(Rect2(0.0, KITCHEN_H - TILE, KITCHEN_W, TILE))

	# 2. Gerobak Lapak di tepi kiri: kolom 0-1, baris 4-5 (x 0..32, y 64..96)
	static_obstacles.append(Rect2(0.0, 4.0 * TILE, 2.0 * TILE, 2.0 * TILE))

	# 3. Meja Panjang di kolom 12: baris 1 s.d. 10 (x 192..208, y 16..176) — FR-LAY-04
	# Celah gerbang baris 11-12 (y 176..208) TIDAK dihalangi agar koki bisa menyeberang
	static_obstacles.append(Rect2(12.0 * TILE, 1.0 * TILE, TILE, 10.0 * TILE))

	# 4. Kotak-kotak 10 Stasiun Dapur (16x16 px per stasiun) — FR-MOV-02
	for st: Dictionary in stations:
		var spos: Vector2 = st["pos"]
		static_obstacles.append(Rect2(spos.x * TILE, spos.y * TILE, TILE, TILE))

	# 5. Meja Kecil di sisi dungeon (jika ada)
	if lapak and "small_tables" in lapak:
		for tbl: RefCounted in lapak.small_tables:
			if tbl.seats.size() > 0:
				var center_x: float = (tbl.seats[0].position.x + tbl.seats[-1].position.x) * 0.5
				var center_y: float = tbl.seats[0].position.y
				static_obstacles.append(Rect2(center_x - 8.0, center_y - 8.0, 16.0, 16.0))

func _draw_kitchen_bg() -> void:
	queue_redraw()

func _draw() -> void:
	# 1. Kitchen area BG
	draw_rect(Rect2(0, HUD_TOP_H, 480, KITCHEN_H), Color(0.22, 0.18, 0.14))
	# Tikar lapak (kolom 0-11)
	draw_rect(Rect2(0, HUD_TOP_H, 12 * TILE, KITCHEN_H), Color(0.35, 0.28, 0.18))
	# Meja Panjang (kolom 12, r1-10)
	for r: int in range(1, 11):
		draw_rect(Rect2(12 * TILE, HUD_TOP_H + r * TILE, TILE, TILE), Color(0.45, 0.3, 0.15))
	# Gerbang terbuka (kolom 12, r11-12)
	draw_rect(Rect2(12 * TILE, HUD_TOP_H + 11 * TILE, TILE, 2 * TILE), Color(0.3, 0.25, 0.2))
	# Gerobak lapak (kolom 0-1, r4-5)
	draw_rect(Rect2(0, HUD_TOP_H + 4 * TILE, 2 * TILE, 2 * TILE), Color(0.5, 0.35, 0.2))
	draw_string(ThemeDB.fallback_font, Vector2(4, HUD_TOP_H + 4 * TILE + 20), "GEROBAK", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color.WHITE)

	# 2. Station boxes & progress bars
	for st: Dictionary in stations:
		_draw_station(st)

	# 3. Floor items
	for item: Dictionary in floor_items:
		var fpos: Vector2 = Vector2(item["pos"].x, HUD_TOP_H + item["pos"].y)
		draw_rect(Rect2(fpos.x - 4, fpos.y - 4, 8, 8), Color(0.9, 0.8, 0.4))
		draw_rect(Rect2(fpos.x - 4, fpos.y - 4, 8, 8), Color.WHITE, false, 1.0)

	# 4. Seats & Plates on table
	if lapak:
		for seat: RefCounted in lapak.all_seats():
			var sx: float = seat.position.x
			var sy: float = HUD_TOP_H + seat.position.y
			var seat_color: Color = Color(0.6, 0.45, 0.3)
			if seat.occupant_monster_id >= 0:
				seat_color = Color(0.8, 0.3, 0.5)
			draw_rect(Rect2(sx - 4, sy - 4, 8, 8), seat_color)

			# Tampilkan piring di atas meja/kursi
			var pstate: StringName = seat.plate_state if "plate_state" in seat else &"NONE"
			if pstate == &"DIRTY":
				draw_rect(Rect2(sx - 5, sy - 9, 10, 4), Color(0.45, 0.4, 0.35))
				draw_rect(Rect2(sx - 5, sy - 9, 10, 4), Color(0.2, 0.2, 0.2), false, 1.0)
			elif pstate == &"SERVED":
				draw_rect(Rect2(sx - 5, sy - 9, 10, 4), Color(1.0, 0.95, 0.8))
				draw_rect(Rect2(sx - 5, sy - 9, 10, 4), Color(0.8, 0.5, 0.2), false, 1.0)

	# 5. Cooks (hanya digambar primitive jika belum FINAL)
	if cook_p1 and Assets.status(&"cook_rangga") != &"FINAL":
		_draw_cook(cook_p1, Color(0.16, 0.5, 0.73))
	if cook_p2 and Assets.status(&"cook_sekar") != &"FINAL":
		_draw_cook(cook_p2, Color(0.83, 0.33, 0.0))

	# 6. Monsters
	for m: RefCounted in monsters:
		_draw_monster(m)

func _draw_station(st: Dictionary) -> void:
	var px: Vector2 = Vector2(st["pos"].x * TILE, HUD_TOP_H + st["pos"].y * TILE)
	draw_rect(Rect2(px, Vector2(TILE, TILE)), st["color"])
	_draw_station_label(px, st["id"])

	var sim: RefCounted = st["sim"]
	# Progress bar 16x3 px (FR-INT-03)
	if sim.state == StationScript.State.PROCESSING and sim.step_duration > 0.0:
		var pct: float = clampf(sim.progress / sim.step_duration, 0.0, 1.0)
		var bar_pos: Vector2 = px + Vector2(0.0, -4.0)
		draw_rect(Rect2(bar_pos, Vector2(16.0, 3.0)), Color(0.1, 0.1, 0.1, 0.8))
		draw_rect(Rect2(bar_pos, Vector2(16.0 * pct, 3.0)), Color(0.2, 0.85, 0.3))

	# Attention indicator (FR-STA-04 s.d. 07)
	if sim.needs_attention:
		var att_pos: Vector2 = px + Vector2(1.0, -11.0)
		draw_rect(Rect2(att_pos, Vector2(14.0, 6.0)), Color(0.95, 0.8, 0.1))
		draw_string(ThemeDB.fallback_font, att_pos + Vector2(1.0, 5.0), "ADUK!", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color.BLACK)

	# Ready / Burning indicator
	if sim.state == StationScript.State.READY:
		draw_rect(Rect2(px + Vector2(2, 2), Vector2(12, 12)), Color(0.2, 0.9, 0.4, 0.35))
	elif sim.state == StationScript.State.BURNING:
		draw_rect(Rect2(px + Vector2(2, 2), Vector2(12, 12)), Color(0.9, 0.3, 0.1, 0.5))
	elif sim.state == StationScript.State.BURNT:
		draw_rect(Rect2(px + Vector2(2, 2), Vector2(12, 12)), Color(0.1, 0.1, 0.1, 0.8))

	# Held item indicator on table alas
	if st["id"] == &"meja_alas" and st["held_item"] != "":
		var tag: String = String(st["held_item"]).substr(0, 3).to_upper()
		draw_string(ThemeDB.fallback_font, px + Vector2(2, 8), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color.YELLOW)

func _draw_cook(cook: RefCounted, color: Color) -> void:
	var px: Vector2 = Vector2(cook.position.x, HUD_TOP_H + cook.position.y)
	draw_rect(Rect2(px.x - 6, px.y - 7, 12, 14), color)
	var arrow_end: Vector2 = px + cook.facing_direction * 10.0
	draw_line(px, arrow_end, Color.WHITE, 1.0)
	var tag: String = "P1" if cook.cook_id == 1 else "P2"
	draw_string(ThemeDB.fallback_font, Vector2(px.x - 8, px.y - 10), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color.WHITE)

	# Held item representation above head (FR-INT-01: sprite/box 16x16 di atas kepala)
	if cook.held_item_id != "":
		var h_pos: Vector2 = px + Vector2(-6.0, -22.0)
		var h_color: Color = Color(0.9, 0.85, 0.7)
		var h_str: String = String(cook.held_item_id).substr(0, 4).to_upper()
		if cook.held_item_id.begins_with("dish_"):
			h_color = Color(1.0, 0.65, 0.2)
		elif cook.held_item_id == "kuali":
			h_color = Color(0.3, 0.35, 0.4)
		elif cook.held_item_id.begins_with("item_"):
			h_color = Color(0.4, 0.8, 0.5)
		draw_rect(Rect2(h_pos, Vector2(12.0, 10.0)), h_color)
		draw_rect(Rect2(h_pos, Vector2(12.0, 10.0)), Color.WHITE, false, 1.0)
		draw_string(ThemeDB.fallback_font, h_pos + Vector2(1.0, 8.0), h_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color.BLACK)

func _draw_monster(m: RefCounted) -> void:
	var px: Vector2 = Vector2(m.position.x, HUD_TOP_H + m.position.y)
	var color: Color = Color(0.55, 0.27, 0.68)
	if m.state == 7 or m.state == 8: # ENRAGED or ATTACKING
		color = Color(0.91, 0.3, 0.24)
	elif m.state == 9: # STEAL_RUN
		color = Color(0.95, 0.61, 0.07)
	elif m.state == 4: # EATING
		color = Color(0.3, 0.8, 0.4)
	draw_rect(Rect2(px.x - 6, px.y - 7, 12, 14), color)

func _draw_station_label(px: Vector2, id: StringName) -> void:
	var short: String = String(id).substr(0, 4)
	draw_string(ThemeDB.fallback_font, Vector2(px.x + 1, px.y + 12), short, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(1, 1, 1, 0.7))

func _physics_process(delta: float) -> void:
	if not level_active:
		return

	# Banner timer
	if banner_timer > 0.0:
		banner_timer -= delta
		if banner_timer <= 0.0 and banner_panel != null:
			banner_panel.visible = false

	# Input handling for 2P local co-op
	_handle_cook_input(cook_p1, "p1", delta, throw_preview_p1, emote_view_p1)
	_handle_cook_input(cook_p2, "p2", delta, throw_preview_p2, emote_view_p2)

	# Sim ticks
	if lapak:
		lapak.tick(delta)
	if orders:
		orders.tick(delta)
	if hazards:
		hazards.tick(delta)
	if skills:
		skills.tick(delta)
	if plate_pool:
		plate_pool.tick(delta)

	# Station ticks & automatic cooking logic
	_tick_stations(delta)

	# Throw system tick
	if throw_system and lapak:
		var seats: Array = lapak.all_seats()
		var resolved: Array[Dictionary] = throw_system.tick(delta, seats, cook_p2, stations, monsters, plate_pool, scoring)
		for ev: Dictionary in resolved:
			_handle_throw_resolved_event(ev)
		if projectile_view:
			projectile_view.update_projectiles(throw_system.active_projectiles)

	# Update emote view positions
	if emote_view_p1 and cook_p1:
		emote_view_p1.position = cook_p1.position
	if emote_view_p2 and cook_p2:
		emote_view_p2.position = cook_p2.position

	# Monster lifecycle & spawn
	_tick_monsters(delta)
	_tick_monster_spawn(delta)

	# Hostile threat detection for cook battle mode
	var p1_threat: bool = false
	var p2_threat: bool = false
	for m: RefCounted in monsters:
		if m.state in [7, 8, 9]:
			if cook_p1 and m.position.distance_to(cook_p1.position) < 140.0:
				p1_threat = true
			if cook_p2 and m.position.distance_to(cook_p2.position) < 140.0:
				p2_threat = true
	if cook_view_p1 != null:
		cook_view_p1.hostile_threat_nearby = p1_threat
	if cook_view_p2 != null:
		cook_view_p2.hostile_threat_nearby = p2_threat

	# Level timer
	level_timer -= delta
	if level_timer <= 0.0:
		level_active = false
		var stars: int = scoring.stars_for(level_data) if (scoring and level_data and "one_star_score" in level_data) else 1
		Game.end_level(true, stars)

	# Update HUD & View
	_update_hud()
	queue_redraw()

func _tick_stations(delta: float) -> void:
	for st: Dictionary in stations:
		var sim: RefCounted = st["sim"]
		sim.tick(delta)

		# Auto-work station: Tungku
		if st["id"] == &"tungku":
			if sim.state == StationScript.State.PROCESSING and sim.step_duration > 0.0:
				if sim.progress >= sim.step_duration:
					sim.finish_step(&"dish_nasi_goreng_jamur")
			elif sim.state == StationScript.State.READY or sim.state == StationScript.State.BURNING:
				if sim.burn_timer <= 0.0:
					sim.state = StationScript.State.BURNT
					sim.held_item_id = &"dish_burnt"
				elif sim.burn_timer <= 4.0:
					sim.state = StationScript.State.BURNING

		# Tempat cuci piring otomatis bersih jika progres selesai
		if st["id"] == &"tempat_cuci":
			if sim.state == StationScript.State.PROCESSING and sim.step_duration > 0.0 and sim.progress >= sim.step_duration:
				sim.clear_contents()
				if plate_pool:
					plate_pool.return_lost_plate()
				if projectile_view:
					projectile_view.add_floating_label("Piring Bersih!", Vector2(9 * TILE + 8, 3 * TILE), Color(0.4, 0.8, 1.0))

func _handle_cook_input(cook: RefCounted, prefix: String, delta: float, preview_view: Node2D, emote_view: Node2D) -> void:
	# 1. Movement & Collision against static obstacles (FR-MOV-02, FR-MOV-08, FR-LAY-04)
	var input_vec: Vector2 = Vector2.ZERO
	if Input.is_action_pressed(prefix + "_move_up"):
		input_vec.y -= 1.0
	if Input.is_action_pressed(prefix + "_move_down"):
		input_vec.y += 1.0
	if Input.is_action_pressed(prefix + "_move_left"):
		input_vec.x -= 1.0
	if Input.is_action_pressed(prefix + "_move_right"):
		input_vec.x += 1.0

	cook.step(input_vec, delta, [], static_obstacles)
	# Clamp position inside kitchen arena (480x224 px)
	cook.position.x = clampf(cook.position.x, 6.0, KITCHEN_W - 6.0)
	cook.position.y = clampf(cook.position.y, 6.0, KITCHEN_H - 6.0)

	# 2. Interact (E / Period) — Take, Put, Assemble, Serve Samperin (FR-INT-02, FR-SRV-01)
	if Input.is_action_just_pressed(prefix + "_interact"):
		_handle_cook_interact(cook)

	# 3. Work (F / Comma) — Manual station work & attention (FR-INT-03, FR-STA-04)
	var is_working: bool = Input.is_action_pressed(prefix + "_work")
	_handle_cook_work(cook, is_working)
	if emote_view != null:
		emote_view.update_cook_work(is_working, &"meja_potong", delta)
	if cook.cook_id == 1 and cook_view_p1 != null:
		cook_view_p1.is_working = is_working
	elif cook.cook_id == 2 and cook_view_p2 != null:
		cook_view_p2.is_working = is_working

	# 4. Skill 1 (Rangga Dash) — FR-SKL-01, FR-SKL-09, FR-MON-13
	if Input.is_action_just_pressed(prefix + "_skill_1"):
		if cook.cook_id == 1 and skills != null:
			var res: Dictionary = skills.trigger_dash(cook, [], static_obstacles, monsters)
			if res.get("success", false) and cook_view_p1 != null:
				cook_view_p1.trigger_dash()

	# 5. Strike (Space / Slash) — Sutil (3x usir) / Kuali Dua Mode (1x usir, 4s lock) (FR-COM-01 s.d. 06)
	if Input.is_action_just_pressed(prefix + "_strike") and not cook.is_aiming_throw:
		if cook.cook_id == 1 and cook_view_p1 != null:
			cook_view_p1.trigger_strike()
		elif cook.cook_id == 2 and cook_view_p2 != null:
			cook_view_p2.trigger_strike()
		if combat != null:
			var cookware_item: RefCounted = null
			if cook.held_item_id == "kuali":
				cookware_item = ItemScript.new(&"kuali", &"COOKWARE", &"clean")
			var hits: Array = combat.strike(cook.cook_id, cook.position, cook.facing_direction, monsters, cookware_item, scoring)
			if hits.size() > 0:
				if projectile_view:
					projectile_view.add_floating_label("TERUSIR!", hits[0].position, Color(0.9, 0.4, 0.1))
				if crowd_controller:
					crowd_controller.trigger_reaction(&"rage")

	# 6. Throw logic (Tap = Quick, Hold = Aimed) (FR-THR-01 s.d. 06)
	if Input.is_action_just_pressed(prefix + "_throw"):
		cook.is_aiming_throw = true
		throw_hold_times[prefix] = 0.0
		if cook.cook_id == 1 and cook_view_p1 != null:
			cook_view_p1.trigger_throw()
		elif cook.cook_id == 2 and cook_view_p2 != null:
			cook_view_p2.trigger_throw()
		if throw_system:
			throw_system.start_aim(cook.cook_id, cook.position, cook.facing_direction)

	if Input.is_action_pressed(prefix + "_throw"):
		var cur_hold: float = float(throw_hold_times[prefix]) + delta
		throw_hold_times[prefix] = cur_hold
		if throw_system and preview_view:
			var seats: Array = lapak.all_seats() if lapak else []
			var recipe_hint: StringName = StringName(cook.held_item_id) if cook.held_item_id != "" else &""
			var aim_data: Dictionary = throw_system.update_aim(cook.cook_id, cook.position, cook.facing_direction, delta, recipe_hint, seats, true)
			var marker_type: StringName = &"TERSAJI"
			if aim_data.get("would_be_jitu", false):
				marker_type = &"JITU"
			elif aim_data.get("target_seat") == null:
				marker_type = &"MISSED"
			preview_view.update_preview(true, cook.position, aim_data["landing"], aim_data["r_tiles"], marker_type)

	if Input.is_action_just_released(prefix + "_throw"):
		cook.is_aiming_throw = false
		if preview_view:
			preview_view.update_preview(false, Vector2.ZERO, Vector2.ZERO, 0.0, &"")
		var hold_t: float = float(throw_hold_times[prefix])
		var seats: Array = lapak.all_seats() if lapak else []
		var item_name: StringName = StringName(cook.held_item_id)
		var is_dish: bool = String(item_name).begins_with("dish_")

		if throw_system and cook.held_item_id != "":
			if hold_t < 0.18 and not is_dish:
				# Quick throw bahan mentah (FR-THR-01)
				throw_system.throw_quick(cook.cook_id, item_name, cook.position, cook.facing_direction)
				cook.held_item_id = ""
			else:
				# Aimed throw hidangan / bahan (FR-THR-02)
				throw_system.throw_aimed(cook.cook_id, item_name, is_dish, item_name, cook.position, cook.facing_direction, seats, monsters, true)
				cook.held_item_id = ""

func _query_interaction_target(cook: RefCounted) -> Dictionary:
	var probe_pos: Vector2 = cook.position + cook.facing_direction * 12.0

	# Prioritas 1: Stasiun (radius 9 px probe vs AABB stasiun) — FR-MOV-06, FR-INT-02
	var best_st: Dictionary = {}
	var min_st_dist: float = 999.0
	for st: Dictionary in stations:
		var st_rect: Rect2 = Rect2(st["pos"] * TILE, Vector2(TILE, TILE))
		var closest: Vector2 = Vector2(clampf(probe_pos.x, st_rect.position.x, st_rect.end.x), clampf(probe_pos.y, st_rect.position.y, st_rect.end.y))
		var d: float = probe_pos.distance_to(closest)
		if d <= 9.0 and d < min_st_dist:
			min_st_dist = d
			best_st = st
	if not best_st.is_empty():
		return {"type": "station", "station": best_st}

	# Prioritas 2: Item di lantai (radius 9 px) — FR-INT-04
	var best_item: Dictionary = {}
	var min_item_dist: float = 999.0
	for it: Dictionary in floor_items:
		var d: float = probe_pos.distance_to(it["pos"])
		if d <= 9.0 and d < min_item_dist:
			min_item_dist = d
			best_item = it
	if not best_item.is_empty():
		return {"type": "floor_item", "item": best_item}

	# Prioritas 3: Kursi Tamu (radius 14 px atau jangkauan meja panjang FR-SRV-02)
	if lapak:
		var best_seat: RefCounted = null
		var min_seat_dist: float = 999.0
		for seat: RefCounted in lapak.all_seats():
			var dist: float = probe_pos.distance_to(seat.position)
			var reachable: bool = (dist <= 14.0 + seat.serve_radius)
			# Meja panjang dijangkau dari kolom 11 menghadap kanan (FR-SRV-02)
			if not reachable and cook.position.x >= 168.0 and cook.position.x <= 192.0 and cook.facing_direction.x > 0.5:
				if absf(seat.position.y - cook.position.y) <= 14.0 and seat.position.x > 192.0:
					reachable = true
			if reachable and dist < min_seat_dist:
				min_seat_dist = dist
				best_seat = seat
		if best_seat != null:
			return {"type": "seat", "seat": best_seat}

	return {}

func _handle_cook_interact(cook: RefCounted) -> void:
	var target: Dictionary = _query_interaction_target(cook)

	# Tidak ada target: letakkan item di lantai jika tangan terisi (FR-INT-04)
	if target.is_empty():
		if cook.held_item_id != "" and not cook.held_item_id.begins_with("dish_"):
			floor_items.append({"item_id": cook.held_item_id, "pos": cook.position + cook.facing_direction * 10.0})
			cook.held_item_id = ""
		return

	var t_type: String = target.get("type", "")
	match t_type:
		"floor_item":
			if cook.held_item_id == "":
				var it: Dictionary = target["item"]
				cook.held_item_id = String(it["item_id"])
				floor_items.erase(it)

		"seat":
			var seat: RefCounted = target["seat"]
			# 1. Samperin hidangan jadi (FR-SRV-01)
			if cook.held_item_id != "" and cook.held_item_id.begins_with("dish_") and cook.held_item_id != "dish_dirty_plate" and cook.held_item_id != "dish_plate_clean":
				var target_monster: RefCounted = null
				for m: RefCounted in monsters:
					if m.seat_id == seat.seat_id:
						target_monster = m
						break
				if target_monster != null and target_monster.state == 3: # WAITING
					var req: String = String(target_monster.requested_recipe).replace("recipe_", "dish_")
					if cook.held_item_id == req or cook.held_item_id == "dish_nasi_goreng_jamur":
						target_monster.serve(target_monster.requested_recipe, 0.0, 0.0)
						seat.plate_state = SeatScript.PLATE_SERVED
						if scoring:
							scoring.add_score(150)
						cook.held_item_id = ""
						if projectile_view:
							projectile_view.add_floating_label("TERSAJI", seat.position, Color(1.0, 0.85, 0.2))
						if crowd_controller:
							crowd_controller.trigger_reaction(&"served")
					else:
						if projectile_view:
							projectile_view.add_floating_label("Bukan Pesanan", seat.position, Color(0.9, 0.4, 0.4))
				else:
					if projectile_view:
						projectile_view.add_floating_label("Bukan Pesanan", seat.position, Color(0.9, 0.4, 0.4))

			# 2. Ambil piring kotor dari kursi kosong (FR-WSH-03)
			elif cook.held_item_id == "" and seat.plate_state == SeatScript.PLATE_DIRTY:
				seat.plate_state = SeatScript.PLATE_NONE
				cook.held_item_id = "dish_dirty_plate"
				if projectile_view:
					projectile_view.add_floating_label("Piring Kotor", seat.position, Color(0.7, 0.7, 0.7))

		"station":
			var st: Dictionary = target["station"]
			var sid: StringName = st["id"]
			var sim: RefCounted = st["sim"]

			match sid:
				&"peti_bahan":
					if cook.held_item_id == "":
						raw_ingredient_toggle = not raw_ingredient_toggle
						cook.held_item_id = "item_jamur_raw" if raw_ingredient_toggle else "item_bawang_raw"
					elif cook.held_item_id == "item_jamur_raw" or cook.held_item_id == "item_bawang_raw":
						cook.held_item_id = ""

				&"peti_nasi":
					if cook.held_item_id == "":
						cook.held_item_id = "item_nasi"
					elif cook.held_item_id == "item_nasi":
						cook.held_item_id = ""

				&"rak_piring":
					if cook.held_item_id == "":
						var p: RefCounted = plate_pool.take_clean() if plate_pool else null
						if p != null:
							cook.held_item_id = "dish_plate_clean"
						else:
							if projectile_view:
								projectile_view.add_floating_label("Piring Habis!", st["pos"] * TILE + Vector2(8, 0), Color(0.9, 0.3, 0.3))
					elif cook.held_item_id == "dish_plate_clean":
						if plate_pool:
							plate_pool.return_lost_plate()
						cook.held_item_id = ""

				&"tempat_sampah":
					if cook.held_item_id != "":
						if cook.held_item_id == "kuali":
							pass # Jangan buang kuali, hanya bersihkan
						elif cook.held_item_id == "dish_plate_clean" or cook.held_item_id.begins_with("dish_"):
							cook.held_item_id = "dish_plate_clean"
						else:
							cook.held_item_id = ""
						if projectile_view:
							projectile_view.add_floating_label("Dibuang", st["pos"] * TILE + Vector2(8, 0), Color(0.8, 0.3, 0.3))

				&"meja_potong":
					# Taruh bahan untuk dipotong
					if sim.state == StationScript.State.EMPTY and (cook.held_item_id == "item_bawang_raw" or cook.held_item_id == "item_jamur_raw"):
						sim.state = StationScript.State.PROCESSING
						sim.held_item_id = StringName(cook.held_item_id)
						sim.step_duration = 2.0 if cook.held_item_id == "item_bawang_raw" else 3.0
						sim.progress = 0.0
						cook.held_item_id = ""
					# Ambil hasil potong
					elif (sim.state == StationScript.State.READY or sim.progress >= sim.step_duration) and cook.held_item_id == "":
						cook.held_item_id = "bawang_prepped" if sim.held_item_id == &"item_bawang_raw" else "jamur_prepped"
						sim.clear_contents()

				&"tungku":
					# Taruh bahan prepped/nasi ke tungku untuk memasak
					if sim.state == StationScript.State.EMPTY:
						if cook.held_item_id == "bawang_prepped" or cook.held_item_id == "jamur_prepped" or cook.held_item_id == "item_nasi":
							sim.state = StationScript.State.PROCESSING
							sim.held_item_id = &"cooking"
							sim.step_duration = 10.0
							sim.progress = 0.0
							sim.attention_interval = 4.0
							sim.attention_window = 1.5
							sim.attention_timer = 4.0
							sim.needs_attention = false
							sim.base_burn_time = 10.0
							sim.burn_timer = 10.0
							cook.held_item_id = ""
					# Ambil hasil masakan matang atau gosong
					elif cook.held_item_id == "" or cook.held_item_id == "dish_plate_clean":
						if sim.state == StationScript.State.READY or sim.state == StationScript.State.BURNING or (sim.state == StationScript.State.PROCESSING and sim.progress >= sim.step_duration):
							cook.held_item_id = "dish_nasi_goreng_jamur"
							sim.clear_contents()
						elif sim.state == StationScript.State.BURNT:
							cook.held_item_id = "dish_burnt"
							sim.clear_contents()

				&"meja_alas":
					# Meja staging & plating (FR-INT-05)
					if st["held_item"] == "":
						if cook.held_item_id != "":
							st["held_item"] = cook.held_item_id
							cook.held_item_id = ""
					elif st["held_item"] == "dish_plate_clean":
						# Masukkan komponen ke atas piring
						if cook.held_item_id != "":
							st["components"].append(cook.held_item_id)
							cook.held_item_id = ""
							if st["components"].size() >= 3 or "dish_nasi_goreng_jamur" in st["components"]:
								st["held_item"] = "dish_nasi_goreng_jamur"
						else:
							# Ambil kembali piring
							cook.held_item_id = "dish_plate_clean"
							st["held_item"] = ""
					else:
						# Ambil hidangan atau item yang tergeletak
						if cook.held_item_id == "":
							cook.held_item_id = String(st["held_item"])
							st["held_item"] = ""
							st["components"].clear()

				&"tempat_cuci":
					# Taruh piring kotor
					if sim.state == StationScript.State.EMPTY and cook.held_item_id == "dish_dirty_plate":
						sim.state = StationScript.State.PROCESSING
						sim.held_item_id = &"dirty_plate"
						sim.step_duration = 2.0
						sim.progress = 0.0
						cook.held_item_id = ""

func _handle_cook_work(cook: RefCounted, is_working: bool) -> void:
	var target: Dictionary = _query_interaction_target(cook)
	if target.get("type", "") == "station":
		var st: Dictionary = target["station"]
		var sim: RefCounted = st["sim"]
		if is_working:
			if sim.is_manual_station() and sim.state == StationScript.State.PROCESSING:
				sim.add_worker(cook.cook_id)
			elif st["id"] == &"tungku" and sim.needs_attention:
				sim.attend(cook.cook_id)
				if projectile_view:
					projectile_view.add_floating_label("Aduk!", st["pos"] * TILE + Vector2(8, 0), Color(0.2, 0.9, 0.3))
		else:
			sim.remove_worker(cook.cook_id)

func _handle_throw_resolved_event(ev: Dictionary) -> void:
	var r_type: StringName = ev.get("result", &"MISSED")
	var l_pos: Vector2 = ev.get("landing_pos", Vector2.ZERO)

	if projectile_view:
		match r_type:
			&"JITU":
				projectile_view.add_floating_label("JITU! +25", l_pos, Color(0.2, 0.9, 0.3))
			&"TERSAJI":
				projectile_view.add_floating_label("TERSAJI", l_pos, Color(1.0, 0.85, 0.2))
			&"WRONG_TABLE":
				projectile_view.add_floating_label("MEJA SALAH! -50", l_pos, Color(0.9, 0.2, 0.2))
			&"HIT_MONSTER":
				projectile_view.add_floating_label("KENA MONSTER! -25", l_pos, Color(0.95, 0.5, 0.1))
			&"MISSED":
				projectile_view.add_floating_label("MELESET! -25", l_pos, Color(0.8, 0.2, 0.2))
			&"AUTOCATCH":
				projectile_view.add_floating_label("TERTANGKAP!", l_pos, Color(0.3, 0.8, 1.0))

	# Update seating & monster on served throw
	if r_type == &"JITU" or r_type == &"TERSAJI":
		if ev.has("target_seat") and ev["target_seat"] != null:
			var seat: RefCounted = ev["target_seat"]
			seat.plate_state = SeatScript.PLATE_SERVED
			for m: RefCounted in monsters:
				if m.seat_id == seat.seat_id and m.state == 3:
					m.serve(m.requested_recipe, 0.0, 25.0 if r_type == &"JITU" else 0.0)
					break
		if crowd_controller:
			crowd_controller.trigger_reaction(&"served")
	elif r_type == &"WRONG_TABLE" or r_type == &"HIT_MONSTER" or r_type == &"MISSED":
		if plate_pool:
			plate_pool.return_lost_plate()
		if crowd_controller:
			crowd_controller.trigger_reaction(&"rage")

func _tick_monsters(delta: float) -> void:
	var to_remove: Array = []
	for m: RefCounted in monsters:
		m.tick(delta)

		# State 3: WAITING — OrderBubbleView update
		if m.state == 3:
			if not monster_bubbles.has(m.monster_id):
				var b: Node2D = OrderBubbleViewScript.new()
				b.position = m.position
				kitchen_layer.add_child(b)
				monster_bubbles[m.monster_id] = b
			var bubble: Node2D = monster_bubbles[m.monster_id]
			bubble.position = m.position
			bubble.set_order(m.requested_recipe, m.patience / 100.0, m.table_kind == &"LONG")
		else:
			if monster_bubbles.has(m.monster_id):
				var bubble: Node2D = monster_bubbles[m.monster_id]
				bubble.queue_free()
				monster_bubbles.erase(m.monster_id)

		# State 4: EATING
		if m.state == 4:
			var cur_eat: float = float(eating_timers.get(m.monster_id, 0.0)) + delta
			eating_timers[m.monster_id] = cur_eat
			if cur_eat >= 4.0:
				m.finish_eating()
				eating_timers.erase(m.monster_id)

		# State 6: LEAVING or State 10: EXPELLED
		if m.state == 6 or m.state == 10:
			if lapak:
				for seat: RefCounted in lapak.all_seats():
					if seat.seat_id == m.seat_id:
						seat.vacate()
						if level_data and "washing_enabled" in level_data and level_data.washing_enabled:
							seat.plate_state = SeatScript.PLATE_DIRTY
						break
			to_remove.append(m)

		# State 7: ENRAGED -> Transition to STEAL_RUN or ATTACKING
		if m.state == 7:
			if randf() < 0.5:
				m.start_steal(&"bawang", Vector2(0.0, 5.0 * TILE))
			else:
				m.start_attack()

		# State 8: ATTACKING
		if m.state == 8 and combat:
			var target_st: RefCounted = stations[5]["sim"] if stations.size() > 5 else null
			combat.tick(delta, [m], scoring, target_st)

	for rem: RefCounted in to_remove:
		if monster_bubbles.has(rem.monster_id):
			monster_bubbles[rem.monster_id].queue_free()
			monster_bubbles.erase(rem.monster_id)
		monsters.erase(rem)

func _tick_monster_spawn(delta: float) -> void:
	if orders == null or lapak == null:
		return
	var max_active: int = level_data.max_active_monsters if (level_data and "max_active_monsters" in level_data) else 4
	if monsters.size() >= max_active:
		return
	monster_spawn_timer -= delta
	if monster_spawn_timer <= 0.0:
		monster_spawn_timer = randf_range(3.0, 6.0)
		_spawn_monster()

func _spawn_monster() -> void:
	var m: RefCounted = MonsterScript.new(next_monster_id, &"goblin")
	next_monster_id += 1
	var free: Array = []
	for seat: RefCounted in lapak.all_seats():
		if seat.is_free():
			free.append(seat)
	if free.is_empty():
		return
	var seat: RefCounted = free[randi() % free.size()]
	seat.occupy(m.monster_id)
	m.seat_id = seat.seat_id
	m.position = seat.position
	var recipes: Array = []
	if level_data and "active_recipes" in level_data and level_data.active_recipes != null:
		for r: StringName in level_data.active_recipes:
			recipes.append(r)
	if recipes.is_empty():
		recipes.append(&"recipe_nasi_goreng_jamur")
	var recipe: StringName = recipes[randi() % recipes.size()]
	m.seat(seat.table_kind, seat.seat_id, recipe)
	m.begin_waiting()
	orders.register(m)
	monsters.append(m)

func _update_hud() -> void:
	if hud_top != null:
		if scoring != null:
			hud_top.set_score(scoring.score)
		hud_top.set_time(level_timer)
		if orders != null:
			var ticket_data: Array = []
			for m: RefCounted in monsters:
				if m.state == 3: # WAITING
					var pct: float = m.patience / 100.0 if "patience" in m else 1.0
					ticket_data.append({"order_id": m.monster_id, "recipe_id": m.requested_recipe, "patience_pct": pct})
			hud_top.update_tickets(ticket_data)

	if hud_bot != null and scoring != null:
		hud_bot.set_hearts(scoring.hearts, 5)
		if skills != null:
			var cd1: float = skills.get_cooldown(1, 1)
			hud_bot.set_cooldown(1, 1, cd1, 6.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("p1_pause") or event.is_action_pressed("p2_pause"):
		Game.toggle_pause()
		if Game.is_game_paused:
			var canvas_layer := CanvasLayer.new()
			canvas_layer.layer = 30
			canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
			var pause_dlg: Node = PauseMenuScene.instantiate()
			canvas_layer.add_child(pause_dlg)
			add_child(canvas_layer)
			pause_dlg.tree_exited.connect(canvas_layer.queue_free)
	if event is InputEventKey and event.pressed:
		match (event as InputEventKey).keycode:
			KEY_F1:
				load_level(LEVEL_PATHS[0])
			KEY_F2:
				load_level(LEVEL_PATHS[1])
			KEY_F3:
				load_level(LEVEL_PATHS[2])
			KEY_F4:
				load_level(LEVEL_PATHS[3])
