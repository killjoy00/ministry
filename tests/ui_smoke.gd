extends SceneTree
## Verify playable layout at the 1280x800 Steam Deck target.

var failures: Array[String] = []
var checked: int = 0

func _initialize() -> void:
    call_deferred("_exercise")

func _check(ok: bool, message: String) -> void:
    checked += 1
    if not ok: failures.append(message)

func _exercise() -> void:
    var scene: Control = load("res://scenes/main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame
    _assert_visible(scene, ["X  APPROVE", "Y  ADVANCE DAY"], ["THE OFFICIAL CHRONICLE"])
    _check(scene.get_viewport().get_visible_rect().size == Vector2(1280, 800), "Steam Deck viewport must be 1280x800")
    for i in range(7):
        scene._advance_day()
    await process_frame
    await process_frame
    _check(scene.sim.status != "active", "seven days must produce a case result")
    _assert_visible(scene, ["FILE ANOTHER CASE"], ["THE OFFICIAL CHRONICLE"])
    scene._new_case()
    await process_frame
    await process_frame
    _check(scene.sim.status == "active", "another case must be available")
    _assert_visible(scene, ["X  APPROVE", "Y  ADVANCE DAY"], ["THE OFFICIAL CHRONICLE"])
    root.remove_child(scene)
    scene.free()
    if failures.is_empty():
        print("PASS: %d UI layout assertions at 1280x800" % checked)
        quit(0)
    else:
        for problem in failures: printerr("FAIL: " + problem)
        quit(1)

func _assert_visible(scene: Control, buttons: Array[String], labels: Array[String]) -> void:
    var required_buttons: Array[String] = buttons.duplicate()
    var required_labels: Array[String] = labels.duplicate()
    var stack: Array[Node] = [scene]
    while not stack.is_empty():
        var node: Node = stack.pop_back()
        for child in node.get_children(): stack.append(child)
        if not (node is Control): continue
        var c: Control = node
        if node is Button:
            var b: Button = node
            for title in buttons:
                if b.text.begins_with(title):
                    required_buttons.erase(title)
                    var rect: Rect2 = c.get_global_rect()
                    _check(rect.position.y >= 0.0 and rect.end.y <= 800.0 and rect.size.x >= 100.0, title + " must fit in viewport")
        if node is Label:
            var l: Label = node
            for title in labels:
                if l.text.begins_with(title):
                    required_labels.erase(title)
                    _check(c.get_global_rect().size.x >= 500.0, title + " must not be crushed into a vertical column")
    _check(required_buttons.is_empty(), "Missing action buttons: " + str(required_buttons))
    _check(required_labels.is_empty(), "Missing chronicle headings: " + str(required_labels))
