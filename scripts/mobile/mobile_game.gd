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
const TUTORIAL_PATH = "user://ministry_briefing.json"
const STAMP_LABELS = {"nudge":"NUDGE", "misfile":"MISFILE", "reschedule":"DELAY", "domino":"DOMINO"}

var sim: CaseSimulation
var page: String = "incidents"
var selected_event: String = ""
var selected_stamp: String = "nudge"
var evidence_id: String = ""
var feedback: String = ""
var theater: Control = null
var confirm_unstamped_day: bool = false
var tutorial_step: int = 0
var practice: CaseSimulation = null
var first_focus: Button
var _last_width: int = 0
var _last_height: int = 0

func _ready() -> void:
    name = "MinistryMobileGame"
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
        if theater != null:
            _close_theater()
        elif ["evidence", "town", "help", "tutorial"].has(page):
            _change_page("incidents")
        elif ["ministry", "assignments"].has(page):
            _change_page("results")
        elif page == "stamps":
            _change_page("incidents")
        else:
            _change_page("incidents")

func _render() -> void:
    if sim == null:
        return
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
    scroll.follow_focus = true
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
        "ministry": _ministry(body)
        "assignments": _assignments(body)
        "tutorial": _tutorial(body)
        "help": _help(body)
        "results": _results(body)
        _: _incidents(body)
    _bottom_bar(surface)
    # Never auto-scroll the incident choice away from the top of the page.

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
        body.add_child(_label("No new incidents are eligible. Advance the day to resolve the town's business.", 17, MUTED))
    else:
        body.add_child(_label("AVAILABLE OPPORTUNITIES  /  TAP TO SELECT", 14, BURGUNDY, true))
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
        body.add_child(_label("There are no eligible incidents. You may advance without a stamp.", 17, MUTED))
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
        seal.texture = load("res://assets/illustrated/stamp_%s_small.webp" % id) as Texture2D
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
        body.add_child(_label("No incidents yet. The stationery is immaculate.", 17, MUTED))
    for entry in summaries:
        var caption: String = "DAY %d  /  %s\n%s" % [int(entry["day"]), str(entry["title"]), str(entry.get("because", ""))]
        var id: String = str(entry.get("id", ""))
        if sim.get_rule(id).is_empty():
            body.add_child(_label(caption, 15, MUTED))
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
    body.add_child(_label("REQUIRED CONDITIONS", 16, BURGUNDY, true))
    if (info["conditions"] as Array).is_empty():
        body.add_child(_label("No prerequisites. This can start a chain.", 15, MUTED))
    for requirement in info["conditions"]:
        var condition: Dictionary = requirement
        var line: String = "%s  %s [%s]" % ["OK" if bool(condition["met"]) else "MISSING", str(condition["fact"]), str(condition["kind"])]
        if not str(condition.get("source", "")).is_empty():
            line += " - from " + str(condition["source"])
        body.add_child(_label(line, 15, GREEN if bool(condition["met"]) else MUTED))
    body.add_child(_label("POSSIBLE CONSEQUENCES  /  NOT GUARANTEED", 16, BURGUNDY, true))
    for output in info["outcomes"]:
        body.add_child(_label("- " + str(output), 15, INK))
    if not (info["alternative"] as Array).is_empty():
        body.add_child(_label("MISFILE WOULD REPLACE THESE WITH:", 15, BURGUNDY, true))
        for output in info["alternative"]:
            body.add_child(_label("- " + str(output), 15, INK))
    var branches: Array = info["branches"]
    body.add_child(_label("MAY HELP ENABLE %d OTHER INCIDENTS" % branches.size(), 16, BURGUNDY, true))
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
        body.add_child(_label("CONFIRMED PARENT EVENTS", 16, GREEN, true))
        for parent in info["parents"]:
            body.add_child(_label("- " + str(parent["title"]), 15, GREEN))

func _town(body: VBoxContainer) -> void:
    _section(body, "A WINDOW ON ODDFORD", "THIS TOWN IS OPERATING WITHOUT ADULT SUPERVISION")
    var panel := _panel(PAPER, GOLD, 2, 10)
    body.add_child(panel)
    var art := TextureRect.new()
    art.texture = load("res://assets/illustrated/oddford_square.webp") as Texture2D
    art.custom_minimum_size.y = 260
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    panel.add_child(art)
    body.add_child(_label("The town responds to real recorded incidents. Inspect the Chronicle to see what actually happened.", 16, MUTED))
    var latest: Array = sim.history_summary(8)
    for entry in latest:
        var rule: Dictionary = sim.get_rule(str(entry.get("id", "")))
        if rule.is_empty():
            continue
        var item := _button("%s  /  %s" % [str(rule.get("place", "Oddford")), str(entry["title"])], false, 54)
        item.pressed.connect(_show_evidence.bind(str(entry["id"])))
        body.add_child(item)
    var go := _button("BACK TO INCIDENTS", true, 56)
    go.pressed.connect(_change_page.bind("incidents"))
    body.add_child(go)

