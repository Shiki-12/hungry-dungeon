class_name StepData
extends Resource

enum StepType {
	CHOP,
	COOK,
	STEAM,
	GRILL,
	FRY,
	BOIL,
	POUND,
	WRAP,
	ASSEMBLE
}

@export var id: String = ""
@export var step_type: StepType = StepType.CHOP
@export var input_items: Array[String] = []
@export var output_item: String = ""
@export var duration_seconds: float = 5.0
@export var required_station_type: String = ""
