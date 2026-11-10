extends Control
## Card-first UI optimized for 1280x800 and controller-only navigation.

const SimulationEngine = preload("res://scripts/simulation/case_simulation.gd")
const LivingTown = preload("res://scripts/ui/living_town.gd")
const MinistryBoard = preload("res://scripts/ui/ministry_board.gd")
const AssignmentBoard = preload("res://scripts/ui/assignment_board.gd")
const CausalityInspector = preload("res://scripts/ui/causality_inspector.gd")
const FirstDayTutorial = preload("res://scripts/ui/first_day_tutorial.gd")
const TUTORIAL_SEEN_PATH = "user://ministry_briefing.json"
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
var gallery_overlay: Control = null

func _ready() -> void:
	sim = SimulationEngine.new()
	_render()
	# Avoid intrusive popups during headless CI and never interrupt a resumed
	# mid-case save. New players see this once; HELP can reopen it at any time.
	if DisplayServer.get_name() != "headless" and sim.persist and sim.status == "active" and sim.day == 1 and int(sim.profile.get("completed", 0)) == 0 and not FileAccess.file_exists(TUTORIAL_SEEN_PATH):
		call_deferred("_open_tutorial")

func _input(event: InputEvent) -> void:
	# Gallery is a modal: back closes it rather than accidentally clearing
	# an intervention or advancing a simulation step beneath the artwork.
	if gallery_overlay != null:
		if (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B) or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			if gallery_overlay is FirstDayTutorial:
				_finish_tutorial()
			else:
				_close_gallery()
			get_viewport().set_input_as_handled()
		return
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
			JOY_BUTTON_START:
				_toggle_music()
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
			KEY_M:
				_toggle_music()
				get_viewport().set_input_as_handled()
			KEY_I:
				_open_inspector(selected_event)
				get_viewport().set_input_as_handled()
			KEY_H:
				_open_tutorial()
				get_viewport().set_input_as_handled()
			KEY_MINUS:
				_adjust_music(-0.10)
				get_viewport().set_input_as_handled()
			KEY_EQUAL:
				_adjust_music(0.10)
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
	var chosen := find_child("StampChoice_" + id, true, false) as Button
	if chosen != null:
		_focus_after_layout(chosen)

func _approve_stamp() -> void:
	if sim.status != "active":
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and focused.has_meta("event_id"):
		selected_event = str(focused.get_meta("event_id"))
	if sim.stage_stamp(selected_stamp, selected_event):
		feedback = "Stamp filed for today. Advance day to see what happens."
		var director := get_node_or_null("/root/MusicDirector")
		if director != null:
			director.call("play_stamp_effect")
	else:
		feedback = _stamp_block_reason(sim.get_rule(selected_event))
	_render()
	if feedback.begins_with("Stamp filed"):
		_animate_stamp_press()
		var next := find_child("AdvanceDayButton", true, false) as Button
		if next != null:
			_focus_after_layout(next)

func _animate_stamp_press() -> void:
	var icon := find_child("StampDeskIcon", true, false) as TextureRect
	if icon == null or not is_inside_tree():
		return
	icon.pivot_offset = icon.size / 2.0
	var tween := create_tween()
	tween.tween_property(icon, "scale", Vector2(1.20, 0.68), 0.09).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(icon, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)

func _clear_stamp() -> void:
	if sim.status != "active":
		return
	if sim.pending.is_empty() and sim.second_pending.is_empty():
		feedback = "Nothing filed to undo."
		_render()
		return
	sim.clear_stamp()
	feedback = "Filed stamp undone."
	_render()

func _advance_day() -> void:
	if sim.status != "active":
		return
	var previous_count: int = sim.history.size()
	sim.advance_day()
	var recorded: Array = []
	for item in sim.history.slice(previous_count):
		var event_id: String = str(item.get("id", ""))
		# Administrative notes remain in the chronicle but are not represented
		# as physical incidents that supposedly occurred in Oddford.
		if not sim.get_rule(event_id).is_empty() or event_id.begins_with("correction_"):
			recorded.append(item)
	feedback = "The daily register has been updated."
	_render()
	# Replays are entirely sourced from this day's actual simulation ledger.
	# They never alter the game state, chances, rewards or available stamps.
	_open_town_report(recorded)

func _toggle_music() -> void:
	var director := get_node_or_null("/root/MusicDirector")
	if director == null:
		return
	director.call("set_music_enabled", not bool(director.get("music_enabled")))
	feedback = "Office music %s." % ("enabled" if bool(director.get("music_enabled")) else "muted")
	_render()

