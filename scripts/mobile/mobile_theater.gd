extends Control
## Portrait-native Causality Theater. The displayed incidents and connections
## come exclusively from CaseSimulation.history, NEVER from guessed story text.
## Shares the desktop highlight-selection algorithm with CausalityTheater.

signal close_requested
signal log_requested
signal inspect_requested(event_id: String)

const DesktopTheater = preload("res://scripts/ui/causality_theater.gd")
const Causal = preload("res://scripts/simulation/causal_inspection.gd")
const PAPER = Color("#f1e2c4")
const INK = Color("#273c41")
const BURGUNDY = Color("#7e454c")
const GREEN = Color("#426e60")
const GOLD = Color("#c49a58")
const MUTED = Color("#6c6a60")
const CREAM = Color("#fff7e7")
const STAMPS = {"nudge":"nudge", "misfile":"misfile", "reschedule":"reschedule", "domino":"domino"}

var simulation: CaseSimulation
var recorded: Array = []
var filings: Array = []
var featured: Array = []
var day_number: int = 1
var before_support: int = 0
var after_support: int = 0
var before_strain: int = 0
var after_strain: int = 0
var revealed_count: int = 0
var complete: bool = false
var reduced_motion: bool = false
var elapsed: float = 0.0
var cards: Array[Control] = []
var status_label: Label
var summary: Label
var skip_button: Button
var replay_scroll: ScrollContainer

func configure(game: CaseSimulation, history: Array, stamped: Array, day: int, momentum_before: int, momentum_after: int, strain_before: int, strain_after: int) -> void:
    simulation = game
    recorded = history.duplicate(true)
    filings = stamped.duplicate(true)
    featured = DesktopTheater._choose_events(recorded, filings, 4)
    day_number = day
    before_support = momentum_before
    after_support = momentum_after
    before_strain = strain_before
    after_strain = strain_after

func _ready() -> void:
    name = "MobileCausalityTheater"
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var cfg := ConfigFile.new()
    if cfg.load("user://ministry_visuals.cfg") == OK:
        reduced_motion = bool(cfg.get_value("accessibility", "reduced_motion", false))
    _build()
    if reduced_motion:
        _finish()
    else:
        var audio := get_node_or_null("/root/MusicDirector")
        if audio != null:
            audio.call("play_stamp_effect")
    set_process(not reduced_motion)

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_GO_BACK_REQUEST:
        close_requested.emit()

func _process(delta: float) -> void:
    if complete:
        return
    elapsed += minf(delta, 0.1)
    while revealed_count < featured.size() and elapsed >= 0.45 + float(revealed_count) * 0.52:
        _reveal(revealed_count)
        revealed_count += 1
    if elapsed >= 2.8:
        _finish()

