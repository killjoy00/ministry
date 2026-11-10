extends Control
## Controller-first dossier: possible future effects and actual proven causes.
signal close_requested

const Logic = preload("res://scripts/simulation/causal_inspection.gd")
const INK = Color("#273c41")
const PAPER = Color("#f1e2c4")
const CARD = Color("#fff7e7")
const BURGUNDY = Color("#7e454c")
const GREEN = Color("#426e60")
const MUTED = Color("#6c6a60")
var game: CaseSimulation
var event_id: String = ""
var first_focus: Button

func configure(simulation: CaseSimulation, id: String) -> void:
	game = simulation
	event_id = id
	if is_inside_tree():
		_render()

func _ready() -> void:
	name = "CausalityInspector"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_render()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		close_requested.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_requested.emit()
		get_viewport().set_input_as_handled()

func _label(value: String, px: int, color: Color, bold: bool = false) -> Label:
	var text := Label.new()
	text.text = value
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", px)
	text.add_theme_color_override("font_color", color)
	if bold:
		text.add_theme_color_override("font_shadow_color", Color("#00000022"))
		text.add_theme_constant_override("shadow_offset_x", 1)
	return text

func _panel(color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#b59a6d")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _button(label: String) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size.y = 44
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", INK)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#f8ead1")
	normal.border_color = Color("#bdad8b")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(7)
	normal.set_content_margin_all(7)
	b.add_theme_stylebox_override("normal", normal)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.bg_color = Color("#f1d49e")
	focus.border_color = BURGUNDY
	focus.set_border_width_all(2)
	b.add_theme_stylebox_override("hover", focus)
	b.add_theme_stylebox_override("focus", focus)
	return b

func _scroll(parent: Control) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	parent.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	scroll.add_child(v)
	return v

