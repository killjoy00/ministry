extends Control
## Touch-first companion to scenes/main.tscn. Uses the SAME persisted CaseSimulation,
## case catalog, seeded rule engine, Ministry departments and causal evidence.
## Never edit the desktop scene just to accommodate narrow mobile screens.

const Simulation = preload("res://scripts/simulation/case_simulation.gd")
const Cases = preload("res://scripts/scenarios/case_catalog.gd")
const Causal = preload("res://scripts/simulation/causal_inspection.gd")
const Departments = preload("res://scripts/simulation/department_catalog.gd")
const MobileTheater = preload("res://scripts/mobile/mobile_theater.gd")
const INK = Color("#273c41")
const DEEP = Color("#183239")
const PAPER = Color("#f1e2c4")
const CREAM = Color("#fff7e7")
const GOLD = Color("#c49a58")
const BURGUNDY = Color("#7e454c")
const GREEN = Color("#426e60")
const MUTED = Color("#6c6a60")
# Light ink for text directly on the dark page, unlike cream-paper cards.
const LIGHT_TEXT = Color("#f5e8ca")
const LIGHT_SUB = Color("#d5e0d3")
const LIGHT_ACCENT = Color("#f0ca90")
const LIGHT_SUCCESS = Color("#b6d9c4")
const TUTORIAL_PATH = "user://ministry_briefing.json"
const STAMP_LABELS = {"nudge":"NUDGE", "misfile":"MISFILE", "reschedule":"DELAY", "domino":"DOMINO"}
const TOWN_LOCATIONS = ["Town Hall", "Bakery", "Post Office", "High Street", "Public Gardens", "Parade Hall"]
const RESIDENTS = [["gerald", "GERALD / MAYORAL ASPIRANT"], ["clerk", "MISS QUILL / MINISTRY CLERK"], ["mayor", "HUXLEY / INCUMBENT MAYOR"], ["reporter", "THE REPORTER / OBSERVER"], ["organizer", "PIP / PETITION ORGANIZER"], ["baker", "NORA / BAKER"]]

var sim: CaseSimulation
var page: String = "incidents"
var selected_event: String = ""
var selected_stamp: String = "nudge"
var evidence_id: String = ""
var feedback: String = ""
var theater: Control = null
var confirm_unstamped_day: bool = false
var selected_town_location: String = "Town Hall"
var tutorial_step: int = 0
var practice: CaseSimulation = null
var first_focus: Button
var _last_width: int = 0
var _last_height: int = 0
var _rendered_page: String = ""

func _ready() -> void:
    name = "MinistryMobileGame"
    # Disable Android's default Back=quit behavior at runtime too; some
    # launch environments do not carry through the project setting.
    get_tree().set_quit_on_go_back(false)
    sim = Simulation.new()
    if DisplayServer.get_name() != "headless" and sim.persist and sim.status == "active" and sim.day == 1 and int(sim.profile.get("completed", 0)) == 0 and not FileAccess.file_exists(TUTORIAL_PATH):
        page = "tutorial"
    get_viewport().size_changed.connect(_size_changed)
    _render()

func _size_changed() -> void:
    if not is_inside_tree() or theater != null:
        return
    var sz: Vector2 = get_viewport_rect().size
    if absi(roundi(sz.x) - _last_width) > 10 or absi(roundi(sz.y) - _last_height) > 10:
        _render()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_GO_BACK_REQUEST:
        _handle_android_back()

func _handle_android_back() -> void:
    # Android Back navigates the case; it must not kill the app by default.
    if theater != null:
        _close_theater()
    elif page == "tutorial":
        _finish_tutorial()
    elif ["evidence", "town", "cast", "settings", "help", "stamps", "log"].has(page):
        _change_page("incidents" if sim.status == "active" else "results")
    elif ["ministry", "assignments"].has(page):
        _change_page("results")
    else:
        _change_page("incidents" if sim.status == "active" else "results")

func _render() -> void:
    if sim == null:
        return
    # Reselecting an incident or stamp rebuilds this page. Preserve the
    # scrolled position instead of jumping back to the first card on every tap.
    var previous := find_child("MobileContentScroll", true, false) as ScrollContainer
    var restore_offset: int = 0
    if previous != null and _rendered_page == page:
        restore_offset = previous.scroll_vertical
    _last_width = roundi(get_viewport_rect().size.x)
    _last_height = roundi(get_viewport_rect().size.y)
    for child in get_children():
        remove_child(child)
        child.queue_free()
    theater = null
    first_focus = null
    var backdrop := ColorRect.new()
    backdrop.color = DEEP
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)
    # Center the phone column horizontally, but fill the full height.
    # CenterContainer collapses the scroll viewport to its minimum height.
    var center := HBoxContainer.new()
    center.alignment = BoxContainer.ALIGNMENT_CENTER
    center.name = "MobileSafeSurface"
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(center)
    var margin := MarginContainer.new()
    var safe: Dictionary = _safe_margins()
    margin.add_theme_constant_override("margin_left", int(safe["left"]))
    margin.add_theme_constant_override("margin_right", int(safe["right"]))
    margin.add_theme_constant_override("margin_top", int(safe["top"]))
    margin.add_theme_constant_override("margin_bottom", int(safe["bottom"]))
    margin.custom_minimum_size.x = minf(640.0, maxf(240.0, get_viewport_rect().size.x))
    margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
    center.add_child(margin)
    var surface := VBoxContainer.new()
    surface.name = "MobileDecisionSurface"
    surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
    surface.add_theme_constant_override("separation", 9)
    margin.add_child(surface)
    _header(surface)
    if sim.status == "active" and ["incidents", "stamps", "log"].has(page):
        _tabs(surface)
    var scroll := ScrollContainer.new()
    scroll.name = "MobileContentScroll"
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.scroll_deadzone = 8
    # A real-device smoke-test marker, emitted ONLY by Android debug builds.
    # Screenshot deltas alone can pass if a swipe accidentally presses a card.
    if OS.has_feature("android") and OS.is_debug_build():
        scroll.get_v_scroll_bar().value_changed.connect(_debug_native_scroll.bind(page))
    # Touch focus must not jump the viewport back to a focused incident card.
    scroll.follow_focus = false
    surface.add_child(scroll)
    var body := VBoxContainer.new()
    body.name = "MobilePageBody"
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 10)
    scroll.add_child(body)
    if sim.status != "active" and ["incidents", "stamps"].has(page):
        page = "results"
    match page:
        "incidents": _incidents(body)
        "stamps": _stamps(body)
        "log": _log(body)
        "evidence": _evidence(body)
        "town": _town(body)
        "cast": _cast(body)
        "settings": _settings(body)
        "ministry": _ministry(body)
        "assignments": _assignments(body)
        "tutorial": _tutorial(body)
        "help": _help(body)
        "results": _results(body)
        _: _incidents(body)
    _bottom_bar(surface)
    # Godot's default STOP filter on buttons and panel wrappers swallows touch
    # drags before they reach the containing ScrollContainer. PASS still lets
    # controls receive taps, but bubbles drag gestures up to the scroller.
    _enable_touch_scroll(body)
    _rendered_page = page
    if restore_offset > 0:
        _restore_scroll_position(scroll, page, restore_offset)

func _debug_native_scroll(offset: float, screen: String) -> void:
    if offset >= 30.0:
        print("MINISTRY_NATIVE_SCROLL page=%s offset=%d" % [screen, roundi(offset)])

func _enable_touch_scroll(node: Node) -> void:
    for child in node.get_children():
        if child is Control:
            (child as Control).mouse_filter = Control.MOUSE_FILTER_PASS
        _enable_touch_scroll(child)

func _restore_scroll_position(scroll: ScrollContainer, screen: String, offset: int) -> void:
    # Wait for Godot's Container layout to calculate the content extent.
    await get_tree().process_frame
    if is_instance_valid(scroll) and scroll.is_inside_tree() and page == screen:
        scroll.scroll_vertical = offset

