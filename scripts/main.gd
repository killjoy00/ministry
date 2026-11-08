extends Control
## Card-first UI optimized for 1280x800 and controller-only navigation.

const SimulationEngine = preload("res://scripts/simulation/case_simulation.gd")
const INK = Color("#342c37")
const MUTED = Color("#645d60")
const PAPER = Color("#f5eee1")
const CARD = Color("#fffaf1")
const GOLD = Color("#d8ad67")
const BURGUNDY = Color("#6b3647")
const GREEN = Color("#426756")
const BORDER = Color("#cbbb9f")

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

func _render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var bg := ColorRect.new()
	bg.color = PAPER
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var shell := MarginContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "top", "right", "bottom"]:
		shell.add_theme_constant_override("margin_" + edge, 18)
	add_child(shell)
	root_view = VBoxContainer.new()
	root_view.add_theme_constant_override("separation", 10)
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
		initial_focus.grab_focus.call_deferred()

func _header() -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	root_view.add_child(top)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 0)
	top.add_child(left)
	left.add_child(_label("THE MINISTRY OF COINCIDENCES", 34, BURGUNDY, true))
	left.add_child(_label("DEPARTMENT OF UNLIKELY BUT PERFECTLY LEGAL EVENTS", 16, MUTED))
	var right := VBoxContainer.new()
	# Reserve width before the HBox minimum-size pass so the status labels
	# cannot wrap into a vertical strip and push gameplay below the viewport.
	right.custom_minimum_size.x = 345
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.add_theme_constant_override("separation", 1)
	top.add_child(right)
	var case_number := _label("CASE #001  /  DAY %d OF %d" % [sim.day, sim.case_info["deadline"]], 22, INK, true)
	case_number.autowrap_mode = TextServer.AUTOWRAP_OFF
	case_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(case_number)
	var merit_number := _label("CIVIL SERVICE MERIT  %d" % sim.profile["merit"], 17, MUTED)
	merit_number.autowrap_mode = TextServer.AUTOWRAP_OFF
	merit_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(merit_number)