func _adjust_music(delta: float) -> void:
	var director := get_node_or_null("/root/MusicDirector")
	if director == null:
		return
	director.call("set_music_volume", float(director.get("music_volume")) + delta)
	feedback = "Music volume: %d%%." % roundi(float(director.get("music_volume")) * 100.0)
	_render()

func _open_town_report(records: Array) -> void:
	_close_gallery()
	gallery_overlay = LivingTown.new()
	gallery_overlay.configure(sim, records, true)
	gallery_overlay.close_requested.connect(_close_gallery)
	gallery_overlay.investigate_requested.connect(_investigate_from_town)
	add_child(gallery_overlay)

func _investigate_from_town(event_id: String) -> void:
	_close_gallery()
	_select_event(event_id)

func _open_inspector(id: String) -> void:
	if sim.get_rule(id).is_empty():
		feedback = "Select an incident to inspect its evidence."
		_render()
		return
	if gallery_overlay != null:
		_close_gallery()
	gallery_overlay = CausalityInspector.new()
	gallery_overlay.configure(sim, id)
	gallery_overlay.close_requested.connect(_close_gallery)
	add_child(gallery_overlay)

func _open_tutorial() -> void:
	if gallery_overlay != null:
		_close_gallery()
	gallery_overlay = FirstDayTutorial.new()
	gallery_overlay.finished.connect(_finish_tutorial)
	gallery_overlay.skipped.connect(_finish_tutorial)
	add_child(gallery_overlay)