func _safe_margins() -> Dictionary:
    # Android/iOS safe areas are in physical display pixels; Godot UI operates
    # in scaled logical viewport points. Clamp defensive values for emulators.
    var values: Dictionary = {"left":12,"right":12,"top":14,"bottom":14}
    if not OS.has_feature("mobile"):
        return values
    var full: Vector2i = DisplayServer.window_get_size()
    var safe: Rect2i = DisplayServer.get_display_safe_area()
    if full.x <= 0 or full.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
        return values
    var fx: float = get_viewport_rect().size.x / float(full.x)
    var fy: float = get_viewport_rect().size.y / float(full.y)
    values["left"] = clampi(roundi(float(safe.position.x) * fx) + 12, 12, 85)
    values["right"] = clampi(roundi(float(full.x - safe.end.x) * fx) + 12, 12, 85)
    values["top"] = clampi(roundi(float(safe.position.y) * fy) + 12, 12, 95)
    values["bottom"] = clampi(roundi(float(full.y - safe.end.y) * fy) + 12, 12, 95)
    return values

func _header(parent: VBoxContainer) -> void:
    var panel := _panel(Color("#27464c"), GOLD, 1, 11)
    panel.name = "MobileCaseHeader"
    parent.add_child(panel)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 4)
    panel.add_child(col)
    var top := HBoxContainer.new()
    col.add_child(top)
    var heading := _label("THE MINISTRY OF COINCIDENCES", 16, Color("#f8e8bc"), true)
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(heading)
    var help := _button("?", false, 42)
    help.name = "MobileHelpButton"
    help.custom_minimum_size = Vector2(43, 42)
    help.pressed.connect(_change_page.bind("help"))
    top.add_child(help)
    var settings := _button("♪", false, 42)
    settings.name = "MobileSettingsButton"
    settings.tooltip_text = "Office music and accessibility settings"
    settings.custom_minimum_size = Vector2(43, 42)
    settings.pressed.connect(_change_page.bind("settings"))
    top.add_child(settings)
    col.add_child(_label(str(sim.case_info.get("title", "Official Assignment")), 19, CREAM, true))
    var deadline: int = int(sim.case_info.get("deadline", 7))
    var snapshot: String = "DAY %d / %d    |    %s %d/%d    |    INFLUENCE %d" % [mini(sim.day, deadline), deadline, str(sim.case_info.get("metric", "MOMENTUM")), sim.support, int(sim.case_info.get("required_support", 15)), sim.influence]
    col.add_child(_label(snapshot, 13, Color("#d0c9aa")))
    if sim.status == "active":
        var descriptions: Array[String] = []
        for objective in sim.case_objective_progress():
            descriptions.append(("DONE " if bool(objective["done"]) else "TODO ") + str(objective["label"]))
        col.add_child(_label(" / ".join(PackedStringArray(descriptions)), 12, Color("#ede0be")))
        var achieved: int = 0
        for objective in sim.case_objective_progress():
            if bool(objective.get("done", false)):
                achieved += 1
        col.add_child(_label("OBJECTIVES %d/%d    |    REALITY STRAIN %d/6" % [achieved, sim.case_objective_progress().size(), sim.strain], 13, Color("#e9dbc3")))

func _tabs(parent: VBoxContainer) -> void:
    var nav := HBoxContainer.new()
    nav.name = "MobileTabs"
    nav.add_theme_constant_override("separation", 7)
    parent.add_child(nav)
    for data in [["incidents","1  INCIDENTS"],["stamps","2  STAMPS"],["log","CHRONICLE"]]:
        var id: String = str(data[0])
        var button := _button(str(data[1]), page == id, 48)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.add_theme_font_size_override("font_size", 14)
        button.pressed.connect(_change_page.bind(id))
        nav.add_child(button)

func _incidents(body: VBoxContainer) -> void:
    var available: Array = sim.available_events()
    if selected_event.is_empty() or sim.get_rule(selected_event).is_empty() or not sim._eligible(sim.get_rule(selected_event)):
        selected_event = str(available[0].get("id", "")) if not available.is_empty() else ""
    var limit: int = 2 if sim.has_department("double_booking") else 1
    var filed: int = _filed_count()
    _section(body, "1. CHOOSE AN INCIDENT", "Select something in Oddford to influence. You will stamp it next.")
    body.add_child(_label("%d OF %d FILED  /  Unstamped events may still happen." % [filed, limit], 14, Color("#e9dbc3")))
    var current: Dictionary = sim.get_rule(selected_event)
    if not current.is_empty():
        var featured := _panel(PAPER, GOLD, 2, 12)
        featured.name = "MobileIncidentFeature"
        body.add_child(featured)
        var frame := VBoxContainer.new()
        frame.add_theme_constant_override("separation", 4)
        featured.add_child(frame)
        frame.add_child(_label("UNDER OBSERVATION  /  THE TOWN OF ODDFORD", 13, BURGUNDY, true))
        var picture := TextureRect.new()
        picture.name = "MobileIncidentTown"
        picture.texture = load("res://assets/illustrated/oddford_banner.webp") as Texture2D
        picture.custom_minimum_size.y = 124
        picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        frame.add_child(picture)
        var feature_row := HBoxContainer.new()
        feature_row.add_theme_constant_override("separation", 9)
        frame.add_child(feature_row)
        var image := _art(_family(str(current["id"])), Vector2(86, 86))
        feature_row.add_child(image)
        var caption := VBoxContainer.new()
        caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        caption.add_theme_constant_override("separation", 3)
        feature_row.add_child(caption)
        caption.add_child(_label(str(current["title"]), 19, INK, true))
        caption.add_child(_label(str(current.get("place", "Oddford")), 14, BURGUNDY, true))
        caption.add_child(_label("%d%% NATURAL CHANCE IF ATTEMPTED" % roundi(float(current["chance"]) * 100.0), 14, GREEN, true))
        var actor := TextureRect.new()
        actor.name = "MobileIncidentCharacter"
        actor.texture = load("res://assets/illustrated/portrait_%s.webp" % _portrait_for_event(str(current["id"]))) as Texture2D
        actor.custom_minimum_size = Vector2(70, 82)
        actor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        actor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        feature_row.add_child(actor)
        frame.add_child(_label(str(current["text"]), 15, MUTED))
    if available.is_empty():
        body.add_child(_label("No new incidents are eligible. Advance the day to resolve the town's business.", 17, LIGHT_SUB))
    else:
        body.add_child(_label("AVAILABLE OPPORTUNITIES  /  TAP TO SELECT", 14, LIGHT_ACCENT, true))
        for rule in available:
            var id: String = str(rule["id"])
            var already: bool = id == str(sim.pending.get("target", "")) or id == str(sim.second_pending.get("target", ""))
            var marker: String = "FILED  •  " if already else "SELECTED  •  " if id == selected_event else ""
            var caption: String = "%s%s\n%s  |  %d%% chance if attempted" % [marker, str(rule["title"]), str(rule.get("place", "Oddford")), roundi(float(rule["chance"]) * 100.0)]
            var btn := _button(caption, id == selected_event, 70)
            btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
            btn.name = "MobileIncident_" + id
            btn.pressed.connect(_select_event.bind(id))
            body.add_child(btn)
            if first_focus == null and id == selected_event:
                first_focus = btn

