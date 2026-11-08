extends Control
## Card-first UI optimized for 1280x800 and controller-only navigation.

const SimulationEngine = preload("res://scripts/simulation/case_simulation.gd")
const INK = Color("#273c41")
const MUTED = Color("#6c6a60")
const PAPER = Color("#f1e2c4")
const CARD = Color("#fff7e7")
const GOLD = Color("#c49a58")
const BURGUNDY = Color("#7e454c")
const GREEN = Color("#426e60")
const BORDER = Color("#bdad8b")

var sim: CaseSimulation
var selected_stamp: String = "nudge"
var selected_event: String = ""
var feedback: String = ""
var root_view: VBoxContainer
var initial_focus: Control

func _ready() -> void:
	sim = SimulationEngine.new()
	_render()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_LEFT_SHOULDER:
				_cycle_stamp(-1)
				get_viewport().set_input_as_handled()
			JOY_BUTTON_RIGHT_SHOULDER:
				_cycle_stamp(1)
				get_viewport().set_input_as_handled()
			JOY_BUTTON_X:
				_approve_stamp()
				get_viewport().set_input_as_handled()
			JOY_BUTTON_Y:
				_advance_day()
				get_viewport().set_input_as_handled()
			JOY_BUTTON_B:
				_clear_stamp()
				get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q:
				_cycle_stamp(-1)
				get_viewport().set_input_as_handled()
			KEY_E:
				_cycle_stamp(1)
				get_viewport().set_input_as_handled()
			KEY_F:
				_approve_stamp()
				get_viewport().set_input_as_handled()
			KEY_SPACE:
				_advance_day()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				_clear_stamp()
				get_viewport().set_input_as_handled()

func _cycle_stamp(direction: int) -> void:
	if sim.status != "active":
		return
	var index: int = SimulationEngine.STAMP_ORDER.find(selected_stamp)
	selected_stamp = SimulationEngine.STAMP_ORDER[posmod(index + direction, SimulationEngine.STAMP_ORDER.size())]
	feedback = "Selected %s." % SimulationEngine.STAMPS[selected_stamp]["name"]
	_render()

func _select_event(id: String) -> void:
	selected_event = id
	feedback = ""
	_render()

func _select_stamp(id: String) -> void:
	selected_stamp = id
	feedback = ""
	_render()

func _approve_stamp() -> void:
	if sim.status != "active":
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and focused.has_meta("event_id"):
		selected_event = str(focused.get_meta("event_id"))
	if sim.stage_stamp(selected_stamp, selected_event):
		feedback = "Approval queued. It will be filed when you advance the day."
	else:
		feedback = "The application was denied. Check Influence and stamp eligibility."
	_render()

func _clear_stamp() -> void:
	if sim.status != "active":
		return
	sim.clear_stamp()
	feedback = "Approval withdrawn. The paperwork has been shredded."
	_render()

func _advance_day() -> void:
	if sim.status != "active":
		return
	sim.advance_day()
	feedback = "The daily register has been updated."
	_render()

func _buy_upgrade(kind: String) -> void:
	if sim.buy_upgrade(kind):
		feedback = "Purchase approved. Civil Service thanks you."
	else:
		feedback = "Insufficient Merit or upgrade level reached."
	_render()

func _new_case() -> void:
	sim.start_new_run()
	selected_stamp = "nudge"
	selected_event = ""
	feedback = "A fresh case has been placed on your desk."
	_render()


