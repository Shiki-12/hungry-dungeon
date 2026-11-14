class_name StationData
extends Resource

enum StationType {
	CHOPPING_BOARD,
	MORTAR,
	STOVE,
	STEAMER,
	CHARCOAL_GRILL,
	PAN,
	POT,
	PLATE_RETURN,
	TRASH,
	SERVING_TABLE
}

@export var id: String = ""
@export var station_type: StationType = StationType.CHOPPING_BOARD
@export var is_automatic: bool = false
@export var accepted_items: Array[String] = []
@export var burn_timer_seconds: float = 10.0
@export var lock_duration_after_strike: float = 4.0
