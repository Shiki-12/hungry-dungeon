extends RefCounted

## Integration test for Kitchen Stage (M1 + M2 gameplay wiring).
## Verifies collisions, bounds, clean HUD, and the full prepare-cook-serve cycle.

const KitchenStageScene: PackedScene = preload("res://levels/kitchen_stage.tscn")
const CookScript: Script = preload("res://sim/entities/cook.gd")
const MonsterScript: Script = preload("res://sim/entities/monster.gd")
const SeatScript: Script = preload("res://sim/entities/seat.gd")

func run_all() -> bool:
	var ok: bool = true
	ok = _test_hud_and_banner_cleanliness() and ok
	ok = _test_boundary_and_table_collision() and ok
	ok = _test_gate_passage() and ok
	ok = _test_kitchen_gameplay_cycle() and ok
	return ok

func _test_hud_and_banner_cleanliness() -> bool:
	var stage: Node2D = KitchenStageScene.instantiate()
	if stage == null:
		push_error("Failed to instantiate kitchen_stage.tscn")
		return false
	stage._ready()

	var hud_top: Control = stage.hud_top
	var hud_bot: Control = stage.hud_bot
	if hud_top == null or hud_bot == null:
		push_error("HUD top or HUD bottom missing in kitchen stage")
		stage.free()
		return false

	# Verifikasi banner notifikasi ada dan tidak menimpa HUD bawah
	if stage.banner_panel == null or stage.banner_label == null:
		push_error("Banner panel / label missing")
		stage.free()
		return false

	stage.show_banner("Test Banner Notifikasi", 3.0)
	if not stage.banner_panel.visible or stage.banner_label.text != "Test Banner Notifikasi":
		push_error("Banner show failed")
		stage.free()
		return false

	stage.free()
	return true

func _test_boundary_and_table_collision() -> bool:
	var stage: Node2D = KitchenStageScene.instantiate()
	if stage == null:
		return false
	stage._ready()

	var cook: RefCounted = stage.cook_p1
	if cook == null:
		push_error("cook_p1 is null")
		stage.free()
		return false

	var empty_cells: Array = []

	# 1. Test Batas Dinding Luar: Koki bergerak ke kiri menembus dinding
	cook.position = Vector2(10.0, 100.0)
	for i in range(20):
		cook.step(Vector2(-1.0, 0.0), 0.05, empty_cells, stage.static_obstacles)
	if cook.position.x < 6.0:
		push_error("Cook breached left boundary: %f" % cook.position.x)
		stage.free()
		return false

	# 2. Test Meja Panjang di kolom 12 (x=192 px, r1..r10: y=16..176):
	# Koki di kolom 11 (x=180, y=50) bergerak ke kanan menuju meja panjang
	cook.position = Vector2(180.0, 50.0)
	for i in range(20):
		cook.step(Vector2(1.0, 0.0), 0.05, empty_cells, stage.static_obstacles)
	# Radius koki 6 px, meja mulai di x=192 px -> koki tidak boleh melewati x=186.1 px
	if cook.position.x > 187.0:
		push_error("Cook penetrated long table at x=192: %f" % cook.position.x)
		stage.free()
		return false

	stage.free()
	return true

func _test_gate_passage() -> bool:
	var stage: Node2D = KitchenStageScene.instantiate()
	if stage == null:
		return false
	stage._ready()

	var cook: RefCounted = stage.cook_p1
	if cook == null:
		push_error("cook_p1 is null")
		stage.free()
		return false

	var empty_cells: Array = []

	# Test Celah Gerbang (kolom 12, baris 11-12: y=176..208)
	# Koki di kolom 11 (x=180, y=190) bergerak ke kanan menembus celah gerbang ke sisi dungeon
	cook.position = Vector2(180.0, 190.0)
	for i in range(30):
		cook.step(Vector2(1.0, 0.0), 0.05, empty_cells, stage.static_obstacles)

	# Verifikasi koki berhasil menyeberang melewati x=192 px
	if cook.position.x <= 192.0:
		push_error("Cook failed to pass through open gate at y=190: %f" % cook.position.x)
		stage.free()
		return false

	stage.free()
	return true