func _results(body: VBoxContainer) -> void:
    _section(body, "CASE CLOSED" if sim.status == "won" else "CASE FILED AS INCOMPLETE", str(sim.last_outcome))
    var portrait := TextureRect.new()
    portrait.texture = load("res://assets/illustrated/portrait_%s.webp" % str(sim.case_info["portrait"])) as Texture2D
    portrait.custom_minimum_size.y = 195
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    body.add_child(portrait)
    body.add_child(_label("MERIT AVAILABLE: %d   /   CASES FILED: %d" % [int(sim.profile["merit"]), int(sim.profile["completed"])], 17, GREEN, true))
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
    _section(body, "THE MINISTRY", "DEPARTMENT LOADOUT  /  BUY AND ASSIGN BETWEEN CASES")
    body.add_child(_label("MERIT %d  /  %d OF %d SLOTS ASSIGNED" % [int(sim.profile["merit"]), (sim.profile["equipped"] as Array).size(), sim.department_slots()], 16, GREEN, true))
    for id in Departments.ORDER:
        var info: Dictionary = Departments.get_department(id)
        var owned: bool = sim.department_owned(id)
        var equipped: bool = (sim.profile["equipped"] as Array).has(id)
        var status: String = "ASSIGNED" if equipped else "OWNED" if owned else "%d MERIT  /  %d CASES" % [int(info["cost"]), int(info["cases"])]
        var panel := _panel(CREAM, GOLD if equipped else MUTED, 2 if equipped else 1, 9)
        body.add_child(panel)
        var col := VBoxContainer.new()
        panel.add_child(col)
        col.add_child(_label(str(info["name"]), 18, INK, true))
        col.add_child(_label(str(info["detail"]), 14, MUTED))
        var action := _button(status + ("  /  REMOVE" if equipped else "  /  ASSIGN" if owned else "  /  BUY"), equipped, 50)
        action.disabled = sim.status == "active" or (not owned and (int(sim.profile["completed"]) < int(info["cases"]) or int(sim.profile["merit"]) < int(info["cost"]))) or (owned and not equipped and (sim.profile["equipped"] as Array).size() >= sim.department_slots())
        action.pressed.connect(_department_action.bind(id))
        col.add_child(action)

func _assignments(body: VBoxContainer) -> void:
    _section(body, "CHOOSE YOUR NEXT CASE", "ONE MINISTRY  /  FOUR UNREASONABLE ASSIGNMENTS")
    for id in Cases.ORDER:
        var details: Dictionary = Cases.description(id)
        var unlocked: bool = sim.case_unlocked(id)
        var panel := _panel(CREAM, GOLD, 1, 10)
        body.add_child(panel)
        var col := VBoxContainer.new()
        panel.add_child(col)
        col.add_child(_label(str(details["title"]), 19, INK, true))
        col.add_child(_label(str(details["brief"]), 15, MUTED))
        var btn := _button("START CASE  /  %d DAYS" % int(details["deadline"]) if unlocked else "LOCKED  /  FILE %d CASES" % int(details["unlock_cases"]), unlocked, 54)
        btn.disabled = not unlocked or sim.status == "active"
        btn.pressed.connect(_start_case.bind(str(id)))
        col.add_child(btn)

func _tutorial(body: VBoxContainer) -> void:
    _section(body, "MISS QUILL'S FIRST-DAY BRIEFING", "OPTIONAL PRACTICE  /  YOUR CASE AND MERIT ARE UNAFFECTED")
    var portrait := TextureRect.new()
    portrait.texture = load("res://assets/illustrated/portrait_clerk.webp") as Texture2D
    portrait.custom_minimum_size.y = 176
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    body.add_child(portrait)
    var titles: Array[String] = ["Your job is to engineer unlikely coincidences.", "Choose an incident and a Nudge.", "File the stamp, then advance the day.", "Inspect the real causal trail."]
    var text: Array[String] = [
        "A goose may become mayor, but directly appointing him violates regulation. You'll work indirectly.",
        "A Nudge raises a chosen incident's chance if it's attempted today. It costs Influence and adds Reality Strain.",
        "Other incidents occur without your approval. New facts can start a cascade. Stamps don't guarantee every outcome.",
        "WHY? shows prerequisites and possible results. The Chronicle records what really happened. Nothing in this practice uses your real resources."
    ]
    body.add_child(_label("FORM %d OF 4" % (tutorial_step + 1), 15, BURGUNDY, true))
    body.add_child(_label(titles[tutorial_step], 23, INK, true))
    body.add_child(_label(text[tutorial_step], 18, MUTED))
    if tutorial_step == 3 and practice != null:
        body.add_child(_label("WHAT THE SEPARATE PRACTICE CASE RECORDED", 15, GREEN, true))
        for event in practice.history:
            if not (event.get("facts", []) as Array).is_empty():
                body.add_child(_label("- " + str(event["title"]), 15, INK))
    var button := _button("NEXT" if tutorial_step < 3 else "GO TO YOUR CASE", true, 60)
    button.pressed.connect(_next_tutorial)
    body.add_child(button)
    var skip := _button("SKIP BRIEFING", false, 52)
    skip.pressed.connect(_finish_tutorial)
    body.add_child(skip)

func _help(body: VBoxContainer) -> void:
    _section(body, "HOW TO FILE A COINCIDENCE", "YOUR TEN-SECOND MANUAL")
    body.add_child(_label("1. Choose up to 1 incident to influence (2 with Double Booking). Other incidents still happen.", 17, INK))
    body.add_child(_label("2. Choose Nudge, Misfile, Delay, or Domino, then FILE. This only queues your action.", 17, INK))
    body.add_child(_label("3. Advance the day. Watch Causality Theater, then investigate genuine links in the Chronicle.", 17, INK))
    body.add_child(_label("4. Win or lose, earn Merit to buy permanent causal departments after the case.", 17, INK))
    var tutorial := _button("REPLAY MISS QUILL'S BRIEFING", true, 54)
    tutorial.pressed.connect(_change_page.bind("tutorial"))
    body.add_child(tutorial)
    var town := _button("VIEW ODDFORD", false, 54)
    town.pressed.connect(_change_page.bind("town"))
    body.add_child(town)

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
    elif ["help", "town", "tutorial"].has(page):
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
    if tutorial_step < 3:
        if tutorial_step == 1:
            practice = Simulation.new(1, false)
            if practice.stage_stamp("nudge", "sandwich"):
                practice.advance_day()
        tutorial_step += 1
        _render()
    else:
        _finish_tutorial()

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
