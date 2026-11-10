extends Control
## Illustrated case selector. Cases are unlocked by cases filed, not replay RNG.
## Supports gamepad D-pad/A/B and keyboard; no live run can be switched.

signal case_selected(id: String)
signal close_requested

const Catalog = preload("res://scripts/scenarios/case_catalog.gd")
const INK = Color("#273c41")
const PAPER = Color("#f1e2c4")
const CARD = Color("#fff7e7")
const BURGUNDY = Color("#7e454c")
const GOLD = Color("#c49a58")
const MUTED = Color("#6c6a60")
const GREEN = Color("#426e60")

var game: CaseSimulation
var first_focus: Button

func configure(simulation: CaseSimulation) -> void:
	game = simulation

func _ready() -> void:
	name = "AssignmentCaseBoard"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_render()

func _input(event: InputEvent) -> void:
	if (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B) or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		close_requested.emit()
		get_viewport().set_input_as_handled()

func _style(bg: Color, edge: Color, width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _label(value: String, px: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", px)
	label.add_theme_color_override("font_color", color)
	return label

func _button(label: String, enabled: bool, important: bool = false) -> Button:
	var button := Button.new()
	button.text = label
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(120, 50)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color.WHITE if important else INK)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_stylebox_override("normal", _style(BURGUNDY if important else Color("#f1e1bf"), GOLD))
	button.add_theme_stylebox_override("hover", _style(Color("#fbe1a2"), BURGUNDY, 3))
	button.add_theme_stylebox_override("focus", _style(Color("#fbe1a2"), BURGUNDY, 3))
	button.add_theme_stylebox_override("disabled", _style(Color("#ded8c8"), Color("#b9aa95")))
	return button

func _render() -> void:
	var dimmer := ColorRect.new()
	dimmer.color = Color("#172e32f5")
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)
	var frame := PanelContainer.new()
	frame.position = Vector2(31, 21)
	frame.size = Vector2(1218, 757)
	frame.add_theme_stylebox_override("panel", _style(PAPER, GOLD, 4))
	add_child(frame)
	var heading := _label("THE MINISTRY  /  INCOMING ASSIGNMENTS", 29, INK)
	heading.position = Vector2(63, 43)
	heading.size = Vector2(890, 48)
	add_child(heading)
	var back := _button("B  RETURN", true, true)
	back.position = Vector2(1034, 45)
	back.size = Vector2(173, 47)
	back.pressed.connect(func(): close_requested.emit())
	add_child(back)
	var sub := _label("Select one case for your next shift. Your departments are fixed once a new case starts.", 18, MUTED)
	sub.position = Vector2(64, 100)
	sub.size = Vector2(1115, 30)
	add_child(sub)
	var panel := ScrollContainer.new()
	panel.name = "AssignmentCatalogScroll"
	panel.position = Vector2(63, 145)
	panel.size = Vector2(1154, 570)
	panel.follow_focus = true
	add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	panel.add_child(grid)
	first_focus = back
	for case_id in Catalog.ORDER:
		var spec: Dictionary = Catalog.description(str(case_id))
		var allowed: bool = game.case_unlocked(str(case_id)) and game.status != "active"
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(554, 253)
		card.add_theme_stylebox_override("panel", _style(CARD, GREEN if allowed else Color("#c3b69e")))
		grid.add_child(card)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 5)
		card.add_child(col)
		var headline := _label(str(spec["title"]).to_upper(), 22, INK)
		col.add_child(headline)
		var excerpt := _label(str(spec["brief"]), 16, MUTED)
		col.add_child(excerpt)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 9)
		col.add_child(line)
		var portrait := TextureRect.new()
		portrait.texture = load("res://assets/illustrated/portrait_%s.webp" % spec["portrait"]) as Texture2D
		portrait.custom_minimum_size = Vector2(92, 104)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		line.add_child(portrait)
		var detail := VBoxContainer.new()
		detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(detail)
		detail.add_child(_label("%s    /    %d DAYS" % [spec["difficulty"], spec["deadline"]], 15, BURGUNDY))
		detail.add_child(_label("MUST COMPLETE: " + ", ".join(PackedStringArray(spec["requirement_labels"])), 14, MUTED))
		detail.add_child(_label("+%d BONUS MERIT ON SUCCESS" % int(spec["merit_bonus"]), 14, GREEN))
		var choose := _button("START CASE" if allowed else "FILE %d CASES TO UNLOCK" % int(spec["unlock_cases"]), allowed, allowed)
		choose.name = "AssignmentChoose_" + str(case_id)
		choose.custom_minimum_size.y = 45
		choose.pressed.connect(_choose.bind(str(case_id)))
		col.add_child(choose)
		if allowed and first_focus == back:
			first_focus = choose
	var footer := _label("CASES FILED: %d    /    UNLOCKS AT 2, 5 AND 9 CASES    /    WINNING HARDER CASES AWARDS MORE MERIT" % int(game.profile.get("completed", 0)), 16, BURGUNDY)
	footer.position = Vector2(66, 730)
	footer.size = Vector2(1100, 31)
	add_child(footer)
	if is_inside_tree():
		_focus_after_layout(first_focus)

func _choose(id: String) -> void:
	if game.status != "active" and game.case_unlocked(id):
		case_selected.emit(id)

func _focus_after_layout(control: Button) -> void:
	await get_tree().process_frame
	if is_instance_valid(control) and control.is_inside_tree():
		control.grab_focus()
