extends SceneTree
## Real 1280x800 interface contract for the new illustrated assignment board.
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
const CaseCatalog = preload("res://scripts/scenarios/case_catalog.gd")
var checks := 0
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		errors.append(description)

func _run() -> void:
	var game: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.sim = Simulation.new(901, false)
	game.sim.profile["completed"] = 10
	game.sim.profile["merit"] = 89
	game.sim.status = "won"
	game.sim.last_outcome = "Officially closed"
	game._render()
	await process_frame
	var choose := game.find_child("ChooseAssignmentButton", true, false) as Button
	_check(choose != null and not choose.disabled, "Result screen offers the assignment selector")
	game._open_assignment_board()
	await process_frame
	await process_frame
	var board: Control = game.gallery_overlay
	_check(board != null and board.name == "AssignmentCaseBoard", "Selection opens the illustrated assignment dossier")
	var scroll := board.find_child("AssignmentCatalogScroll", true, false) as ScrollContainer
	_check(scroll != null and scroll.get_global_rect().end.y <= 800, "Catalog fits the Steam Deck viewport")
	for id in CaseCatalog.ORDER:
		var select := board.find_child("AssignmentChoose_" + id, true, false) as Button
		_check(select != null, "A gamepad-selectable entry exists for " + id)
		if select != null:
			_check(not select.disabled, "Completed-case account can choose " + id)
	if DisplayServer.get_name() != "headless":
		root.get_viewport().get_texture().get_image().save_png("/mnt/data/ministry-hard-cases/case-selection.png")
	game._start_selected_case("bakery")
	await process_frame
	_check(game.sim.status == "active" and game.sim.case_id == "bakery", "Selecting bakery launches the correct simulation")
	_check(game.find_child("AssignmentCaseBoard", true, false) == null, "Starting a case closes the selection modal")
	var all_texts: Array[String] = []
	_collect_labels(game, all_texts)
	_check(_contains(all_texts, "THE BAKERY THAT BOUGHT THE BANK"), "UI displays dynamic case title")
	_check(_contains(all_texts, "FINANCIAL LEVERAGE"), "UI displays the correct metric")
	_check(_contains(all_texts, "Verified backers"), "UI displays specific causal conditions")
	if DisplayServer.get_name() != "headless":
		root.get_viewport().get_texture().get_image().save_png("/mnt/data/ministry-hard-cases/bakery-case.png")
	game.sim.status = "won"
	game.sim.last_outcome = str(game.sim.case_info["success"])
	game._render()
	await process_frame
	_check(game.find_child("ChooseAssignmentButton", true, false) != null, "Hard case results still allow the next selection")
	game.sim.profile["completed"] = 0
	game._open_assignment_board()
	await process_frame
	for id in ["bakery", "thursday", "apology"]:
		var disabled := game.gallery_overlay.find_child("AssignmentChoose_" + id, true, false) as Button
		_check(disabled != null and disabled.disabled, "Fresh accounts cannot skip to hard case " + id)
	var routine := game.gallery_overlay.find_child("AssignmentChoose_fowl", true, false) as Button
	_check(routine != null and not routine.disabled, "Routine election stays playable on a new account")
	game._close_gallery()
	await process_frame
	_check(game.gallery_overlay == null, "Controller back dismisses assignment board")
	root.remove_child(game)
	game.free()
	if errors.is_empty():
		print("PASS: %d assignment selection, case HUD and controller layout assertions" % checks)
		quit(0)
	else:
		for e in errors: printerr("FAIL: ", e)
		printerr("FAILED: %d of %d assertions" % [errors.size(), checks])
		quit(1)

func _collect_labels(node: Node, dest: Array[String]) -> void:
	if node is Label:
		dest.append(str((node as Label).text))
	for ch in node.get_children():
		_collect_labels(ch, dest)

func _contains(labels: Array[String], fragment: String) -> bool:
	for s in labels:
		if s.contains(fragment): return true
	return false
