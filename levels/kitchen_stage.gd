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

const TILE: float = 16.0
const HUD_TOP_H: float = 30.0
const KITCHEN_H: float = 224.0
const HUD_BOT_H: float = 16.0
const KITCHEN_OFFSET: Vector2 = Vector2(0.0, HUD_TOP_H)

# --- Sim State ---
var cook_p1: RefCounted
var cook_p2: RefCounted
var lapak: LapakModule
var orders: RefCounted
var scoring: RefCounted
var combat: RefCounted
var hazards: RefCounted
var plate_pool: RefCounted
var level_data: Resource
var monsters: Array = []
var stations: Array = []
var floor_items: Array = []
var level_timer: float = 0.0
var level_active: bool = false
var monster_spawn_timer: float = 0.0
var next_monster_id: int = 100

# --- View Nodes (created dynamically) ---
var kitchen_layer: Node2D
var hud_top: Control
var hud_bot: Control
var score_label: Label
var timer_label: Label
var hearts_label: Label
var tickets_label: Label
var popup_label: Label

# --- Level paths for debug switching ---
const LEVEL_PATHS: Array[String] = [
	"res://data/levels/level_1_1.tres",
	"res://data/levels/level_1_2.tres",
	"res://data/levels/level_1_3.tres",
	"res://data/levels/level_1_4.tres",
]

func _ready() -> void:
	_build_ui()
	load_level(LEVEL_PATHS[0])

func _build_ui() -> void:
	# HUD Top
	hud_top = Control.new()
	hud_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_top.custom_minimum_size = Vector2(480, HUD_TOP_H)
	hud_top.size = Vector2(480, HUD_TOP_H)
	add_child(hud_top)
	var top_bg: ColorRect = ColorRect.new()
	top_bg.color = Color(0.1, 0.1, 0.15, 0.9)
	top_bg.size = Vector2(480, HUD_TOP_H)
	hud_top.add_child(top_bg)
	tickets_label = Label.new()
	tickets_label.position = Vector2(4, 2)
	tickets_label.add_theme_font_size_override("font_size", 8)
	tickets_label.text = "TIKET: --"
	hud_top.add_child(tickets_label)
	score_label = Label.new()
	score_label.position = Vector2(200, 2)
	score_label.add_theme_font_size_override("font_size", 8)
	score_label.text = "SKOR: 0"
	hud_top.add_child(score_label)
	timer_label = Label.new()
	timer_label.position = Vector2(380, 2)
	timer_label.add_theme_font_size_override("font_size", 8)
	timer_label.text = "03:00"
	hud_top.add_child(timer_label)

	# Kitchen layer
	kitchen_layer = Node2D.new()
	kitchen_layer.position = KITCHEN_OFFSET
	kitchen_layer.y_sort_enabled = true
	add_child(kitchen_layer)

	# HUD Bottom
	hud_bot = Control.new()
	hud_bot.position = Vector2(0, HUD_TOP_H + KITCHEN_H)
	hud_bot.custom_minimum_size = Vector2(480, HUD_BOT_H)
	hud_bot.size = Vector2(480, HUD_BOT_H)
	add_child(hud_bot)
	var bot_bg: ColorRect = ColorRect.new()
	bot_bg.color = Color(0.1, 0.1, 0.15, 0.9)
	bot_bg.size = Vector2(480, HUD_BOT_H)
	hud_bot.add_child(bot_bg)
	hearts_label = Label.new()
	hearts_label.position = Vector2(4, 1)
	hearts_label.add_theme_font_size_override("font_size", 7)
	hearts_label.text = "♥♥♥♥♥"
	hud_bot.add_child(hearts_label)
	popup_label = Label.new()
	popup_label.position = Vector2(160, 1)
	popup_label.add_theme_font_size_override("font_size", 7)
	popup_label.text = ""
	hud_bot.add_child(popup_label)

