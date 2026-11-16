class_name ThrowMath
extends RefCounted

## Rumus lempar bersama: Klien (pratinjau) dan Simulasi/Server (hasil).
## Patuh FR-THR-01 s.d. FR-THR-16.

const TILE: float = 16.0
const MIN_R: float = 2.0
const MAX_R: float = 8.0
const RAMP_TIME: float = 1.2 # detik dari 2 ke 8 tile (FR-THR-04)
const SERVE_RADIUS: float = 12.0 # FR-THR-07 zona saji
const JITU_RADIUS: float = 6.0 # FR-THR-08 titik jatuh dalam 6 px
const ASSIST_RADIUS: float = 20.0 # FR-THR-12 bantuan bidik keyboard
const AUTOCATCH_RADIUS: float = 16.0 # FR-THR-10 rekan koki
const MISSED_PATIENCE_RADIUS: float = 40.0 # FR-THR-08 kesabaran -15 terdekat
const THROW_COOLDOWN: float = 0.3 # FR-THR-13
const QUICK_THROW_RANGE: float = 4.0 # FR-THR-01
const TAP_THRESHOLD: float = 0.18 # FR-THR-01
const PLATE_RETURN_TIME: float = 10.0 # FR-THR-13
const MIN_JITU_TILES: float = 3.0 # FR-THR-14

static func range_at(hold_time: float) -> float:
	var phase: float = fposmod(hold_time / RAMP_TIME, 2.0)
	var t: float = phase if phase <= 1.0 else 2.0 - phase # gelombang segitiga 0..1
	return lerpf(MIN_R, MAX_R, t)

static func flight_time(r_tiles: float) -> float:
	var clamped_r: float = clampf(r_tiles, MIN_R, MAX_R)
	return 0.4 + (clamped_r - MIN_R) / (MAX_R - MIN_R) * 0.5

static func landing_point(origin: Vector2, dir: Vector2, r_tiles: float, wind: Vector2 = Vector2.ZERO) -> Vector2:
	return origin + dir.normalized() * (r_tiles * TILE) + wind

static func arc_height(r_tiles: float) -> float:
	return r_tiles * 4.0

static func parabola_y(peak_height: float, s: float) -> float:
	# s adalah waktu terbang ternormalisasi 0..1
	return 4.0 * peak_height * s * (1.0 - s)

static func can_throw_item(item_category: StringName, item_id: StringName, is_dirty: bool, is_aimed: bool) -> bool:
	# FR-THR-05: Kuali dan sutil tidak bisa dilempar
	if item_category == &"COOKWARE" or item_id == &"kuali" or item_id == &"sutil":
		return false
	# FR-WSH-09: Piring kotor tidak bisa dilempar
	if is_dirty or item_id == &"plate_dirty":
		return false
	# FR-THR-02: Hidangan jadi hanya bisa dilempar dengan mode bidik
	if item_category == &"DISH" or String(item_id).begins_with("dish_"):
		return is_aimed
	# Bahan dan piring bersih bisa dilempar cepat maupun bidik
	return true

static func assist_aim(raw_landing: Vector2, r_tiles: float, target_recipe: StringName, seats: Array, is_keyboard_user: bool) -> Dictionary:
	var result_pos: Vector2 = raw_landing
	var is_assisted: bool = false
	var target_seat: RefCounted = null
	var would_be_jitu: bool = false
	
	if is_keyboard_user:
		var closest_seat: RefCounted = null
		var min_dist: float = ASSIST_RADIUS + 1.0
		for seat: RefCounted in seats:
			# Hanya menempel ke kursi berpesanan cocok
			var req_recipe: StringName = seat.requested_recipe if "requested_recipe" in seat else &""
			if req_recipe == &"" and "occupant_recipe" in seat:
				req_recipe = seat.occupant_recipe
			if req_recipe != &"" and req_recipe == target_recipe:
				var dist: float = raw_landing.distance_to(seat.position)
				if dist <= ASSIST_RADIUS and dist < min_dist:
					min_dist = dist
					closest_seat = seat
		
		if closest_seat != null:
			result_pos = closest_seat.position
			is_assisted = true
			target_seat = closest_seat
			var raw_dist: float = raw_landing.distance_to(closest_seat.position)
			# FR-THR-12 & FR-THR-14: Jitu bila titik mentah dalam 6 px DAN jarak >= 3 tile
			if raw_dist <= JITU_RADIUS and r_tiles >= MIN_JITU_TILES:
				would_be_jitu = true
			else:
				would_be_jitu = false
				
	return {
		"landing": result_pos,
		"is_assisted": is_assisted,
		"target_seat": target_seat,
		"would_be_jitu": would_be_jitu
	}

