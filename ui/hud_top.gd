extends Control

## HUD Atas (480x30 px) — FR-UI-01.
## Menampilkan hingga 6 kartu tiket pesanan (40x26 px) di sisi kiri, serta Skor dan Timer di sisi kanan.

const AssetsScript: Script = preload("res://autoload/assets.gd")

const HUD_W: float = 480.0
const HUD_H: float = 30.0
const MAX_TICKETS: int = 6

var tickets_container: HBoxContainer
var score_label: Label
var timer_label: Label
var active_tickets: Array[Dictionary] = [] # Array of { order_id, recipe_id, patience_pct }

func _init() -> void:
	custom_minimum_size = Vector2(HUD_W, HUD_H)
	size = Vector2(HUD_W, HUD_H)

func _ready() -> void:
	_build_hud()
	_connect_events()

func _build_hud() -> void:
	# Latar belakang gelap
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.1, 0.12, 0.15, 0.95)
	bg.size = Vector2(HUD_W, HUD_H)
	add_child(bg)
	
	# Garis pembatas bawah 1 px
	var border: ColorRect = ColorRect.new()
	border.color = Color(0.2, 0.3, 0.25, 0.8)
	border.position = Vector2(0.0, HUD_H - 1.0)
	border.size = Vector2(HUD_W, 1.0)
	add_child(border)

	# Container tiket pesanan di kiri
	tickets_container = HBoxContainer.new()
	tickets_container.position = Vector2(4.0, 2.0)
	tickets_container.custom_minimum_size = Vector2(250.0, 26.0)
	tickets_container.add_theme_constant_override("separation", 3)
	add_child(tickets_container)

	# Papan skor di kanan
	score_label = Label.new()
	score_label.position = Vector2(280.0, 7.0)
	score_label.custom_minimum_size = Vector2(100.0, 16.0)
	score_label.add_theme_font_size_override("font_size", 8)
	score_label.text = "SKOR: 0"
	add_child(score_label)

	# Timer di ujung kanan
	timer_label = Label.new()
	timer_label.position = Vector2(400.0, 7.0)
	timer_label.custom_minimum_size = Vector2(70.0, 16.0)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_label.add_theme_font_size_override("font_size", 8)
	timer_label.text = "03:00"
	add_child(timer_label)

func _connect_events() -> void:
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree and (loop as SceneTree).root:
		var events_node: Node = (loop as SceneTree).root.get_node_or_null("Events")
		if events_node != null:
			if events_node.has_signal("score_changed"):
				events_node.connect("score_changed", Callable(self, "_on_score_changed"))
			if events_node.has_signal("level_time_updated"):
				events_node.connect("level_time_updated", Callable(self, "_on_time_updated"))

func _on_score_changed(current_score: int, _delta: int) -> void:
	set_score(current_score)

func _on_time_updated(time_remaining: float, _total: float) -> void:
	set_time(time_remaining)

func set_score(score: int) -> void:
	if score_label:
		score_label.text = "SKOR: %d" % score

func set_time(time_sec: float) -> void:
	if timer_label:
		var m: int = int(maxf(0.0, time_sec)) / 60
		var s: int = int(maxf(0.0, time_sec)) % 60
		timer_label.text = "%02d:%02d" % [m, s]

func update_tickets(tickets: Array) -> void:
	active_tickets.clear()
	for child: Node in tickets_container.get_children():
		child.queue_free()

	var limit: int = mini(MAX_TICKETS, tickets.size())
	for i: int in range(limit):
		var t_info: Dictionary = tickets[i]
		active_tickets.append(t_info)
		var card: Control = _create_ticket_card(t_info)
		tickets_container.add_child(card)

func _create_ticket_card(t_info: Dictionary) -> Control:
	var card: Control = Control.new()
	card.custom_minimum_size = Vector2(40.0, 26.0)
	card.size = Vector2(40.0, 26.0)

	# Latar kartu 40x26
	var bg: ColorRect = ColorRect.new()
	bg.size = Vector2(40.0, 26.0)
	bg.color = Color(0.18, 0.22, 0.25, 0.9)
	card.add_child(bg)

	# Ikon hidangan 24x24
	var icon_box: ColorRect = ColorRect.new()
	icon_box.position = Vector2(8.0, 1.0)
	icon_box.size = Vector2(24.0, 20.0)
	icon_box.color = Color(0.9, 0.5, 0.2, 0.85)
	card.add_child(icon_box)

	# Label teks pendek resep
	var r_name: String = String(t_info.get("recipe_id", "")).trim_prefix("recipe_").substr(0, 3).to_upper()
	var lbl: Label = Label.new()
	lbl.position = Vector2(8.0, 5.0)
	lbl.size = Vector2(24.0, 12.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 6)
	lbl.text = r_name
	card.add_child(lbl)

	# Bar waktu kesabaran (16x3 atau 36x2)
	var pct: float = clampf(float(t_info.get("patience_pct", 1.0)), 0.0, 1.0)
	var bar_bg: ColorRect = ColorRect.new()
	bar_bg.position = Vector2(2.0, 22.0)
	bar_bg.size = Vector2(36.0, 2.0)
	bar_bg.color = Color(0.1, 0.1, 0.1, 0.8)
	card.add_child(bar_bg)

	var bar_fill: ColorRect = ColorRect.new()
	bar_fill.position = Vector2(2.0, 22.0)
	bar_fill.size = Vector2(36.0 * pct, 2.0)
	if pct > 0.5:
		bar_fill.color = Color(0.2, 0.85, 0.3) # Hijau
	elif pct > 0.0:
		bar_fill.color = Color(0.95, 0.75, 0.15) # Kuning
	else:
		bar_fill.color = Color(0.9, 0.2, 0.2) # Merah
	card.add_child(bar_fill)

	return card