func _finish_tutorial() -> void:
	if not (gallery_overlay is FirstDayTutorial):
		return
	# A separate flag avoids changing the case-save schema or old user profiles.
	# Finishing or skipping both suppress the automatic first-run briefing.
	var file := FileAccess.open(TUTORIAL_SEEN_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string('{"version":1,"seen":true}')
		file.close()
	_close_gallery()

func _open_ministry() -> void:
	if gallery_overlay != null:
		_close_gallery()
	gallery_overlay = MinistryBoard.new()
	gallery_overlay.configure(sim)
	gallery_overlay.close_requested.connect(_close_gallery)
	add_child(gallery_overlay)

func _buy_upgrade(kind: String) -> void:
	if sim.buy_upgrade(kind):
		feedback = "Purchase approved. Civil Service thanks you."
	else:
		feedback = "Insufficient Merit or upgrade level reached."
	_render()

func _new_case() -> void:
	# Legacy/restart helper: repeat the current assignment with a new seed.
	sim.start_new_run()
	selected_stamp = "nudge"
	selected_event = ""
	feedback = "A fresh case has been placed on your desk."
	_render()

func _open_assignment_board() -> void:
	if sim.status == "active":
		return
	if gallery_overlay != null:
		_close_gallery()
	gallery_overlay = AssignmentBoard.new()
	gallery_overlay.configure(sim)
	gallery_overlay.close_requested.connect(_close_gallery)
	gallery_overlay.case_selected.connect(_start_selected_case)
	add_child(gallery_overlay)

func _start_selected_case(id: String) -> void:
	if not sim.start_new_run(-1, id):
		return
	selected_stamp = "nudge"
	selected_event = ""
	feedback = "Assignment accepted. Your departments are now on duty."
	_render()


# Original storybook visual direction: illustrated miniature town, a physical
# paper case file and tactile rubber stamps. Game logic stays in CaseSimulation.
func _render() -> void:
	gallery_overlay = null
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
	banner.custom_minimum_size.y = 68
	root_view.add_child(banner)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	banner.add_child(row)
	row.add_child(_illustration("res://assets/seal.svg", Vector2(48, 48)))
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 1)
	row.add_child(heading)
	var name := _label("THE MINISTRY OF COINCIDENCES", 28, Color("#f8e8bc"), true)
	name.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.add_child(name)
	heading.add_child(_label("OFFICE OF DELICATE INTERVENTIONS     |     EST. 1893", 14, Color("#b7ccbf")))
	var reference := VBoxContainer.new()
	reference.custom_minimum_size.x = 263
	reference.add_theme_constant_override("separation", 3)
	row.add_child(reference)
	var case_code := _label("CASE / %s    DAY %d OF %d" % [sim.case_id.to_upper(), sim.day, int(sim.case_info["deadline"])], 18, Color("#fae7c3"), true)
	case_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	case_code.autowrap_mode = TextServer.AUTOWRAP_OFF
	reference.add_child(case_code)
	var civil := _label("MERIT: %d     CLASSIFICATION: %s" % [int(sim.profile["merit"]), sim.case_info["difficulty"]], 14, Color("#c2c9bb"))
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
	cover.custom_minimum_size.y = 149
	root_view.add_child(cover)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	cover.add_child(row)
	var contents := VBoxContainer.new()
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents.add_theme_constant_override("separation", 4)
	row.add_child(contents)
	contents.add_child(_label("OFFICIAL CASE FILE    /    CLASSIFIED ASSIGNMENT    /    TOWN OF ODDFORD", 14, BURGUNDY, true))
	contents.add_child(_label(str(sim.case_info["title"]).to_upper(), 25 if sim.case_id != "fowl" else 31, INK, true))
	contents.add_child(_label(str(sim.case_info["brief"]), 16, INK))
	var finished: Array = []
	for item in sim.case_objective_progress():
		finished.append(("[OK] " if bool(item["done"]) else "[  ] ") + str(item["label"]))
	contents.add_child(_label("REQUIREMENTS: " + "   |   ".join(PackedStringArray(finished)), 13, BURGUNDY, true))
	contents.add_child(_rule())
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 22)
	contents.add_child(metrics)
	metrics.add_child(_metric(str(sim.case_info["metric"]), "%d / %d" % [sim.support, sim.case_info["required_support"]]))
	metrics.add_child(_metric("INFLUENCE", "%d / %d" % [sim.influence, sim.maximum_influence()]))
	metrics.add_child(_metric("REALITY STRAIN", "%d / 6" % sim.strain))
	var gerald_holder := _card(Color("#ecd7aa"), Color("#9a7854"), 2)
	gerald_holder.custom_minimum_size.x = 115
	row.add_child(gerald_holder)
	gerald_holder.add_child(_illustration("res://assets/illustrated/portrait_%s.webp" % sim.case_info["portrait"], Vector2(106, 108)))
	var village_holder := _card(Color("#ddcfac"), Color("#967d5c"), 2)
	village_holder.custom_minimum_size.x = 352
	row.add_child(village_holder)
	var town_column := VBoxContainer.new()
	town_column.add_theme_constant_override("separation", 4)
	village_holder.add_child(town_column)
	town_column.add_child(_illustration("res://assets/illustrated/oddford_banner.webp", Vector2(332, 74)))
	var doors := HBoxContainer.new()
	doors.add_theme_constant_override("separation", 6)
	town_column.add_child(doors)
	var map_button := _button("VIEW ODDFORD")
	map_button.custom_minimum_size.y = 31
	map_button.add_theme_font_size_override("font_size", 15)
	map_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_button.pressed.connect(_open_gallery.bind("town"))
	doors.add_child(map_button)
	var cast_button := _button("MEET THE TOWN")
	cast_button.custom_minimum_size.y = 31
	cast_button.add_theme_font_size_override("font_size", 15)
	cast_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cast_button.pressed.connect(_open_gallery.bind("cast"))
	doors.add_child(cast_button)
	var department_button := _button("THE MINISTRY")
	department_button.name = "OpenMinistryBoard"
	department_button.custom_minimum_size.y = 31
	department_button.add_theme_font_size_override("font_size", 13)
	department_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	department_button.pressed.connect(_open_ministry)
	doors.add_child(department_button)