func load_level(path: String) -> void:
	# Clean previous
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
	orders.max_open_tickets = level_data.max_open_tickets
	plate_pool = PlatePoolScript.new(level_data.plate_count)

	# Lapak
	var small_count: int = 0
	if level_data.seating != null and level_data.seating.has_method("get"):
		small_count = level_data.seating.small_tables if "small_tables" in level_data.seating else 0
	elif "seating" in level_data and level_data.seating != null:
		small_count = level_data.seating.small_tables if level_data.seating.get("small_tables") != null else 0
	lapak = LapakModule.new(5, small_count)
	kitchen_layer.add_child(lapak)

	# Cooks
	cook_p1 = CookScript.new()
	cook_p1.cook_id = 1
	cook_p1.cook_name = "Rangga"
	cook_p1.position = Vector2(5 * TILE, 7 * TILE)
	cook_p2 = CookScript.new()
	cook_p2.cook_id = 2
	cook_p2.cook_name = "Sekar"
	cook_p2.position = Vector2(7 * TILE, 7 * TILE)

	# Spawn station placeholders
	_spawn_stations()

	# Draw kitchen background
	_draw_kitchen_bg()

	# Start level
	level_timer = level_data.duration_sec
	level_active = true
	monster_spawn_timer = 3.0
	Game.start_level(level_data.id, level_data.duration_sec)
	_show_popup_for_level(level_data.id)

func _clear_level() -> void:
	level_active = false
	monsters.clear()
	stations.clear()
	floor_items.clear()
	for child: Node in kitchen_layer.get_children():
		child.queue_free()

func _spawn_stations() -> void:
	# Place stations as colored placeholder rects in kitchen_layer
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
		var sim: RefCounted = StationScript.new(sd)
		stations.append({"sim": sim, "pos": def["pos"], "color": def["color"], "id": def["id"]})
		var view: Node2D = Node2D.new()
		view.position = Vector2(def["pos"].x * TILE + 8, def["pos"].y * TILE + 8)
		view.set_meta(&"station_id", def["id"])
		kitchen_layer.add_child(view)

func _draw_kitchen_bg() -> void:
	queue_redraw()

func _draw() -> void:
	# Kitchen area BG
	draw_rect(Rect2(0, HUD_TOP_H, 480, KITCHEN_H), Color(0.22, 0.18, 0.14))
	# Tikar lapak (kolom 0-11)
	draw_rect(Rect2(0, HUD_TOP_H, 12 * TILE, KITCHEN_H), Color(0.35, 0.28, 0.18))
	# Meja Panjang (kolom 12)
	for r: int in range(1, 11):
		draw_rect(Rect2(12 * TILE, HUD_TOP_H + r * TILE, TILE, TILE), Color(0.45, 0.3, 0.15))
	# Gerbang (kolom 12, r11-12)
	draw_rect(Rect2(12 * TILE, HUD_TOP_H + 11 * TILE, TILE, 2 * TILE), Color(0.3, 0.25, 0.2))
	# Gerobak placeholder (kolom 0-1, r4-5)
	draw_rect(Rect2(0, HUD_TOP_H + 4 * TILE, 2 * TILE, 2 * TILE), Color(0.5, 0.35, 0.2))
	# Station boxes
	for st: Dictionary in stations:
		var px: Vector2 = Vector2(st["pos"].x * TILE, HUD_TOP_H + st["pos"].y * TILE)
		draw_rect(Rect2(px, Vector2(TILE, TILE)), st["color"])
		# Label
		_draw_station_label(px, st["id"])
	# Seats
	if lapak:
		for seat: RefCounted in lapak.all_seats():
			var sx: float = seat.position.x
			var sy: float = HUD_TOP_H + seat.position.y
			var seat_color: Color = Color(0.6, 0.45, 0.3)
			if seat.occupant_monster_id >= 0:
				seat_color = Color(0.8, 0.3, 0.5)
			draw_rect(Rect2(sx - 4, sy - 4, 8, 8), seat_color)
	# Cooks
	if cook_p1:
		_draw_cook(cook_p1, Color(0.16, 0.5, 0.73))
	if cook_p2:
		_draw_cook(cook_p2, Color(0.83, 0.33, 0.0))
	# Monsters
	for m: RefCounted in monsters:
		_draw_monster(m)

func _draw_cook(cook: RefCounted, color: Color) -> void:
	var px: Vector2 = Vector2(cook.position.x, HUD_TOP_H + cook.position.y)
	draw_rect(Rect2(px.x - 6, px.y - 7, 12, 14), color)
	# Facing arrow
	var arrow_end: Vector2 = px + cook.facing_direction * 10.0
	draw_line(px, arrow_end, Color.WHITE, 1.0)
	# Name tag
	var tag: String = "P1" if cook.cook_id == 1 else "P2"
	draw_string(ThemeDB.fallback_font, Vector2(px.x - 8, px.y - 10), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color.WHITE)

