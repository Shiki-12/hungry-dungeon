class_name SimItem
extends RefCounted

const MAX_PLATE_COMPONENTS: int = 3
const MAX_TRAY_COMPONENTS: int = 8
const MAX_DIRTY_STACK: int = 3
var item_id: StringName
var category: StringName
var form: StringName
var components: Array[StringName] = []
var is_dirty: bool = false
var stack_count: int = 1
var cookware_locked_timer: float = 0.0

func _init(id: StringName = &"", item_category: StringName = &"", item_form: StringName = &"") -> void:
	item_id = id
	category = item_category
	form = item_form

func matches_signature(required: Array) -> bool:
	if required.size() != components.size(): return false
	var a: Dictionary = {}; var b: Dictionary = {}
	for c: StringName in components: a[c] = int(a.get(c, 0)) + 1
	for value: Variant in required:
		var c: StringName = StringName(value)
		b[c] = int(b.get(c, 0)) + 1
	return a == b

func add_component(component: StringName) -> bool:
	var limit: int = MAX_TRAY_COMPONENTS if category == &"TRAY" or item_id == &"plate_tumpeng" else MAX_PLATE_COMPONENTS
	if component == &"" or components.size() >= limit: return false
	components.append(component); return true

func clear_contents() -> void:
	components.clear(); is_dirty = false

func mark_dirty() -> void:
	is_dirty = true; stack_count = clampi(stack_count, 1, MAX_DIRTY_STACK)

static func make_plate() -> SimItem:
	return SimItem.new(&"plate_clean", &"PLATE", &"clean")

static func make_dirty_plate(count: int = 1) -> SimItem:
	var p: SimItem = make_plate(); p.mark_dirty(); p.stack_count = clampi(count, 1, MAX_DIRTY_STACK); return p