func _event_tray(parent: HBoxContainer) -> void:
	var panel := _card(Color("#fff4dd"), Color("#b89564"), 2)
	panel.custom_minimum_size.x = 710
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	panel.add_child(content)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	content.add_child(line)
	var stamp_limit: int = 2 if sim.has_department("double_booking") else 1
	var filed_count: int = int(not sim.pending.is_empty()) + int(not sim.second_pending.is_empty())
	var heading := _label("1. CHOOSE UP TO %d INCIDENT%s TO INFLUENCE" % [stamp_limit, "" if stamp_limit == 1 else "S"], 19, INK, true)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	line.add_child(heading)
	var tray_tag := _label("%d OF %d FILED" % [filed_count, stamp_limit], 14, BURGUNDY, true)
	tray_tag.autowrap_mode = TextServer.AUTOWRAP_OFF
	line.add_child(tray_tag)
	var available: Array = sim.available_events()
	if selected_event.is_empty() or sim.get_rule(selected_event).is_empty() or not sim._eligible(sim.get_rule(selected_event)):
		selected_event = str(available[0]["id"]) if not available.is_empty() else ""
	content.add_child(_incident_stage(sim.get_rule(selected_event)))
	var list_head := HBoxContainer.new()
	list_head.add_theme_constant_override("separation", 8)
	content.add_child(list_head)
	var options_caption := _label("AVAILABLE INCIDENTS  /  SELECT ONE TO INFLUENCE", 13, BURGUNDY, true)
	options_caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	options_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_head.add_child(options_caption)
	var count := _label("%d POSSIBLE" % available.size(), 13, MUTED, true)
	count.autowrap_mode = TextServer.AUTOWRAP_OFF
	count.custom_minimum_size.x = 100
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	list_head.add_child(count)
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
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_constant_override("h_separation", 12)
		button.custom_minimum_size.y = 65
		button.add_theme_font_size_override("font_size", 16)
		button.set_meta("event_id", str(rule["id"]))
		button.pressed.connect(_select_event.bind(str(rule["id"])))
		entries.add_child(button)
		if initial_focus == null or picked:
			initial_focus = button

func _incident_stage(rule: Dictionary) -> Control:
	# Stage shows potential events; it never asserts they occurred.
	var frame := PanelContainer.new()
	frame.name = "IncidentSpotlight"
	frame.custom_minimum_size.y = 150
	frame.add_theme_stylebox_override("panel", _style(Color("#e4d3af"), BURGUNDY, 2, 8, 0, 0))
	var stage := Control.new()
	stage.name = "IncidentTheater"
	stage.custom_minimum_size.y = 150
	stage.clip_contents = true
	frame.add_child(stage)
	var landscape := TextureRect.new()
	landscape.name = "OddfordStageBackdrop"
	landscape.texture = load("res://assets/illustrated/oddford_square.webp") as Texture2D
	landscape.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	landscape.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	landscape.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	landscape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(landscape)
	var tint := ColorRect.new()
	tint.color = Color("#18343836")
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(tint)
	if rule.is_empty():
		var none := _label("THE TOWN IS TEMPORARILY OUT OF INCIDENTS", 18, CARD, true)
		none.position = Vector2(32, 57)
		stage.add_child(none)
		return frame
	var character := TextureRect.new()
	character.name = "IncidentStageCharacter"
	character.texture = load("res://assets/illustrated/portrait_%s.webp" % _incident_actor(rule)) as Texture2D
	character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	character.position = Vector2(10, 14)
	character.size = Vector2(124, 130)
	character.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(character)
	var paper := PanelContainer.new()
	paper.name = "IncidentStageDossier"
	paper.anchor_left = 0.20
	paper.anchor_right = 0.76
	paper.anchor_top = 0.0
	paper.anchor_bottom = 1.0
	paper.offset_left = 0
	paper.offset_right = -3
	paper.offset_top = 10
	paper.offset_bottom = -10
	paper.add_theme_stylebox_override("panel", _style(Color("#fff2dceF"), Color("#976b5b"), 1, 8, 7, 11))
	stage.add_child(paper)
	var memo := VBoxContainer.new()
	memo.add_theme_constant_override("separation", 2)
	paper.add_child(memo)
	memo.add_child(_label("UNDER OBSERVATION  /  " + str(rule["place"]).to_upper(), 12, BURGUNDY, true))
	var title := _label(str(rule["title"]), 19, INK, true)
	title.max_lines_visible = 2
	memo.add_child(title)
	var caption := _label(str(rule["text"]), 13, MUTED)
	caption.max_lines_visible = 2
	memo.add_child(caption)
	var odds := _label("%d%% CHANCE IF ATTEMPTED  /  NOT GUARANTEED" % roundi(float(rule["chance"]) * 100.0), 13, GREEN, true)
	memo.add_child(odds)
	var postcard := PanelContainer.new()
	postcard.name = "IncidentStagePostcard"
	postcard.anchor_left = 0.78
	postcard.anchor_right = 0.985
	postcard.anchor_top = 0.0
	postcard.anchor_bottom = 1.0
	postcard.offset_top = 10
	postcard.offset_bottom = -10
	postcard.add_theme_stylebox_override("panel", _style(Color("#fff4dd"), Color("#7e454c"), 2, 5, 4, 4))
	stage.add_child(postcard)
	var image := _illustration(_event_illustration(str(rule["id"])), Vector2(112, 117))
	image.name = "IncidentStageIllustration"
	postcard.add_child(image)
	return frame

