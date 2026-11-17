extends Node

# Global Signal Bus (Pemisahan Sim, View, dan UI)

# --- Sinyal Pesanan ---
@warning_ignore("unused_signal")
signal order_received(order_id: String, recipe_id: String, monster_id: String, patience_seconds: float)
@warning_ignore("unused_signal")
signal order_served(order_id: String, result_type: String, score_delta: int, satisfaction_delta: int)
@warning_ignore("unused_signal")
signal order_failed(order_id: String, penalty: int, reason: String)

# --- Sinyal Stasiun & Memasak ---
@warning_ignore("unused_signal")
signal station_state_changed(station_id: String, old_state: int, new_state: int, progress: float)
@warning_ignore("unused_signal")
signal station_item_placed(station_id: String, item_id: String)
@warning_ignore("unused_signal")
signal station_item_taken(station_id: String, item_id: String)

# --- Sinyal Lemparan ---
@warning_ignore("unused_signal")
signal throw_started(cook_id: int, item_id: String, origin: Vector2, target: Vector2, flight_time: float)
@warning_ignore("unused_signal")
signal throw_resolved(cook_id: int, item_id: String, result_type: String, landing_pos: Vector2)

# --- Sinyal Koki & Interaksi ---
@warning_ignore("unused_signal")
signal cook_interacted(cook_id: int, target_name: String)
@warning_ignore("unused_signal")
signal cook_struck(cook_id: int, hit_pos: Vector2, is_pan: bool)
@warning_ignore("unused_signal")
signal pan_spilled(cook_id: int, item_id: String, spill_pos: Vector2)
@warning_ignore("unused_signal")
signal cook_item_changed(cook_id: int, held_item_id: String)

# --- Sinyal Monster ---
@warning_ignore("unused_signal")
signal monster_spawned(monster_id: String, table_index: int)
@warning_ignore("unused_signal")
signal monster_state_changed(monster_id: String, old_state: int, new_state: int)
@warning_ignore("unused_signal")
signal monster_patience_changed(monster_id: String, current_patience: float, max_patience: float)
@warning_ignore("unused_signal")
signal monster_expelled(monster_id: String, by_cook_id: int, was_pan: bool)
@warning_ignore("unused_signal")
signal monster_left(monster_id: String, satisfied: bool)

# --- Sinyal Skill & Combo ---
@warning_ignore("unused_signal")
signal skill_activated(cook_id: int, skill_id: String)
@warning_ignore("unused_signal")
signal combo_triggered(combo_id: String, bonus_score: int)

# --- Sinyal Dapur, Level, dan Sistem ---
@warning_ignore("unused_signal")
signal kitchen_health_changed(current_health: int, max_health: int)
@warning_ignore("unused_signal")
signal score_changed(current_score: int, score_delta: int)
@warning_ignore("unused_signal")
signal star_reached(star_index: int, score: int)
@warning_ignore("unused_signal")
signal level_started(level_id: String)
@warning_ignore("unused_signal")
signal level_time_updated(time_remaining: float, total_duration: float)
@warning_ignore("unused_signal")
signal level_completed(level_id: String, final_score: int, stars_earned: int, is_win: bool)
@warning_ignore("unused_signal")
signal game_paused(is_paused: bool)