func _stamps(body: VBoxContainer) -> void:
    _section(body, "2. CHOOSE A STAMP", "Pick how to influence the incident. The stamp does nothing until you file it.")
    var rule: Dictionary = sim.get_rule(selected_event)
    if rule.is_empty() or not sim._eligible(rule):
        var events: Array = sim.available_events()
        selected_event = str(events[0]["id"]) if not events.is_empty() else ""
        rule = sim.get_rule(selected_event)
    if not rule.is_empty():
        var choice := _panel(PAPER, GOLD, 2, 11)
        body.add_child(choice)
        var line := HBoxContainer.new()
        line.add_theme_constant_override("separation", 10)
        choice.add_child(line)
        line.add_child(_art(_family(str(rule["id"])), Vector2(83, 83)))
        var text := VBoxContainer.new()
        text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        line.add_child(text)
        text.add_child(_label("TARGET INCIDENT", 13, BURGUNDY, true))
        text.add_child(_label(str(rule["title"]), 19, INK, true))
        text.add_child(_label(str(rule.get("place", "Oddford")), 14, MUTED))
    else:
        body.add_child(_label("There are no eligible incidents. You may advance without a stamp.", 17, LIGHT_SUB))
    var grid := GridContainer.new()
    grid.name = "MobileStampSealGallery"
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    body.add_child(grid)
    for id in Simulation.STAMP_ORDER:
        var stamp: Dictionary = Simulation.STAMPS[id]
        var is_selected: bool = id == selected_stamp
        var tile := _panel(PAPER if is_selected else CREAM, BURGUNDY if is_selected else GOLD, 3 if is_selected else 1, 11)
        tile.name = "MobileStampTile_" + id
        tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        grid.add_child(tile)
        var contents := VBoxContainer.new()
        contents.add_theme_constant_override("separation", 2)
        tile.add_child(contents)
        var seal := TextureRect.new()
        seal.name = "MobileSealArt_" + id
        seal.texture = load("res://assets/illustrated/stamp_%s.webp" % id) as Texture2D
        seal.custom_minimum_size = Vector2(64, 62)
        seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
        contents.add_child(seal)
        var caption: String = "%s%s\n%d Influence / +%d Strain" % ["SELECTED: " if is_selected else "", str(STAMP_LABELS[id]), int(stamp["cost"]), maxi(1, int(stamp["strain"]) - int(sim.profile.get("audit", 0)))]
        var button := _button(caption, is_selected, 64)
        button.name = "MobileStamp_" + id
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.add_theme_font_size_override("font_size", 14)
        button.pressed.connect(_select_stamp.bind(id))
        contents.add_child(button)
    var active: Dictionary = Simulation.STAMPS[selected_stamp]
    var preview := _panel(CREAM, GOLD, 1, 11)
    preview.name = "MobileStampPreview"
    body.add_child(preview)
    var info := VBoxContainer.new()
    preview.add_child(info)
    info.add_child(_label("EXPECTED EFFECT  /  %s" % str(active["name"]).to_upper(), 14, BURGUNDY, true))
    info.add_child(_label(_preview(rule), 17, INK, true))
    info.add_child(_label("Cost on Advance: %d Influence, +%d Reality Strain" % [int(active["cost"]), maxi(1, int(active["strain"]) - int(sim.profile.get("audit", 0)))], 14, MUTED))
    var outlook: String = sim.forecast()
    var forecast := _label("REALITY FORECAST  /  " + outlook, 14, BURGUNDY, true)
    forecast.name = "MobileRealityForecast"
    info.add_child(forecast)
    var status: String = "%d OF %d INCIDENTS FILED TODAY" % [_filed_count(), 2 if sim.has_department("double_booking") else 1]
    info.add_child(_label(status, 14, GREEN, true))
    for pending in [sim.pending, sim.second_pending]:
        if pending.is_empty():
            continue
        var r: Dictionary = sim.get_rule(str(pending.get("target", "")))
        info.add_child(_label("FILED: %s on %s" % [str(Simulation.STAMPS[str(pending["stamp"])]["name"]), str(r.get("title", "incident"))], 14, GREEN))
    if not rule.is_empty() and not _can_file():
        info.add_child(_label(_blocked_reason(rule), 14, BURGUNDY))
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    body.add_child(row)
    var change := _button("CHANGE INCIDENT", false, 54)
    change.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    change.pressed.connect(_change_page.bind("incidents"))
    row.add_child(change)
    var why := _button("WHY THIS INCIDENT?", false, 54)
    why.disabled = rule.is_empty()
    why.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    why.pressed.connect(_show_evidence.bind(selected_event))
    row.add_child(why)

func _log(body: VBoxContainer) -> void:
    _section(body, "THE OFFICIAL CHRONICLE", "WHAT HAPPENED  /  AND WHY")
    var summaries: Array = sim.history_summary(40)
    if summaries.is_empty():
        body.add_child(_label("No incidents yet. The stationery is immaculate.", 17, LIGHT_SUB))
    for entry in summaries:
        var caption: String = "DAY %d  /  %s\n%s" % [int(entry["day"]), str(entry["title"]), str(entry.get("because", ""))]
        var id: String = str(entry.get("id", ""))
        if sim.get_rule(id).is_empty():
            body.add_child(_label(caption, 15, LIGHT_SUB))
        else:
            var btn := _button(caption, false, 66)
            btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
            btn.pressed.connect(_show_evidence.bind(id))
            body.add_child(btn)

func _evidence(body: VBoxContainer) -> void:
    var info: Dictionary = Causal.inspect(sim, evidence_id)
    if info.is_empty():
        _section(body, "NO EVIDENCE FILED", "Return to an eligible incident")
        return
    _section(body, str(info["title"]).to_upper(), "THE MINISTRY'S DOCUMENTED CAUSAL FILE")
    var card := _panel(PAPER, GOLD, 2, 10)
    body.add_child(card)
    var text := VBoxContainer.new()
    card.add_child(text)
    text.add_child(_label(str(info["description"]), 17, INK))
    text.add_child(_label("NATURAL CHANCE: %d%%  /  %s" % [roundi(float(info["chance"])*100.0), "OCCURRED" if bool(info["occurred"]) else "POSSIBLE, NOT CONFIRMED"], 14, GREEN if bool(info["occurred"]) else BURGUNDY, true))
    body.add_child(_label("REQUIRED CONDITIONS", 16, LIGHT_ACCENT, true))
    if (info["conditions"] as Array).is_empty():
        body.add_child(_label("No prerequisites. This can start a chain.", 15, LIGHT_SUB))
    for requirement in info["conditions"]:
        var condition: Dictionary = requirement
        var line: String = "%s  %s [%s]" % ["OK" if bool(condition["met"]) else "MISSING", str(condition["fact"]), str(condition["kind"])]
        if not str(condition.get("source", "")).is_empty():
            line += " - from " + str(condition["source"])
        body.add_child(_label(line, 15, LIGHT_SUCCESS if bool(condition["met"]) else LIGHT_SUB))
    body.add_child(_label("POSSIBLE CONSEQUENCES  /  NOT GUARANTEED", 16, LIGHT_ACCENT, true))
    for output in info["outcomes"]:
        body.add_child(_label("- " + str(output), 15, LIGHT_SUB))
    if not (info["alternative"] as Array).is_empty():
        body.add_child(_label("MISFILE WOULD REPLACE THESE WITH:", 15, LIGHT_ACCENT, true))
        for output in info["alternative"]:
            body.add_child(_label("- " + str(output), 15, LIGHT_SUB))
    var branches: Array = info["branches"]
    body.add_child(_label("MAY HELP ENABLE %d OTHER INCIDENTS" % branches.size(), 16, LIGHT_ACCENT, true))
    for j in range(mini(branches.size(), 16)):
        var downstream: Dictionary = branches[j]
        var desc: String = "%s  /  %s route" % [str(downstream["title"]), str(downstream["route"])]
        if not (downstream["still_needed"] as Array).is_empty():
            desc += "\nStill needs: " + ", ".join(PackedStringArray(downstream["still_needed"]))
        var btn := _button(desc, false, 64)
        btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
        btn.pressed.connect(_show_evidence.bind(str(downstream["id"])))
        body.add_child(btn)
    if bool(info["occurred"]):
        body.add_child(_label("CONFIRMED PARENT EVENTS", 16, LIGHT_SUCCESS, true))
        for parent in info["parents"]:
            body.add_child(_label("- " + str(parent["title"]), 15, LIGHT_SUCCESS))


