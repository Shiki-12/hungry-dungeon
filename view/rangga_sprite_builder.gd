extends RefCounted

## Builder cerdas untuk mengimpor dan menyusun SpriteFrames Rangga dari res://assets/rangga/

const RANGGA_ROOT: String = "res://assets/rangga"
const SAVED_FRAMES_PATH: String = "res://assets/rangga/cook_rangga_frames.tres"

const ANIM_CONFIGS: Dictionary = {
	"work": {"fps": 8.0, "loop": true},
	"walk_down": {"fps": 8.0, "loop": true},
	"walk_up": {"fps": 8.0, "loop": true},
	"walk_side_left": {"fps": 8.0, "loop": true},
	"walk_side_right": {"fps": 8.0, "loop": true},
	"walk_battle_down": {"fps": 8.0, "loop": true},
	"walk_battle_up": {"fps": 8.0, "loop": true},
	"walk_battle_side_left": {"fps": 8.0, "loop": true},
	"walk_battle_side_right": {"fps": 8.0, "loop": true},
	"dash_down": {"fps": 12.0, "loop": false},
	"dash_up": {"fps": 12.0, "loop": false},
	"dash_side_left": {"fps": 14.0, "loop": false},
	"dash_side_right": {"fps": 14.0, "loop": false},
	"dash_battle_down": {"fps": 12.0, "loop": false},
	"dash_battle_up": {"fps": 12.0, "loop": false},
	"dash_battle_side_left": {"fps": 14.0, "loop": false},
	"dash_battle_side_right": {"fps": 14.0, "loop": false},
	"idle_down": {"fps": 4.0, "loop": true},
	"idle_up": {"fps": 4.0, "loop": true},
	"idle_side_left": {"fps": 4.0, "loop": true},
	"idle_side_right": {"fps": 4.0, "loop": true},
	"idle_battle_down": {"fps": 4.0, "loop": true},
	"idle_battle_up": {"fps": 4.0, "loop": true},
	"idle_battle_side_left": {"fps": 4.0, "loop": true},
	"idle_battle_side_right": {"fps": 4.0, "loop": true},
	"throw_side_left": {"fps": 8.0, "loop": false},
	"throw_side_right": {"fps": 8.0, "loop": false},
	"strike_1_down": {"fps": 14.0, "loop": false},
	"strike_1_up": {"fps": 14.0, "loop": false},
	"strike_1_side_left": {"fps": 14.0, "loop": false},
	"strike_1_side_right": {"fps": 14.0, "loop": false},
	"strike_2_down": {"fps": 14.0, "loop": false},
	"strike_2_up": {"fps": 14.0, "loop": false},
	"strike_2_side_left": {"fps": 14.0, "loop": false},
	"strike_2_side_right": {"fps": 14.0, "loop": false},
	"shield_down": {"fps": 8.0, "loop": false},
	"shield_up": {"fps": 8.0, "loop": false},
	"shield_side_left": {"fps": 8.0, "loop": false},
	"shield_side_right": {"fps": 8.0, "loop": false},
	"knocked_down": {"fps": 6.0, "loop": false},
	"knocked_up": {"fps": 6.0, "loop": false},
	"knocked_side_left": {"fps": 6.0, "loop": false},
	"knocked_side_right": {"fps": 6.0, "loop": false},
}