func _incident_actor(rule: Dictionary) -> String:
	var id: String = str(rule.get("id", ""))
	var place: String = str(rule.get("place", ""))
	if "goose" in id or "sandwich" in id:
		return "gerald"
	if place == "Bakery":
		return "baker"
	if place == "Post Office":
		return "clerk"
	if place == "Town Hall":
		return "mayor"
	if place == "Public Gardens":
		return "organizer"
	return "reporter"

func _incident_name(id: String) -> String:
	# Data-driven art families: a card remains legible even for events without
	# a bespoke illustration. The rules engine does not depend on artwork.
	if "rain" in id or "indoor_parade" in id or "fair" in id or "crowd" in id:
		return "rain"
	if "sandwich" in id or "goose_hungry" in id or "bread" in id or "endorsement" in id:
		return "sandwich"
	if "post" in id or "letter" in id or "invitation" in id or "rulebook" in id or "petition" in id:
		return "letter"
	if "wind" in id or "traffic" in id or "coffee" in id or "posters" in id:
		return "wind"
	if "camera" in id or "photo" in id or "front_page" in id or "viral" in id or "poll" in id:
		return "newspaper"
	return "election"

func _event_icon(id: String) -> Texture2D:
	return load("res://assets/illustrated/incident_%s_small.webp" % _incident_name(id)) as Texture2D

func _event_illustration(id: String) -> String:
	return "res://assets/illustrated/incident_%s.webp" % _incident_name(id)

func _stamp_effect_preview(rule: Dictionary) -> String:
    if rule.is_empty(): return "Pick an incident on the left first."
    var base: int = roundi(float(rule["chance"]) * 100.0)
    match selected_stamp:
        "nudge":
            return "%d%% -> %d%% chance if attempted today. Not guaranteed." % [base, roundi(minf(0.98, float(rule["chance"]) + 0.55) * 100.0)]
        "misfile":
            if (rule["misfile_facts"] as Array).is_empty():
                return "This incident has no alternative outcome to redirect."
            return "%d%% -> %d%% chance; replaces the normal result if it happens." % [base, roundi(minf(0.98, float(rule["chance"]) + 0.40) * 100.0)]
        "reschedule":
            return "Do not try it today. Try it tomorrow with guaranteed success if still eligible."
        "domino":
            return "%d%% -> %d%% chance; guarantees the first newly eligible follow-up if it happens." % [base, roundi(minf(0.98, float(rule["chance"]) + 0.25) * 100.0)]
    return ""

func _stamp_block_reason(rule: Dictionary) -> String:
    if rule.is_empty(): return "Select an available incident first."
    if selected_stamp == "misfile" and (rule["misfile_facts"] as Array).is_empty():
        return "Misfile cannot change this incident. Choose another stamp or incident."
    if sim.has_department("double_booking") and not sim.pending.is_empty() and str(sim.pending.get("target", "")) == selected_event:
        return "Your first filed stamp already targets this incident. Choose another."
    var price: int = int(SimulationEngine.STAMPS[selected_stamp]["cost"])
    if sim.has_department("double_booking") and not sim.pending.is_empty():
        price += int(SimulationEngine.STAMPS[sim.pending["stamp"]]["cost"])
    if sim.influence < price:
        return "Not enough Influence: %d needed, %d available." % [price, sim.influence]
    return "This stamp cannot be filed for the selected incident."

