extends Control
## An interactive surveillance diorama driven by REAL simulation events.
## Locations reveal eligible interventions; day reports replay only logged events.
## No separate town simulation is invented. All animations are skippable.

signal close_requested
signal investigate_requested(event_id: String)

const FX = preload("res://scripts/ui/town_fx.gd")
const PAPER := Color("#f1e2c4")
const BURGUNDY := Color("#7e454c")
const INK := Color("#263b40")
const MUTED := Color("#697064")
const GOLD := Color("#c49a58")
const MAP_ORIGIN := Vector2(52.0, 111.0)
const MAP_SIZE := Vector2(872.0, 496.0)
const LOCATION_NAMES := ["Town Hall", "Bakery", "Post Office", "High Street", "Public Gardens", "Parade Hall"]
const COORDS := [
	Vector2(0.51, 0.54), Vector2(0.89, 0.57), Vector2(0.17, 0.54),
	Vector2(0.38, 0.77), Vector2(0.69, 0.77), Vector2(0.46, 0.38)
]

var simulation: Object
var replay_events: Array = []
var replay_mode: bool = false
var replay_index: int = 0
var replay_elapsed: float = 0.0
var replay_paused: bool = false
var reduced_motion: bool = false
var selected_location: String = "Town Hall"
var image_frame: TextureRect
var effect_layer: Control
var marker: ColorRect
var location_buttons: Array[Button] = []
var docket_title: Label
var docket_body: Label
var docket_details: Label
var docket_picture: TextureRect
var docket_location: Label
var investigate_button: Button
var proceed_button: Button
var focused_before: Control
var _focus_target: Control
var _selected_eligible_id: String = ""

func configure(game: Object, recent_events: Array = [], replay: bool = false) -> void:
	simulation = game
	replay_events = recent_events.duplicate(true)
	replay_mode = replay
	replay_index = 0
	replay_paused = not replay

func _ready() -> void:
	name = "LivingOddford"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	if replay_mode:
		_show_replay()
	else:
		_show_location("Town Hall")
	if is_inside_tree():
		await get_tree().process_frame
		if is_instance_valid(_focus_target):
			_focus_target.grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_B:
				close_requested.emit()
				get_viewport().set_input_as_handled()
			JOY_BUTTON_RIGHT_SHOULDER:
				_next_event()
				get_viewport().set_input_as_handled()
			JOY_BUTTON_LEFT_SHOULDER:
				_previous_event()
				get_viewport().set_input_as_handled()
			JOY_BUTTON_Y:
				_skip_replay()
				get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				close_requested.emit()
				get_viewport().set_input_as_handled()
			KEY_E:
				if replay_mode:
					_next_event()
					get_viewport().set_input_as_handled()
			KEY_Q:
				if replay_mode:
					_previous_event()
					get_viewport().set_input_as_handled()
			KEY_SPACE:
				if replay_mode:
					_skip_replay()
					get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not replay_mode or replay_paused:
		return
	replay_elapsed += minf(delta, 0.1)
	if replay_elapsed >= (0.85 if reduced_motion else 2.25):
		if replay_index + 1 < replay_events.size():
			_next_event()
		else:
			replay_paused = true
			if proceed_button != null:
				proceed_button.text = "REPORT COMPLETE  ·  B RETURN"

