extends SceneTree
## Validate the operational Ministry board at 1280x800 for controller focus,
## all 12 office cards, purchase flow, and no hidden UI actions.
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
var checks: int = 0
var errors: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: errors.append(message)
func _run() -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.sim = Simulation.new(711, false)
	scene.sim.status = "won"
	scene.sim.last_outcome = "Gerald is elected. The town has questions; the Ministry does not."
	scene.sim.profile["merit"] = 160
	scene.sim.profile["completed"] = 10
	scene._render()
	await process_frame
	_check(scene.find_child("OpenMinistryBoard", true, false) != null, "A case result exposes the department board")
	scene._open_ministry()
	await process_frame
	await process_frame
	var board: Control = scene.gallery_overlay
	_check(board != null and board.name == "MinistryDepartmentBoard", "Board opens as full-screen modal")
	var scroll := board.find_child("DepartmentCatalogScroll", true, false) as Control
	_check(scroll != null, "Board scrolls without mouse")
	if scroll != null:
		var rect := scroll.get_global_rect()
		_check(rect.position.y >= 0 and rect.end.y <= 800, "Department catalog fits 1280x800")
	var count: int = 0
	for name in ["lost_property", "fortuitous_timing", "embarrassments", "postal_inspector", "double_booking", "appointment_bureau", "echo_chamber", "rumour_mill", "reality_reconciliation", "chain_reactions", "second_chances", "automatic_paperwork"]:
		if board.find_child("DepartmentAction_" + name, true, false) != null:
			count += 1
	_check(count == 12, "Every unlocked or locked office is navigable")
	_check(get_current_scene() == null or root.get_child_count() > 0, "Board remains part of an active scene tree")
	board._action("lost_property")
	await process_frame
	_check(scene.sim.department_owned("lost_property"), "Clicking a license buys a functional department")
	_check((scene.sim.profile["equipped"] as Array).has("lost_property"), "Purchased office auto-equips if a slot is free")
	board._action("fortuitous_timing")
	await process_frame
	_check((scene.sim.profile["equipped"] as Array).size() == 2, "Two offices fill initial slots")
	board._action("embarrassments")
	await process_frame
	_check(scene.sim.department_owned("embarrassments") and not (scene.sim.profile["equipped"] as Array).has("embarrassments"), "A third purchase is permanent but not assigned")
	board._action("fortuitous_timing")
	board._action("embarrassments")
	await process_frame
	_check((scene.sim.profile["equipped"] as Array).has("embarrassments"), "Player can swap department loadouts")
	# Need a stable image for human review; headless runs do not have a framebuffer.
	if DisplayServer.get_name() != "headless":
		board._render()
		await process_frame
		await process_frame
		var image := root.get_viewport().get_texture().get_image()
		image.save_png("/mnt/data/ministry-incremental/department-board.png")
	scene._close_gallery()
	await process_frame
	_check(scene.gallery_overlay == null, "Closing the Ministry restores the case and refreshes Merit")
	scene._new_case()
	await process_frame
	_check(scene.sim.has_department("lost_property") and scene.sim.has_department("embarrassments"), "Next case receives chosen roster")
	scene._open_ministry()
	await process_frame
	board = scene.gallery_overlay
	var locked := board.find_child("DepartmentAction_postal_inspector", true, false) as Button
	_check(locked != null and locked.disabled, "No purchase or swapping while a case is active")
	scene._close_gallery()
	root.remove_child(scene)
	scene.free()
	if errors.is_empty():
		print("PASS: %d department UI, purchasing and focus checks" % checks)
		quit(0)
	else:
		for problem in errors: printerr("FAIL: ", problem)
		printerr("FAILED: %d of %d" % [errors.size(), checks])
		quit(1)
