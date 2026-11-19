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
func _contrast_ratio(foreground: Color, background: Color) -> float:
    var a: Color = foreground.srgb_to_linear()
    var b: Color = background.srgb_to_linear()
    var la: float = a.r * 0.2126 + a.g * 0.7152 + a.b * 0.0722
    var lb: float = b.r * 0.2126 + b.g * 0.7152 + b.b * 0.0722
    return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

func _assert_readable_body(ui: Control, page_name: String) -> void:
    var body: Node = _find(ui, "MobilePageBody")
    _assert(body != null, page_name + " main page body exists")
    if body == null:
        return
    for node in body.get_children():
        if node is Label:
            var label := node as Label
            var color: Color = label.get_theme_color("font_color")
            var caption: String = label.text.left(32)
            _assert(_contrast_ratio(color, Color("#183239")) >= 4.5, page_name + " label contrast: " + caption)

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
    _assert(not is_quit_on_go_back(), "Android Back does not automatically exit the game")
    _assert_readable_body(ui, "incidents")
    # Instruction screens must be readable against the dark page, not just
    # structurally present in the Godot scene.
    for screen in ["help", "tutorial", "stamps", "log", "town", "cast", "settings", "evidence"]:
        ui._change_page(screen)
        await _run_frame()
        _assert_readable_body(ui, screen)
    ui._change_page("tutorial")
    var skip_tutorial := _find(ui, "MobileSkipBriefingFooter") as Button
    _assert(skip_tutorial != null, "First-run briefing has an explicit sticky skip action")
    skip_tutorial.pressed.emit()
    _assert(ui.page == "incidents" and FileAccess.file_exists("user://ministry_briefing.json"), "Skipping the briefing persists completion and opens the real case")
    ui._change_page("help")
    ui._handle_android_back()
    _assert(ui.page == "incidents", "Android Back returns from Help to current case")
    ui._change_page("stamps")
    ui._handle_android_back()
    _assert(ui.page == "incidents", "Android Back returns from Stamp Desk to incident choice")
    ui._change_page("incidents")
    await _run_frame()
    _assert(_find(ui, "MobileSafeSurface") != null, "Portrait-safe layout exists")
    var content_scroll := _find(ui, "MobileContentScroll") as ScrollContainer
    _assert(content_scroll != null and content_scroll.get_global_rect().size.y >= 220.0, "Portrait content viewport occupies usable vertical space")
    _assert(_find(ui, "MobileIncidentFeature") != null, "Incident has an illustrated feature")
    _assert(_find(ui, "MobileSettingsButton") != null, "Settings are reachable from any active case")
    var character := _find(ui, "MobileIncidentCharacter") as TextureRect
    _assert(character != null and character.texture != null, "The actual illustrated Oddford character is present")
    _assert((_find(ui, "MobileIncidentTown") as TextureRect).texture != null, "Real Oddford town illustration is loaded")
    var selected_id: String = ui.selected_event
    _assert(not selected_id.is_empty(), "An eligible incident is selected")
    _assert((_find(ui, "MobileContinueToStamp") as Button) != null, "Portrait has a stamp-navigation button")
    ui._change_page("stamps")
    await _run_frame()
    _assert(_find(ui, "MobileStampPreview") != null, "Probability / cost preview available")
    var forecast := _find(ui, "MobileRealityForecast") as Label
    _assert(forecast != null and forecast.text.contains(ui.sim.forecast()), "Mobile uses the actual simulation correction forecast, same as desktop")
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
    var actor := _find(ui, "MobileBeatActor0") as TextureRect
    _assert(actor != null and actor.texture != null, "Causality Theater has original character portraits for recorded beats")
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
    _assert((_find(ui, "MobileInteractiveTownImage") as TextureRect).texture != null, "Original interactive Oddford map is loaded")
    _assert(_find(ui, "MobileTownWitnessDocket") != null, "Town has a location-specific incident docket")
    for district in ["TownHall", "Bakery", "PostOffice", "HighStreet", "PublicGardens", "ParadeHall"]:
        _assert(_find(ui, "MobileTownLocation" + district) != null, "Town district is selectable: " + district)
        _assert(_find(ui, "MobileTownPin_" + district) != null, "Town map has an illustrated touch hotspot: " + district)
    var replay := _find(ui, "MobileTownReplayButton") as Button
    _assert(replay != null and not replay.disabled, "Recorded days can be replayed through the same theater")
    ui._open_town_replay()
    _assert(ui.theater != null and ui.theater.historical_replay, "Archived replay displays recorded simulation events with historical mode")
    if ui.theater != null:
        var count := ui.theater.recorded.size()
        _assert(count > 0, "Historical replay has real incident records")
        ui.theater.call("_finish")
        var archival := _find(ui.theater, "MobileDailySummary") as Label
        _assert(archival != null and archival.text.contains("ORIGINAL CHRONICLE"), "Historical replay never invents old stamp or Strain data")
        ui._close_theater()
    ui._select_town_location("Bakery")
    _assert(ui.selected_town_location == "Bakery", "Changing a district updates the selected local office")
    ui._change_page("cast")
    _assert(_find(ui, "MobileCastGallery") != null, "Mobile has the desktop cast gallery")
    for resident in ["gerald", "clerk", "mayor", "reporter", "organizer", "baker"]:
        var portrait := _find(ui, "MobileResident_" + resident) as TextureRect
        _assert(portrait != null and portrait.texture != null, "Real cast art available: " + resident)
    ui._change_page("settings")
    _assert(_find(ui, "MobileReducedMotionToggle") != null, "Reduced motion preference is controllable")
    var director := root.get_node_or_null("MusicDirector")
    if director != null:
        var old_music: bool = bool(director.get("music_enabled"))
        var old_volume: float = float(director.get("music_volume"))
        _assert(_find(ui, "MobileMusicToggle") != null, "Mobile shares desktop music controls")
        ui._toggle_music()
        _assert(bool(director.get("music_enabled")) != old_music, "Music toggle updates real MusicDirector")
        ui._toggle_music()
        _assert(bool(director.get("music_enabled")) == old_music, "Music toggle is reversible")
        ui._adjust_music(-0.10)
        _assert(float(director.get("music_volume")) <= old_volume, "Music volume is controlled in the real director")
        director.call("set_music_volume", old_volume)
    ui._change_page("help")
    _assert(ui.page == "help", "Mobile help accessible")
    ui._change_page("tutorial")
    var before: int = ui.sim.profile["merit"]
    var day_before: int = ui.sim.day
    ui._next_tutorial()
    _assert(ui.practice != null and ui.tutorial_step == 1, "Briefing starts a separate seeded practice simulation")
    _assert(ui.practice.pending.is_empty(), "Practice starts with no pre-filed stamp")
    ui._next_tutorial()
    _assert(str(ui.practice.pending.get("stamp", "")) == "nudge" and str(ui.practice.pending.get("target", "")) == "sandwich", "Player action files the actual practice Nudge")
    ui._next_tutorial()
    _assert(ui.tutorial_step == 3 and ui.practice.day > 1, "Practice advances only after explicit player action")
    _assert(ui.sim.profile["merit"] == before and ui.sim.day == day_before and ui.sim.pending.is_empty(), "Practice cannot change real progress, Merit or stamp filings")
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