const ALIASES: Dictionary = {
	"default": "idle_down",
	"idle": "idle_down",
	"idle_side": "idle_side_right",
	"walk": "walk_down",
	"walk_side": "walk_side_right",
	"work_side": "work",
	"work_down": "work",
	"work_up": "work",
	"dash": "dash_down",
	"dash_side": "dash_side_right",
	"throw": "throw_side_right",
	"throw_side": "throw_side_right",
	"throw_down": "throw_side_right",
	"throw_up": "throw_side_left",
	"strike": "strike_1_down",
	"strike_side": "strike_1_side_right",
	"strike_down": "strike_1_down",
	"strike_up": "strike_1_up",
	"strike_side_left": "strike_1_side_left",
	"strike_side_right": "strike_1_side_right",
	"shield": "shield_down",
	"shield_side": "shield_side_right",
	"knocked": "knocked_down",
	"knocked_side": "knocked_side_right",
	"walk_battle": "walk_battle_down",
	"walk_battle_side": "walk_battle_side_right",
	"dash_battle": "dash_battle_down",
	"dash_battle_side": "dash_battle_side_right",
	"idle_battle": "idle_battle_down",
	"idle_battle_side": "idle_battle_side_right",
	"walk_down1": "walk_battle_down",
	"walk_up1": "walk_battle_up",
	"walk_side_left1": "walk_battle_side_left",
	"walk_side_right1": "walk_battle_side_right",
	"dash_down1": "dash_battle_down",
	"dash_up1": "dash_battle_up",
	"dash_side_left1": "dash_battle_side_left",
	"dash_side_right1": "dash_battle_side_right",
	"idle_down1": "idle_battle_down",
	"idle_up1": "idle_battle_up",
	"idle_side_left1": "idle_battle_side_left",
	"idle_side_right1": "idle_battle_side_right",
}

## Mengekstrak nomor urut numerik frame dari filename seperti "... (3).png"
static func get_frame_number(filename: String) -> int:
	var p1: int = filename.rfind("(")
	var p2: int = filename.rfind(")")
	if p1 != -1 and p2 != -1 and p2 > p1:
		return int(filename.substr(p1 + 1, p2 - p1 - 1))
	return 1

## Memetakan path direktori dan nama file ke tag animasi kanonikal
static func map_file_to_anim(dir_path: String, filename: String) -> String:
	var dir_clean: String = dir_path.replace("\\", "/").to_lower()
	var name_lower: String = filename.to_lower()

	if dir_clean.ends_with("/bekerja"):
		return "work"
	elif dir_clean.ends_with("/berjalan/biasa"):
		if "walk_down" in name_lower: return "walk_down"
		elif "walk_up" in name_lower: return "walk_up"
		elif "walk_side_left" in name_lower: return "walk_side_left"
		elif "walk_side_right" in name_lower: return "walk_side_right"
	elif dir_clean.ends_with("/berjalan/battle"):
		if "walk_down1" in name_lower: return "walk_battle_down"
		elif "walk_up1" in name_lower: return "walk_battle_up"
		elif "walk_side_left1" in name_lower: return "walk_battle_side_left"
		elif "walk_side_right1" in name_lower: return "walk_battle_side_right"
	elif dir_clean.ends_with("/dash/biasa"):
		if "dash_down" in name_lower: return "dash_down"
		elif "dash_up" in name_lower: return "dash_up"
		elif "dash_side_left" in name_lower: return "dash_side_left"
		elif "dash_side_right" in name_lower: return "dash_side_right"
	elif dir_clean.ends_with("/dash/battle"):
		if "dash_down1" in name_lower: return "dash_battle_down"
		elif "dash_up1" in name_lower: return "dash_battle_up"
		elif "dash_side_left1" in name_lower: return "dash_battle_side_left"
		elif "dash_side_right1" in name_lower: return "dash_battle_side_right"
	elif dir_clean.ends_with("/diam/biasa"):
		if "idle_down_up" in name_lower: return "idle_up"
		elif "idle_down" in name_lower: return "idle_down"
		elif "idle_side_left" in name_lower: return "idle_side_left"
		elif "idle_side_right" in name_lower: return "idle_side_right"
	elif dir_clean.ends_with("/diam/battle"):
		if "idle_down1" in name_lower: return "idle_battle_down"
		elif "idle_up1" in name_lower: return "idle_battle_up"
		elif "idle_side_left1" in name_lower: return "idle_battle_side_left"
		elif "idle_side_right1" in name_lower: return "idle_battle_side_right"
	elif dir_clean.ends_with("/lempar"):
		if "idle_side_left" in name_lower: return "throw_side_left"
		elif "idle_side_right" in name_lower: return "throw_side_right"
	elif dir_clean.ends_with("/memukul/memukul 1"):
		if "strike_down" in name_lower: return "strike_1_down"
		elif "strike_up" in name_lower: return "strike_1_up"
		elif "strike_side_left" in name_lower: return "strike_1_side_left"
		elif "strike_side_right" in name_lower: return "strike_1_side_right"
	elif dir_clean.ends_with("/memukul/memukul 2"):
		if "strike_down1" in name_lower: return "strike_2_down"
		elif "strike_up1" in name_lower: return "strike_2_up"
		elif "strike_side_left1" in name_lower: return "strike_2_side_left"
		elif "strike_side_right1" in name_lower: return "strike_2_side_right"
	elif dir_clean.ends_with("/menangkis"):
		if "shield_down" in name_lower: return "shield_down"
		elif "shield_up" in name_lower: return "shield_up"
		elif "idle_side_left" in name_lower: return "shield_side_left"
		elif "idle_side_right" in name_lower: return "shield_side_right"
	elif dir_clean.ends_with("/terpental"):
		if "knocked_down" in name_lower: return "knocked_down"
		elif "knocked_up" in name_lower: return "knocked_up"
		elif "knocked_side_left" in name_lower: return "knocked_side_left"
		elif "knocked_side_right" in name_lower: return "knocked_side_right"

	return ""