func _build() -> void:
	var wash := ColorRect.new()
	wash.color = Color("#10272cf4")
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(wash)
	var paper := PanelContainer.new()
	paper.name = "OddfordDioramaBoard"
	paper.position = Vector2(20, 14)
	paper.size = Vector2(1240, 765)
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = GOLD
	style.set_border_width_all(4)
	style.set_corner_radius_all(15)
	paper.add_theme_stylebox_override("panel", style)
	add_child(paper)
	# All coordinates are aligned to the 1280x800 Deck canvas.
	var heading := _label("ODDFORD     /     MINISTRY SURVEILLANCE", 29, INK, true)
	heading.position = Vector2(57, 35)
	heading.size = Vector2(770, 45)
	add_child(heading)
	var subhead := _label("Every incident is a matter of public record.", 17, MUTED)
	subhead.position = Vector2(58, 76)
	subhead.size = Vector2(800, 26)
	add_child(subhead)
	var back := _button("B  RETURN TO CASE", true)
	back.position = Vector2(1021, 36)
	back.size = Vector2(204, 51)
	back.pressed.connect(func(): close_requested.emit())
	add_child(back)
	image_frame = TextureRect.new()
	image_frame.name = "LivingTownImage"
	image_frame.texture = load("res://assets/illustrated/oddford_square.webp") as Texture2D
	image_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image_frame.clip_contents = true
	image_frame.position = MAP_ORIGIN
	image_frame.size = MAP_SIZE
	image_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image_frame)
	var border := Panel.new()
	border.position = MAP_ORIGIN
	border.size = MAP_SIZE
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = Color.TRANSPARENT
	st.border_color = Color("#946b52")
	st.set_border_width_all(3)
	st.set_corner_radius_all(6)
	border.add_theme_stylebox_override("panel", st)
	add_child(border)
	effect_layer = FX.new()
	effect_layer.name = "RecordedIncidentEffects"
	effect_layer.position = MAP_ORIGIN
	effect_layer.size = MAP_SIZE
	add_child(effect_layer)
	marker = ColorRect.new()
	marker.name = "CausalSpotlight"
	marker.color = Color("#fff3bd88")
	marker.size = Vector2(138, 8)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marker)
	for i in range(LOCATION_NAMES.size()):
		var place: String = LOCATION_NAMES[i]
		var location_btn := _button(place, false)
		location_btn.name = "Location" + place.replace(" ", "")
		location_btn.custom_minimum_size = Vector2(122, 36)
		location_btn.size = Vector2(135, 36)
		location_btn.add_theme_font_size_override("font_size", 16)
		location_btn.position = _marker_position(place) - Vector2(67, 17)
		location_btn.pressed.connect(_show_location.bind(place))
		add_child(location_btn)
		location_buttons.append(location_btn)
	var strip := _label("A INSPECT LOCATION     ·     LB/RB REPORT STEPS     ·     Y SKIP     ·     B RETURN", 17, INK)
	strip.position = Vector2(56, 628)
	strip.size = Vector2(1100, 37)
	add_child(strip)
	var desk := PanelContainer.new()
	desk.name = "WitnessReport"
	desk.position = Vector2(946, 111)
	desk.size = Vector2(282, 495)
	var desk_style := StyleBoxFlat.new()
	desk_style.bg_color = Color("#fff7e7")
	desk_style.border_color = BURGUNDY
	desk_style.set_border_width_all(2)
	desk_style.set_corner_radius_all(8)
	desk.add_theme_stylebox_override("panel", desk_style)
	add_child(desk)
	docket_location = _label("FILE  /  TOWN HALL", 15, BURGUNDY, true)
	docket_location.position = Vector2(961, 126)
	docket_location.size = Vector2(253, 28)
	add_child(docket_location)
	docket_picture = TextureRect.new()
	docket_picture.name = "WitnessIllustration"
	docket_picture.position = Vector2(964, 161)
	docket_picture.size = Vector2(244, 174)
	docket_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	docket_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	docket_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(docket_picture)
	docket_title = _label("Investigate a location", 21, INK, true)
	docket_title.position = Vector2(962, 347)
	docket_title.size = Vector2(251, 57)
	add_child(docket_title)
	docket_body = _label("", 16, INK)
	docket_body.position = Vector2(962, 405)
	docket_body.size = Vector2(249, 90)
	add_child(docket_body)
	docket_details = _label("", 14, BURGUNDY)
	docket_details.position = Vector2(962, 500)
	docket_details.size = Vector2(249, 51)
	add_child(docket_details)
	investigate_button = _button("INSPECT THIS INCIDENT", true)
	investigate_button.name = "InspectIncident"
	investigate_button.position = Vector2(958, 562)
	investigate_button.size = Vector2(260, 40)
	investigate_button.pressed.connect(_investigate)
	add_child(investigate_button)
	proceed_button = _button("NEXT EVENT   RB  >", true)
	proceed_button.name = "NextRecordedIncident"
	proceed_button.position = Vector2(944, 685)
	proceed_button.size = Vector2(280, 59)
	proceed_button.pressed.connect(_next_event)
	add_child(proceed_button)
	_focus_target = location_buttons[0]
	_effect("", false)

func _marker_position(place: String) -> Vector2:
	var index: int = LOCATION_NAMES.find(place)
	if index < 0:
		index = 0
	return MAP_ORIGIN + Vector2(MAP_SIZE.x * COORDS[index].x, MAP_SIZE.y * COORDS[index].y)

