class_name ItemView
extends Node2D

## View-only bridge. Asset lookup uses ID through global Assets when available.
var item_id: StringName = &""
var displayed_components: Array[StringName] = []

func set_item(item: SimItem) -> void:
	item_id = item.item_id
	displayed_components = item.components.duplicate()

func clear_item() -> void:
	item_id = &""
	displayed_components.clear()
