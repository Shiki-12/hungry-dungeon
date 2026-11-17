class_name CookView
extends Node2D

## CookView — View representation for kitchen cooks (Rangga & Sekar).
## Handles AnimatedSprite2D, 4-way direction, battle/normal mode, actions, and held items.

const RanggaBuilder: Script = preload("res://view/rangga_sprite_builder.gd")

var cook_entity: RefCounted # Cook simulation entity
var asset_id: StringName = &"cook_rangga"

@export var facing_map: FacingMapData

var anim_sprite: AnimatedSprite2D
var label: Label
var facing_marker: Polygon2D
var body_rect: ColorRect
var held_item_container: Node2D
var held_item_bg: ColorRect
var held_item_label: Label

# Battle & Action state
var battle_timer: float = 0.0
var _current_action: String = ""
var _action_timer: float = 0.0
var _strike_combo: int = 1
var is_working: bool = false
var is_dashing: bool = false
var hostile_threat_nearby: bool = false
var _last_pos: Vector2 = Vector2.ZERO
var _is_moving: bool = false

func _ready() -> void:
	_ensure_child_nodes()
	_update_appearance()

func setup(entity: RefCounted, p_asset_id: StringName = &"cook_rangga") -> void:
	cook_entity = entity
	asset_id = p_asset_id
	_ensure_child_nodes()
	_update_appearance()

func _ensure_child_nodes() -> void:
	if anim_sprite == null:
		anim_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if anim_sprite == null:
			anim_sprite = AnimatedSprite2D.new()
			anim_sprite.name = "AnimatedSprite2D"
			add_child(anim_sprite)

	anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim_sprite.scale = Vector2(0.25, 0.25)
	anim_sprite.offset = Vector2(0.0, -80.0) # Pivot bottom_center: feet at y=0

	if label == null:
		label = get_node_or_null("NameLabel") as Label
		if label == null:
			label = Label.new()
			label.name = "NameLabel"
			label.add_theme_font_size_override("font_size", 8)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.size = Vector2(48, 12)
			add_child(label)
	label.position = Vector2(-24, -36)

	if facing_marker == null:
		facing_marker = get_node_or_null("FacingMarker") as Polygon2D

	if body_rect == null:
		body_rect = get_node_or_null("BodyRect") as ColorRect
		if body_rect == null:
			body_rect = ColorRect.new()
			body_rect.name = "BodyRect"
			body_rect.size = Vector2(12, 14)
			body_rect.position = Vector2(-6, -14)
			add_child(body_rect)

	if held_item_container == null:
		held_item_container = get_node_or_null("HeldItem") as Node2D
		if held_item_container == null:
			held_item_container = Node2D.new()
			held_item_container.name = "HeldItem"
			held_item_container.position = Vector2(0.0, -32.0)
			add_child(held_item_container)

			held_item_bg = ColorRect.new()
			held_item_bg.size = Vector2(16, 12)
			held_item_bg.position = Vector2(-8, -6)
			held_item_bg.color = Color(0.9, 0.85, 0.7)
			held_item_container.add_child(held_item_bg)

			held_item_label = Label.new()
			held_item_label.size = Vector2(16, 12)
			held_item_label.position = Vector2(-8, -6)
			held_item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			held_item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			held_item_label.add_theme_font_size_override("font_size", 5)
			held_item_label.add_theme_color_override("font_color", Color.BLACK)
			held_item_container.add_child(held_item_label)

func _update_appearance() -> void:
	if not is_inside_tree() and Engine.is_editor_hint():
		return

	var is_final: bool = (Assets.status(asset_id) == &"FINAL")
	if is_final:
		var sf: SpriteFrames = Assets.frames(asset_id)
		if sf != null:
			anim_sprite.sprite_frames = sf
			anim_sprite.visible = true
			if body_rect != null:
				body_rect.visible = false
			if facing_marker != null:
				facing_marker.visible = false
	else:
		anim_sprite.visible = false
		if body_rect != null:
			body_rect.visible = true
			var cid: int = int(cook_entity.get("cook_id")) if cook_entity != null else 1
			body_rect.color = Color("#2980b9") if cid == 1 else Color("#d35400")

	if label != null and cook_entity != null:
		var cid: int = int(cook_entity.get("cook_id"))
		var cname: String = String(cook_entity.get("cook_name"))
		var p_tag: String = "P1" if cid == 1 else "P2"
		label.text = "%s (%s)" % [cname, p_tag]

