extends Control
## Diegetic civil-service upgrade board; full controller navigation, no mouse required.
## Purchases and assignments happen between cases. Case effects are snapshotted.

signal close_requested

const Catalog = preload("res://scripts/simulation/department_catalog.gd")
const INK := Color("#263d42")
const PAPER := Color("#f1e2c4")
const CARD := Color("#fff8e6")
const BURGUNDY := Color("#7e454c")
const GOLD := Color("#c49a58")
const MUTED := Color("#646c64")
const GREEN := Color("#446f58")

const FACES: Array[String] = ["clerk", "reporter", "mayor", "organizer", "clerk", "reporter", "baker", "reporter", "mayor", "gerald", "organizer", "gerald"]
var simulation: CaseSimulation
var focus_id: String = ""
var status_message: String = ""
var _first_focus: Button

func configure(game: CaseSimulation) -> void:
	simulation = game

func _ready() -> void:
	name = "MinistryDepartmentBoard"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_render()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		close_requested.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close_requested.emit()
		get_viewport().set_input_as_handled()

func _action(id: String) -> void:
	if simulation.status == "active":
		return
	if not simulation.department_owned(id):
		if simulation.buy_department(id):
			status_message = "License purchased. Choose your operational offices."
		else:
			status_message = "Application refused. Check Merit and case requirements."
	elif simulation.toggle_department(id):
		status_message = "Office assignments updated for the next case."
	else:
		status_message = "All operational slots are occupied. Stand down another office first."
	focus_id = id
	_render()