# Original storybook visual direction: illustrated miniature town, a physical
# paper case file and tactile rubber stamps. Game logic stays in CaseSimulation.
func _render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var bg := ColorRect.new()
	bg.color = Color("#1d363c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var shell := MarginContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "top", "right", "bottom"]:
		shell.add_theme_constant_override("margin_" + edge, 16)
	add_child(shell)
	root_view = VBoxContainer.new()
	root_view.add_theme_constant_override("separation", 8)
	shell.add_child(root_view)
	initial_focus = null
	_header()
	if sim.status == "active":
		_active_screen()
	else:
		_result_screen()
	_chronicle()
	_footer()
	if initial_focus != null:
		_focus_after_layout(initial_focus)

func _focus_after_layout(target: Control) -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if is_instance_valid(target) and target.is_inside_tree():
		target.grab_focus()

func _header() -> void:
	var banner := PanelContainer.new()
	var style := _style(Color("#27464c"), Color("#89755b"), 1, 8, 7, 12)
	banner.add_theme_stylebox_override("panel", style)
	banner.custom_minimum_size.y = 77
	root_view.add_child(banner)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	banner.add_child(row)
	row.add_child(_illustration("res://assets/seal.svg", Vector2(59, 59)))
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 1)
	row.add_child(heading)
	var name := _label("THE MINISTRY OF COINCIDENCES", 31, Color("#f8e8bc"), true)
	name.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.add_child(name)
	heading.add_child(_label("OFFICE OF DELICATE INTERVENTIONS     |     EST. 1893", 14, Color("#b7ccbf")))
	var reference := VBoxContainer.new()
	reference.custom_minimum_size.x = 263
	reference.add_theme_constant_override("separation", 3)
	row.add_child(reference)
	var case_code := _label("CASE 001    /    DAY %d OF %d" % [sim.day, int(sim.case_info["deadline"])], 18, Color("#fae7c3"), true)
	case_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	case_code.autowrap_mode = TextServer.AUTOWRAP_OFF
	reference.add_child(case_code)
	var civil := _label("MERIT: %d     CLASSIFICATION: ROUTINE" % int(sim.profile["merit"]), 14, Color("#c2c9bb"))
	civil.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	civil.autowrap_mode = TextServer.AUTOWRAP_OFF
	reference.add_child(civil)

func _active_screen() -> void:
	_case_file()
	var main_row := HBoxContainer.new()
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_theme_constant_override("separation", 12)
	root_view.add_child(main_row)
	_event_tray(main_row)
	_stamp_desk(main_row)

func _case_file() -> void:
	var cover := _card(PAPER, Color("#af8f62"), 2)
	cover.custom_minimum_size.y = 178
	root_view.add_child(cover)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	cover.add_child(row)
	var contents := VBoxContainer.new()
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents.add_theme_constant_override("separation", 4)
	row.add_child(contents)
	contents.add_child(_label("OFFICIAL CASE FILE    /    FORM 19-B    /    TOWN OF ODDFORD", 14, BURGUNDY, true))
	contents.add_child(_label("A FOWL ELECTION", 31, INK, true))
	contents.add_child(_label("Get Gerald the Goose elected mayor by Sunday.", 18, INK))
	contents.add_child(_label("Direct appointment is strictly forbidden.", 15, MUTED))
	contents.add_child(_rule())
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 22)
	contents.add_child(metrics)
	metrics.add_child(_metric("PUBLIC SUPPORT", "%d / %d" % [sim.support, sim.case_info["required_support"]]))
	metrics.add_child(_metric("INFLUENCE", "%d / %d" % [sim.influence, sim.maximum_influence()]))
	metrics.add_child(_metric("REALITY STRAIN", "%d / 6" % sim.strain))
	var gerald_holder := _card(Color("#ecd7aa"), Color("#9a7854"), 2)
	gerald_holder.custom_minimum_size.x = 140
	row.add_child(gerald_holder)
	gerald_holder.add_child(_illustration("res://assets/gerald.svg", Vector2(128, 132)))
	var village_holder := _card(Color("#ddcfac"), Color("#967d5c"), 2)
	village_holder.custom_minimum_size.x = 390
	row.add_child(village_holder)
	village_holder.add_child(_illustration("res://assets/town.svg", Vector2(379, 145)))

