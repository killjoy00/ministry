extends SceneTree
## Ten-plus truly mechanical departments: catalog, accounting, old saves,
## seeded deterministic outcomes, and one real effect per office.

const Simulation = preload("res://scripts/simulation/case_simulation.gd")
const Catalog = preload("res://scripts/simulation/department_catalog.gd")
const Board = preload("res://scripts/ui/ministry_board.gd")
const TEST_SAVE = "user://ministry_departments_test.json"
var checks: int = 0
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: errors.append(why)

func _licensed(department_id: String, seed_id: int = 88) -> CaseSimulation:
	var sim: CaseSimulation = Simulation.new(seed_id, false)
	(sim.profile["departments"] as Dictionary)[department_id] = true
	sim.profile["equipped"] = [department_id]
	sim.start_new_run(seed_id)
	return sim

func _recorded(sim: CaseSimulation, id: String) -> bool:
	for event in sim.history:
		if str(event["id"]) == id:
			return true
	return false

func _department_used(sim: CaseSimulation, department_id: String) -> bool:
	for event in sim.history:
		if str(event["title"]) == "DEPARTMENT / " + str(Catalog.DATA[department_id]["name"]).to_upper():
			return true
	return false

func _run() -> void:
	_check(Catalog.ORDER.size() >= 10, "At least ten different offices unlock")
	var ids: Dictionary = {}
	for id in Catalog.ORDER:
		_check(not ids.has(id), "Department IDs are unique: " + id)
		ids[id] = true
		var data: Dictionary = Catalog.get_department(id)
		_check(data.has("name") and data.has("detail") and data.has("tag"), "Department has a display contract: " + id)
		_check(int(data["cost"]) > 0 and int(data["cases"]) >= 0, "Department has earned unlock requirements: " + id)
	var base = Simulation.new(31, false)
	_check(base.owned_department_count() == 0 and base.department_slots() == 2, "New clerk starts with two empty department slots")
	_check(not base.buy_department("lost_property"), "Cannot spend Merit during an active case")
	base.status = "lost"
	base.profile["merit"] = 500
	base.profile["completed"] = 12
	for id in Catalog.ORDER:
		_check(base.buy_department(id), "Department can be bought with earned merit: " + id)
		_check(not base.buy_department(id), "No license can be bought twice: " + id)
	_check(base.owned_department_count() == 12, "All twelve departments are ownable")
	_check(base.department_slots() == 5, "Full Ministry grows to five operational slots")
	_check((base.profile["equipped"] as Array).size() <= base.department_slots(), "Auto-equipping never overflows")
	_check(not base.toggle_department("second_chances"), "Full assignment board rejects a sixth active office")
	_check(base.toggle_department("lost_property"), "Can stand down an office")
	_check(base.toggle_department("second_chances"), "Can assign a different office")
	_check(base.rank_title() == "ACTING DEPUTY TO THE UNIVERSE", "Career rank rises as Ministry expands")
	base.start_new_run(31)
	_check(base.run_departments.size() == 5 and base.has_department("second_chances") and not base.has_department("lost_property"), "Case snapshots chosen departments")
	base.profile["equipped"] = []
	_check(base.run_departments.size() == 5, "Changing a profile does not alter a running case")

	var lost = _licensed("lost_property")
	lost.facts["postal_mixup"] = true
	lost.fact_sources["postal_mixup"] = "post"
	lost.scheduled["wrong_invitation"] = 1
	lost.advance_day()
	_check(lost.has_fact("goose_invited") and not lost.has_fact("mayor_invited"), "Lost Property redirects the real invitation automatically")
	_check(_department_used(lost, "lost_property"), "Lost Property's action is visible in official log")

	var timing = _licensed("fortuitous_timing")
	timing.scheduled["fair"] = 1
	timing.advance_day()
	_check(_department_used(timing, "fortuitous_timing"), "Fortuitous Timing synchronizes at same place")

	var embarrassment = _licensed("embarrassments")
	embarrassment.scheduled["coffee"] = 1
	embarrassment.advance_day()
	_check(embarrassment.has_fact("public_gossip") and embarrassment.influence >= 5, "Embarrassments creates gossip and replenishes Influence")
	_check(_department_used(embarrassment, "embarrassments"), "Embarrassment is logged")

	var postal = _licensed("postal_inspector")
	postal.scheduled["post"] = 1
	postal.advance_day()
	_check(_recorded(postal, "wrong_invitation") and _department_used(postal, "postal_inspector"), "Postal inspector guarantees a true postal consequence")

	var double = _licensed("double_booking")
	_check(double.stage_stamp("nudge", "rain"), "First of two stamps can be approved")
	_check(double.stage_stamp("reschedule", "sandwich"), "Second distinct stamp can be approved")
	_check(double.stage_stamp("nudge", "traffic"), "The second approval can be changed without adding a third slot")
	_check(double.stage_stamp("reschedule", "sandwich"), "A changed second slot remains replaceable")
	_check(not double.second_pending.is_empty() and str(double.second_pending["target"]) == "sandwich", "Only the latest second approval is kept")
	_check(not double.can_stamp("nudge", "rain"), "Same event cannot receive duplicate stamps")
	double.advance_day()
	_check(double.influence == 2 and double.scheduled.has("sandwich"), "Both stamps cost Influence; second appointment is actually booked")

	var appointments = _licensed("appointment_bureau")
	appointments.stage_stamp("reschedule", "rain")
	appointments.advance_day()
	_check(appointments.scheduled.has("rain") and appointments.scheduled.has("traffic"), "Convenient Appointments books a real sibling at the same place")
	appointments.advance_day()
	_check(appointments.fired.has("rain") and appointments.fired.has("traffic"), "Both rescheduled cases actually happen next day")

	var echo = _licensed("echo_chamber")
	echo.facts["postal_mixup"] = true
	echo.fact_sources["postal_mixup"] = "post"
	echo.scheduled["wrong_invitation"] = 1
	echo.advance_day()
	_check(echo.has_fact("mayor_invited") and echo.has_fact("goose_invited"), "Parallel Outcomes records both branches, not cosmetic text")

	var rumour = _licensed("rumour_mill")
	rumour.facts["mayor_embarrassed"] = true
	rumour.fact_sources["mayor_embarrassed"] = "speech_ruined"
	rumour.scheduled["scandal"] = 1
	rumour.advance_day()
	_check(rumour.has_fact("public_interest") and _department_used(rumour, "rumour_mill"), "Rumour Mill injects a new public-interest prerequisite")
	_check(not rumour.get_rule("rumour_circulates").is_empty(), "Public interest has real downstream content")

	var reconciliation = _licensed("reality_reconciliation")
	reconciliation.corrections = [{"day": 1, "id": "gust", "title": "Wind"}]
	reconciliation.advance_day()
	_check(reconciliation.has_fact("posters_loose") and reconciliation.has_fact("pavement_wet"), "Reconciliation resolves two distinct correction families")
	_check(_recorded(reconciliation, "correction_reconciled_1"), "Second correction is a recorded real event")

	var chain = _licensed("chain_reactions")
	chain.scheduled["post"] = 1
	chain.advance_day()
	_check(chain.fired.has("wrong_invitation") and _department_used(chain, "chain_reactions"), "Knock-on Effects guarantees its first eligible child")

	var appeals_found: bool = false
	for seed_id in range(120):
		var appeal = _licensed("second_chances", seed_id)
		appeal.stage_stamp("nudge", "wind")
		appeal.advance_day()
		if appeal.scheduled.has("wind"):
			appeals_found = true
			_check(_department_used(appeal, "second_chances"), "Failed stamped attempt gets a visible appeal")
			appeal.advance_day()
			_check(appeal.fired.has("wind"), "Appealed incident is guaranteed on the next day")
			break
	_check(appeals_found, "Some stamps fail, making appeals meaningful")

	var paperwork = _licensed("automatic_paperwork")
	paperwork.facts["fair"] = true
	paperwork.fact_sources["fair"] = "fair"
	paperwork.facts["sandwich"] = true
	paperwork.fact_sources["sandwich"] = "sandwich"
	paperwork.scheduled["goose_hungry"] = 1
	paperwork.advance_day()
	_check(paperwork.fired.has("fair_prize") and _department_used(paperwork, "automatic_paperwork"), "Self-filing office completes valid multi-prerequisite consequences")

	# Two identical staffed cases produce exactly the same event log. Unstaffed
	# run remains backward-compatible, so baseline balancing still applies.
	var one = _licensed("fortuitous_timing", 104)
	var two = _licensed("fortuitous_timing", 104)
	for sim in [one, two]:
		sim.stage_stamp("nudge", "post")
		for i in range(7): sim.advance_day()
	_check(JSON.stringify(one.history) == JSON.stringify(two.history), "Staffed cases replay deterministically from seed and actions")

	if FileAccess.file_exists(TEST_SAVE): DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	var save = Simulation.new(104, true, TEST_SAVE)
	save.status = "lost"
	save.profile["merit"] = 100
	save.profile["completed"] = 12
	_check(save.buy_department("lost_property"), "Merit can buy a license in real persistence mode")
	save.start_new_run(105)
	var reopened = Simulation.new(-1, true, TEST_SAVE)
	_check(reopened.department_owned("lost_property") and reopened.has_department("lost_property"), "Department ownership and assigned case survive a real save/load")
	# Simulate the previous game's v1 save format, including its profile without
	# departments. No user's old Merit or desk upgrades may be lost.
	var v1: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TEST_SAVE))
	v1["version"] = 1
	v1.erase("run_departments")
	v1.erase("second_pending")
	v1["profile"] = {"merit": 71, "completed": 3, "desk": 2, "ink": 1, "audit": 1}
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(v1))
	file.close()
	var legacy = Simulation.new(-1, true, TEST_SAVE)
	_check(legacy.profile["merit"] == 71 and legacy.profile["desk"] == 2 and legacy.owned_department_count() == 0, "v1 saves preserve earned progress, upgrade levels and begin without departments")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))

	var board := Board.new()
	board.configure(base)
	root.add_child(board)
	board._render()
	await process_frame
	await process_frame
	_check(board.find_child("DepartmentCardGrid", true, false) != null, "Actual in-game board contains department cards")
	_check(board.find_child("DepartmentAction_lost_property", true, false) != null, "Each of twelve departments is controller-addressable")
	_check(board.find_child("DepartmentAction_automatic_paperwork", true, false) != null, "Automated office is included, not just promised")
	root.remove_child(board)
	board.free()
	if errors.is_empty():
		print("PASS: %d department, progression, causality and migration checks" % checks)
		quit(0)
	else:
		for problem in errors: printerr("FAIL: ", problem)
		printerr("FAILED: %d / %d" % [errors.size(), checks])
		quit(1)
