extends SceneTree
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
var checks: int = 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, desc: String) -> void:
    checks += 1
    if not ok: failures.append(desc)
func _find(node: Node, name: String) -> Node:
    if node.name == name: return node
    for child in node.get_children():
        var v: Node = _find(child, name)
        if v != null: return v
    return null
func _label_has(node: Node, phrase: String) -> bool:
    if node is Label and (node as Label).text.contains(phrase): return true
    for child in node.get_children():
        if _label_has(child, phrase): return true
    return false
func _run() -> void:
    var scene: Control = load("res://scenes/main.tscn").instantiate()
    root.add_child(scene)
    scene.sim = Simulation.new(1,false)
    scene._render()
    await process_frame
    await process_frame
    _check(_label_has(scene,"1. CHOOSE AN INCIDENT"),"First step labelled")
    _check(_label_has(scene,"2. CHOOSE A STAMP"),"Second step labelled")
    _check(_label_has(scene,"NOT FILED"),"Selection is not filed")
    _check(_label_has(scene,"35% -> 90%"),"True conditional odds preview")
    _check(_label_has(scene,"Cost when day runs"),"Cost timing shown")
    var file := _find(scene,"FileStampButton") as Button
    var advance := _find(scene,"AdvanceDayButton") as Button
    _check(file!=null and not file.disabled,"File action available")
    _check(advance!=null,"Advance is a separate action")
    _check(scene.get_viewport().get_visible_rect().size==Vector2(1280,800),"Steam Deck resolution")
    for b in [file,advance]:
        if b!=null:
            var rect:=b.get_global_rect()
            _check(rect.position.y>=0 and rect.end.y<=800,"Critical button is on-screen")
    var influence: int = scene.sim.influence
    scene._approve_stamp()
    await process_frame
    await process_frame
    _check(not scene.sim.pending.is_empty(),"Filed action is pending")
    _check(scene.sim.influence==influence,"No cost charged until day resolution")
    _check(_label_has(scene,"FILED FOR TODAY"),"Filed state shown")
    _check((_find(scene,"FileStampButton") as Button).text.contains("REPLACE"),"Replacing is explicit")
    _check(scene.get_viewport().gui_get_focus_owner()==_find(scene,"AdvanceDayButton"),"Controller focus advances")
    scene._clear_stamp()
    _check(scene.sim.pending.is_empty(),"Undo clears filing")
    _check(_label_has(scene,"NOT FILED"),"Undo restores selection state")
    scene._select_stamp("reschedule")
    await process_frame
    await process_frame
    _check(scene.get_viewport().gui_get_focus_owner()==_find(scene,"StampChoice_reschedule"),"Changing stamp keeps focus")
    _check(_label_has(scene,"Try it tomorrow"),"Delay explains deferred action")
    scene.selected_stamp="misfile"
    scene._render()
    var rule: Dictionary = scene.sim.get_rule(scene.selected_event)
    if (rule["misfile_facts"] as Array).is_empty():
        _check((_find(scene,"FileStampButton") as Button).disabled,"Impossible Misfile disabled")
    scene.selected_stamp="domino"
    scene._render()
    _check(_label_has(scene,"first newly eligible follow-up"),"Domino's condition explained")
    scene.selected_stamp="nudge"
    scene._render()
    scene._approve_stamp()
    scene._advance_day()
    _check(scene.sim.influence<influence+int(scene.sim.case_info.get("regen",2)),"Cost paid on advance")
    root.remove_child(scene)
    scene.free()
    if failures.is_empty():
        print("PASS: %d stamp-desk clarity assertions" % checks)
        quit(0)
    for problem in failures: printerr("FAIL: "+problem)
    quit(1)