func _town(body: VBoxContainer) -> void:
    _section(body, "ODDFORD / LIVE SURVEILLANCE", "SIX DISTRICTS  /  REAL INCIDENTS, NOT A SECOND SIMULATION")
    var picture := _panel(PAPER, GOLD, 2, 11)
    body.add_child(picture)
    var map_canvas := Control.new()
    map_canvas.name = "MobileTownMapCanvas"
    map_canvas.custom_minimum_size.y = 230
    map_canvas.clip_contents = true
    picture.add_child(map_canvas)
    var map := TextureRect.new()
    map.name = "MobileInteractiveTownImage"
    map.texture = load("res://assets/illustrated/oddford_square.webp") as Texture2D
    map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    map.mouse_filter = Control.MOUSE_FILTER_IGNORE
    map_canvas.add_child(map)
    # These are the exact six district positions used by LivingTown on desktop.
    # The pins are touch targets; a text list below remains available.
    var district_points := [Vector2(.51, .54), Vector2(.89, .57), Vector2(.17, .54), Vector2(.38, .77), Vector2(.69, .77), Vector2(.46, .38)]
    for i in range(TOWN_LOCATIONS.size()):
        var place: String = TOWN_LOCATIONS[i]
        var pin := _button(["TH", "BK", "PO", "HS", "PG", "PH"][i], place == selected_town_location, 44)
        pin.name = "MobileTownPin_" + place.replace(" ", "")
        pin.tooltip_text = place
        pin.add_theme_font_size_override("font_size", 14)
        pin.add_theme_color_override("font_color", CREAM)
        var seal_style := StyleBoxFlat.new()
        seal_style.bg_color = BURGUNDY if place == selected_town_location else Color("#30484ce8")
        seal_style.border_color = GOLD
        seal_style.set_border_width_all(2)
        seal_style.set_corner_radius_all(24)
        seal_style.set_content_margin_all(2)
        pin.add_theme_stylebox_override("normal", seal_style)
        var hover_seal := seal_style.duplicate() as StyleBoxFlat
        hover_seal.bg_color = BURGUNDY
        pin.add_theme_stylebox_override("hover", hover_seal)
        pin.add_theme_stylebox_override("pressed", hover_seal)
        pin.add_theme_stylebox_override("focus", hover_seal)
        pin.anchor_left = district_points[i].x
        pin.anchor_right = district_points[i].x
        pin.anchor_top = district_points[i].y
        pin.anchor_bottom = district_points[i].y
        pin.offset_left = -22
        pin.offset_right = 22
        pin.offset_top = -22
        pin.offset_bottom = 22
        pin.pressed.connect(_select_town_location.bind(place))
        map_canvas.add_child(pin)
    body.add_child(_label("VISIT A DISTRICT  /  TAP TO INSPECT ITS LIVE FILE", 14, LIGHT_ACCENT, true))
    var districts := GridContainer.new()
    districts.name = "MobileTownDistricts"
    districts.columns = 2
    districts.add_theme_constant_override("h_separation", 7)
    districts.add_theme_constant_override("v_separation", 7)
    body.add_child(districts)
    for place in TOWN_LOCATIONS:
        var waiting: int = 0
        for rule in sim.available_events():
            if str(rule.get("place", "")) == place:
                waiting += 1
        var nameplate := _button("%s\n%d AVAILABLE" % [place.to_upper(), waiting], place == selected_town_location, 62)
        nameplate.name = "MobileTownLocation" + place.replace(" ", "")
        nameplate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        nameplate.pressed.connect(_select_town_location.bind(place))
        districts.add_child(nameplate)
    var docket := _panel(CREAM, GOLD, 2, 11)
    docket.name = "MobileTownWitnessDocket"
    body.add_child(docket)
    var details := VBoxContainer.new()
    details.add_theme_constant_override("separation", 7)
    docket.add_child(details)
    details.add_child(_label("LOCAL OFFICE  /  " + selected_town_location.to_upper(), 18, BURGUNDY, true))
    var available: int = 0
    for rule in sim.available_events():
        if str(rule.get("place", "")) != selected_town_location:
            continue
        available += 1
        var entry := HBoxContainer.new()
        entry.add_theme_constant_override("separation", 8)
        details.add_child(entry)
        entry.add_child(_art(_family(str(rule["id"])), Vector2(74, 74)))
        var file := VBoxContainer.new()
        file.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        entry.add_child(file)
        file.add_child(_label(str(rule["title"]), 17, INK, true))
        file.add_child(_label("%d%% chance if attempted" % roundi(float(rule["chance"]) * 100.0), 14, GREEN))
        file.add_child(_label(str(rule["text"]), 14, MUTED))
        var select := _button("CHOOSE THIS INCIDENT", true, 52)
        select.name = "MobileTownChoose_" + str(rule["id"])
        select.disabled = sim.status != "active"
        select.pressed.connect(_select_town_incident.bind(str(rule["id"])))
        file.add_child(select)
        var inspect := _button("INSPECT ITS CAUSES", false, 48)
        inspect.pressed.connect(_show_evidence.bind(str(rule["id"])))
        file.add_child(inspect)
    if available == 0:
        details.add_child(_label("No available incidents here. An earlier coincidence may open a new route.", 15, MUTED))
    var latest: Array = []
    for entry in sim.history_summary(40):
        var rule: Dictionary = sim.get_rule(str(entry.get("id", "")))
        if str(rule.get("place", "")) == selected_town_location:
            latest.append(entry)
        if latest.size() >= 4:
            break
    body.add_child(_label("RECORDED IN THIS DISTRICT  /  " + str(latest.size()) + " RECENT FILES", 14, LIGHT_ACCENT, true))
    if latest.is_empty():
        body.add_child(_label("No recorded incidents here yet.", 15, LIGHT_SUB))
    for entry in latest:
        var item := _button("DAY %d  /  %s\n%s" % [int(entry["day"]), str(entry["title"]), str(entry.get("because", ""))], false, 70)
        item.alignment = HORIZONTAL_ALIGNMENT_LEFT
        item.pressed.connect(_show_evidence.bind(str(entry["id"])))
        body.add_child(item)
    var archived_day: int = _last_recorded_day()
    var replay := _button("REPLAY DAY %d / ACTUAL RECORDED EVENTS" % archived_day if archived_day > 0 else "NO RECORDED DAY TO REPLAY", true, 58)
    replay.name = "MobileTownReplayButton"
    replay.disabled = archived_day == 0
    replay.pressed.connect(_open_town_replay)
    body.add_child(replay)
    var cast := _button("MEET ODDFORD'S RESIDENTS", false, 56)
    cast.name = "MobileTownResidentsButton"
    cast.pressed.connect(_change_page.bind("cast"))
    body.add_child(cast)

func _select_town_location(place: String) -> void:
    selected_town_location = place
    _render()
    # Bring the new witness report into view on a phone instead of leaving
    # players staring at the top of a long map after tapping a district.
    var scroll := find_child("MobileContentScroll", true, false) as ScrollContainer
    var docket := find_child("MobileTownWitnessDocket", true, false) as Control
    if scroll != null and docket != null:
        await get_tree().process_frame
        if is_instance_valid(scroll) and is_instance_valid(docket):
            scroll.ensure_control_visible(docket)

func _select_town_incident(id: String) -> void:
    selected_event = id
    _change_page("stamps")

func _last_recorded_day() -> int:
    for i in range(sim.history.size() - 1, -1, -1):
        var event: Dictionary = sim.history[i]
        var id: String = str(event.get("id", ""))
        if not sim.get_rule(id).is_empty() or id.begins_with("correction_"):
            return int(event.get("day", 0))
    return 0

func _open_town_replay() -> void:
    var archived_day: int = _last_recorded_day()
    if archived_day == 0:
        return
    var real_events: Array = []
    for event in sim.history:
        var id: String = str(event.get("id", ""))
        if int(event.get("day", 0)) == archived_day and (not sim.get_rule(id).is_empty() or id.begins_with("correction_")):
            real_events.append(event)
    if real_events.is_empty():
        return
    theater = MobileTheater.new()
    # Historical filings and intermediate Strain are not saved; never invent
    # those values or present the replay as an unstamped/natural-only day.
    theater.configure(sim, real_events, [], archived_day, sim.support, sim.support, sim.strain, sim.strain, true)
    theater.close_requested.connect(_close_theater)
    theater.log_requested.connect(_open_theater_log)
    theater.inspect_requested.connect(_open_theater_evidence)
    add_child(theater)

func _cast(body: VBoxContainer) -> void:
    _section(body, "REGISTER OF PECULIAR RESIDENTS", "THE ILLUSTRATED CAST OF ODDFORD")
    var gallery := GridContainer.new()
    gallery.name = "MobileCastGallery"
    gallery.columns = 2
    gallery.add_theme_constant_override("h_separation", 9)
    gallery.add_theme_constant_override("v_separation", 9)
    body.add_child(gallery)
    for person in RESIDENTS:
        var panel := _panel(CREAM, GOLD, 2, 10)
        panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        gallery.add_child(panel)
        var frame := VBoxContainer.new()
        frame.add_theme_constant_override("separation", 4)
        panel.add_child(frame)
        var portrait := TextureRect.new()
        portrait.name = "MobileResident_" + str(person[0])
        portrait.texture = load("res://assets/illustrated/portrait_%s.webp" % str(person[0])) as Texture2D
        portrait.custom_minimum_size.y = 154
        portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        frame.add_child(portrait)
        var title := _label(str(person[1]), 15, BURGUNDY, true)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        frame.add_child(title)
    var return_to_town := _button("BACK TO ODDFORD", true, 56)
    return_to_town.pressed.connect(_change_page.bind("town"))
    body.add_child(return_to_town)