func _set_spotlight(place: String) -> void:
	var target := _marker_position(place) + Vector2(-68.0, 21.0)
	if reduced_motion or marker.position == Vector2.ZERO:
		marker.position = target
	else:
		var tween := create_tween()
		tween.tween_property(marker, "position", target, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	selected_location = place

func _show_location(place: String) -> void:
	replay_paused = true
	_set_spotlight(place)
	var nearby: Array = []
	if simulation != null:
		for rule in simulation.available_events():
			if str(rule.get("place", "")) == place:
				nearby.append(rule)
	docket_location.text = "LOCAL OFFICE  /  " + place.to_upper()
	_selected_eligible_id = ""
	if nearby.is_empty():
		docket_title.text = "No filings pending"
		docket_body.text = "No eligible incidents at this address. An earlier coincidence may unlock more."
		docket_details.text = "Browse the town or return to the case file."
		docket_picture.texture = load("res://assets/illustrated/oddford_banner.webp") as Texture2D
	else:
		var rule: Dictionary = nearby[0]
		_selected_eligible_id = str(rule["id"])
		docket_title.text = str(rule["title"])
		docket_body.text = str(rule["text"])
		docket_details.text = "%d possible filing(s) here   /   %d%% base chance" % [nearby.size(), roundi(float(rule["chance"]) * 100.0)]
		docket_picture.texture = load("res://assets/illustrated/incident_%s.webp" % _incident_family(_selected_eligible_id)) as Texture2D
	investigate_button.visible = true
	investigate_button.disabled = _selected_eligible_id.is_empty()
	proceed_button.text = "RETURN TO CASE" if not replay_mode else "NEXT RECORDED EVENT  >"
	_effect("", false)

func _show_replay() -> void:
	replay_elapsed = 0.0
	if replay_events.is_empty():
		replay_paused = true
		docket_location.text = "TODAY  /  NO INCIDENTS"
		docket_title.text = "Quiet day in Oddford"
		docket_body.text = "Nothing noteworthy occurred. The Ministry remains suspicious."
		docket_details.text = "No causal chain was recorded today."
		docket_picture.texture = load("res://assets/illustrated/oddford_banner.webp") as Texture2D
		investigate_button.visible = false
		investigate_button.disabled = true
		proceed_button.text = "B  RETURN TO CASE"
		_effect("", false)
		return
	var entry: Dictionary = replay_events[replay_index]
	var event_id: String = str(entry.get("id", ""))
	var rule: Dictionary = simulation.get_rule(event_id) if simulation != null else {}
	var place: String = str(rule.get("place", "Town Hall"))
	if event_id.begins_with("correction_"):
		place = "Public Gardens"
	_set_spotlight(place)
	docket_location.text = "DAY %d   /   EVENT %d OF %d" % [int(entry.get("day", 0)), replay_index + 1, replay_events.size()]
	docket_title.text = str(entry.get("title", "An official incident"))
	docket_body.text = str(entry.get("text", ""))
	var causes: Array = entry.get("causes", [])
	var cause_names: Array[String] = []
	for cause_id in causes:
		var parent_rule: Dictionary = simulation.get_rule(str(cause_id)) if simulation != null else {}
		if not parent_rule.is_empty():
			cause_names.append(str(parent_rule.get("title", "")))
	var because: String = "Because: " + ", ".join(PackedStringArray(cause_names)) if not cause_names.is_empty() else "Independent incident / official filing"
	var reward: String = "   +%d support" % int(entry.get("support", 0)) if int(entry.get("support", 0)) > 0 else ""
	docket_details.text = because + reward
	var family: String = _incident_family(event_id)
	docket_picture.texture = load("res://assets/illustrated/incident_%s.webp" % family) as Texture2D
	investigate_button.visible = false
	investigate_button.disabled = true
	proceed_button.text = "NEXT EVENT   RB  >" if replay_index + 1 < replay_events.size() else "END OF REPORT  /  B RETURN"
	_effect(family, true)

func _effect(family: String, animate: bool) -> void:
	(effect_layer as Node).call("set_incident", family if animate else "")
	(effect_layer as Node).set("reduced_motion", reduced_motion)

func _next_event() -> void:
	if not replay_mode:
		close_requested.emit()
		return
	if replay_index < replay_events.size() - 1:
		replay_index += 1
		replay_paused = false
		_show_replay()
	else:
		replay_paused = true
		close_requested.emit()

func _previous_event() -> void:
	if not replay_mode or replay_events.is_empty():
		return
	replay_index = maxi(0, replay_index - 1)
	replay_paused = true
	_show_replay()
	replay_paused = true

func _skip_replay() -> void:
	if not replay_mode:
		return
	replay_paused = true
	if replay_events.size() > 0:
		replay_index = replay_events.size() - 1
		_show_replay()
		replay_paused = true
		proceed_button.text = "REPORT COMPLETE  /  B RETURN"

func _investigate() -> void:
	if not _selected_eligible_id.is_empty():
		investigate_requested.emit(_selected_eligible_id)

func _incident_family(event_id: String) -> String:
	var id := event_id.to_lower()
	if "rain" in id or "indoor" in id or "parade" in id or "fair" in id:
		return "rain"
	if "sandwich" in id or "hungry" in id or "bread" in id or "endorsement" in id:
		return "sandwich"
	if "post" in id or "invitation" in id or "letter" in id or "rulebook" in id or "petition" in id:
		return "letter"
	if "wind" in id or "traffic" in id or "coffee" in id or "correction" in id:
		return "wind"
	if "camera" in id or "photo" in id or "front_page" in id or "viral" in id or "poll" in id:
		return "newspaper"
	return "election"

func _label(text_value: String, size_value: int, color: Color, heavy: bool = false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size_value)
	if heavy:
		label.add_theme_color_override("font_shadow_color", Color("#00000028"))
	return label

func _button(title: String, important: bool) -> Button:
	var button := Button.new()
	button.text = title
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("#fff3de") if important else INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	var normal := StyleBoxFlat.new()
	normal.bg_color = BURGUNDY if important else Color("#fff5dc")
	normal.border_color = GOLD if important else Color("#7d544b")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(9)
	normal.content_margin_left = 9
	normal.content_margin_right = 9
	button.add_theme_stylebox_override("normal", normal)
	var focus_style := normal.duplicate() as StyleBoxFlat
	focus_style.bg_color = Color("#ffe1a2")
	focus_style.border_color = BURGUNDY
	focus_style.set_border_width_all(4)
	button.add_theme_stylebox_override("focus", focus_style)
	button.add_theme_stylebox_override("hover", focus_style)
	return button
