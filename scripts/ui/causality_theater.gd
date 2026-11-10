extends Control
## A 3-second, skippable daily payoff made EXCLUSIVELY from simulation history.
## The full chronological LivingOddford replay is still available on demand.

signal close_requested
signal full_replay_requested

const Threads = preload("res://scripts/ui/theater_threads.gd")
const PaperActor = preload("res://scripts/ui/paper_actor.gd")
const Choreography = preload("res://scripts/ui/character_choreography.gd")
const COORDS: Dictionary = {
	"Town Hall": Vector2(.51, .54), "Bakery": Vector2(.87, .61),
	"Post Office": Vector2(.17, .54), "High Street": Vector2(.38, .77),
	"Public Gardens": Vector2(.69, .77), "Parade Hall": Vector2(.46, .38)
}
const CARD_START := 0.57
const CARD_STEP := 0.48
const SUMMARY_AT := 2.73
const PAPER := Color("#f1e2c4")
const INK := Color("#273c41")
const MUTED := Color("#697064")
const BURGUNDY := Color("#7e454c")
const GOLD := Color("#c49a58")
const STAMPS = {"nudge":"NUDGE", "misfile":"MISFILE", "reschedule":"DELAY", "domino":"DOMINO"}

var simulation: Object
var recorded: Array = []
var filings: Array = []
var day_number: int = 1
var before_support: int = 0
var after_support: int = 0
var before_strain: int = 0
var after_strain: int = 0
var reduced_motion: bool = false
var elapsed: float = 0.0
var completed: bool = false
var visible_count: int = 0
var featured: Array = []
var cards: Array[Control] = []
var card_final_positions: Dictionary = {}
var active_actor: Node2D
var thread_layer: Control
var stamp_image: TextureRect
var current_title: Label
var summary_label: Label
var continue_button: Button
var full_replay_button: Button
var count_label: Label
var _motion_tweens: Array[Tween] = []

func configure(game: Object, events: Array, applied_stamps: Array, resolved_day: int, support_from: int, support_to: int, strain_from: int, strain_to: int) -> void:
	simulation = game
	recorded = events.duplicate(true)
	filings = applied_stamps.duplicate(true)
	day_number = resolved_day
	before_support = support_from
	after_support = support_to
	before_strain = strain_from
	after_strain = strain_to
	featured = _choose_events(recorded, filings)

# The showcase is a real, chronological subset of actual incidents. Whenever
# possible it includes the stamped target, its recorded parents and descendants.
# No unrelated events are connected just because they follow each other.
static func _choose_events(events: Array, stamped: Array, cap: int = 4) -> Array:
	if events.size() <= cap:
		return events.duplicate(true)
	var chosen: Dictionary = {}
	var candidates: Array[Dictionary] = []
	for i in range(events.size()):
		var item: Dictionary = events[i]
		var weight: int = int(item.get("support", 0)) * 2
		for filing in stamped:
			if str(filing.get("target", "")) == str(item.get("id", "")):
				weight += 18
		if not (item.get("causes", []) as Array).is_empty():
			weight += 2
		for other in events:
			if (other.get("causes", []) as Array).has(str(item.get("id", ""))):
				weight += 3
				break
		candidates.append({"index":i,"weight":weight})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["weight"]) > int(b["weight"]) if int(a["weight"]) != int(b["weight"]) else int(a["index"]) < int(b["index"])
	)
	for score in candidates:
		if chosen.size() >= cap:
			break
		chosen[int(score["index"])] = true
	# Preserve chronology; some genuine parents may lie outside the short excerpt.
	# Those connections are intentionally omitted (never invented).
	var ordered: Array = []
	for i in range(events.size()):
		if chosen.has(i):
			ordered.append(events[i].duplicate(true))
	return ordered

func _ready() -> void:
	name = "DailyCausalityTheater"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var cfg := ConfigFile.new()
	if cfg.load("user://ministry_visuals.cfg") == OK:
		reduced_motion = bool(cfg.get_value("accessibility", "reduced_motion", false))
	_build()
	if reduced_motion:
		_finish_animation()
	else:
		_start_stamp_slam()
	set_process(not reduced_motion)
	await get_tree().process_frame
	if is_instance_valid(continue_button):
		continue_button.grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_Y: _finish_animation(); get_viewport().set_input_as_handled()
			JOY_BUTTON_X: _view_full_replay(); get_viewport().set_input_as_handled()
			# B is handled by the main scene and closes the modal at once.
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: _finish_animation(); get_viewport().set_input_as_handled()
			KEY_R: _view_full_replay(); get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if completed:
		return
	elapsed += minf(delta, 0.1)
	while visible_count < featured.size() and elapsed >= CARD_START + float(visible_count) * CARD_STEP:
		_reveal(visible_count)
		visible_count += 1
		thread_layer.call("set_revealed", visible_count)
	if elapsed >= SUMMARY_AT:
		_finish_animation()