func _render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var info: Dictionary = Logic.inspect(game, event_id)
	if info.is_empty():
		close_requested.emit()
		return
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("#142b31ef")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 35)
	margins.add_theme_constant_override("margin_right", 35)
	margins.add_theme_constant_override("margin_top", 25)
	margins.add_theme_constant_override("margin_bottom", 25)
	add_child(margins)
	var paper := _panel(PAPER)
	margins.add_child(paper)
	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 11)
	paper.add_child(main)
	var title_row := HBoxContainer.new()
	main.add_child(title_row)
	var title := VBoxContainer.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	title.add_child(_label("OFFICE OF CAUSAL ACCOUNTABILITY  /  EVENT DOSSIER", 15, BURGUNDY, true))
	title.add_child(_label(str(info["title"]), 28, INK, true))
	var close := _button("B  RETURN TO CASE")
	close.custom_minimum_size.x = 220
	close.pressed.connect(func(): close_requested.emit())
	title_row.add_child(close)
	first_focus = close
	var detail := _label("%s   /   %s" % [info["place"], "ALREADY RECORDED" if info["occurred"] else ("AVAILABLE TO INFLUENCE" if info["eligible"] else "NOT YET POSSIBLE")], 16, GREEN if info["eligible"] or info["occurred"] else BURGUNDY)
	main.add_child(detail)
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)
	main.add_child(cols)
	var left_panel := _panel(CARD)
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 1.0
	cols.add_child(left_panel)
	var left := _scroll(left_panel)
	left.add_child(_label("WHAT MUST BE TRUE", 23, INK, true))
	var requirements: Array = info["conditions"]
	if requirements.is_empty():
		left.add_child(_label("No prerequisite. This is an ordinary starting incident.", 18, MUTED))
	else:
		var all_count: int = 0
		var any_count: int = 0
		for item in requirements:
			if str(item["kind"]) == "ALL": all_count += 1
			else: any_count += 1
		if all_count > 0:
			left.add_child(_label("ALL of these are needed:", 17, BURGUNDY, true))
			for item in requirements:
				if str(item["kind"]) == "ALL": _add_condition(left, item)
		if any_count > 0:
			left.add_child(_label("AT LEAST ONE of these is needed:", 17, BURGUNDY, true))
			for item in requirements:
				if str(item["kind"]) == "ANY": _add_condition(left, item)
	left.add_child(_label("CHANCE WHEN ATTEMPTED", 22, INK, true))
	left.add_child(_label("Unstamped: %d%%   /   Nudge: %d%%" % [roundi(float(info["chance"]) * 100.0), roundi(float(info["nudge"]) * 100.0)], 19, INK))
	var misfile_text: String = "%d%%" % roundi(float(info["misfile"]) * 100.0) if bool(info["misfile_allowed"]) else "not available"
	left.add_child(_label("Misfile: %s   /   Domino: %d%%" % [misfile_text, roundi(float(info["domino"]) * 100.0)], 19, INK))
	left.add_child(_label("These are conditional chances if the event is attempted, not a promise it will happen today. Reschedule guarantees an eligible event tomorrow.", 16, MUTED))
	left.add_child(_label("WHAT THE EVENT PRODUCES", 22, INK, true))
	left.add_child(_label(", ".join(info["outcomes"]) if not (info["outcomes"] as Array).is_empty() else "No new facts", 18, GREEN))
	left.add_child(_label("+%d case momentum" % int(info["momentum"]), 17, MUTED))
	if not (info["alternative"] as Array).is_empty():
		left.add_child(_label("WITH MISFILE INSTEAD: " + ", ".join(info["alternative"]), 17, BURGUNDY))
	var right_panel := _panel(CARD)
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = 1.0
	cols.add_child(right_panel)
	var right := _scroll(right_panel)
	right.add_child(_label("WHAT MIGHT FOLLOW", 23, INK, true))
	right.add_child(_label("These are POSSIBLE consequences, not recorded events. Normal and Misfile routes are distinct. Department effects can change them further.", 16, MUTED))
	var branches: Array = info["branches"]
	if branches.is_empty():
		right.add_child(_label("No further event uses these particular outputs.", 17, MUTED))
	for item in branches:
		var label: String = ("MISFILE ONLY  /  " if item["route"] == "MISFILE" else "NORMAL  /  ") + str(item["title"]) + "   /   %d%% if attempted" % roundi(float(item["chance"]) * 100.0)
		var b := _button(label)
		b.pressed.connect(_visit.bind(str(item["id"])))
		right.add_child(b)
		right.add_child(_label("Could be enabled by: " + ", ".join(item["because"]), 16, GREEN))
		if bool(item["already_occurred"]):
			right.add_child(_label("Already recorded in this case.", 15, GREEN))
		elif not (item["still_needed"] as Array).is_empty():
			right.add_child(_label("Other requirements: " + ", ".join(item["still_needed"]), 15, MUTED))
		else:
			right.add_child(_label("Would meet its factual prerequisites; it must still be attempted and succeed.", 15, MUTED))
	right.add_child(_label("WHAT ACTUALLY HAPPENED", 23, INK, true))
	var record: Dictionary = info["actual_record"]
	if record.is_empty():
		right.add_child(_label("No recorded occurrence. The possibilities above are predictions only.", 17, MUTED))
	else:
		right.add_child(_label("Day %d: %s" % [int(record["day"]), str(record["text"])], 17, INK))
		right.add_child(_label("Recorded effects: " + ", ".join(Logic._pretty(record["facts"])), 17, GREEN))
		if (info["parents"] as Array).is_empty():
			right.add_child(_label("No prerequisite source: this began a causal chain.", 16, MUTED))
		else:
			right.add_child(_label("CAUSED BY (recorded evidence):", 16, BURGUNDY, true))
			for source in info["parents"]:
				var link := _button(str(source["title"]))
				link.pressed.connect(_visit.bind(str(source["id"])))
				right.add_child(link)
	main.add_child(_label("D-PAD / A: INSPECT A LINK     ·     B: RETURN     ·     Confirmed history is separate from possible consequences.", 15, BURGUNDY))
	_focus_after_layout(first_focus)

func _add_condition(parent: VBoxContainer, item: Dictionary) -> void:
	parent.add_child(_label(("✓  " if item["met"] else "○  ") + str(item["fact"]), 18, GREEN if item["met"] else BURGUNDY))
	if item["met"] and not str(item["source"]).is_empty():
		parent.add_child(_label("    Established by: " + str(item["source"]), 15, MUTED))

func _visit(id: String) -> void:
	if game.get_rule(id).is_empty():
		return
	event_id = id
	_render()

func _focus_after_layout(target: Button) -> void:
	if not is_inside_tree(): return
	await get_tree().process_frame
	if is_instance_valid(target) and target.is_inside_tree(): target.grab_focus()
