extends SceneTree
## Illustrated incident staging follows the selected rule; the engine is unchanged.
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
var checks: int = 0
var errors: Array[String] = []
func _initialize() -> void:
    call_deferred("_test")
func _check(ok: bool, title: String) -> void:
    checks += 1
    if not ok:
        errors.append(title)
func _named(node: Node, query: String) -> Node:
    if node.name == query:
        return node
    for child in node.get_children():
        var found := _named(child, query)
        if found != null:
            return found
    return null
func _label(node: Node, text: String) -> bool:
    if node is Label and (node as Label).text.contains(text):
        return true
    for child in node.get_children():
        if _label(child, text):
            return true
    return false
func _test() -> void:
    var scene: Control = load("res://scenes/main.tscn").instantiate()
    root.add_child(scene)
    scene.sim = Simulation.new(1,false)
    scene._render()
    await process_frame
    await process_frame
    _check(_named(scene,"IncidentSpotlight") != null,"Hero stage on main decision screen")
    _check(_named(scene,"OddfordStageBackdrop") is TextureRect,"Real illustrated town in event stage")
    _check(_named(scene,"IncidentStagePostcard") != null,"Selected incident has illustrated postcard")
    _check(_named(scene,"IncidentStageCharacter") is TextureRect,"Character cutout on paper theatre")
    _check(_label(scene,"UNDER OBSERVATION"),"Potential incidents not described as resolved")
    _check(_label(scene,"35% CHANCE IF ATTEMPTED"),"Honest base probability")
    var spotlight := _named(scene,"IncidentSpotlight") as Control
    _check(spotlight.get_global_rect().position.y >= 0 and spotlight.get_global_rect().end.y <= 800,"Scene fits Deck height")
    for label in ["FileStampButton","AdvanceDayButton","StampFilingStatus"]:
        var node := _named(scene,label) as Control
        _check(node != null,"Decision control exists: " + label)
        if node != null:
            _check(node.get_global_rect().position.y >= 0 and node.get_global_rect().end.y <= 800,"Decision control visible: " + label)
    _check(_label(scene,"Cost when day runs"),"Stamp costs still visible before approval")
    scene._select_event("sandwich")
    await process_frame
    _check(_label(scene,"An Abandoned Sandwich"),"Selecting incident updates stage")
    var portrait := _named(scene,"IncidentStageCharacter") as TextureRect
    _check(portrait != null and portrait.texture.resource_path.contains("portrait_gerald"),"Gerald appears for sandwich")
    scene._select_event("post")
    await process_frame
    portrait = _named(scene,"IncidentStageCharacter") as TextureRect
    _check(portrait != null and portrait.texture.resource_path.contains("portrait_clerk"),"Clerk appears for postal incident")
    _check(_label(scene,"A Mislaid Delivery"),"Selection changes stage title")
    scene.sim.run_departments = ["double_booking"]
    scene._render()
    _check(_label(scene,"CHOOSE UP TO 2 INCIDENTS TO INFLUENCE"),"Double Booking displayed")
    for case_id in ["fowl", "bakery", "thursday", "apology"]:
        scene.sim.profile["completed"] = 12
        scene.sim.start_new_run(83,case_id)
        scene.selected_event = ""
        scene._render()
        await process_frame
        _check(_named(scene,"IncidentSpotlight") != null,"Stage available in " + case_id)
        var advance := _named(scene,"AdvanceDayButton") as Button
        _check(advance != null and advance.get_global_rect().end.y <= 800,"Advance visible in " + case_id)
    root.remove_child(scene)
    scene.free()
    if errors.is_empty():
        print("PASS: %d decision-theater assertions" % checks)
        quit(0)
    else:
        for e in errors:
            printerr("FAIL: " + e)
        quit(1)
