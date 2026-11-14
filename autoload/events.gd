extends Node

# Global Signal Bus (Pemisahan Sim, View, dan UI)

# --- Sinyal Pesanan ---
signal order_received(order_id: String, recipe_id: String, monster_id: String, patience_seconds: float)
signal order_served(order_id: String, result_type: String, score_delta: int, satisfaction_delta: int)
signal order_failed(order_id: String, penalty: int, reason: String)

# --- Sinyal Stasiun & Memasak ---
signal station_state_changed(station_id: String, old_state: int, new_state: int, progress: float)
signal station_item_placed(station_id: String, item_id: String)
signal station_item_taken(station_id: String, item_id: String)

# --- Sinyal Lemparan ---
signal throw_started(cook_id: int, item_id: String, origin: Vector2, target: Vector2, flight_time: float)
signal throw_resolved(cook_id: int, item_id: String, result_type: String, landing_pos: Vector2)

# --- Sinyal Koki & Interaksi ---
signal cook_interacted(cook_id: int, target_name: String)
signal cook_struck(cook_id: int, hit_pos: Vector2, is_pan: bool)
signal pan_spilled(cook_id: int, item_id: String, spill_pos: Vector2)
signal cook_item_changed(cook_id: int, held_item_id: String)

# --- Sinyal Monster ---
signal monster_spawned(monster_id: String, table_index: int)
signal monster_state_changed(monster_id: String, old_state: int, new_state: int)
signal monster_patience_changed(monster_id: String, current_patience: float, max_patience: float)
signal monster_expelled(monster_id: String, by_cook_id: int, was_pan: bool)
signal monster_left(monster_id: String, satisfied: bool)

# --- Sinyal Skill & Combo ---
signal skill_activated(cook_id: int, skill_id: String)
signal combo_triggered(combo_id: String, bonus_score: int)

# --- Sinyal Dapur, Level, dan Sistem ---
signal kitchen_health_changed(current_health: int, max_health: int)
signal score_changed(current_score: int, score_delta: int)
signal star_reached(star_index: int, score: int)
signal level_started(level_id: String)
signal level_time_updated(time_remaining: float, total_duration: float)
signal level_completed(level_id: String, final_score: int, stars_earned: int, is_win: bool)
signal game_paused(is_paused: bool)
