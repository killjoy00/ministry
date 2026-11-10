extends SceneTree
## First-run practice is isolated; inspection uses proven historical parents.
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
const Logic = preload("res://scripts/simulation/causal_inspection.gd")
const Tutorial = preload("res://scripts/ui/first_day_tutorial.gd")
const Inspector = preload("res://scripts/ui/causality_inspector.gd")
var assertions: int = 0
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, msg: String) -> void:
	assertions += 1
	if not ok: errors.append(msg)

func _run() -> void:
	var sim := Simulation.new(1, false)
	var before: Dictionary = Logic.inspect(sim, "sandwich")
	_check(not before.is_empty(), "Known incident has a dossier")
	_check(not before["occurred"], "Unhappened events cannot be claimed as recorded")
	_check(before["eligible"], "Unconditional event available")
	_check((before["conditions"] as Array).is_empty(), "No fictional prerequisites")
	_check((before["branches"] as Array).any(func(b): return b["id"] == "goose_hungry"), "Sandwich can plausibly unlock Gerald's search")
	_check(is_equal_approx(float(before["nudge"]), 0.98), "Nudge preview capped to actual 98% rule")
	_check(not before["misfile_allowed"], "Misfile cannot be advertised on incident without alternate result")
	var redirected: Dictionary = Logic.inspect(sim, "wrong_invitation")
	_check(redirected["misfile_allowed"], "Eligible Misfile alternative is shown")
	_check((redirected["branches"] as Array).any(func(b): return b["id"] == "goose_stage" and b["route"] == "MISFILE"), "Misfile opens a clearly differentiated route to Gerald's stage")
	var blocked: Dictionary = Logic.inspect(sim, "goose_stage")
	_check(not blocked["eligible"], "Later stage appearance is blocked")
	_check((blocked["conditions"] as Array).any(func(c): return c["fact"] == "Crowd" and not c["met"]), "Required crowd shown as missing")
	_check((blocked["conditions"] as Array).any(func(c): return c["kind"] == "ANY"), "Alternative factual prerequisites shown")
	_check(sim.stage_stamp("nudge", "sandwich"), "Practice Nudge is accepted")
	sim.advance_day()
	var after: Dictionary = Logic.inspect(sim, "goose_hungry")
	_check(after["occurred"], "Seeded practice causes Gerald to follow the sandwich")
	_check((after["parents"] as Array).any(func(p): return p["id"] == "sandwich"), "Recorded cause points to actual sandwich event")
	_check(not after["actual_record"].is_empty(), "History record is available for inspection")
	_check(Logic.inspect(sim, "front_page")["actual_record"].is_empty(), "Future events remain unrecorded")
	for e in sim.history:
		if (e.get("facts", []) as Array).is_empty(): continue
		var current: Dictionary = Logic.inspect(sim, str(e["id"]))
		if current.is_empty(): continue
		for p in current["parents"]:
			_check(not Logic._recorded(sim, str(p["id"])).is_empty() or str(p["id"]).begins_with("correction_"), "Recorded parents come from actual events")
	var control: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(control)
	control.sim = sim
	control._render()
	await process_frame
	await process_frame
	_check(_find_button(control, "WHY?") != null, "WHY? button is visible on the case")
	_check(_find_button(control, "?  HELP") != null, "Help button reopens practice")
	control._open_inspector("goose_hungry")
	await process_frame
	await process_frame
	_check(control.gallery_overlay is Inspector, "Full-screen incident inspector is controller accessible")
	_check(control.gallery_overlay.event_id == "goose_hungry", "Inspector opens selected event")
	_check(_find_button(control.gallery_overlay, "B  RETURN TO CASE") != null, "Inspector B return shown")
	_check(_find_button(control.gallery_overlay, "An Abandoned Sandwich") != null, "Recorded source can be inspected with A")
	control.gallery_overlay._visit("sandwich")
	await process_frame
	_check(control.gallery_overlay.event_id == "sandwich", "Following linked evidence updates the dossier")
	control._close_gallery()
	control._open_tutorial()
	await process_frame
	await process_frame
	_check(control.gallery_overlay is Tutorial, "Four-step practice is available manually")
	var practice: CaseSimulation = control.gallery_overlay.practice
	_check(not practice.persist, "Practice has no persistence")
	_check(practice.seed == Tutorial.PRACTICE_SEED, "Practice seed is stable and reproducible")
	var profile_before: Dictionary = sim.profile.duplicate(true)
	var history_before: int = sim.history.size()
	var day_before: int = sim.day
	control.gallery_overlay._next()
	_check(control.gallery_overlay.step == 1, "Welcome advances to stamp briefing")
	control.gallery_overlay._next()
	_check(control.gallery_overlay.step == 2 and not practice.pending.is_empty(), "Practice stamps Nudge")
	control.gallery_overlay._next()
	_check(control.gallery_overlay.step == 3 and practice.day == 2, "Practice resolves real seeded events")
	_check((Logic.inspect(practice, "goose_hungry")["parents"] as Array).size() > 0, "Practice explanation uses actual causal link")
	_check(sim.day == day_before and sim.history.size() == history_before and sim.profile == profile_before, "Practice cannot affect real case or Merit")
	control.gallery_overlay._next() # finishes and stores only the separate help preference
	await process_frame
	_check(control.gallery_overlay == null, "Returning from briefing restores the game")
	_check(control.get_viewport().get_visible_rect().size == Vector2(1280, 800), "All UI tests run at Steam Deck native target")
	root.remove_child(control)
	control.free()
	if errors.is_empty():
		print("PASS: %d first-run and causality assertions" % assertions)
		quit(0)
	else:
		for e in errors: printerr("FAIL: ", e)
		quit(1)

func _find_button(node: Node, caption: String) -> Button:
	if node is Button and (node as Button).text.begins_with(caption): return node as Button
	for child in node.get_children():
		var found := _find_button(child, caption)
		if found != null: return found
	return null