func _stamp_desk(parent: HBoxContainer) -> void:
    var panel := _card(Color("#f0dfbb"), Color("#af875f"), 2)
    panel.custom_minimum_size.x = 464
    parent.add_child(panel)
    var outer := VBoxContainer.new()
    outer.add_theme_constant_override("separation", 4)
    panel.add_child(outer)
    var heading := HBoxContainer.new()
    heading.add_theme_constant_override("separation", 8)
    outer.add_child(heading)
    var icon := _illustration("res://assets/illustrated/stamp_%s_small.webp" % selected_stamp, Vector2(36, 32))
    icon.name = "StampDeskIcon"
    heading.add_child(icon)
    var title := _label("2. CHOOSE A STAMP", 21, INK, true)
    title.autowrap_mode = TextServer.AUTOWRAP_OFF
    heading.add_child(title)
    var instructions := _label("Pick a stamp below. X files it; Y runs the day.", 14, MUTED)
    instructions.autowrap_mode = TextServer.AUTOWRAP_OFF
    outer.add_child(instructions)
    var buttons := HBoxContainer.new()
    buttons.add_theme_constant_override("separation", 4)
    outer.add_child(buttons)
    var names := {"nudge": "NUDGE", "misfile": "MISFILE", "reschedule": "DELAY", "domino": "DOMINO"}
    for id in SimulationEngine.STAMP_ORDER:
        var choice := _button(names[id], id == selected_stamp)
        choice.name = "StampChoice_" + id
        choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        choice.custom_minimum_size = Vector2(99, 42)
        choice.add_theme_font_size_override("font_size", 13)
        choice.tooltip_text = "%s: %s" % [SimulationEngine.STAMPS[id]["name"], SimulationEngine.STAMPS[id]["description"]]
        choice.pressed.connect(_select_stamp.bind(id))
        buttons.add_child(choice)
    var scroll := ScrollContainer.new()
    scroll.name = "StampPreviewScroll"
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    outer.add_child(scroll)
    var preview := VBoxContainer.new()
    preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    preview.add_theme_constant_override("separation", 2)
    scroll.add_child(preview)
    var rule: Dictionary = sim.get_rule(selected_event)
    if not rule.is_empty():
        var incident_row := HBoxContainer.new()
        incident_row.add_theme_constant_override("separation", 7)
        preview.add_child(incident_row)
        incident_row.add_child(_illustration(_event_illustration(str(rule["id"])), Vector2(48, 52)))
        var explanation := VBoxContainer.new()
        explanation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        explanation.add_theme_constant_override("separation", 1)
        incident_row.add_child(explanation)
        explanation.add_child(_label("TARGET: " + str(rule["title"]), 15, BURGUNDY, true))
        explanation.add_child(_label(_stamp_effect_preview(rule), 14, INK))
        var stamp: Dictionary = SimulationEngine.STAMPS[selected_stamp]
        var paid_strain: int = maxi(1, int(stamp["strain"]) - int(sim.profile.get("audit", 0)))
        preview.add_child(_label("Cost when day runs: %d Influence, +%d Strain" % [stamp["cost"], paid_strain], 14, MUTED))
        if not sim.can_stamp(selected_stamp, selected_event):
            preview.add_child(_label(_stamp_block_reason(rule), 14, BURGUNDY))
    else:
        preview.add_child(_label("Select an incident from the left to begin.", 15, MUTED))
    var filed: Array[String] = []
    for entry in [sim.pending, sim.second_pending]:
        if entry.is_empty(): continue
        var event: Dictionary = sim.get_rule(str(entry["target"]))
        filed.append("%s on %s" % [SimulationEngine.STAMPS[entry["stamp"]]["name"], str(event.get("title", "incident"))])
    var status_text: String = "FILED FOR TODAY: " + "; ".join(filed) if not filed.is_empty() else "NOT FILED: The selected stamp has not been applied."
    preview.add_child(_label(status_text, 14, GREEN if not filed.is_empty() else BURGUNDY, true))
    if not filed.is_empty():
        preview.add_child(_label("Filing is reversible until you advance the day.", 13, MUTED))
    preview.add_child(_label("FORECAST: " + sim.forecast(), 13, MUTED))
    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 5)
    outer.add_child(actions)
    var file_caption: String = "X  FILE STAMP"
    if not sim.pending.is_empty():
        file_caption = "X  FILE 2ND STAMP" if sim.has_department("double_booking") else "X  REPLACE STAMP"
    var approve := _button(file_caption)
    approve.name = "FileStampButton"
    approve.custom_minimum_size = Vector2(198, 38)
    approve.add_theme_font_size_override("font_size", 16)
    approve.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    approve.autowrap_mode = TextServer.AUTOWRAP_OFF
    approve.disabled = not sim.can_stamp(selected_stamp, selected_event)
    approve.tooltip_text = "File the selected stamp on the selected incident. Costs apply when the day advances."
    approve.pressed.connect(_approve_stamp)
    actions.add_child(approve)
    var undo := _button("B  UNDO")
    undo.custom_minimum_size.x = 97
    undo.add_theme_font_size_override("font_size", 15)
    undo.autowrap_mode = TextServer.AUTOWRAP_OFF
    undo.disabled = sim.pending.is_empty() and sim.second_pending.is_empty()
    undo.pressed.connect(_clear_stamp)
    actions.add_child(undo)
    var why := _button("WHY?")
    why.name = "InspectIncidentButton"
    why.custom_minimum_size.x = 90
    why.tooltip_text = "Inspect prerequisites, possible consequences and recorded causes"
    why.disabled = rule.is_empty()
    why.pressed.connect(func(): _open_inspector(selected_event))
    actions.add_child(why)
    var advance := _button("Y  ADVANCE DAY  /  RESOLVE EVENTS", false, true)
    advance.name = "AdvanceDayButton"
    advance.custom_minimum_size.y = 45
    advance.add_theme_font_size_override("font_size", 16)
    advance.tooltip_text = "Resolve filed interventions and natural incidents. Filing is optional."
    advance.pressed.connect(_advance_day)
    outer.add_child(advance)