func _settings(body: VBoxContainer) -> void:
    _section(body, "OFFICE SETTINGS", "THE SAME AUDIO AND ACCESSIBILITY PREFERENCES AS DESKTOP")
    var director := get_node_or_null("/root/MusicDirector")
    var music := _panel(CREAM, GOLD, 2, 10)
    body.add_child(music)
    var controls := VBoxContainer.new()
    music.add_child(controls)
    controls.add_child(_label("ODDFORD'S ORIGINAL WALTZ", 18, BURGUNDY, true))
    if director == null:
        controls.add_child(_label("Audio controls are not available in this environment.", 15, MUTED))
    else:
        var enabled: bool = bool(director.get("music_enabled"))
        var volume: int = roundi(float(director.get("music_volume")) * 100.0)
        var toggle := _button("MUSIC: ON" if enabled else "MUSIC: OFF", enabled, 56)
        toggle.name = "MobileMusicToggle"
        toggle.pressed.connect(_toggle_music)
        controls.add_child(toggle)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        controls.add_child(row)
        var quieter := _button("QUIETER", false, 54)
        quieter.name = "MobileMusicVolumeDown"
        quieter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        quieter.disabled = volume == 0
        quieter.pressed.connect(_adjust_music.bind(-0.10))
        row.add_child(quieter)
        var louder := _button("LOUDER", false, 54)
        louder.name = "MobileMusicVolumeUp"
        louder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        louder.disabled = volume == 100
        louder.pressed.connect(_adjust_music.bind(0.10))
        row.add_child(louder)
        controls.add_child(_label("MUSIC VOLUME  /  %d%%" % volume, 15, MUTED, true))
    var cfg := ConfigFile.new()
    var reduced: bool = false
    if cfg.load("user://ministry_visuals.cfg") == OK:
        reduced = bool(cfg.get_value("accessibility", "reduced_motion", false))
    var motion := _button("REDUCED MOTION: ON" if reduced else "REDUCED MOTION: OFF", reduced, 56)
    motion.name = "MobileReducedMotionToggle"
    motion.pressed.connect(_toggle_reduced_motion)
    body.add_child(motion)
    body.add_child(_label("When enabled, Causality Theater shows the entire register without pans or animated reveals. This preference is saved on this device.", 15, LIGHT_SUB))

func _toggle_music() -> void:
    var director := get_node_or_null("/root/MusicDirector")
    if director == null:
        return
    director.call("set_music_enabled", not bool(director.get("music_enabled")))
    _render()

func _adjust_music(delta: float) -> void:
    var director := get_node_or_null("/root/MusicDirector")
    if director == null:
        return
    director.call("set_music_volume", float(director.get("music_volume")) + delta)
    _render()

func _toggle_reduced_motion() -> void:
    var cfg := ConfigFile.new()
    cfg.load("user://ministry_visuals.cfg")
    cfg.set_value("accessibility", "reduced_motion", not bool(cfg.get_value("accessibility", "reduced_motion", false)))
    cfg.save("user://ministry_visuals.cfg")
    _render()
func _results(body: VBoxContainer) -> void:
    _section(body, "CASE CLOSED" if sim.status == "won" else "CASE FILED AS INCOMPLETE", str(sim.last_outcome))
    var portrait := TextureRect.new()
    portrait.texture = load("res://assets/illustrated/portrait_%s.webp" % str(sim.case_info["portrait"])) as Texture2D
    portrait.custom_minimum_size.y = 195
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    body.add_child(portrait)
    body.add_child(_label("MERIT AVAILABLE: %d   /   CASES FILED: %d" % [int(sim.profile["merit"]), int(sim.profile["completed"])], 17, LIGHT_SUCCESS, true))
    for kind in ["desk", "ink", "audit"]:
        var price: int = sim.upgrade_cost(kind)
        var level: int = int(sim.profile[kind])
        var label: String = "%s  LV %d  /  %d MERIT" % [kind.to_upper(), level, price]
        var buy := _button(label, false, 56)
        buy.disabled = level >= 3 or int(sim.profile["merit"]) < price
        buy.pressed.connect(_buy_upgrade.bind(kind))
        body.add_child(buy)
    var offices := _button("REORGANIZE DEPARTMENTS", false, 56)
    offices.pressed.connect(_change_page.bind("ministry"))
    body.add_child(offices)
    var cases := _button("CHOOSE THE NEXT CASE", true, 60)
    cases.pressed.connect(_change_page.bind("assignments"))
    body.add_child(cases)


func _ministry(body: VBoxContainer) -> void:
    _section(body, "THE MINISTRY / ORGANIZATIONAL CHART", "LICENSE OFFICES PERMANENTLY  /  ASSIGN THEM BETWEEN CASES")
    var masthead := _panel(PAPER, GOLD, 2, 10)
    body.add_child(masthead)
    var heading := HBoxContainer.new()
    heading.add_theme_constant_override("separation", 10)
    masthead.add_child(heading)
    var seal := TextureRect.new()
    seal.texture = load("res://assets/seal.svg") as Texture2D
    seal.custom_minimum_size = Vector2(62, 62)
    seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    heading.add_child(seal)
    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.add_child(info)
    info.add_child(_label(sim.rank_title(), 17, BURGUNDY, true))
    info.add_child(_label("%d MERIT  /  %d OF %d OFFICES ASSIGNED" % [int(sim.profile["merit"]), (sim.profile["equipped"] as Array).size(), sim.department_slots()], 14, GREEN, true))
    body.add_child(_label("Effects are locked when a case starts. Only selected offices run; shared automatic approvals are limited.", 15, LIGHT_SUB))
    var faces: Array[String] = ["clerk", "reporter", "mayor", "organizer", "clerk", "reporter", "baker", "reporter", "mayor", "gerald", "organizer", "gerald"]
    for index in range(Departments.ORDER.size()):
        var id: String = str(Departments.ORDER[index])
        var spec: Dictionary = Departments.get_department(id)
        var owned: bool = sim.department_owned(id)
        var equipped: bool = (sim.profile["equipped"] as Array).has(id)
        var active: bool = sim.has_department(id)
        var panel := _panel(CREAM if owned else PAPER, GREEN if equipped else GOLD, 3 if equipped else 1, 10)
        panel.name = "MobileDepartmentDossier_" + id
        body.add_child(panel)
        var col := VBoxContainer.new()
        col.add_theme_constant_override("separation", 4)
        panel.add_child(col)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 9)
        col.add_child(row)
        var portrait := TextureRect.new()
        portrait.name = "MobileDepartmentPortrait_" + id
        portrait.texture = load("res://assets/illustrated/portrait_%s.webp" % faces[index]) as Texture2D
        portrait.custom_minimum_size = Vector2(81, 87)
        portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        row.add_child(portrait)
        var detail := VBoxContainer.new()
        detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(detail)
        detail.add_child(_label(str(spec["name"]), 18, INK, true))
        detail.add_child(_label("ACTIVE IN THIS CASE" if active else "ASSIGNED TO NEXT CASE" if equipped else "LICENSED / STANDBY" if owned else "UNLICENSED", 13, GREEN if active or equipped else BURGUNDY, true))
        detail.add_child(_label(str(spec["detail"]), 14, MUTED))
        if not owned:
            detail.add_child(_label("%d MERIT  /  FILE %d CASES TO UNLOCK" % [int(spec["cost"]), int(spec["cases"])], 13, BURGUNDY))
        var action_caption := "REMOVE OFFICE" if equipped else "ASSIGN OFFICE" if owned else "BUY DEPARTMENT LICENSE"
        var action := _button(action_caption, equipped, 53)
        action.name = "MobileDepartmentAction_" + id
        action.disabled = sim.status == "active" or (not owned and (int(sim.profile["completed"]) < int(spec["cases"]) or int(sim.profile["merit"]) < int(spec["cost"]))) or (owned and not equipped and (sim.profile["equipped"] as Array).size() >= sim.department_slots())
        action.pressed.connect(_department_action.bind(id))
        col.add_child(action)