func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#10262df7")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var panel := PanelContainer.new()
	panel.name = "CausalDailyDossier"
	panel.position = Vector2(24, 15)
	panel.size = Vector2(1232, 770)
	var paper_style := _style(PAPER, GOLD, 4, 16)
	panel.add_theme_stylebox_override("panel", paper_style)
	add_child(panel)
	var heading := _label("THE MINISTRY  /  CAUSALITY THEATER", 30, INK, true)
	heading.position = Vector2(57, 35)
	heading.size = Vector2(780, 46)
	add_child(heading)
	var day := _label("DAY %d    /    OFFICIAL RECONSTRUCTION" % day_number, 18, BURGUNDY, true)
	day.position = Vector2(785, 47)
	day.size = Vector2(425, 34)
	day.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(day)
	var subtitle := _label("Only documented incidents. Only documented causes.", 17, MUTED)
	subtitle.position = Vector2(58, 85)
	subtitle.size = Vector2(950, 27)
	add_child(subtitle)
	var picture_frame := PanelContainer.new()
	picture_frame.name = "CausalityTownBackdrop"
	picture_frame.position = Vector2(55, 120)
	picture_frame.size = Vector2(1170, 326)
	picture_frame.add_theme_stylebox_override("panel", _style(Color("#243b41"), Color("#936f58"), 3, 10))
	add_child(picture_frame)
	var town := TextureRect.new()
	town.name = "CausalityTownImage"
	town.position = Vector2(62, 126)
	town.size = Vector2(1156, 313)
	town.texture = load("res://assets/illustrated/oddford_square.webp") as Texture2D
	town.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	town.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	town.mouse_filter = Control.MOUSE_FILTER_IGNORE
	town.clip_contents = true
	add_child(town)
	var fade := ColorRect.new()
	fade.name = "StageInkWash"
	fade.color = Color("#152d3b6d")
	fade.position = town.position
	fade.size = town.size
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	var headline_back := ColorRect.new()
	headline_back.color = Color("#203b40d9")
	headline_back.position = Vector2(78, 141)
	headline_back.size = Vector2(820, 65)
	add_child(headline_back)
	current_title = _label("AUTHORIZING THE DAY'S EVENTS", 25, Color("#f9e1a7"), true)
	current_title.name = "TheaterCurrentEvent"
	current_title.position = Vector2(91, 153)
	current_title.size = Vector2(795, 49)
	add_child(current_title)
	stamp_image = TextureRect.new()
	stamp_image.name = "DailyStampSlam"
	stamp_image.position = Vector2(94, 247)
	stamp_image.size = Vector2(170, 161)
	stamp_image.texture = load(_seal_texture()) as Texture2D
	stamp_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stamp_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stamp_image.pivot_offset = stamp_image.size / 2.0
	stamp_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stamp_image)
	var filing_text := "NO STAMP FILED  /  NATURAL EVENTS ONLY"
	if filings.size() > 0:
		var names: Array[String] = []
		for stamp in filings:
			var rule: Dictionary = simulation.get_rule(str(stamp.get("target", ""))) if simulation != null else {}
			names.append("%s ON %s" % [STAMPS.get(str(stamp.get("stamp", "")), "STAMP"), str(rule.get("title", "INCIDENT")).to_upper()])
		filing_text = "   +   ".join(PackedStringArray(names))
	var applied := _label(filing_text, 16, Color("#fff0c7"), true)
	applied.name = "RecordedFiledStamps"
	applied.position = Vector2(285, 367)
	applied.size = Vector2(888, 45)
	add_child(applied)
	thread_layer = Threads.new()
	thread_layer.name = "ActualCausalThreads"
	thread_layer.position = Vector2(77, 473)
	thread_layer.size = Vector2(1140, 180)
	thread_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(thread_layer)
	thread_layer.call("configure", featured)
	var cards_title := _label("WHAT ACTUALLY HAPPENED", 17, BURGUNDY, true)
	cards_title.position = Vector2(83, 453)
	cards_title.size = Vector2(720, 27)
	add_child(cards_title)
	var deck := HBoxContainer.new()
	deck.name = "RecordedEventCards"
	deck.position = Vector2(77, 499)
	deck.size = Vector2(1120, 118)
	deck.add_theme_constant_override("separation", 13)
	add_child(deck)
	if featured.is_empty():
		var empty := _label("No incidents occurred. The Ministry has filed a concerned silence.", 20, INK)
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		deck.add_child(empty)
	for i in range(featured.size()):
		var entry: Dictionary = featured[i]
		var card := PanelContainer.new()
		card.name = "RecordedBeat%d" % i
		card.custom_minimum_size = Vector2(269, 112)
		card.add_theme_stylebox_override("panel", _style(Color("#fff8e9"), Color("#b6a080"), 2, 7))
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 3)
		card.add_child(col)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 7)
		col.add_child(top)
		var family: String = _family(str(entry.get("id", "")))
		var art := TextureRect.new()
		art.texture = load("res://assets/illustrated/incident_%s_small.webp" % family) as Texture2D
		art.custom_minimum_size = Vector2(53, 54)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		top.add_child(art)
		var title := _label(str(entry.get("title", "INCIDENT")), 15, INK, true)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(title)
		var detail: String = "%s   /   +%d MOMENTUM" % ["RECORDED", int(entry.get("support", 0))]
		if not (entry.get("causes", []) as Array).is_empty():
			detail = "%d DOCUMENTED CAUSE(S)   /   +%d" % [(entry["causes"] as Array).size(), int(entry.get("support", 0))]
		col.add_child(_label(detail, 12, BURGUNDY, true))
		deck.add_child(card)
		card.modulate.a = 0.0
		cards.append(card)
	count_label = _label("%d REAL INCIDENT%s" % [recorded.size(), "" if recorded.size() == 1 else "S"], 16, MUTED, true)
	count_label.position = Vector2(850, 454)
	count_label.size = Vector2(342, 27)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(count_label)
	summary_label = _label("", 19, BURGUNDY, true)
	summary_label.name = "DailyRegisterSummary"
	summary_label.position = Vector2(82, 627)
	summary_label.size = Vector2(1090, 48)
	summary_label.visible = false
	add_child(summary_label)
	var bottom := HBoxContainer.new()
	bottom.position = Vector2(72, 695)
	bottom.size = Vector2(1135, 57)
	bottom.add_theme_constant_override("separation", 14)
	add_child(bottom)
	var skip := _button("Y  SKIP ANIMATION", false)
	skip.name = "SkipDailyAnimation"
	skip.custom_minimum_size = Vector2(248, 52)
	skip.pressed.connect(_finish_animation)
	bottom.add_child(skip)
	full_replay_button = _button("X  FULL TOWN REPLAY", false)
	full_replay_button.name = "FullTownReplay"
	full_replay_button.custom_minimum_size = Vector2(270, 52)
	full_replay_button.pressed.connect(_view_full_replay)
	bottom.add_child(full_replay_button)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(space)
	continue_button = _button("A / B  BACK TO CASE", true)
	continue_button.name = "ReturnFromDailyTheater"
	continue_button.custom_minimum_size = Vector2(285, 52)
	continue_button.pressed.connect(func(): close_requested.emit())
	bottom.add_child(continue_button)