## Mengumpulkan seluruh file PNG di res://assets/rangga/ dan mengelompokkannya per animasi
static func scan_rangga_frames() -> Dictionary:
	var anim_frames: Dictionary = {} # anim_name -> Array of {"num": int, "path": String}
	_scan_dir_recursive(RANGGA_ROOT, anim_frames)

	# Urutkan secara numerik berdasarkan nomor frame (1..N)
	for anim_name: String in anim_frames.keys():
		var frames_list: Array = anim_frames[anim_name] as Array
		frames_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a["num"]) < int(b["num"])
		)
	return anim_frames

static func _scan_dir_recursive(dir_path: String, out_map: Dictionary) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var item: String = dir.get_next()
	while not item.is_empty():
		if item != "." and item != "..":
			var full_path: String = dir_path + "/" + item
			if dir.current_is_dir():
				_scan_dir_recursive(full_path, out_map)
			elif item.to_lower().ends_with(".png"):
				var anim: String = map_file_to_anim(dir_path, item)
				if not anim.is_empty():
					if not out_map.has(anim):
						out_map[anim] = []
					var num: int = get_frame_number(item)
					out_map[anim].append({"num": num, "path": full_path})
		item = dir.get_next()
	dir.list_dir_end()

## Membangun SpriteFrames lengkap berisi 43 animasi utama + alias kompatibilitas
static func build_sprite_frames() -> SpriteFrames:
	var anim_frames: Dictionary = scan_rangga_frames()
	if anim_frames.is_empty():
		push_warning("RanggaSpriteBuilder: No frames found in " + RANGGA_ROOT)
		return null

	var sf: SpriteFrames = SpriteFrames.new()
	if sf.has_animation(&"default"):
		sf.remove_animation(&"default")

	# Tambahkan animasi utama
	for anim_name: String in anim_frames.keys():
		var s_name: StringName = StringName(anim_name)
		if not sf.has_animation(s_name):
			sf.add_animation(s_name)

		var cfg: Dictionary = ANIM_CONFIGS.get(anim_name, {"fps": 8.0, "loop": true})
		sf.set_animation_speed(s_name, float(cfg["fps"]))
		sf.set_animation_loop(s_name, bool(cfg["loop"]))

		var frames_list: Array = anim_frames[anim_name] as Array
		for f_info: Dictionary in frames_list:
			var path: String = f_info["path"] as String
			var tex: Texture2D = load(path) as Texture2D
			if tex != null:
				sf.add_frame(s_name, tex)

	# Tambahkan alias kompatibilitas
	for alias_name: String in ALIASES.keys():
		var target_name: String = ALIASES[alias_name] as String
		var s_alias: StringName = StringName(alias_name)
		var s_target: StringName = StringName(target_name)

		if sf.has_animation(s_target):
			if not sf.has_animation(s_alias):
				sf.add_animation(s_alias)
			sf.set_animation_speed(s_alias, sf.get_animation_speed(s_target))
			sf.set_animation_loop(s_alias, sf.get_animation_loop(s_target))
			var frame_count: int = sf.get_frame_count(s_target)
			for i: int in range(frame_count):
				sf.add_frame(s_alias, sf.get_frame_texture(s_target, i))

	return sf