func _event_tray(parent: HBoxContainer) -> void:
	var panel := _card(CARD, BORDER)
	panel.custom_minimum_size.x = 710
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	panel.add_child(content)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	content.add_child(line)
	var heading := _label("INCOMING COINCIDENCES", 23, INK, true)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	line.add_child(heading)
	var tray_tag := _label("TRAY 01  /  UNFILED", 14, BURGUNDY, true)
	tray_tag.autowrap_mode = TextServer.AUTOWRAP_OFF
	line.add_child(tray_tag)
	content.add_child(_label("Choose one small disturbance. The consequences will take care of themselves.", 16, MUTED))
	var available: Array = sim.available_events()
	if selected_event.is_empty() or sim.get_rule(selected_event).is_empty() or not sim._eligible(sim.get_rule(selected_event)):
		selected_event = str(available[0]["id"]) if not available.is_empty() else ""
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	content.add_child(scroll)
	var entries := VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation", 6)
	scroll.add_child(entries)
	if available.is_empty():
		entries.add_child(_label("No incidents await approval. Advance the day.", 20, MUTED))
	for rule in available:
		var picked: bool = str(rule["id"]) == selected_event
		var button := _button(_event_caption(rule), picked)
		button.icon = _event_icon(str(rule["id"]))
		button.expand_icon = false
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_constant_override("h_separation", 12)
		button.custom_minimum_size.y = 73
		button.add_theme_font_size_override("font_size", 18)
		button.set_meta("event_id", str(rule["id"]))
		button.pressed.connect(_select_event.bind(str(rule["id"])))
		entries.add_child(button)
		if initial_focus == null or picked:
			initial_focus = button

func _event_icon(id: String) -> Texture2D:
	if "rain" in id or "weather" in id or "wind" in id:
		return load("res://assets/weather.svg")
	if "sandwich" in id or "bread" in id or "lunch" in id or "goose_hungry" in id:
		return load("res://assets/sandwich.svg")
	if "letter" in id or "post" in id or "delivery" in id or "invitation" in id:
		return load("res://assets/letter.svg")
	if "schedule" in id or "time" in id or "late" in id:
		return load("res://assets/clock.svg")
	return load("res://assets/incident.svg")

func _stamp_desk(parent: HBoxContainer) -> void:
	var panel := _card(Color("#f0dfbb"), Color("#af875f"), 2)
	panel.custom_minimum_size.x = 464
	parent.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	panel.add_child(outer)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	outer.add_child(heading)
	heading.add_child(_illustration("res://assets/ink.svg", Vector2(44, 35)))
	var desk_title := _label("THE STAMP DESK", 23, INK, true)
	desk_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.add_child(desk_title)
	var active_stamp: Dictionary = SimulationEngine.STAMPS[selected_stamp]
	outer.add_child(_label("LB/RB SEALS   /   %s: %d INFLUENCE, +%d STRAIN" % [str(active_stamp["name"]).to_upper(), active_stamp["cost"], active_stamp["strain"]], 14, MUTED))
	var desk_scroll := ScrollContainer.new()
	desk_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desk_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desk_scroll.follow_focus = true
	outer.add_child(desk_scroll)
	var desk := VBoxContainer.new()
	desk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desk.add_theme_constant_override("separation", 7)
	desk_scroll.add_child(desk)
	var stamps := GridContainer.new()
	stamps.columns = 2
	stamps.add_theme_constant_override("h_separation", 7)
	stamps.add_theme_constant_override("v_separation", 5)
	desk.add_child(stamps)
	var stamp_symbols := {"nudge": "NUDGE", "misfile": "MISFILE", "reschedule": "RESCHEDULE", "domino": "DOMINO"}
	for id in SimulationEngine.STAMP_ORDER:
		var stamp_button := _button(stamp_symbols[id], id == selected_stamp)
		stamp_button.icon = load("res://assets/stamp_%s.svg" % id) as Texture2D
		stamp_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		stamp_button.add_theme_constant_override("h_separation", 8)
		stamp_button.custom_minimum_size = Vector2(193, 43)
		stamp_button.add_theme_font_size_override("font_size", 17)
		stamp_button.add_theme_color_override("font_color", BURGUNDY if id == selected_stamp else INK)
		stamp_button.pressed.connect(_select_stamp.bind(id))
		stamps.add_child(stamp_button)
	var rule: Dictionary = sim.get_rule(selected_event)
	if not rule.is_empty():
		var stamp: Dictionary = SimulationEngine.STAMPS[selected_stamp]
		var stamp_info := _label("%s  /  %d influence  /  +%d strain" % [stamp["name"], stamp["cost"], stamp["strain"]], 17, BURGUNDY, true)
		# Stamp cost is always visible above the grid, not concealed below a scroll.
		desk.add_child(_label(str(stamp["description"]) + " - " + str(rule["title"]), 16, INK))
		desk.add_child(_label("MAY CAUSE: " + _effects_label(rule), 15, MUTED))
		if selected_stamp == "misfile" and (rule["misfile_facts"] as Array).is_empty():
			desk.add_child(_label("Cannot redirect this particular incident.", 15, BURGUNDY))
	var pending_text := "NO INTERVENTION FILED"
	if not sim.pending.is_empty():
		pending_text = "FILED: " + str(SimulationEngine.STAMPS[sim.pending["stamp"]]["name"]).to_upper()
	desk.add_child(_label(pending_text, 15, GREEN, true))
	desk.add_child(_label("LEDGER: " + sim.forecast(), 15, BURGUNDY))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	outer.add_child(actions)
	var approve := _button("X  APPROVE")
	approve.custom_minimum_size.x = 225
	approve.autowrap_mode = TextServer.AUTOWRAP_OFF
	approve.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	approve.disabled = not sim.can_stamp(selected_stamp, selected_event)
	approve.pressed.connect(_approve_stamp)
	actions.add_child(approve)
	var clear := _button("B  CLEAR")
	clear.custom_minimum_size.x = 120
	clear.autowrap_mode = TextServer.AUTOWRAP_OFF
	clear.disabled = sim.pending.is_empty()
	clear.pressed.connect(_clear_stamp)
	actions.add_child(clear)
	var advance := _button("Y  ADVANCE DAY", false, true)
	advance.custom_minimum_size.y = 50
	advance.pressed.connect(_advance_day)
	outer.add_child(advance)