func _start_stamp_slam() -> void:
	stamp_image.scale = Vector2(1.45, 1.45)
	stamp_image.modulate.a = 0.35
	stamp_image.rotation = -0.15
	var tween := create_tween()
	_motion_tweens.append(tween)
	tween.tween_property(stamp_image, "scale", Vector2(0.88, 0.62), 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(stamp_image, "modulate:a", 1.0, 0.20)
	tween.tween_property(stamp_image, "scale", Vector2.ONE, 0.21).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(stamp_image, "rotation", 0.0, 0.21)
	var director := get_node_or_null("/root/MusicDirector")
	if director != null and director.has_method("play_stamp_effect"):
		director.call("play_stamp_effect")

func _reveal(index: int) -> void:
	if index >= cards.size():
		return
	var card: Control = cards[index]
	card.modulate.a = 1.0
	var entry: Dictionary = featured[index]
	current_title.text = str(entry.get("title", "INCIDENT"))
	if active_actor != null and is_instance_valid(active_actor):
		active_actor.queue_free()
	active_actor = null
	var rule: Dictionary = simulation.get_rule(str(entry.get("id", ""))) if simulation != null else {}
	if not rule.is_empty() and not reduced_motion:
		var place: String = str(rule.get("place", "Town Hall"))
		var role: String = _actor_role(str(entry.get("id", "")), place)
		var actor := PaperActor.new()
		actor.configure(role, reduced_motion)
		actor.name = "RecordedTheaterActor"
		actor.position = Vector2(1050, 345)
		actor.scale = Vector2(0.74, 0.74)
		add_child(actor)
		active_actor = actor
		actor.set_walking(true)
		var target: Vector2 = Vector2(60, 128) + Vector2(1150, 300) * COORDS.get(place, Vector2(.5, .65))
		var motion := create_tween()
		_motion_tweens.append(motion)
		motion.tween_property(actor, "position", target, 0.43).set_trans(Tween.TRANS_SINE)
		motion.tween_callback(actor.set_walking.bind(false))
		motion.tween_callback(actor.set_action.bind("surprised"))
	var start: Vector2 = card.position
	card_final_positions[index] = start
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2(.88, .88)
	card.position = start - Vector2(0, 27)
	var rise := create_tween()
	_motion_tweens.append(rise)
	rise.tween_property(card, "position", start, 0.28).set_trans(Tween.TRANS_BACK)
	rise.parallel().tween_property(card, "scale", Vector2.ONE, 0.28)

func _finish_animation() -> void:
	if completed:
		return
	completed = true
	set_process(false)
	for tween in _motion_tweens:
		if tween != null and tween.is_running():
			tween.kill()
	_motion_tweens.clear()
	stamp_image.scale = Vector2.ONE
	stamp_image.modulate.a = 1.0
	stamp_image.rotation = 0.0
	for i in range(cards.size()):
		var card: Control = cards[i]
		card.modulate.a = 1.0
		card.scale = Vector2.ONE
		if card_final_positions.has(i):
			card.position = card_final_positions[i]
	visible_count = featured.size()
	thread_layer.call("set_revealed", visible_count)
	current_title.text = "THE DAILY REGISTER HAS BEEN UPDATED"
	var others: String = "   /   %d MORE IN THE CHRONICLE" % (recorded.size() - featured.size()) if recorded.size() > featured.size() else ""
	var gain: int = after_support - before_support
	summary_label.text = "%d INCIDENTS   /   %+d MOMENTUM   /   STRAIN %d TO %d%s" % [recorded.size(), gain, before_strain, after_strain, others]
	summary_label.visible = true
	var skip := find_child("SkipDailyAnimation", true, false) as Button
	if skip != null:
		skip.text = "Y  REPLAY COMPLETE"
		skip.disabled = true

func _view_full_replay() -> void:
	full_replay_requested.emit()

func _seal_texture() -> String:
	if filings.size() > 0:
		var id: String = str(filings[0].get("stamp", "nudge"))
		if STAMPS.has(id):
			return "res://assets/illustrated/stamp_%s.webp" % id
	return "res://assets/seal.svg"

static func _actor_role(id: String, place: String) -> String:
	if "goose" in id or "sandwich" in id: return "gerald"
	if place == "Bakery": return "baker"
	if place == "Post Office": return "clerk"
	if place == "Town Hall": return "mayor"
	if place == "Public Gardens": return "organizer"
	return "reporter"

static func _family(id: String) -> String:
	if "rain" in id or "fair" in id or "crowd" in id: return "rain"
	if "sandwich" in id or "goose" in id or "bread" in id: return "sandwich"
	if "post" in id or "letter" in id or "invitation" in id or "petition" in id: return "letter"
	if "wind" in id or "traffic" in id or "coffee" in id: return "wind"
	if "camera" in id or "press" in id or "front_page" in id or "news" in id: return "newspaper"
	return "election"

func _label(message: String, font: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bold:
		label.add_theme_color_override("font_shadow_color", Color("#00000023"))
	return label

func _style(background: Color, border: Color, thickness: int = 2, radius: int = 9) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(thickness)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(9)
	return style

func _button(text: String, emphasized: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_stylebox_override("normal", _style(BURGUNDY if emphasized else Color("#fff5df"), GOLD))
	b.add_theme_stylebox_override("hover", _style(Color("#d3b580"), BURGUNDY, 3))
	b.add_theme_stylebox_override("focus", _style(Color("#e4c18a"), BURGUNDY, 3))
	b.add_theme_color_override("font_color", Color("#fff4d9") if emphasized else INK)
	b.add_theme_color_override("font_focus_color", INK)
	return b