func _assignments(body: VBoxContainer) -> void:
    _section(body, "THE MINISTRY / INCOMING ASSIGNMENTS", "FOUR REAL CASE FILES  /  SELECT YOUR NEXT SHIFT")
    body.add_child(_label("Your selected departments and upgrades are locked into the next case when it begins.", 15, LIGHT_SUB))
    for id in Cases.ORDER:
        var details: Dictionary = Cases.description(str(id))
        var unlocked: bool = sim.case_unlocked(str(id))
        var panel := _panel(CREAM, GREEN if unlocked else GOLD, 2 if unlocked else 1, 11)
        panel.name = "MobileAssignmentDossier_" + str(id)
        body.add_child(panel)
        var col := VBoxContainer.new()
        col.add_theme_constant_override("separation", 7)
        panel.add_child(col)
        col.add_child(_label(str(details["title"]).to_upper(), 20, INK, true))
        col.add_child(_label(str(details["brief"]), 15, MUTED))
        var story := HBoxContainer.new()
        story.add_theme_constant_override("separation", 9)
        col.add_child(story)
        var portrait := TextureRect.new()
        portrait.name = "MobileAssignmentPortrait_" + str(id)
        portrait.texture = load("res://assets/illustrated/portrait_%s.webp" % str(details["portrait"])) as Texture2D
        portrait.custom_minimum_size = Vector2(95, 107)
        portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        story.add_child(portrait)
        var plan := VBoxContainer.new()
        plan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        story.add_child(plan)
        plan.add_child(_label("%s  /  %d DAYS" % [str(details["difficulty"]), int(details["deadline"])], 14, BURGUNDY, true))
        plan.add_child(_label("MUST COMPLETE: " + ", ".join(PackedStringArray(details["requirement_labels"])), 14, MUTED))
        plan.add_child(_label("+%d BONUS MERIT ON SUCCESS" % int(details["merit_bonus"]), 14, GREEN, true))
        var illustration := TextureRect.new()
        illustration.name = "MobileAssignmentIllustration_" + str(id)
        illustration.texture = load("res://assets/illustrated/%s.webp" % str(details["illustration"])) as Texture2D
        illustration.custom_minimum_size.y = 120
        illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        col.add_child(illustration)
        var start := _button("START CASE" if unlocked else "LOCKED  /  FILE %d CASES TO UNLOCK" % int(details["unlock_cases"]), unlocked, 57)
        start.name = "MobileAssignmentChoose_" + str(id)
        start.disabled = not unlocked or sim.status == "active"
        start.pressed.connect(_start_case.bind(str(id)))
        col.add_child(start)
func _tutorial(body: VBoxContainer) -> void:
    _section(body, "MISS QUILL'S FIRST-DAY BRIEFING", "FOUR ACTUAL PRACTICE ACTIONS  /  YOUR CASE AND MERIT ARE UNTOUCHED")
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 9)
    body.add_child(row)
    var portrait := TextureRect.new()
    portrait.texture = load("res://assets/illustrated/portrait_clerk.webp") as Texture2D
    portrait.custom_minimum_size = Vector2(104, 136)
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    row.add_child(portrait)
    var introduction := VBoxContainer.new()
    introduction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(introduction)
    introduction.add_child(_label("FORM %d OF 4" % (tutorial_step + 1), 15, LIGHT_ACCENT, true))
    var titles: Array[String] = ["WELCOME, PROBATIONARY CLERK", "STEP 1 / FILE A NUDGE", "STEP 2 / ADVANCE THE PRACTICE DAY", "STEP 3 / INSPECT THE EVIDENCE"]
    introduction.add_child(_label(titles[tutorial_step], 19, LIGHT_TEXT, true))
    introduction.add_child(_label("Your real assignment stays open. Nothing in this practice spends your Influence, Merit or upgrades.", 14, LIGHT_SUB))
    if tutorial_step == 0:
        body.add_child(_label("Your job is to engineer unlikely coincidences. You cannot simply appoint a goose as mayor. Regulations are quite specific.", 17, LIGHT_SUB))
        body.add_child(_label("You'll nudge a real simulated incident, advance a separate seeded day, then read the recorded consequences.", 16, LIGHT_SUB))
    else:
        var incident: Dictionary = practice.get_rule("sandwich") if practice != null else {}
        var sheet := _panel(CREAM, GOLD, 2, 10)
        body.add_child(sheet)
        var col := VBoxContainer.new()
        sheet.add_child(col)
        var image := _art("sandwich", Vector2(110, 94))
        col.add_child(image)
        col.add_child(_label(str(incident.get("title", "The Sandwich Incident")), 19, INK, true))
        col.add_child(_label("%d%% NATURAL CHANCE IF ATTEMPTED" % roundi(float(incident.get("chance", 0.0)) * 100.0), 14, GREEN, true))
        if tutorial_step == 1:
            col.add_child(_label("File a Nudge. It raises the chance of the incident, but does not guarantee it. The separate practice file will pay its own Influence cost when the day advances.", 16, MUTED))
            var seal := TextureRect.new()
            seal.texture = load("res://assets/illustrated/stamp_nudge.webp") as Texture2D
            seal.custom_minimum_size.y = 75
            seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            col.add_child(seal)
        elif tutorial_step == 2:
            col.add_child(_label("FILED: NUDGE ON " + str(incident.get("title", "incident")), 16, GREEN, true))
            col.add_child(_label("Advance this practice day to let the actual seeded simulation resolve incidents, update facts and follow causal links.", 16, MUTED))
        else:
            col.add_child(_label("THE REGISTER ACTUALLY RECORDED:", 14, GREEN, true))
            var listed: int = 0
            for event in practice.history:
                if (event.get("facts", []) as Array).is_empty():
                    continue
                var sentence: String = str(event["title"])
                var causes: Array = event.get("causes", [])
                if not causes.is_empty():
                    var sources: Array[String] = []
                    for id in causes:
                        sources.append(Causal._event_name(practice, str(id)))
                    sentence += "\nCAUSED BY  /  " + ", ".join(PackedStringArray(sources))
                col.add_child(_label(sentence, 15, INK))
                listed += 1
                if listed >= 5:
                    break
            if listed == 0:
                col.add_child(_label("No confirmed incidents on this day. The stamp was only a probability adjustment.", 15, MUTED))
            col.add_child(_label("Inspect real cases with WHY? and the Chronicle. Possible follow-ups are not confirmed facts.", 15, MUTED))
    var buttons: Array[String] = ["START PRACTICE", "FILE THE PRACTICE NUDGE", "ADVANCE PRACTICE DAY", "RETURN TO MY CASE"]
    var action := _button(buttons[tutorial_step], true, 60)
    action.name = "MobilePracticeAction"
    action.pressed.connect(_next_tutorial)
    body.add_child(action)
func _help(body: VBoxContainer) -> void:
    _section(body, "HOW TO FILE A COINCIDENCE", "YOUR TEN-SECOND MANUAL")
    body.add_child(_label("1. Choose up to 1 incident to influence (2 with Double Booking). Other incidents still happen.", 17, LIGHT_SUB))
    body.add_child(_label("2. Choose Nudge, Misfile, Delay, or Domino, then FILE. This only queues your action.", 17, LIGHT_SUB))
    body.add_child(_label("3. Advance the day. Watch Causality Theater, then investigate genuine links in the Chronicle.", 17, LIGHT_SUB))
    body.add_child(_label("4. Win or lose, earn Merit to buy permanent causal departments after the case.", 17, LIGHT_SUB))
    var tutorial := _button("REPLAY MISS QUILL'S BRIEFING", true, 54)
    tutorial.pressed.connect(_change_page.bind("tutorial"))
    body.add_child(tutorial)
    var town := _button("VIEW ODDFORD", false, 54)
    town.pressed.connect(_change_page.bind("town"))
    body.add_child(town)
    var residents := _button("MEET THE RESIDENTS", false, 54)
    residents.pressed.connect(_change_page.bind("cast"))
    body.add_child(residents)
    var settings := _button("MUSIC AND ACCESSIBILITY", false, 54)
    settings.pressed.connect(_change_page.bind("settings"))
    body.add_child(settings)

