class_name FacingMapData
extends Resource

@export var id: StringName = &""
@export var direction_to_animation: Dictionary = {
	&"N": &"up", &"NE": &"up", &"E": &"side", &"SE": &"side",
	&"S": &"down", &"SW": &"side", &"W": &"side", &"NW": &"up"
}
@export var flip_side: bool = true

static func direction_tag(direction: Vector2) -> StringName:
	if direction == Vector2.ZERO:
		return &"S"
	var angle: float = snappedf(direction.angle(), PI / 4.0)
	var index: int = int(round(angle / (PI / 4.0)))
	var tags: Array[StringName] = [&"E", &"SE", &"S", &"SW", &"W", &"NW", &"N", &"NE"]
	return tags[posmod(index, 8)]

func animation_for(direction: Vector2) -> StringName:
	var tag: StringName = direction_tag(direction)
	return StringName(str(direction_to_animation.get(tag, &"down")))

func should_flip(direction: Vector2) -> bool:
	var tag: StringName = direction_tag(direction)
	return flip_side and (tag == &"W" or tag == &"SW")