func _style(bg: Color, border: Color, stroke: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(stroke)
	style.set_corner_radius_all(9)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _label(caption: String, size: int, ink: Color, wrap: bool = true) -> Label:
	var l := Label.new()
	l.text = caption
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", ink)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	return l

func _button(caption: String, emphasized: bool = false) -> Button:
	var button := Button.new()
	button.text = caption
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(116, 43)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color.WHITE if emphasized else INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_stylebox_override("normal", _style(BURGUNDY if emphasized else Color("#e6d2af"), GOLD))
	button.add_theme_stylebox_override("hover", _style(Color("#f7dc9e"), BURGUNDY, 3))
	button.add_theme_stylebox_override("focus", _style(Color("#f7dc9e"), BURGUNDY, 3))
	button.add_theme_stylebox_override("pressed", _style(Color("#e5bd70"), BURGUNDY, 3))
	button.add_theme_stylebox_override("disabled", _style(Color("#ddd5c4"), Color("#bcb1a0")))
	button.add_theme_color_override("font_disabled_color", MUTED)
	return button

func _render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var backdrop := ColorRect.new()
	backdrop.color = Color("#142d32f3")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	var frame := PanelContainer.new()
	frame.name = "MinistryDepartmentsPanel"
	frame.position = Vector2(31, 19)
	frame.size = Vector2(1218, 763)
	frame.add_theme_stylebox_override("panel", _style(PAPER, GOLD, 4))
	add_child(frame)
	var header := HBoxContainer.new()
	header.position = Vector2(65, 51)
	header.size = Vector2(1142, 59)
	header.add_theme_constant_override("separation", 14)
	add_child(header)
	var seal := TextureRect.new()
	seal.texture = load("res://assets/seal.svg") as Texture2D
	seal.custom_minimum_size = Vector2(58, 58)
	seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	header.add_child(seal)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 2)
	header.add_child(titles)
	titles.add_child(_label("THE MINISTRY / ORGANIZATIONAL CHART", 26, INK, false))
	titles.add_child(_label("%s  |  %d MERIT  |  %d/%d OFFICES ASSIGNED" % [simulation.rank_title(), int(simulation.profile["merit"]), (simulation.profile["equipped"] as Array).size(), simulation.department_slots()], 17, BURGUNDY, false))
	var back := _button("B  CLOSE", true)
	back.custom_minimum_size.x = 138
	back.pressed.connect(func(): close_requested.emit())
	header.add_child(back)
	var guidance := _label("BUY offices permanently. EQUIP a limited team for the next case. The first two free automatic approvals are shared daily. Deployed effects cannot change mid-case." if simulation.status != "active" else "ON ASSIGNMENT: Your current team's powers are fixed until this case closes. Inspect offices now; purchase between cases.", 17, MUTED)
	guidance.position = Vector2(69, 116)
	guidance.size = Vector2(1125, 34)
	add_child(guidance)
	var scroll := ScrollContainer.new()
	scroll.name = "DepartmentCatalogScroll"
	scroll.position = Vector2(68, 161)
	scroll.size = Vector2(1146, 529)
	scroll.follow_focus = true
	add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "DepartmentCardGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	_first_focus = back
	var restore_target: Button = null
	for index in range(Catalog.ORDER.size()):
		var id: String = Catalog.ORDER[index]
		var spec: Dictionary = Catalog.get_department(id)
		var owned: bool = simulation.department_owned(id)
		var equipped: bool = (simulation.profile["equipped"] as Array).has(id)
		var run_active: bool = simulation.has_department(id)
		var enough_cases: bool = int(simulation.profile["completed"]) >= int(spec["cases"])
		var enough_merit: bool = int(simulation.profile["merit"]) >= int(spec["cost"])
		var box := PanelContainer.new()
		box.custom_minimum_size = Vector2(552, 137)
		box.add_theme_stylebox_override("panel", _style(Color("#fffaf0") if owned else CARD, GREEN if equipped else Color("#c0ac88"), 3 if equipped else 1))
		grid.add_child(box)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)
		var portrait := TextureRect.new()
		portrait.texture = load("res://assets/illustrated/portrait_%s.webp" % FACES[index]) as Texture2D
		portrait.custom_minimum_size = Vector2(74, 95)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(portrait)
		var content := VBoxContainer.new()
		content.custom_minimum_size.x = 307
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_theme_constant_override("separation", 2)
		row.add_child(content)
		var name := _label(str(spec["name"]).to_upper(), 17, INK)
		content.add_child(name)
		content.add_child(_label(str(spec["tag"]) + "  /  " + str(spec["detail"]), 14, MUTED))
		var action := _button("")
		action.name = "DepartmentAction_" + id
		action.custom_minimum_size = Vector2(108, 45)
		var blocked: bool = simulation.status == "active"
		if not owned:
			if not enough_cases:
				action.text = "AFTER %d\nCASES" % int(spec["cases"])
				blocked = true
			else:
				action.text = "%d MERIT\nUNLOCK" % int(spec["cost"])
				blocked = blocked or not enough_merit
		elif equipped:
			action.text = "IN SERVICE" if run_active and simulation.status == "active" else "STAND DOWN"
		else:
			action.text = "ASSIGN" if (simulation.profile["equipped"] as Array).size() < simulation.department_slots() else "SLOTS FULL"
			blocked = blocked or (simulation.profile["equipped"] as Array).size() >= simulation.department_slots()
		action.disabled = blocked
		action.pressed.connect(_action.bind(id))
		row.add_child(action)
		if not blocked and _first_focus == back:
			_first_focus = action
		if focus_id == id and not blocked:
			restore_target = action
	var footer := _label(("LAST DECISION: " + status_message) if not status_message.is_empty() else "B CLOSE   |   D-PAD NAVIGATE   |   A PURCHASE OR ASSIGN   |   NEW ASSIGNMENTS TAKE EFFECT NEXT CASE", 16, BURGUNDY)
	footer.position = Vector2(70, 711)
	footer.size = Vector2(1120, 40)
	add_child(footer)
	if is_inside_tree():
		_focus_after_layout(restore_target if restore_target != null else _first_focus)

func _focus_after_layout(target: Button) -> void:
	await get_tree().process_frame
	if is_instance_valid(target) and target.is_inside_tree():
		target.grab_focus()
