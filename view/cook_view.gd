class_name CookView
extends Node2D

var cook_entity: CookEntity
@export var facing_map: FacingMapData
@onready var label: Label = $NameLabel
@onready var facing_marker: Polygon2D = $FacingMarker
@onready var body_rect: ColorRect = $BodyRect

func _ready() -> void:
	if not cook_entity and get_parent() is Node:
		var parent_entity: Object = get_parent()
		if parent_entity is CookEntity:
			cook_entity = parent_entity as CookEntity
	if not facing_map:
		facing_map = FacingMapData.new()
	_update_appearance()

func _process(_delta: float) -> void:
	if not cook_entity:
		return
	position = cook_entity.position
	if facing_marker:
		facing_marker.position = cook_entity.facing_direction * 10.0
		facing_marker.rotation = cook_entity.facing_direction.angle()

func _update_appearance() -> void:
	if not cook_entity:
		return
	if label:
		var p_tag: String = "P1" if cook_entity.cook_id == 1 else "P2"
		label.text = "%s (%s)" % [cook_entity.cook_name, p_tag]
		label.position = Vector2(-24, -20)
	if body_rect:
		body_rect.color = Color("#2980b9") if cook_entity.cook_id == 1 else Color("#d35400")