func _active_screen() -> void:
	var summary := _card(BURGUNDY)
	root_view.add_child(summary)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 30)
	summary.add_child(stats)
	var objective := VBoxContainer.new()
	objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective.add_child(_label("A FOWL ELECTION", 25, Color.WHITE, true))
	objective.add_child(_label("Elect Gerald the Goose. Direct appointment is forbidden under Regulation 19-B.", 18, Color("#f9edea")))
	stats.add_child(objective)
	stats.add_child(_metric("GOOSE SUPPORT", "%d / %d" % [sim.support, sim.case_info["required_support"]]))
	stats.add_child(_metric("INFLUENCE", "%d / %d" % [sim.influence, sim.maximum_influence()]))
	stats.add_child(_metric("REALITY STRAIN", "%d / 6" % sim.strain))
	var main_row := HBoxContainer.new()
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_theme_constant_override("separation", 12)
	root_view.add_child(main_row)
	var left := _card(CARD)
	left.custom_minimum_size.x = 735
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_row.add_child(left)
	var opportunities := VBoxContainer.new()
	opportunities.size_flags_vertical = Control.SIZE_EXPAND_FILL
	opportunities.add_theme_constant_override("separation", 5)
	left.add_child(opportunities)
	opportunities.add_child(_label("PENDING COINCIDENCES", 25, INK, true))
	opportunities.add_child(_label("Select an event to influence. Every eligible incident can also happen naturally.", 17, MUTED))
	var available: Array = sim.available_events()
	if selected_event.is_empty() or sim.get_rule(selected_event).is_empty() or not sim._eligible(sim.get_rule(selected_event)):
		selected_event = str(available[0]["id"]) if not available.is_empty() else ""
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	opportunities.add_child(scroll)
	var entries := VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation", 7)
	scroll.add_child(entries)
	if available.is_empty():
		entries.add_child(_label("The event desk is empty. Advance the day to file your report.", 21, MUTED))
	for rule in available:
		var button := _button(_event_caption(rule), str(rule["id"]) == selected_event)
		button.custom_minimum_size.y = 78
		button.set_meta("event_id", str(rule["id"]))
		button.pressed.connect(_select_event.bind(str(rule["id"])))
		entries.add_child(button)
		if initial_focus == null or str(rule["id"]) == selected_event:
			initial_focus = button
	var right := _card(CARD)
	right.custom_minimum_size.x = 425
	main_row.add_child(right)
	var desk := VBoxContainer.new()
	desk.add_theme_constant_override("separation", 7)
	right.add_child(desk)
	desk.add_child(_label("THE STAMP DESK", 25, INK, true))
	desk.add_child(_label("LB / RB switches stamps  ·  X approves", 16, MUTED))
	var stamps := GridContainer.new()
	stamps.columns = 2
	stamps.add_theme_constant_override("h_separation", 6)
	stamps.add_theme_constant_override("v_separation", 6)
	desk.add_child(stamps)
	for id in SimulationEngine.STAMP_ORDER:
		var stamp: Dictionary = SimulationEngine.STAMPS[id]
		var stamp_button := _button("%s\n%d Influence / +%d Strain" % [stamp["name"], stamp["cost"], stamp["strain"]], id == selected_stamp)
		stamp_button.custom_minimum_size = Vector2(187, 63)
		stamp_button.add_theme_font_size_override("font_size", 17)
		stamp_button.pressed.connect(_select_stamp.bind(id))
		stamps.add_child(stamp_button)
	var rule := sim.get_rule(selected_event)
	if not rule.is_empty():
		desk.add_child(_label("SELECTED: " + str(rule["title"]), 20, BURGUNDY, true))
		desk.add_child(_label(SimulationEngine.STAMPS[selected_stamp]["description"], 18, MUTED))
		desk.add_child(_label("Possible consequences: " + _effects_label(rule), 17, INK))
		if selected_stamp == "misfile" and (rule["misfile_facts"] as Array).is_empty():
			desk.add_child(_label("Misfile not applicable to this event.", 16, BURGUNDY))
	var pending_text := "NONE — let events unfold normally"
	if not sim.pending.is_empty():
		pending_text = "%s / %s" % [SimulationEngine.STAMPS[sim.pending["stamp"]]["name"], sim.get_rule(str(sim.pending["target"]))["title"]]
	desk.add_child(_label("APPROVAL: " + pending_text, 17, GREEN, true))
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 7)
	desk.add_child(controls)
	var approve := _button("X  APPROVE")
	approve.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	approve.disabled = not sim.can_stamp(selected_stamp, selected_event)
	approve.pressed.connect(_approve_stamp)
	controls.add_child(approve)
	var clear := _button("B  CLEAR")
	clear.disabled = sim.pending.is_empty()
	clear.pressed.connect(_clear_stamp)
	controls.add_child(clear)
	var advance := _button("Y  ADVANCE DAY", true, true)
	advance.custom_minimum_size.y = 55
	advance.pressed.connect(_advance_day)
	desk.add_child(advance)
	desk.add_child(_label("REALITY FORECAST: " + sim.forecast(), 17, BURGUNDY))

func _result_screen() -> void:
	var panel := _card(CARD)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_view.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	content.add_child(_label("CASE CLOSED" if sim.status == "won" else "CASE FILED AS INCOMPLETE", 34, GREEN if sim.status == "won" else BURGUNDY, true))
	content.add_child(_label(sim.last_outcome, 24, INK))
	content.add_child(_label("Support %d / %d  ·  Civil Service Merit %d  ·  Cases filed %d" % [sim.support, sim.case_info["required_support"], sim.profile["merit"], sim.profile["completed"]], 21, MUTED))
	content.add_child(_label("PERMANENT MINISTRY IMPROVEMENTS", 25, INK, true))
	var upgrades := HBoxContainer.new()
	upgrades.add_theme_constant_override("separation", 12)
	content.add_child(upgrades)
	for kind in ["desk", "ink", "audit"]:
		var headline: String = {"desk": "BETTER DESK", "ink": "FRESH INK", "audit": "AUDIT TRAINING"}[kind]
		var detail: String = {"desk": "+2 max Influence", "ink": "+1 starting Influence", "audit": "-1 stamp Strain"}[kind]
		var price: int = sim.upgrade_cost(kind)
		var upgrade := _button("%s  LV %d\n%s\n%d Merit" % [headline, sim.profile[kind], detail, price])
		upgrade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		upgrade.custom_minimum_size.y = 110
		upgrade.disabled = int(sim.profile[kind]) >= 3 or int(sim.profile["merit"]) < price
		upgrade.pressed.connect(_buy_upgrade.bind(kind))
		upgrades.add_child(upgrade)
		if initial_focus == null and not upgrade.disabled:
			initial_focus = upgrade
	var new_case := _button("FILE ANOTHER CASE", true, true)
	new_case.custom_minimum_size.y = 66
	new_case.pressed.connect(_new_case)
	content.add_child(new_case)
	if initial_focus == null:
		initial_focus = new_case

