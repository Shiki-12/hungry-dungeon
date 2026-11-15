extends RefCounted

const ItemScript: Script = preload("res://sim/entities/item.gd")
const StationScript: Script = preload("res://sim/entities/station.gd")

func run_all() -> bool:
	var plate: RefCounted = ItemScript.new(&"plate_clean", &"PLATE", &"clean")
	if not plate.add_component(&"item_bawang_prepped"):
		return false
	if not plate.add_component(&"item_jamur_prepped"):
		return false
	if not plate.add_component(&"item_nasi_cooked"):
		return false
	var required: Array[StringName] = [&"item_nasi_cooked", &"item_bawang_prepped", &"item_jamur_prepped"]
	if not plate.matches_signature(required):
		return false
	return not plate.add_component(&"extra")