func _bottom_bar(parent: VBoxContainer) -> void:
    # Keep the selected incident and filed stamp visible next to the real action.
    # Never make players hunt for FILE inside a long scroll while ADVANCE is sticky.
    if sim.status == "active" and page == "stamps":
        var ribbon := _panel(PAPER, GOLD, 2, 8)
        ribbon.name = "MobileFilingRibbon"
        parent.add_child(ribbon)
        var info := VBoxContainer.new()
        info.add_theme_constant_override("separation", 2)
        ribbon.add_child(info)
        if _filed_count() == 0:
            var target: Dictionary = sim.get_rule(selected_event)
            info.add_child(_label("YOUR INCIDENT: " + str(target.get("title", "Choose an incident")), 15, INK, true))
            info.add_child(_label("YOUR STAMP: %s  •  NOT YET FILED" % str(STAMP_LABELS[selected_stamp]), 14, BURGUNDY, true))
            if not target.is_empty():
                info.add_child(_label(_preview(target), 13, MUTED))
        else:
            info.add_child(_label("%d STAMP%s FILED FOR TODAY" % [_filed_count(), "" if _filed_count() == 1 else "S"], 14, GREEN, true))
            for filing in [sim.pending, sim.second_pending]:
                if filing.is_empty():
                    continue
                var rule: Dictionary = sim.get_rule(str(filing.get("target", "")))
                var label: String = "%s → %s" % [str(Simulation.STAMPS[str(filing["stamp"])]["name"]), str(rule.get("title", "incident"))]
                info.add_child(_label(label, 14, INK, true))
    if not feedback.is_empty() and page != "stamps":
        var note := _label(feedback, 14, Color("#f5dba5"))
        note.name = "MobileFeedback"
        parent.add_child(note)
    # Full-width vertical actions prevent the secondary button collapsing to
    # a zero-width strip and inflating both buttons to hundreds of pixels tall.
    var footer: BoxContainer = VBoxContainer.new() if sim.status == "active" and page == "stamps" else HBoxContainer.new()
    footer.name = "MobileActionFooter"
    footer.size_flags_vertical = Control.SIZE_SHRINK_END
    footer.add_theme_constant_override("separation", 8)
    parent.add_child(footer)
    if sim.status == "active" and page == "incidents":
        var proceed := _button("NEXT: CHOOSE A STAMP", true, 60)
        proceed.name = "MobileContinueToStamp"
        proceed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        proceed.disabled = selected_event.is_empty()
        proceed.pressed.connect(_change_page.bind("stamps"))
        footer.add_child(proceed)
        var town := _button("TOWN", false, 60)
        town.pressed.connect(_change_page.bind("town"))
        footer.add_child(town)
    elif sim.status == "active" and page == "stamps":
        if confirm_unstamped_day and _filed_count() == 0:
            var confirm := _button("CONFIRM: NO STAMP TODAY", true, 60)
            confirm.name = "MobileConfirmEmptyDayButton"
            confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            confirm.pressed.connect(_advance_day)
            footer.add_child(confirm)
            var cancel := _button("CANCEL", false, 44)
            cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            cancel.pressed.connect(_cancel_unstamped_day)
            footer.add_child(cancel)
        elif _filed_count() == 0:
            var file := _button("FILE %s ON THIS INCIDENT" % str(STAMP_LABELS[selected_stamp]), true, 62)
            file.name = "MobileFileStampButton"
            file.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            file.disabled = not _can_file()
            file.pressed.connect(_file_stamp)
            footer.add_child(file)
            var skip := _button("LET THIS DAY PASS WITHOUT A STAMP", false, 44)
            skip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            skip.name = "MobileSkipFilingButton"
            skip.pressed.connect(_arm_unstamped_day)
            footer.add_child(skip)
        else:
            var advance := _button("ADVANCE DAY  /  %d FILED" % _filed_count(), true, 64)
            advance.name = "MobileAdvanceDayButton"
            advance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            advance.pressed.connect(_advance_day)
            footer.add_child(advance)
            var undo := _button("UNDO FILED STAMP", false, 44)
            undo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            undo.name = "MobileUndoButton"
            undo.pressed.connect(_undo)
            footer.add_child(undo)
            if sim.has_department("double_booking") and _filed_count() == 1:
                var second := _button("CHOOSE A SECOND INCIDENT", false, 52)
                second.name = "MobileSecondIncidentButton"
                second.pressed.connect(_change_page.bind("incidents"))
                parent.add_child(second)
    elif page == "log":
        var back := _button("BACK TO INCIDENTS" if sim.status == "active" else "BACK TO RESULTS", true, 60)
        back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        back.pressed.connect(_change_page.bind("incidents" if sim.status == "active" else "results"))
        footer.add_child(back)
    elif page == "evidence":
        var back := _button("BACK TO CASE", true, 60)
        back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        back.pressed.connect(_change_page.bind("incidents" if sim.status == "active" else "results"))
        footer.add_child(back)
    elif page == "tutorial":
        var skip := _button("SKIP BRIEFING / RETURN TO CASE", true, 60)
        skip.name = "MobileSkipBriefingFooter"
        skip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        skip.pressed.connect(_finish_tutorial)
        footer.add_child(skip)
    elif ["help", "town", "cast", "settings"].has(page):
        var back := _button("BACK TO CASE", true, 60)
        back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        back.pressed.connect(_change_page.bind("incidents" if sim.status == "active" else "results"))
        footer.add_child(back)
    elif ["ministry", "assignments"].has(page):
        var back := _button("BACK TO RESULTS", true, 60)
        back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        back.pressed.connect(_change_page.bind("results"))
        footer.add_child(back)
    elif page == "results":
        var another := _button("CHOOSE NEXT CASE", true, 60)
        another.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        another.pressed.connect(_change_page.bind("assignments"))
        footer.add_child(another)

func _filed_count() -> int:
    return int(not sim.pending.is_empty()) + int(not sim.second_pending.is_empty())

func _can_file() -> bool:
    if selected_event.is_empty() or sim.status != "active":
        return false
    if not sim.has_department("double_booking") and _filed_count() >= 1:
        # Single-stamp clerks may deliberately replace a filed choice.
        return sim.can_stamp(selected_stamp, selected_event)
    if sim.has_department("double_booking") and _filed_count() >= 2:
        return false
    return sim.can_stamp(selected_stamp, selected_event)

func _blocked_reason(rule: Dictionary) -> String:
    if rule.is_empty():
        return "Select an available incident first."
    if sim.has_department("double_booking") and _filed_count() >= 2:
        return "Both interventions are filed. Undo them to choose again."
    if selected_stamp == "misfile" and (rule["misfile_facts"] as Array).is_empty():
        return "This incident has no alternate outcome for Misfile."
    if sim.has_department("double_booking") and str(sim.pending.get("target", "")) == selected_event:
        return "Double Booking requires two different incidents."
    var required: int = int(Simulation.STAMPS[selected_stamp]["cost"])
    if sim.has_department("double_booking") and not sim.pending.is_empty():
        required += int(Simulation.STAMPS[str(sim.pending["stamp"])]["cost"])
    if sim.influence < required:
        return "Not enough Influence: %d required, %d available." % [required, sim.influence]
    return "This stamp can't be filed on this incident."

func _preview(rule: Dictionary) -> String:
    if rule.is_empty():
        return "No incident selected."
    var chance: float = float(rule["chance"])
    var before: int = roundi(chance * 100.0)
    match selected_stamp:
        "nudge": return "%d%% -> %d%% if attempted today. Not guaranteed." % [before, roundi(minf(.98, chance + .55) * 100.0)]
        "misfile":
            if (rule["misfile_facts"] as Array).is_empty():
                return "No alternative result available."
            return "%d%% -> %d%%; swaps in the alternate outcome." % [before, roundi(minf(.98, chance + .40) * 100.0)]
        "reschedule": return "Defer until tomorrow. Guaranteed if still eligible."
        "domino": return "%d%% -> %d%%; first eligible follow-up guaranteed if the incident fires." % [before, roundi(minf(.98, chance + .25) * 100.0)]
    return ""