func _build() -> void:
    var background := ColorRect.new()
    background.color = Color("#132b31")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    # Center only horizontally. A CenterContainer vertically shrinks the
    # expanding ScrollContainer, hiding every scene, beat, and illustration.
    var center := HBoxContainer.new()
    center.name = "MobileTheaterSafeSurface"
    center.alignment = BoxContainer.ALIGNMENT_CENTER
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var margins := MarginContainer.new()
    margins.custom_minimum_size.x = minf(620.0, maxf(240.0, get_viewport_rect().size.x))
    margins.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var edge: int = 14
    if OS.has_feature("mobile"):
        var full: Vector2i = DisplayServer.window_get_size()
        var safe: Rect2i = DisplayServer.get_display_safe_area()
        if full.y > 0 and safe.size.y > 0:
            edge += clampi(roundi(float(safe.position.y) * get_viewport_rect().size.y / float(full.y)), 0, 80)
    for key in ["margin_left", "margin_right", "margin_bottom"]:
        margins.add_theme_constant_override(key, 12)
    margins.add_theme_constant_override("margin_top", edge)
    center.add_child(margins)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 8)
    margins.add_child(root)
    root.add_child(_label("THE MINISTRY / CAUSALITY THEATER", 18, Color("#f8e8bc"), true))
    root.add_child(_label("DAY %d  /  OFFICIAL RECONSTRUCTION" % day_number, 15, GOLD, true))
    var scroll := ScrollContainer.new()
    scroll.name = "MobileTheaterScroll"
    replay_scroll = scroll
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root.add_child(scroll)
    var content := VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 8)
    scroll.add_child(content)
    var town := TextureRect.new()
    town.name = "MobileCausalityTown"
    town.texture = load("res://assets/illustrated/oddford_square.webp") as Texture2D
    town.custom_minimum_size.y = 154
    town.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    town.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    content.add_child(town)
    # The existing illustrated Oddford ensemble is part of the replay stage.
    var cast := TextureRect.new()
    cast.name = "MobileCausalityCast"
    cast.texture = load("res://assets/illustrated/oddford_cast.webp") as Texture2D
    cast.custom_minimum_size.y = 88
    cast.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    cast.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    content.add_child(cast)
    var file_note := _panel(PAPER, GOLD)
    content.add_child(file_note)
    var file_row := HBoxContainer.new()
    file_row.add_theme_constant_override("separation", 9)
    file_note.add_child(file_row)
    var stamp := TextureRect.new()
    stamp.name = "MobileStampSlam"
    var seal: String = str(filings[0].get("stamp", "nudge")) if not filings.is_empty() else "nudge"
    stamp.texture = load("res://assets/illustrated/stamp_%s_small.webp" % STAMPS.get(seal, "nudge")) as Texture2D
    stamp.custom_minimum_size = Vector2(66, 66)
    stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    file_row.add_child(stamp)
    var filing_text := "NO STAMP / NATURAL COINCIDENCES ONLY"
    if not filings.is_empty():
        var names: Array[String] = []
        for filing in filings:
            var name: String = str(filing.get("stamp", "STAMP")).to_upper()
            var rule: Dictionary = simulation.get_rule(str(filing.get("target", "")))
            names.append("%s: %s" % [name, str(rule.get("title", "incident"))])
        filing_text = "\n".join(PackedStringArray(names))
    status_label = _label("AUTHORIZING THE DAY...\n" + filing_text, 15, BURGUNDY, true)
    status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    file_row.add_child(status_label)
    content.add_child(_label("INCIDENTS ACTUALLY RECORDED", 15, Color("#f5e1bf"), true))
    content.add_child(_label("The sequence is chronological. A link is shown only when the simulation records a cause.", 13, Color("#d7ded2")))
    if featured.is_empty():
        content.add_child(_label("The town has filed a very quiet day.", 16, CREAM))
    var names_by_id: Dictionary = {}
    for event in recorded:
        names_by_id[str(event.get("id", ""))] = str(event.get("title", "Incident"))
    for i in range(featured.size()):
        var entry: Dictionary = featured[i]
        var panel := _panel(CREAM, GOLD)
        panel.name = "MobileBeat%d" % i
        content.add_child(panel)
        var column := VBoxContainer.new()
        column.add_theme_constant_override("separation", 3)
        panel.add_child(column)
        var causes: Array = entry.get("causes", [])
        var parent_names: Array[String] = []
        for parent in causes:
            parent_names.append(Causal._event_name(simulation, str(parent)))
        if not parent_names.is_empty():
            var link := _label("DOCUMENTED CAUSAL LINK  ↓  " + ", ".join(PackedStringArray(parent_names)), 13, GREEN, true)
            link.name = "MobileCausalLink%d" % i
            column.add_child(link)
        else:
            column.add_child(_label("NO RECORDED PARENT INCIDENT  /  START OF A POSSIBLE CHAIN", 12, MUTED))
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 7)
        column.add_child(row)
        var actor := TextureRect.new()
        actor.name = "MobileBeatActor%d" % i
        actor.texture = load("res://assets/illustrated/portrait_%s.webp" % _portrait_for_event(str(entry.get("id", "")))) as Texture2D
        actor.custom_minimum_size = Vector2(60, 77)
        actor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        actor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        row.add_child(actor)
        var icon := TextureRect.new()
        icon.texture = load("res://assets/illustrated/incident_%s_small.webp" % _family(str(entry.get("id", "")))) as Texture2D
        icon.custom_minimum_size = Vector2(55, 55)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        row.add_child(icon)
        var text := VBoxContainer.new()
        text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(text)
        text.add_child(_label(str(entry.get("title", "Incident")), 17, INK, true))
        text.add_child(_label("+%d MOMENTUM" % int(entry.get("support", 0)), 13, BURGUNDY))
        var event_id: String = str(entry.get("id", ""))
        var rule: Dictionary = simulation.get_rule(event_id)
        if not rule.is_empty():
            text.add_child(_label(str(rule.get("place", "Oddford")).to_upper(), 12, GREEN, true))
            var inspect := _button("INSPECT DOCUMENTED CAUSES", false)
            inspect.name = "MobileBeatInspect%d" % i
            inspect.custom_minimum_size.y = 48
            inspect.pressed.connect(_request_inspect.bind(event_id))
            column.add_child(inspect)
        panel.modulate.a = 0.0
        cards.append(panel)
    summary = _label("", 16, GOLD, true)
    summary.name = "MobileDailySummary"
    summary.visible = false
    root.add_child(summary)
    var footer := HBoxContainer.new()
    footer.add_theme_constant_override("separation", 8)
    root.add_child(footer)
    skip_button = _button("SKIP", false)
    skip_button.name = "MobileSkipAnimation"
    skip_button.pressed.connect(_finish)
    footer.add_child(skip_button)
    var chronicle := _button("FULL CHRONICLE", false)
    chronicle.name = "MobileFullChronicle"
    chronicle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    chronicle.pressed.connect(func(): log_requested.emit())
    footer.add_child(chronicle)
    var back := _button("CONTINUE", true)
    back.name = "MobileReturnFromTheater"
    back.pressed.connect(func(): close_requested.emit())
    footer.add_child(back)