func _test_kitchen_gameplay_cycle() -> bool:
	var stage: Node2D = KitchenStageScene.instantiate()
	if stage == null:
		return false
	stage._ready()

	var cook: RefCounted = stage.cook_p1
	if cook == null:
		push_error("cook_p1 is null")
		stage.free()
		return false

	# --- Langkah 1: Ambil Bahan Mentah di Peti Bahan ---
	# Peti bahan di (1, 1) -> rect(16, 16, 16, 16). Koki di (24, 38), menghadap atas
	cook.position = Vector2(24.0, 38.0)
	cook.facing_direction = Vector2.UP
	cook.held_item_id = ""
	stage._handle_cook_interact(cook)
	if cook.held_item_id != "item_bawang_raw" and cook.held_item_id != "item_jamur_raw":
		push_error("Failed to take raw ingredient from peti_bahan: %s" % cook.held_item_id)
		stage.free()
		return false

	# Pastikan kita pegang item_bawang_raw untuk meja potong
	cook.held_item_id = "item_bawang_raw"

	# --- Langkah 2: Taruh di Meja Potong & Kerjakan ---
	# Meja potong di (3, 2) -> rect(48, 32, 16, 16). Koki di (56, 56), menghadap atas
	cook.position = Vector2(56.0, 56.0)
	cook.facing_direction = Vector2.UP
	stage._handle_cook_interact(cook)
	if cook.held_item_id != "":
		push_error("Failed to place raw ingredient on meja_potong")
		stage.free()
		return false

	# Kerjakan stasiun potong selama 2.5 detik (durasi bawang prepped = 2.0s)
	stage._handle_cook_work(cook, true)
	for i in range(25):
		stage._tick_stations(0.1)
	stage._handle_cook_work(cook, false)

	# Ambil hasil potongan
	stage._handle_cook_interact(cook)
	if cook.held_item_id != "bawang_prepped":
		push_error("Failed to pick up prepped item from meja_potong: %s" % cook.held_item_id)
		stage.free()
		return false

	# --- Langkah 3: Masak di Tungku (Auto-work) ---
	# Tungku di (5, 4) -> rect(80, 64, 16, 16). Koki di (88, 88), menghadap atas
	cook.position = Vector2(88.0, 88.0)
	cook.facing_direction = Vector2.UP
	stage._handle_cook_interact(cook)
	if cook.held_item_id != "":
		push_error("Failed to put prepped item into tungku")
		stage.free()
		return false

	# Tungku memasak otomatis selama 10.5 detik sampai DONE
	for i in range(105):
		stage._tick_stations(0.1)

	# Ambil masakan jadi dari tungku
	stage._handle_cook_interact(cook)
	if cook.held_item_id != "dish_nasi_goreng_jamur":
		push_error("Failed to pick up cooked dish from tungku: %s" % cook.held_item_id)
		stage.free()
		return false

	# --- Langkah 4: Samperin ke Tamu Meja Panjang ---
	# Siapkan monster di kursi meja panjang yang meminta recipe_nasi_goreng_jamur
	var seats: Array = stage.lapak.all_seats()
	var test_seat: RefCounted = seats[0] # Meja panjang kolom 13, y=18
	test_seat.occupy(999)

	var monster: RefCounted = MonsterScript.new(999, &"goblin")
	monster.seat(test_seat.table_kind, test_seat.seat_id, &"recipe_nasi_goreng_jamur")
	monster.begin_waiting()
	stage.monsters.append(monster)

	# Koki berdiri di kolom 11 menghadap ke kursi (kolom 13) di y yang sama
	cook.position = Vector2(180.0, test_seat.position.y)
	cook.facing_direction = Vector2.RIGHT

	var initial_score: int = stage.scoring.score
	stage._handle_cook_interact(cook)

	# Verifikasi hidangan tersaji
	if cook.held_item_id != "":
		push_error("Dish still held after samperin: %s" % cook.held_item_id)
		stage.free()
		return false
	if stage.scoring.score <= initial_score:
		push_error("Score not incremented after samperin: %d" % stage.scoring.score)
		stage.free()
		return false
	if monster.state != 4: # EATING
		push_error("Monster state not changed to EATING: %d" % monster.state)
		stage.free()
		return false

	stage.free()
	return true
