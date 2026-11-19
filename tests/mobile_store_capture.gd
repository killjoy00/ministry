extends SceneTree
## Render genuine Ministry mobile gameplay for store-listing QA.
## These images come from the actual mobile scene and deterministic simulation.
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
const OUT = "res://build/mobile-store-shots"
var game: Control
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_go")

func _capture(filename: String) -> void:
    for n in range(6):
        await process_frame
    await RenderingServer.frame_post_draw
    var scroll := game.find_child("MobileContentScroll", true, false) as ScrollContainer
    if scroll == null or scroll.get_global_rect().size.y < 220.0:
        errors.append("Collapsed visible game content before " + filename)
        return
    var image := root.get_viewport().get_texture().get_image()
    if image.is_empty() or image.get_width() < 1000 or image.get_height() < 2000:
        errors.append("Invalid native screenshot " + filename + " " + str(image.get_size()))
        return
    var dest := ProjectSettings.globalize_path(OUT + "/" + filename)
    var code := image.save_png(dest)
    if code != OK:
        errors.append("Could not write " + filename + ": " + str(code))
    else:
        print("CAPTURED ", dest, " size=", image.get_size())

func _go() -> void:
    if DisplayServer.get_name() == "headless":
        printerr("Store captures require a real renderer; headless capture is prohibited")
        quit(1)
        return
    var output := ProjectSettings.globalize_path(OUT)
    DirAccess.make_dir_recursive_absolute(output)
    var size := Vector2i(1320, 2880)
    DisplayServer.window_set_size(size)
    root.size = size
    root.content_scale_size = Vector2i(390, 844)
    game = load("res://scenes/mobile_main.tscn").instantiate()
    root.add_child(game)
    game.sim = Simulation.new(41, false)
    game.page = "incidents"
    game._render()
    await _capture("01-incident-decision.png")
    game._change_page("stamps")
    await _capture("02-stamp-desk.png")
    game._file_stamp()
    game._advance_day()
    for i in range(18):
        await process_frame
    if game.theater == null:
        errors.append("No real Causality Theater after advancing the simulation")
    else:
        await _capture("03-causality-theater.png")
        game.theater.call("_finish")
        await _capture("04-daily-results.png")
        game._close_theater()
    game._change_page("log")
    await _capture("05-chronicle.png")
    game._change_page("town")
    await _capture("06-oddford.png")
    game._change_page("ministry")
    await _capture("07-departments.png")
    root.remove_child(game)
    game.queue_free()
    for error in errors:
        printerr("STORE CAPTURE ERROR: ", error)
    if errors.is_empty():
        print("PASS: seven genuine mobile gameplay store screenshots")
        quit(0)
    else:
        quit(1)