func _draw_monster(m: RefCounted) -> void:
	var px: Vector2 = Vector2(m.position.x, HUD_TOP_H + m.position.y)
	var color: Color = Color(0.55, 0.27, 0.68)
	if m.state == 7 or m.state == 8: # ENRAGED or ATTACKING
		color = Color(0.91, 0.3, 0.24)
	elif m.state == 9: # STEAL_RUN
		color = Color(0.95, 0.61, 0.07)
	draw_rect(Rect2(px.x - 6, px.y - 7, 12, 14), color)

func _draw_station_label(px: Vector2, id: StringName) -> void:
	var short: String = String(id).substr(0, 4)
	draw_string(ThemeDB.fallback_font, Vector2(px.x + 1, px.y + 12), short, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(1, 1, 1, 0.7))

func _physics_process(delta: float) -> void:
	if not level_active:
		return
	# Input
	_handle_cook_input(cook_p1, "p1", delta)
	_handle_cook_input(cook_p2, "p2", delta)
	# Sim tick
	if lapak:
		lapak.tick(delta)
	if orders:
		orders.tick(delta)
	if hazards:
		hazards.tick(delta)
	for st: Dictionary in stations:
		(st["sim"] as RefCounted).tick(delta)
	# Monster spawning
	_tick_monster_spawn(delta)
	# Level timer
	level_timer -= delta
	if level_timer <= 0.0:
		level_active = false
		var stars: int = scoring.stars_for(level_data)
		Game.end_level(true, stars)
	# Update HUD
	_update_hud()
	queue_redraw()

func _handle_cook_input(cook: RefCounted, prefix: String, delta: float) -> void:
	var input_vec: Vector2 = Vector2.ZERO
	if Input.is_action_pressed(prefix + "_move_up"):
		input_vec.y -= 1.0
	if Input.is_action_pressed(prefix + "_move_down"):
		input_vec.y += 1.0
	if Input.is_action_pressed(prefix + "_move_left"):
		input_vec.x -= 1.0
	if Input.is_action_pressed(prefix + "_move_right"):
		input_vec.x += 1.0
	cook.step(input_vec, delta)

func _tick_monster_spawn(delta: float) -> void:
	if orders == null or lapak == null:
		return
	var max_active: int = level_data.max_active_monsters if level_data else 4
	if monsters.size() >= max_active:
		return
	monster_spawn_timer -= delta
	if monster_spawn_timer <= 0.0:
		monster_spawn_timer = randf_range(3.0, 6.0)
		_spawn_monster()

func _spawn_monster() -> void:
	var m: RefCounted = MonsterScript.new(next_monster_id, &"goblin")
	next_monster_id += 1
	# Pick a free seat
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
	# Pick recipe
	var recipes: Array = []
	if level_data:
		for r: StringName in level_data.active_recipes:
			recipes.append(r)
	if recipes.is_empty():
		recipes.append(&"recipe_nasi_goreng_jamur")
	var recipe: StringName = recipes[randi() % recipes.size()]
	m.seat(seat.table_kind, seat.seat_id, recipe)
	orders.register(m)
	monsters.append(m)

func _update_hud() -> void:
	if score_label:
		score_label.text = "SKOR: %d" % scoring.score
	if timer_label:
		var mins: int = int(level_timer) / 60
		var secs: int = int(level_timer) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
	if hearts_label:
		var h: String = ""
		for i: int in range(5):
			h += "♥" if i < scoring.hearts else "♡"
		hearts_label.text = h
	if tickets_label:
		tickets_label.text = "TIKET: %d/%d" % [orders.open_ticket_count(), orders.max_open_tickets]

func _show_popup_for_level(id: StringName) -> void:
	if popup_label == null:
		return
	match id:
		&"level_1_1":
			popup_label.text = "Level 1-1: Bekal Terakhir"
		&"level_1_2":
			popup_label.text = "Level 1-2: Cuci Piring!"
		&"level_1_3":
			popup_label.text = "Level 1-3: Awas Pencuri!"
		&"level_1_4":
			popup_label.text = "Level 1-4: Pesta Goblin!"
		_:
			popup_label.text = String(id)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("p1_pause") or event.is_action_pressed("p2_pause"):
		Game.toggle_pause()
	# Debug: F1-F4 switch levels
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