func _process(delta: float) -> void:
	if not cook_entity:
		return

	# Update position from simulation entity
	var ent_pos: Vector2 = cook_entity.position if "position" in cook_entity else position
	position = ent_pos
	_is_moving = ent_pos.distance_squared_to(_last_pos) > 0.04
	_last_pos = ent_pos

	var facing: Vector2 = cook_entity.facing_direction if "facing_direction" in cook_entity else Vector2.DOWN
	if facing_marker != null and facing_marker.visible:
		facing_marker.position = facing * 10.0
		facing_marker.rotation = facing.angle()

	# Battle timer countdown
	if battle_timer > 0.0:
		battle_timer = maxf(0.0, battle_timer - delta)

	# Action timer countdown
	if _action_timer > 0.0:
		_action_timer = maxf(0.0, _action_timer - delta)
		if _action_timer <= 0.0:
			_current_action = ""

	# Update held item node
	_update_held_item()

	# Update sprite animation
	if anim_sprite.visible and anim_sprite.sprite_frames != null:
		_update_animation(facing, delta)

func _update_held_item() -> void:
	if held_item_container == null:
		return
	var held_id: String = String(cook_entity.get("held_item_id")) if cook_entity != null else ""
	if held_id == "":
		held_item_container.visible = false
	else:
		held_item_container.visible = true
		held_item_container.position = Vector2(0.0, -32.0)
		var short_tag: String = held_id.substr(0, 4).to_upper()
		if held_item_label != null:
			held_item_label.text = short_tag
		if held_item_bg != null:
			if held_id.begins_with("dish_"):
				held_item_bg.color = Color(1.0, 0.65, 0.2)
			elif held_id == "kuali":
				held_item_bg.color = Color(0.3, 0.35, 0.4)
			elif held_id.begins_with("item_"):
				held_item_bg.color = Color(0.4, 0.8, 0.5)
			else:
				held_item_bg.color = Color(0.9, 0.85, 0.7)

func get_dir_string(dir: Vector2) -> String:
	if absf(dir.x) >= absf(dir.y):
		return "side_left" if dir.x < 0.0 else "side_right"
	else:
		return "up" if dir.y < 0.0 else "down"

func is_battle_mode() -> bool:
	var held_id: String = String(cook_entity.get("held_item_id")) if cook_entity != null else ""
	var holding_food: bool = (held_id != "" and held_id != "kuali" and held_id != "sutil")
	if holding_food:
		return false
	return battle_timer > 0.0 or hostile_threat_nearby

func enter_battle_mode(duration: float = 3.0) -> void:
	battle_timer = maxf(battle_timer, duration)

func trigger_dash(duration: float = 0.25) -> void:
	_current_action = "dash_battle" if is_battle_mode() else "dash"
	_action_timer = duration

func trigger_strike() -> void:
	enter_battle_mode(3.0)
	_strike_combo = 2 if _strike_combo == 1 else 1
	_current_action = "strike_%d" % _strike_combo
	_action_timer = 0.5

func trigger_shield() -> void:
	enter_battle_mode(3.0)
	_current_action = "shield"
	_action_timer = 0.5

func trigger_throw() -> void:
	_current_action = "throw"
	_action_timer = 0.35

func trigger_knocked() -> void:
	_current_action = "knocked"
	_action_timer = 0.6

func _update_animation(facing: Vector2, _delta: float) -> void:
	var dir_str: String = get_dir_string(facing)
	var sf: SpriteFrames = anim_sprite.sprite_frames
	if sf == null:
		return

	var target_anim: String = ""

	# 1. Action animation has top priority
	if not _current_action.is_empty():
		var act_name: String = "%s_%s" % [_current_action, dir_str]
		if sf.has_animation(StringName(act_name)):
			target_anim = act_name
		elif sf.has_animation(StringName(_current_action)):
			target_anim = _current_action
		else:
			# Fallback for throw side
			if _current_action == "throw":
				target_anim = "throw_side_left" if dir_str == "side_left" else "throw_side_right"

	# 2. Work animation
	elif is_working:
		target_anim = "work"

	# 3. Dash animation
	elif is_dashing or (cook_entity != null and "is_dashing" in cook_entity and cook_entity.get("is_dashing") == true):
		var prefix: String = "dash_battle_" if is_battle_mode() else "dash_"
		target_anim = prefix + dir_str

	# 4. Walk animation
	elif _is_moving:
		var prefix: String = "walk_battle_" if is_battle_mode() else "walk_"
		target_anim = prefix + dir_str

	# 5. Idle animation
	else:
		var prefix: String = "idle_battle_" if is_battle_mode() else "idle_"
		target_anim = prefix + dir_str

	var s_target: StringName = StringName(target_anim)
	if not sf.has_animation(s_target):
		s_target = &"idle_down"

	if anim_sprite.animation != s_target:
		anim_sprite.play(s_target)
