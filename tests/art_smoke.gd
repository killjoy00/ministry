extends SceneTree
## The Ministry must ship with its illustrations, not a bare controls-only UI.
var checked: int = 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, message: String) -> void:
    checked += 1
    if not ok: failures.append(message)

func _run() -> void:
    var assets: Array[String] = ["town", "gerald", "seal", "weather", "sandwich", "letter", "clock", "incident", "ink", "stamp_nudge", "stamp_misfile", "stamp_reschedule", "stamp_domino"]
    for name in assets:
        var path := "res://assets/%s.svg" % name
        _check(FileAccess.file_exists(path), "missing hand-drawn vector asset " + name)
        _check(load(path) is Texture2D, "original illustration must import as a texture: " + name)
    var scene: Control = load("res://scenes/main.tscn").instantiate()
    root.add_child(scene)
    scene.sim.start_new_run(4242)
    scene._render()
    await process_frame
    await process_frame
    var count := _visible_art(scene)
    _check(count >= 4, "initial screen must contain illustrated town, goose, seal and stamps")
    for day in range(7):
        scene._advance_day()
    await process_frame
    await process_frame
    _check(_visible_art(scene) >= 2, "result screen must retain the game's visual identity")
    root.remove_child(scene)
    scene.free()
    if failures.is_empty():
        print("PASS: %d original-art and scene assertions" % checked)
        quit(0)
    else:
        for failure in failures: printerr("FAIL: " + failure)
        quit(1)

func _visible_art(parent: Node) -> int:
    var number := 0
    var stack: Array[Node] = [parent]
    while not stack.is_empty():
        var node: Node = stack.pop_back()
        for child in node.get_children():
            stack.append(child)
        if node is TextureRect:
            var art := node as TextureRect
            if art.texture != null and art.size.x >= 32 and art.size.y >= 32:
                number += 1
    return number