func _select_event(id: String) -> void:
    selected_event = id
    confirm_unstamped_day = false
    feedback = ""
    _render()

func _select_stamp(id: String) -> void:
    selected_stamp = id
    confirm_unstamped_day = false
    feedback = ""
    _render()

func _change_page(id: String) -> void:
    page = id
    feedback = ""
    _render()

func _show_evidence(id: String) -> void:
    evidence_id = id
    _change_page("evidence")

func _file_stamp() -> void:
    if not _can_file():
        feedback = _blocked_reason(sim.get_rule(selected_event))
        _render()
        return
    if sim.stage_stamp(selected_stamp, selected_event):
        confirm_unstamped_day = false
        var rule: Dictionary = sim.get_rule(selected_event)
        feedback = "FILED: %s on %s." % [str(Simulation.STAMPS[selected_stamp]["name"]), str(rule.get("title", "incident"))]
        var audio := get_node_or_null("/root/MusicDirector")
        if audio != null:
            audio.call("play_stamp_effect")
    else:
        feedback = _blocked_reason(sim.get_rule(selected_event))
    _render()

func _undo() -> void:
    sim.clear_stamp()
    confirm_unstamped_day = false
    feedback = "Today's filings have been cleared."
    _render()

func _arm_unstamped_day() -> void:
    if _filed_count() > 0:
        return
    confirm_unstamped_day = true
    feedback = "You will let Oddford run without an intervention."
    _render()

func _cancel_unstamped_day() -> void:
    confirm_unstamped_day = false
    feedback = ""
    _render()

func _advance_day() -> void:
    if sim.status != "active":
        return
    # No filing may resolve silently. The separate no-stamp button must
    # explicitly arm and confirm an unstamped day.
    if _filed_count() == 0 and not confirm_unstamped_day:
        _arm_unstamped_day()
        return
    confirm_unstamped_day = false
    var old_count: int = sim.history.size()
    var day: int = sim.day
    var old_support: int = sim.support
    var old_strain: int = sim.strain
    var filings: Array = []
    for filing in [sim.pending, sim.second_pending]:
        if not filing.is_empty():
            filings.append(filing.duplicate(true))
    sim.advance_day()
    var recorded: Array = []
    for event in sim.history.slice(old_count):
        var id: String = str(event.get("id", ""))
        if not sim.get_rule(id).is_empty() or id.begins_with("correction_"):
            recorded.append(event)
    feedback = ""
    page = "incidents" if sim.status == "active" else "results"
    selected_event = ""
    _render()
    theater = MobileTheater.new()
    theater.configure(sim, recorded, filings, day, old_support, sim.support, old_strain, sim.strain)
    theater.close_requested.connect(_close_theater)
    theater.log_requested.connect(_open_theater_log)
    theater.inspect_requested.connect(_open_theater_evidence)
    add_child(theater)

func _close_theater() -> void:
    if theater == null:
        return
    theater.queue_free()
    theater = null
    _render()

func _open_theater_log() -> void:
    if theater != null:
        theater.queue_free()
        theater = null
    page = "log"
    _render()

func _open_theater_evidence(id: String) -> void:
    if theater != null:
        theater.queue_free()
        theater = null
    _show_evidence(id)

func _buy_upgrade(kind: String) -> void:
    feedback = "Purchase approved." if sim.buy_upgrade(kind) else "Not enough Merit or already at the maximum level."
    _render()

func _department_action(id: String) -> void:
    var ok: bool = sim.toggle_department(id) if sim.department_owned(id) else sim.buy_department(id)
    feedback = "Ministry organization updated." if ok else "Purchase or reassignment is currently unavailable."
    _render()

func _start_case(id: String) -> void:
    if not sim.start_new_run(-1, id):
        feedback = "Case locked. File more assignments first."
        _render()
        return
    selected_event = ""
    selected_stamp = "nudge"
    confirm_unstamped_day = false
    feedback = "New assignment accepted."
    page = "incidents"
    _render()


func _next_tutorial() -> void:
    match tutorial_step:
        0:
            practice = Simulation.new(1, false)
            tutorial_step = 1
        1:
            if practice == null or not practice.stage_stamp("nudge", "sandwich"):
                feedback = "The practice stamp could not be filed."
                _render()
                return
            tutorial_step = 2
        2:
            if practice == null:
                return
            practice.advance_day()
            tutorial_step = 3
        3:
            _finish_tutorial()
            return
    _render()
func _finish_tutorial() -> void:
    var file := FileAccess.open(TUTORIAL_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string('{"version":1,"seen":true}')
        file.close()
    tutorial_step = 0
    practice = null
    _change_page("incidents" if sim.status == "active" else "results")

func _section(parent: VBoxContainer, headline: String, subtitle: String) -> void:
    parent.add_child(_label(headline, 20, Color("#f5e8ca"), true))
    parent.add_child(_label(subtitle, 14, Color("#c6d2c7")))

func _art(family: String, dimensions: Vector2) -> TextureRect:
    var art := TextureRect.new()
    art.texture = load("res://assets/illustrated/incident_%s.webp" % family) as Texture2D
    art.custom_minimum_size = dimensions
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return art

func _portrait_for_event(id: String) -> String:
    var key: String = id.to_lower()
    if "bake" in key or "bread" in key or "sandwich" in key or "recipe" in key:
        return "baker"
    if "paper" in key or "press" in key or "news" in key or "camera" in key or "report" in key:
        return "reporter"
    if "mayor" in key or "election" in key or "vote" in key or "council" in key:
        return "mayor"
    if "post" in key or "letter" in key or "organize" in key:
        return "organizer"
    return "gerald"

func _family(id: String) -> String:
    if "rain" in id or "fair" in id or "parade" in id or "calendar" in id:
        return "rain"
    if "sandwich" in id or "bread" in id or "baker" in id or "recipe" in id:
        return "sandwich"
    if "post" in id or "letter" in id or "invitation" in id or "bank" in id:
        return "letter"
    if "wind" in id or "traffic" in id or "clock" in id:
        return "wind"
    if "camera" in id or "photo" in id or "press" in id or "gossip" in id:
        return "newspaper"
    return "election"

func _label(value: String, font_size: int, ink: Color, heavy: bool = false) -> Label:
    var text := Label.new()
    text.text = value
    text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text.add_theme_font_size_override("font_size", font_size)
    text.add_theme_color_override("font_color", ink)
    if heavy:
        text.add_theme_color_override("font_shadow_color", Color("#10181922"))
    return text

func _panel(bg: Color, edge: Color, width: int, radius: int) -> PanelContainer:
    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = edge
    style.set_border_width_all(width)
    style.set_corner_radius_all(radius)
    style.set_content_margin_all(10)
    panel.add_theme_stylebox_override("panel", style)
    return panel

func _button(value: String, emphasized: bool, minimum_height: int = 56) -> Button:
    var button := Button.new()
    button.text = value
    button.custom_minimum_size.y = minimum_height
    button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    button.alignment = HORIZONTAL_ALIGNMENT_CENTER
    button.add_theme_font_size_override("font_size", 16)
    button.add_theme_color_override("font_color", CREAM if emphasized else INK)
    button.add_theme_color_override("font_focus_color", INK)
    button.add_theme_color_override("font_hover_color", INK)
    button.add_theme_color_override("font_disabled_color", MUTED)
    button.focus_mode = Control.FOCUS_ALL
    var style := StyleBoxFlat.new()
    style.bg_color = BURGUNDY if emphasized else CREAM
    style.border_color = GOLD if emphasized else Color("#b9a584")
    style.set_border_width_all(2)
    style.set_corner_radius_all(10)
    style.set_content_margin_all(7)
    button.add_theme_stylebox_override("normal", style)
    var hover := style.duplicate() as StyleBoxFlat
    hover.bg_color = GOLD
    hover.border_color = BURGUNDY
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", hover)
    button.add_theme_stylebox_override("focus", hover)
    var disabled := style.duplicate() as StyleBoxFlat
    disabled.bg_color = Color("#c9c4b7")
    button.add_theme_stylebox_override("disabled", disabled)
    return button

func _focus_after_layout(button: Button) -> void:
    if not is_inside_tree():
        return
    await get_tree().process_frame
    if is_instance_valid(button) and button.is_inside_tree():
        button.grab_focus()