func _result_screen() -> void:
	var case := _card(PAPER, Color("#af8f62"), 2)
	case.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_view.add_child(case)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	case.add_child(row)
	row.add_child(_illustration("res://assets/gerald.svg", Vector2(205, 230)))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(content)
	content.add_child(_label("CERTIFIED BY THE DEPARTMENT OF HAPPENSTANCE", 15, BURGUNDY, true))
	content.add_child(_label("CASE CLOSED" if sim.status == "won" else "CASE FILED AS INCOMPLETE", 36, GREEN if sim.status == "won" else BURGUNDY, true))
	content.add_child(_label(sim.last_outcome, 22, INK))
	content.add_child(_label("Public support %d / %d     |     Civil Service Merit %d     |     Cases filed %d" % [sim.support, sim.case_info["required_support"], sim.profile["merit"], sim.profile["completed"]], 18, MUTED))
	content.add_child(_rule())
	content.add_child(_label("PERMANENT MINISTRY IMPROVEMENTS", 22, INK, true))
	var upgrades := HBoxContainer.new()
	upgrades.add_theme_constant_override("separation", 10)
	content.add_child(upgrades)
	for kind in ["desk", "ink", "audit"]:
		var headline: String = {"desk": "BETTER DESK", "ink": "FRESH INK", "audit": "AUDIT TRAINING"}[kind]
		var detail: String = {"desk": "+2 max influence", "ink": "+1 starting influence", "audit": "-1 stamp strain"}[kind]
		var price: int = sim.upgrade_cost(kind)
		var upgrade := _button("%s  LV %d\n%s\n%d MERIT" % [headline, sim.profile[kind], detail, price])
		upgrade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		upgrade.custom_minimum_size.y = 107
		upgrade.disabled = int(sim.profile[kind]) >= 3 or int(sim.profile["merit"]) < price
		upgrade.pressed.connect(_buy_upgrade.bind(kind))
		upgrades.add_child(upgrade)
		if initial_focus == null and not upgrade.disabled:
			initial_focus = upgrade
	var new_case := _button("FILE ANOTHER CASE", false, true)
	new_case.custom_minimum_size.y = 64
	new_case.pressed.connect(_new_case)
	content.add_child(new_case)
	if initial_focus == null:
		initial_focus = new_case