func _reveal(i: int) -> void:
    if i >= cards.size():
        return
    var card: Control = cards[i]
    card.modulate.a = 1.0
    # On a phone the next causal beat must be visible automatically; simply
    # fading a card below the fold is not a meaningful replay.
    if replay_scroll != null:
        replay_scroll.ensure_control_visible(card)
    if i < featured.size():
        status_label.text = str(featured[i].get("title", "Incident"))
    var tween := create_tween()
    card.pivot_offset = card.size / 2.0
    card.scale = Vector2(.96, .96)
    tween.tween_property(card, "scale", Vector2.ONE, 0.23).set_trans(Tween.TRANS_BACK)

func _finish() -> void:
    if complete:
        return
    complete = true
    set_process(false)
    for card in cards:
        card.modulate.a = 1.0
        card.scale = Vector2.ONE
    revealed_count = featured.size()
    status_label.text = "THE DAILY REGISTER IS COMPLETE"
    var extra: String = "  /  %d MORE IN THE CHRONICLE" % (recorded.size() - featured.size()) if recorded.size() > featured.size() else ""
    summary.text = "%d INCIDENTS  /  %+d MOMENTUM\nREALITY STRAIN %d -> %d%s" % [recorded.size(), after_support - before_support, before_strain, after_strain, extra]
    summary.visible = true
    skip_button.disabled = true

func _request_inspect(id: String) -> void:
    inspect_requested.emit(id)

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

func _label(value: String, font: int, color: Color, bold: bool = false) -> Label:
    var text := Label.new()
    text.text = value
    text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text.add_theme_color_override("font_color", color)
    text.add_theme_font_size_override("font_size", font)
    if bold:
        text.add_theme_color_override("font_shadow_color", Color("#11111122"))
    return text

func _panel(background: Color, border: Color) -> PanelContainer:
    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(2)
    style.set_corner_radius_all(10)
    style.set_content_margin_all(9)
    panel.add_theme_stylebox_override("panel", style)
    return panel

func _button(value: String, emphatic: bool) -> Button:
    var button := Button.new()
    button.text = value
    button.custom_minimum_size.y = 54
    button.add_theme_font_size_override("font_size", 14)
    button.add_theme_color_override("font_color", CREAM if emphatic else INK)
    button.add_theme_color_override("font_focus_color", INK)
    button.focus_mode = Control.FOCUS_ALL
    var normal := StyleBoxFlat.new()
    normal.bg_color = BURGUNDY if emphatic else PAPER
    normal.border_color = GOLD
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(10)
    normal.set_content_margin_all(8)
    button.add_theme_stylebox_override("normal", normal)
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = GOLD
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", hover)
    button.add_theme_stylebox_override("focus", hover)
    return button
