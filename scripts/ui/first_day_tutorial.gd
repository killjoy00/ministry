extends Control
## Skippable, separate practice case: no Merit, no saved progress, no fake rolls.
signal finished
signal skipped

const Simulation = preload("res://scripts/simulation/case_simulation.gd")
const Causal = preload("res://scripts/simulation/causal_inspection.gd")
const PRACTICE_SEED = 1
const PAPER = Color("#f1e2c4")
const INK = Color("#273c41")
const BURGUNDY = Color("#7e454c")
const GREEN = Color("#426e60")
const MUTED = Color("#6c6a60")
var practice: CaseSimulation
var step: int = 0
var first_focus: Button

func _ready() -> void:
	name = "FirstDayTutorial"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	practice = Simulation.new(PRACTICE_SEED, false)
	_render()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		skipped.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		skipped.emit()
		get_viewport().set_input_as_handled()

func _label(value: String, px: int, color: Color) -> Label:
	var l := Label.new()
	l.text = value
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", color)
	return l

func _button(value: String) -> Button:
	var b := Button.new()
	b.text = value
	b.custom_minimum_size.y = 60
	b.add_theme_font_size_override("font_size", 19)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_focus_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#fff7e7")
	normal.border_color = Color("#bdad8b")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(9)
	normal.set_content_margin_all(9)
	b.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#f2d6a3")
	hover.border_color = BURGUNDY
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover)
	return b

func _render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var shade := ColorRect.new()
	shade.color = Color("#142b31f2")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var pad := MarginContainer.new()
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]: pad.add_theme_constant_override("margin_" + side, 70)
	for side in ["top", "bottom"]: pad.add_theme_constant_override("margin_" + side, 55)
	add_child(pad)
	var panel := PanelContainer.new()
	var sty := StyleBoxFlat.new()
	sty.bg_color = PAPER
	sty.border_color = Color("#bb9464")
	sty.set_border_width_all(3)
	sty.set_corner_radius_all(14)
	sty.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", sty)
	pad.add_child(panel)
	var whole := VBoxContainer.new()
	whole.add_theme_constant_override("separation", 12)
	panel.add_child(whole)
	var heading := HBoxContainer.new()
	whole.add_child(heading)
	var head_col := VBoxContainer.new()
	head_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(head_col)
	head_col.add_child(_label("FIRST-DAY BRIEFING   /   OPTIONAL PRACTICE", 16, BURGUNDY))
	head_col.add_child(_label("A Note from Miss Quill", 34, INK))
	var count := _label("FORM %d OF 4" % (step + 1), 17, MUTED)
	count.custom_minimum_size.x = 120
	count.autowrap_mode = TextServer.AUTOWRAP_OFF
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heading.add_child(count)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 22)
	whole.add_child(row)
	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/illustrated/portrait_clerk.webp") as Texture2D
	portrait.custom_minimum_size = Vector2(250, 355)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 16)
	row.add_child(text_col)
	var rule := practice.get_rule("sandwich")
	match step:
		0:
			text_col.add_child(_label("WELCOME, PROBATIONARY CLERK", 27, BURGUNDY))
			text_col.add_child(_label("Your job is to influence small incidents until they produce something delightfully unreasonable. You may not simply order the goose to become mayor. The budget does not permit it.", 23, INK))
			text_col.add_child(_label("This is a separate practice file. Nothing here uses your real Influence or Merit, and you can skip at any point.", 19, MUTED))
		1:
			text_col.add_child(_label("STEP 1  /  PLACE A NUDGE", 27, BURGUNDY))
			text_col.add_child(_label(str(rule["title"]) + "  /  %d%% base chance" % roundi(float(rule["chance"]) * 100.0), 21, INK))
			text_col.add_child(_label("Nudge costs 2 Influence and makes this incident much likelier (up to 98% if attempted). It raises Reality Strain, which can later trigger a correction.", 21, INK))
			text_col.add_child(_label("We will stamp a practice sandwich. No real case will be changed.", 19, MUTED))
		2:
			text_col.add_child(_label("STEP 2  /  ADVANCE THE DAY", 27, BURGUNDY))
			text_col.add_child(_label("The Nudge has been filed. It is not a guaranteed success. Each day the event engine attempts incidents, then follows any new facts to their possible consequences.", 22, INK))
			text_col.add_child(_label("Advance this practice day to see what the actual seeded simulation records.", 19, MUTED))
		3:
			text_col.add_child(_label("STEP 3  /  INSPECT THE EVIDENCE", 27, BURGUNDY))
			var found: Array = []
			for record in practice.history:
				if not (record.get("facts", []) as Array).is_empty():
					var sentence: String = "• " + str(record["title"])
					if not (record["causes"] as Array).is_empty():
						var titles: Array = []
						for parent_id in record["causes"]:
							titles.append(Causal._event_name(practice, str(parent_id)))
						sentence += "  ←  " + ", ".join(titles)
					found.append(sentence)
					if found.size() >= 5: break
			text_col.add_child(_label("THE REGISTER ACTUALLY RECORDED:", 17, GREEN))
			text_col.add_child(_label("\n".join(found), 19, INK))
			text_col.add_child(_label("In the real case, select WHY? on an incident or open a Chronicle entry. Green facts and recorded causes are evidence; 'might follow' is only a forecast.", 19, BURGUNDY))
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	whole.add_child(footer)
	var skip := _button("B  SKIP BRIEFING")
	skip.custom_minimum_size.x = 245
	skip.pressed.connect(func(): skipped.emit())
	footer.add_child(skip)
	var note := _label("A / ENTER to continue   ·   No practice progress is saved", 15, MUTED)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(note)
	var next_title: String = ["START PRACTICE", "STAMP THE SANDWICH", "ADVANCE PRACTICE DAY", "BEGIN MY CASE"][step]
	var next := _button(next_title)
	next.custom_minimum_size.x = 250
	next.pressed.connect(_next)
	footer.add_child(next)
	first_focus = next
	_focus_after_layout(next)

func _next() -> void:
	match step:
		0:
			step = 1
		1:
			if not practice.stage_stamp("nudge", "sandwich"):
				push_error("Practice Nudge must be eligible")
				return
			step = 2
		2:
			practice.advance_day()
			step = 3
		3:
			finished.emit()
			return
	_render()

func _focus_after_layout(control: Button) -> void:
	if not is_inside_tree(): return
	await get_tree().process_frame
	if is_instance_valid(control) and control.is_inside_tree(): control.grab_focus()