static func evaluate_dish_landing(landing_pos: Vector2, raw_pos: Vector2, r_tiles: float, recipe_id: StringName, seats: Array, monsters: Array = [], was_assisted: bool = false) -> Dictionary:
	# 1. Cari kursi cocok
	var matched_seat: RefCounted = null
	var matched_dist: float = 9999.0
	
	for seat: RefCounted in seats:
		var s_recipe: StringName = seat.requested_recipe if "requested_recipe" in seat else &""
		if s_recipe == &"" and "occupant_recipe" in seat:
			s_recipe = seat.occupant_recipe
		if s_recipe == recipe_id:
			var d: float = landing_pos.distance_to(seat.position)
			if d <= SERVE_RADIUS and d < matched_dist:
				matched_dist = d
				matched_seat = seat
				
	if matched_seat != null:
		var is_jitu: bool = false
		if was_assisted:
			# Jika dibantu assist, titik mentah harus <= 6 px dan r_tiles >= 3.0
			var raw_d: float = raw_pos.distance_to(matched_seat.position)
			is_jitu = (raw_d <= JITU_RADIUS) and (r_tiles >= MIN_JITU_TILES)
		else:
			is_jitu = (matched_dist <= JITU_RADIUS) and (r_tiles >= MIN_JITU_TILES)
			
		if is_jitu:
			# Jitu: Tersaji, +25 poin, kepuasan +5 (FR-THR-08)
			return {
				"result": &"JITU",
				"target_seat": matched_seat,
				"score_delta": 25,
				"satisfaction_bonus": 5.0,
				"patience_delta": 0.0,
				"broken_plate": false
			}
		else:
			# Tersaji: Tersaji normal (FR-THR-08)
			return {
				"result": &"TERSAJI",
				"target_seat": matched_seat,
				"score_delta": 0,
				"satisfaction_bonus": 0.0,
				"patience_delta": 0.0,
				"broken_plate": false
			}

	# 2. Cek meja salah (dalam 12 px dari kursi berpesanan beda dan tidak ada kursi cocok dalam 12 px)
	var wrong_seat: RefCounted = null
	var wrong_dist: float = SERVE_RADIUS + 1.0
	for seat: RefCounted in seats:
		var d: float = landing_pos.distance_to(seat.position)
		if d <= SERVE_RADIUS and d < wrong_dist:
			wrong_dist = d
			wrong_seat = seat
			
	if wrong_seat != null:
		# Meja salah: hidangan hilang, -50 poin, kesabaran monster -10, piring kembali ke rak setelah 10s (FR-THR-08)
		return {
			"result": &"WRONG_TABLE",
			"target_seat": wrong_seat,
			"score_delta": -50,
			"satisfaction_bonus": 0.0,
			"patience_delta": -10.0,
			"broken_plate": true
		}

	# 3. Mengenai monster tidak duduk (antre, mengamuk, steal_run)
	for monster: RefCounted in monsters:
		# Monster yang tidak duduk: state ARRIVING(0), LEAVING(6), ENRAGED(7), ATTACKING(8), STEAL_RUN(9)
		var m_state: int = monster.state if "state" in monster else 0
		if m_state == 0 or m_state == 6 or m_state == 7 or m_state == 8 or m_state == 9:
			if landing_pos.distance_to(monster.position) <= SERVE_RADIUS:
				# Mengenai monster: hancur, -25 poin, kesabaran monster -25, piring kembali ke rak setelah 10s
				return {
					"result": &"HIT_MONSTER",
					"target_monster": monster,
					"score_delta": -25,
					"satisfaction_bonus": 0.0,
					"patience_delta": -25.0,
					"broken_plate": true
				}

	# 4. Meleset di lantai
	# Hancur, -25 poin, kesabaran monster kursi cocok terdekat dalam 40 px berkurang -15, piring kembali ke rak setelah 10s (FR-THR-08)
	var nearby_matched_seat: RefCounted = null
	var nearby_min_dist: float = MISSED_PATIENCE_RADIUS + 1.0
	for seat: RefCounted in seats:
		var s_recipe: StringName = seat.requested_recipe if "requested_recipe" in seat else &""
		if s_recipe == &"" and "occupant_recipe" in seat:
			s_recipe = seat.occupant_recipe
		if s_recipe == recipe_id:
			var d: float = landing_pos.distance_to(seat.position)
			if d <= MISSED_PATIENCE_RADIUS and d < nearby_min_dist:
				nearby_min_dist = d
				nearby_matched_seat = seat

	return {
		"result": &"MISSED",
		"target_seat": nearby_matched_seat,
		"score_delta": -25,
		"satisfaction_bonus": 0.0,
		"patience_delta": -15.0 if nearby_matched_seat != null else 0.0,
		"broken_plate": true
	}

static func evaluate_ingredient_landing(landing_pos: Vector2, other_cook: RefCounted, stations: Array) -> Dictionary:
	# FR-THR-10:
	# 1. Ditangkap otomatis oleh rekan bertangan kosong dalam 16 px
	if other_cook != null:
		var dist_to_cook: float = landing_pos.distance_to(other_cook.position)
		if dist_to_cook <= AUTOCATCH_RADIUS:
			var cook_has_item: bool = false
			if "held_item_id" in other_cook and other_cook.held_item_id != "" and other_cook.held_item_id != &"":
				cook_has_item = true
			if not cook_has_item:
				return {
					"result": &"AUTOCATCH",
					"target_cook": other_cook
				}

	# 2. Masuk stasiun yang cocok bila terkena area terima
	for st_dict: Dictionary in stations:
		var st_pos: Vector2 = st_dict.get("pos", Vector2.ZERO) * TILE + Vector2(8.0, 8.0)
		if landing_pos.distance_to(st_pos) <= TILE:
			return {
				"result": &"STATION",
				"station": st_dict.get("sim", null),
				"station_id": st_dict.get("id", &"")
			}

	# 3. Jatuh di lantai biasa (bisa dipungut)
	return {
		"result": &"FLOOR",
		"position": landing_pos
	}