func _chronicle() -> void:
	var ledger := _card(Color("#fcf2dd"), BORDER)
	ledger.custom_minimum_size.y = 117
	root_view.add_child(ledger)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	ledger.add_child(content)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	content.add_child(head)
	var title := _label("THE OFFICIAL CHRONICLE", 20, BURGUNDY, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(title)
	var chron_note := _label("WHAT HAPPENED  /  AND WHY", 14, MUTED)
	chron_note.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(chron_note)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var entries := VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation", 2)
	scroll.add_child(entries)
	for entry in sim.history_summary(9):
		var reason: String = "  (because: %s)" % entry["because"] if not str(entry["because"]).is_empty() else ""
		var score: String = "  [+%d support]" % int(entry["support"]) if int(entry["support"]) > 0 else ""
		entries.add_child(_label("DAY %d   |   %s  -  %s%s%s" % [entry["day"], entry["title"], entry["text"], score, reason], 16, INK))

func _footer() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	root_view.add_child(row)
	var note := _label("NOTHING HAPPENS BY ACCIDENT.    |    CASE SEED: %d" % sim.seed, 14, Color("#dbd2b3"))
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(note)
	var status := _label(feedback, 14, Color("#f2d6a3"))
	status.custom_minimum_size.x = 300
	status.clip_text = true
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(status)

func _event_caption(rule: Dictionary) -> String:
	var chance: int = roundi(float(rule["chance"]) * 100.0)
	var support_label: String = "   /  +%d support" % int(rule["support"]) if int(rule["support"]) > 0 else ""
	return "%s    |    %d%% chance%s\n%s" % [rule["title"], chance, support_label, rule["text"]]

func _effects_label(rule: Dictionary) -> String:
	var output: String = ", ".join(PackedStringArray(rule["facts"]))
	if selected_stamp == "misfile" and not (rule["misfile_facts"] as Array).is_empty():
		output = ", ".join(PackedStringArray(rule["misfile_facts"]))
	return "social repercussions" if output.is_empty() else output.replace("_", " ")

func _metric(heading: String, value: String) -> VBoxContainer:
	var metric := VBoxContainer.new()
	metric.add_theme_constant_override("separation", 0)
	var label := _label(heading, 13, BURGUNDY, true)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	metric.add_child(label)
	var amount := _label(value, 25, INK, true)
	amount.autowrap_mode = TextServer.AUTOWRAP_OFF
	metric.add_child(amount)
	return metric

func _label(message: String, size: int, color: Color, heavy: bool = false) -> Label:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	if heavy:
		label.add_theme_color_override("font_shadow_color", Color("#00000022"))
		label.add_theme_constant_override("shadow_offset_x", 1)
	return label

func _rule() -> ColorRect:
	var rule := ColorRect.new()
	rule.color = Color("#c5ad7f")
	rule.custom_minimum_size.y = 2
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule

func _illustration(path: String, dimensions: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = load(path) as Texture2D
	image.custom_minimum_size = dimensions
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

func _style(color: Color, edge: Color, border: int = 1, radius: int = 10, margin_y: int = 9, margin_x: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = edge
	style.set_border_width_all(border)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin_x
	style.content_margin_right = margin_x
	style.content_margin_top = margin_y
	style.content_margin_bottom = margin_y
	return style

func _card(color: Color, edge: Color = BORDER, thickness: int = 1) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(color, edge, thickness))
	return panel

func _button(message: String, selected: bool = false, emphasized: bool = false) -> Button:
	var button := Button.new()
	button.text = message
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("#f9e6c8") if emphasized else INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_color_override("font_disabled_color", Color("#847a69"))
	button.focus_mode = Control.FOCUS_ALL
	var ordinary := _style(Color("#f5ead1"), Color("#d2b791"), 1, 7, 6, 11)
	if selected:
		ordinary = _style(Color("#f9e0a9"), BURGUNDY, 2, 7, 6, 11)
	if emphasized:
		ordinary = _style(BURGUNDY, Color("#be8e60"), 2, 7, 6, 11)
	var hover := ordinary.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#f2d4a0")
	hover.border_color = BURGUNDY
	hover.set_border_width_all(2)
	var focused := hover.duplicate() as StyleBoxFlat
	focused.set_border_width_all(3)
	button.add_theme_stylebox_override("normal", ordinary)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", focused)
	var disabled := ordinary.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#d8cfb8")
	button.add_theme_stylebox_override("disabled", disabled)
	return button