func _result_screen() -> void:
	var case := _card(PAPER, Color("#af8f62"), 2)
	case.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_view.add_child(case)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	case.add_child(row)
	row.add_child(_illustration("res://assets/illustrated/%s.webp" % sim.case_info["illustration"] if sim.status == "won" else "res://assets/illustrated/portrait_clerk.webp", Vector2(240, 230)))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(content)
	content.add_child(_label("CERTIFIED BY THE DEPARTMENT OF HAPPENSTANCE", 15, BURGUNDY, true))
	content.add_child(_label("CASE CLOSED" if sim.status == "won" else "CASE FILED AS INCOMPLETE", 36, GREEN if sim.status == "won" else BURGUNDY, true))
	content.add_child(_label(sim.last_outcome, 22, INK))
	content.add_child(_label("%s %d / %d     |     Civil Service Merit %d     |     Cases filed %d" % [sim.case_info["metric"], sim.support, sim.case_info["required_support"], sim.profile["merit"], sim.profile["completed"]], 17, MUTED))
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
	var ministry_button := _button("REORGANIZE THE MINISTRY   /   %d OF 12 DEPARTMENTS UNLOCKED" % sim.owned_department_count(), false, false)
	ministry_button.name = "OpenMinistryBoard"
	ministry_button.custom_minimum_size.y = 50
	ministry_button.add_theme_font_size_override("font_size", 17)
	ministry_button.pressed.connect(_open_ministry)
	content.add_child(ministry_button)
	if initial_focus == null:
		initial_focus = ministry_button
	var new_case := _button("FILE ANOTHER CASE  /  CHOOSE ASSIGNMENT", false, true)
	new_case.name = "ChooseAssignmentButton"
	new_case.custom_minimum_size.y = 64
	new_case.pressed.connect(_open_assignment_board)
	content.add_child(new_case)
	if initial_focus == null:
		initial_focus = new_case


func _open_gallery(which: String) -> void:
	if gallery_overlay != null:
		_close_gallery()
	if which == "town":
		gallery_overlay = LivingTown.new()
		gallery_overlay.configure(sim, [], false)
		gallery_overlay.close_requested.connect(_close_gallery)
		gallery_overlay.investigate_requested.connect(_investigate_from_town)
		add_child(gallery_overlay)
		return
	gallery_overlay = ColorRect.new()
	gallery_overlay.name = "IllustratedGallery"
	gallery_overlay.color = Color("#162c31ee")
	gallery_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gallery_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(gallery_overlay)
	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right"]:
		frame.add_theme_constant_override("margin_" + edge, 53)
	for edge in ["top", "bottom"]:
		frame.add_theme_constant_override("margin_" + edge, 36)
	gallery_overlay.add_child(frame)
	var paper := _card(PAPER, GOLD, 3)
	frame.add_child(paper)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	paper.add_child(layout)
	var toolbar := HBoxContainer.new()
	layout.add_child(toolbar)
	var caption := _label("ODDFORD  /  OFFICIAL SURVEILLANCE" if which == "town" else "ODDFORD  /  REGISTER OF PECULIAR RESIDENTS", 26, INK, true)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(caption)
	var back := _button("B  RETURN TO CASE", false, true)
	back.custom_minimum_size = Vector2(220, 45)
	back.pressed.connect(_close_gallery)
	toolbar.add_child(back)
	if which == "town":
		var town := _illustration("res://assets/illustrated/oddford_square.webp", Vector2(990, 574))
		town.size_flags_vertical = Control.SIZE_EXPAND_FILL
		layout.add_child(town)
		layout.add_child(_label("Extraordinary events are routinely reported from the bakery, town hall and high street.", 17, MUTED))
	else:
		var roster := GridContainer.new()
		roster.columns = 3
		roster.size_flags_vertical = Control.SIZE_EXPAND_FILL
		roster.add_theme_constant_override("h_separation", 14)
		roster.add_theme_constant_override("v_separation", 10)
		layout.add_child(roster)
		var people := [
			["gerald", "GERALD  /  MAYORAL ASPIRANT"],
			["clerk", "MISS QUILL  /  MINISTRY CLERK"],
			["mayor", "HUXLEY  /  INCUMBENT MAYOR"],
			["reporter", "THE REPORTER  /  OBSERVER"],
			["organizer", "PIP  /  PETITION ORGANIZER"],
			["baker", "NORA  /  BAKER"]
		]
		for person in people:
			var box := VBoxContainer.new()
			box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.add_theme_constant_override("separation", 3)
			roster.add_child(box)
			box.add_child(_illustration("res://assets/illustrated/portrait_%s.webp" % person[0], Vector2(180, 225)))
			var name := _label(str(person[1]), 17, BURGUNDY, true)
			name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(name)
	_focus_after_layout(back)

