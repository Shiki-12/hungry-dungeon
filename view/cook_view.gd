class_name CookView
extends Node2D

# view/cook_view.gd
# Tampilan visual & penanda arah untuk CookEntity

@export var cook_entity: CookEntity

@onready var label: Label = $NameLabel
@onready var facing_marker: Polygon2D = $FacingMarker
@onready var body_rect: ColorRect = $BodyRect

func _ready() -> void:
	if not cook_entity and get_parent() is CookEntity:
		cook_entity = get_parent() as CookEntity
	
	_update_appearance()

func _process(_delta: float) -> void:
	if not cook_entity:
		return
	
	# Perbarui posisi penanda arah hadap
	if facing_marker:
		facing_marker.position = cook_entity.facing_direction * 10.0

func _update_appearance() -> void:
	if not cook_entity:
		return
	
	if label:
		var p_tag: String = "P1" if cook_entity.cook_id == 1 else "P2"
		label.text = "%s (%s)" % [cook_entity.cook_name, p_tag]
		label.position = Vector2(-24, -20)
	
	if body_rect:
		# Warna pembeda: Rangga = Biru laut, Sekar = Oranye kemerahan
		if cook_entity.cook_id == 1:
			body_rect.color = Color("#2980b9") # Biru
		else:
			body_rect.color = Color("#d35400") # Oranye
