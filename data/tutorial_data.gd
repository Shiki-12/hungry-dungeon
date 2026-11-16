class_name TutorialData
extends Resource

## Definisi data langkah dan aturan level tutorial (FR-TUT-01 s.d. 10).

@export var id: StringName = &""
@export var title_key: StringName = &""
@export var steps: Array[Dictionary] = [] # Array of { step_id, text_key, event_trigger, target_count, blocked_actions, target_highlight }
@export var popup_modal: StringName = &"" # misal "pan_modes", "plate_washing" (FR-TUT-07)
@export var required_players: int = 2
@export var is_adaptive_radius_enabled: bool = false # Khusus T-4 (+25% radius jika 3x meleset)
