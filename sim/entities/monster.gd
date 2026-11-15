class_name SimMonster
extends RefCounted

## Deterministic guest/hostile monster state machine.
enum State { ARRIVING, SEATED, BROWSING, WAITING, EATING, SATISFIED, LEAVING, ENRAGED, ATTACKING, STEAL_RUN, EXPELLED }
const PATIENCE_MAX: float = 100.0
const SMALL_TABLE_SCALE: float = 0.85
const STEAL_SPEED: float = 48.0

var monster_id: int = 0
var monster_type: StringName = &"goblin"
var state: State = State.ARRIVING
var position: Vector2 = Vector2.ZERO
var tunnel_position: Vector2 = Vector2.ZERO
var seat_id: int = -1
var table_kind: StringName = &"LONG"
var requested_recipe: StringName = &""
var patience: float = PATIENCE_MAX
var base_patience_sec: float = 40.0
var patience_elapsed: float = 0.0
var enraged_hits: int = 0
var stolen_item_id: StringName = &""
var attack_timer: float = 10.0
var cracker_timer: float = 0.0
var satisfaction: float = 0.0

func _init(id: int = 0, kind: StringName = &"goblin") -> void:
	monster_id = id
	monster_type = kind

func seat(table: StringName, assigned_seat: int, recipe: StringName) -> void:
	table_kind = table
	seat_id = assigned_seat
	requested_recipe = recipe
	state = State.SEATED
	patience = PATIENCE_MAX
	patience_elapsed = 0.0

func begin_browsing() -> void:
	if state == State.SEATED:
		state = State.BROWSING

func begin_waiting() -> void:
	if state == State.SEATED or state == State.BROWSING:
		state = State.WAITING
		patience_elapsed = 0.0

func patience_duration() -> float:
	return base_patience_sec * (SMALL_TABLE_SCALE if table_kind == &"SMALL" else 1.0)

func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	if cracker_timer > 0.0:
		cracker_timer = maxf(0.0, cracker_timer - delta)
	if state == State.WAITING and cracker_timer <= 0.0:
		patience_elapsed = minf(patience_duration(), patience_elapsed + delta)
		patience = clampf(100.0 * (1.0 - patience_elapsed / patience_duration()), 0.0, PATIENCE_MAX)
		if patience <= 0.0:
			state = State.ENRAGED
	elif state == State.ATTACKING:
		attack_timer = maxf(0.0, attack_timer - delta)
		if attack_timer <= 0.0:
			state = State.LEAVING
	elif state == State.STEAL_RUN:
		position = position.move_toward(tunnel_position, STEAL_SPEED * delta)
		if position.distance_to(tunnel_position) < 0.5:
			state = State.LEAVING

func patience_stage() -> int:
	if patience > 50.0:
		return 1
	if patience > 0.0:
		return 2
	return 3

func serve(recipe: StringName, sambal_bonus: float = 0.0, jitu_bonus: float = 0.0) -> bool:
	if state != State.WAITING or recipe != requested_recipe:
		return false
	satisfaction = minf(100.0, 40.0 + patience * 0.4 + sambal_bonus + jitu_bonus)
	state = State.EATING
	return true

func finish_eating() -> void:
	if state == State.EATING:
		state = State.SATISFIED
		state = State.LEAVING

func start_attack() -> bool:
	if state != State.ENRAGED:
		return false
	state = State.ATTACKING
	attack_timer = 10.0
	return true

func start_steal(item_id: StringName, target: Vector2) -> bool:
	if state != State.ENRAGED or monster_type != &"goblin" or item_id == &"":
		return false
	stolen_item_id = item_id
	tunnel_position = target
	state = State.STEAL_RUN
	return true

func give_cracker() -> bool:
	if state != State.WAITING:
		return false
	cracker_timer = 8.0
	return true

func hit(cookware: bool) -> bool:
	if state != State.ENRAGED and state != State.ATTACKING and state != State.STEAL_RUN:
		return false
	if state == State.STEAL_RUN:
		stolen_item_id = &""
		state = State.EXPELLED
		return true
	if cookware:
		state = State.EXPELLED
		return true
	enraged_hits += 1
	if enraged_hits >= 3:
		state = State.EXPELLED
	return true

func state_name() -> StringName:
	return [&"ARRIVING", &"SEATED", &"BROWSING", &"WAITING", &"EATING", &"SATISFIED", &"LEAVING", &"ENRAGED", &"ATTACKING", &"STEAL_RUN", &"EXPELLED"][state]
