extends SceneTree
## Touch-first, portrait/landscape regression; same state transitions as desktop.
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
var count: int = 0
var fails: Array[String] = []
func _initialize() -> void: call_deferred("_check_mobile")
func _assert(value: bool, description: String) -> void:
    count += 1
    if not value: fails.append(description)
func _find(node: Node, name: String) -> Node:
    if node.name == name: return node
    for child in node.get_children():
        var match_node: Node = _find(child, name)
        if match_node != null: return match_node
    return null
func _run_frame() -> void:
    await process_frame
    await process_frame
func _check_mobile() -> void:
    root.content_scale_size = Vector2i(390, 844)
    root.size = Vector2i(390, 844)
    var ui: Control = load("res://scenes/mobile_main.tscn").instantiate()
    root.add_child(ui)
    ui.sim = Simulation.new(1, false)
    ui.page = "incidents"
    ui._render()
    await _run_frame()
    _assert(_find(ui, "MobileSafeSurface") != null, "Portrait-safe layout exists")
    _assert(_find(ui, "MobileIncidentFeature") != null, "Incident has an illustrated feature")
    var selected_id: String = ui.selected_event
    _assert(not selected_id.is_empty(), "An eligible incident is selected")
    _assert((_find(ui, "MobileContinueToStamp") as Button) != null, "Portrait has a stamp-navigation button")
    ui._change_page("stamps")
    await _run_frame()
    _assert(_find(ui, "MobileStampPreview") != null, "Probability / cost preview available")
    var file_button := _find(ui, "MobileFileStampButton") as Button
    _assert(file_button != null and not file_button.disabled, "Mobile stamp is available")
    var original_influence: int = ui.sim.influence
    ui._file_stamp()
    _assert(not ui.sim.pending.is_empty(), "Touch filing stages the actual simulation")
    _assert(ui.sim.influence == original_influence, "Filing does not spend Influence until the day advances")
    ui._undo()
    _assert(ui.sim.pending.is_empty(), "Mobile Undo clears a filing")
    ui.sim.run_departments = ["double_booking"]
    ui.sim.influence = 8
    ui._render()
    var first: String = ui.selected_event
    _assert(ui.sim.stage_stamp("nudge", first), "Double Booking permits first filing")
    var second: String = ""
    for event in ui.sim.available_events():
        if str(event["id"]) != first:
            second = str(event["id"])
            break
    _assert(not second.is_empty(), "Another eligible incident exists")
    ui.selected_event = second
    _assert(ui.sim.stage_stamp("nudge", second), "Double Booking permits a second different incident")
    ui._render()
    _assert(ui._filed_count() == 2, "Mobile filing count shows two")
    _assert((_find(ui, "MobileFileStampButton") as Button).disabled, "Third filing is blocked")
    ui._advance_day()
    await _run_frame()
    _assert(ui.theater != null, "Advance opens mobile Causality Theater")
    var theater: Node = _find(ui, "MobileCausalityTheater")
    _assert(theater != null, "Mobile theater is mounted as modal")
    if theater != null:
        theater.call("_finish")
        _assert(_find(theater, "MobileDailySummary") != null, "Daily summary is available after skip")
        _assert((_find(theater, "MobileDailySummary") as Label).visible, "Skip reveals the final summary")
        ui._open_theater_log()
    _assert(ui.page == "log", "Full chronology is accessible from theater")
    ui._show_evidence(first)
    _assert(ui.page == "evidence", "Native evidence view opens")
    ui._change_page("town")
    _assert(ui.page == "town", "Town view available on touch")
    ui._change_page("help")
    _assert(ui.page == "help", "Mobile help accessible")
    ui._change_page("tutorial")
    var before: int = ui.sim.profile["merit"]
    ui._next_tutorial()
    _assert(ui.sim.profile["merit"] == before, "Mobile tutorial cannot change player Merit")
    ui._finish_tutorial()
    _assert(ui.page == "incidents", "Tutorial exits to the real case")
    # Test screen-size changes without losing the actual case state.
    var day: int = ui.sim.day
    root.content_scale_size = Vector2i(844, 390)
    root.size = Vector2i(844, 390)
    ui._render()
    await _run_frame()
    _assert(ui.sim.day == day, "Rotation preserves the active assignment")
    _assert(_find(ui, "MobileActionFooter") != null, "Landscape keeps the main action bar")
    root.remove_child(ui)
    ui.free()
    if fails.is_empty():
        print("PASS: %d mobile gameplay and layout assertions" % count)
        quit(0)
        return
    for error in fails: printerr("FAIL: " + error)
    quit(1)
