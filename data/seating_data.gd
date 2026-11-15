class_name SeatingData
extends Resource

@export var long_seats: int = 0
@export var small_tables: int = 0
@export var max_active_monsters: int = 0
@export var max_open_tickets: int = 0
@export var long_table_bias: float = 0.6
@export var seat_patience_scale_long: float = 1.0
@export var seat_patience_scale_small: float = 0.85
@export var balloon_offset: Vector2 = Vector2(8, -12)
@export var emote_offset: Vector2 = Vector2(8, -20)
