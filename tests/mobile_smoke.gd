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
    var content_scroll := _find(ui, "MobileContentScroll") as ScrollContainer
    _assert(content_scroll != null and content_scroll.get_global_rect().size.y >= 220.0, "Portrait content viewport occupies usable vertical space")
    _assert(_find(ui, "MobileIncidentFeature") != null, "Incident has an illustrated feature")
    var character := _find(ui, "MobileIncidentCharacter") as TextureRect
    _assert(character != null and character.texture != null, "The actual illustrated Oddford character is present")
    _assert((_find(ui, "MobileIncidentTown") as TextureRect).texture != null, "Real Oddford town illustration is loaded")
    var selected_id: String = ui.selected_event
    _assert(not selected_id.is_empty(), "An eligible incident is selected")
    _assert((_find(ui, "MobileContinueToStamp") as Button) != null, "Portrait has a stamp-navigation button")
    ui._change_page("stamps")
    await _run_frame()
    _assert(_find(ui, "MobileStampPreview") != null, "Probability / cost preview available")
    var seal := _find(ui, "MobileSealArt_nudge") as TextureRect
    _assert(seal != null and seal.texture != null, "Original stamp seal art is visible in the chooser")
    _assert(_find(ui, "MobileAdvanceDayButton") == null, "Cannot advance before filing a stamp")
    var current_day: int = ui.sim.day
    ui._advance_day()
    _assert(ui.sim.day == current_day, "An unstamped advance attempt cannot silently consume the day")
    _assert(_find(ui, "MobileConfirmEmptyDayButton") != null, "Explicit no-stamp confirmation appears")
    ui._cancel_unstamped_day()
    await _run_frame()
    var file_button := _find(ui, "MobileFileStampButton") as Button
    _assert(file_button != null and not file_button.disabled, "Mobile stamp is available")
    var skip_button := _find(ui, "MobileSkipFilingButton") as Button
    _assert(skip_button != null and skip_button.get_global_rect().size.x >= 250.0, "Skip action is legible and not a sliver")
    _assert(file_button != null and file_button.get_global_rect().size.y <= 90.0, "File action is normal tap height, not a giant rectangle")
    var original_influence: int = ui.sim.influence
    file_button.pressed.emit()
    _assert(not ui.sim.pending.is_empty(), "Touch filing stages the actual simulation")
    _assert(str(ui.sim.pending.get("target", "")) == selected_id and str(ui.sim.pending.get("stamp", "")) == "nudge", "Filed incident and selected stamp agree")
    _assert(_find(ui, "MobileFilingRibbon") != null, "Filed incident stays visible beside the day action")
    _assert(_find(ui, "MobileAdvanceDayButton") != null, "Advance appears only after filing")
    await _run_frame()
    var advance_button := _find(ui, "MobileAdvanceDayButton") as Button
    _assert(advance_button != null and advance_button.get_global_rect().size.y <= 90.0, "Advance action has a proper touch target")
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
    _assert(_find(ui, "MobileFileStampButton") == null, "No third filing button when both interventions are filed")
    _assert(_find(ui, "MobileAdvanceDayButton") != null, "Two filings can advance together")
    ui._advance_day()
    await _run_frame()
    _assert(ui.theater != null, "Advance opens mobile Causality Theater")
    var theater: Node = _find(ui, "MobileCausalityTheater")
    _assert(theater != null, "Mobile theater is mounted as modal")
    var theater_scroll := _find(ui, "MobileTheaterScroll") as ScrollContainer
    _assert(theater_scroll != null and theater_scroll.get_global_rect().size.y >= 220.0, "Theater artwork viewport has usable height")
    var town := _find(ui, "MobileCausalityTown") as TextureRect
    _assert(town != null and town.texture != null, "Actual illustrated Oddford stage loads in theater")
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