func _close_gallery() -> void:
	if gallery_overlay == null:
		return
	var closed_ministry: bool = gallery_overlay is MinistryBoard
	var closed_cases: bool = gallery_overlay is AssignmentBoard
	gallery_overlay.queue_free()
	gallery_overlay = null
	if closed_ministry:
		_render()  # Refresh Merit, equipment status and access buttons.
	elif closed_cases and is_instance_valid(initial_focus) and initial_focus.is_inside_tree():
		initial_focus.grab_focus()
	elif is_instance_valid(initial_focus) and initial_focus.is_inside_tree():
		initial_focus.grab_focus()

func _chronicle() -> void:
	var ledger := _card(Color("#fcf2dd"), BORDER)
	ledger.custom_minimum_size.y = 101
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
		var score: String = "  [+%d momentum]" % int(entry["support"]) if int(entry["support"]) > 0 else ""
		var caption: String = "DAY %d   |   %s  -  %s%s%s" % [entry["day"], entry["title"], entry["text"], score, reason]
		var source_id: String = str(entry.get("id", ""))
		if sim.get_rule(source_id).is_empty():
			entries.add_child(_label(caption, 16, INK))
		else:
			var dossier := _button("INSPECT  /  " + caption)
			dossier.add_theme_font_size_override("font_size", 16)
			dossier.custom_minimum_size.y = 37
			dossier.pressed.connect(_open_inspector.bind(source_id))
			entries.add_child(dossier)

func _footer() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	root_view.add_child(row)
	var note := _label("CASE SEED: %d    |    I: EVIDENCE   H: HELP" % sim.seed, 14, Color("#dbd2b3"))
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(note)
	var help := _button("?  HELP")
	help.name = "FirstDayBriefingButton"
	help.custom_minimum_size = Vector2(89, 30)
	help.add_theme_font_size_override("font_size", 14)
	help.tooltip_text = "Reopen the skippable first-day practice briefing"
	help.pressed.connect(_open_tutorial)
	row.add_child(help)
	var director := get_node_or_null("/root/MusicDirector")
	if director != null:
		var enabled: bool = bool(director.get("music_enabled"))
		var sound := _button("♪ ON" if enabled else "♪ OFF", true)
		sound.name = "MusicToggle"
		sound.custom_minimum_size = Vector2(83, 30)
		sound.add_theme_font_size_override("font_size", 14)
		sound.pressed.connect(_toggle_music)
		row.add_child(sound)
		for config in [["−", -0.10], ["+", 0.10]]:
			var volume := _button(str(config[0]), false)
			volume.name = "MusicVolumeDown" if float(config[1]) < 0 else "MusicVolumeUp"
			volume.custom_minimum_size = Vector2(35, 30)
			volume.add_theme_font_size_override("font_size", 17)
			volume.tooltip_text = "Decrease music volume" if float(config[1]) < 0 else "Increase music volume"
			volume.pressed.connect(_adjust_music.bind(float(config[1])))
			row.add_child(volume)
	var status := _label(feedback, 14, Color("#f2d6a3"))
	status.custom_minimum_size.x = 245
	status.clip_text = true
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(status)

func _event_caption(rule: Dictionary) -> String:
	var chance: int = roundi(float(rule["chance"]) * 100.0)
	var support_label: String = "   /  +%d momentum" % int(rule["support"]) if int(rule["support"]) > 0 else ""
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