func _chronicle() -> void:
	var box := _card(CARD)
	box.custom_minimum_size.y = 153
	root_view.add_child(box)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	box.add_child(layout)
	layout.add_child(_label("THE OFFICIAL CHRONICLE  ·  WHAT HAPPENED, AND WHY", 20, BURGUNDY, true))
	var log_scroll := ScrollContainer.new()
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(log_scroll)
	var log_items := VBoxContainer.new()
	log_items.add_theme_constant_override("separation", 3)
	log_scroll.add_child(log_items)
	for entry in sim.history_summary(9):
		var reason: String = "  [caused by: %s]" % entry["because"] if not str(entry["because"]).is_empty() else ""
		var score: String = "  (+%d public support)" % int(entry["support"]) if int(entry["support"]) > 0 else ""
		log_items.add_child(_label("DAY %d  ·  %s — %s%s%s" % [entry["day"], entry["title"], entry["text"], score, reason], 17, INK))

func _footer() -> void:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	root_view.add_child(line)
	var note := _label("PROBABILITY IS AN ADMINISTRATIVE MATTER.  ·  RUN SEED: %d" % sim.seed, 15, MUTED)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(note)
	line.add_child(_label(feedback, 15, GREEN))

func _event_caption(rule: Dictionary) -> String:
	var chance: int = roundi(float(rule["chance"]) * 100.0)
	var support_text: String = "  ·  +%d support" % int(rule["support"]) if int(rule["support"]) > 0 else ""
	return "%s  ·  %d%% base chance%s\n%s" % [rule["title"], chance, support_text, rule["text"]]

func _effects_label(rule: Dictionary) -> String:
	var output: String = ", ".join(PackedStringArray(rule["facts"]))
	if selected_stamp == "misfile" and not (rule["misfile_facts"] as Array).is_empty():
		output = ", ".join(PackedStringArray(rule["misfile_facts"]))
	if output.is_empty():
		output = "social repercussions"
	return output.replace("_", " ")

func _metric(heading: String, value: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.add_child(_label(heading, 14, Color("#f5e3d7")))
	col.add_child(_label(value, 22, Color.WHITE, true))
	return col

func _label(message: String, size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_shadow_color", Color("#00000010"))
		label.add_theme_constant_override("shadow_offset_x", 1)
	return label

func _card(color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = BORDER if color != BURGUNDY else BURGUNDY
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", style)
	return p

func _button(message: String, selected: bool = false, emphasized: bool = false) -> Button:
	var b := Button.new()
	b.text = message
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 19)
	b.add_theme_color_override("font_color", Color.WHITE if emphasized else INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_focus_color", INK)
	b.add_theme_color_override("font_disabled_color", MUTED)
	b.focus_mode = Control.FOCUS_ALL
	var regular := StyleBoxFlat.new()
	regular.bg_color = BURGUNDY if emphasized else (Color("#ffebbf") if selected else Color("#f3e9d8"))
	regular.border_color = GOLD if selected else BORDER
	regular.set_border_width_all(2 if selected else 1)
	regular.set_corner_radius_all(7)
	regular.content_margin_left = 10
	regular.content_margin_right = 10
	regular.content_margin_top = 7
	regular.content_margin_bottom = 7
	var focused := regular.duplicate() as StyleBoxFlat
	focused.bg_color = Color("#ffe4a6")
	focused.border_color = BURGUNDY
	focused.set_border_width_all(3)
	b.add_theme_stylebox_override("normal", regular)
	b.add_theme_stylebox_override("hover", focused)
	b.add_theme_stylebox_override("focus", focused)
	b.add_theme_stylebox_override("pressed", focused)
	var disabled := regular.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#e7e1d6")
	b.add_theme_stylebox_override("disabled", disabled)
	return b
