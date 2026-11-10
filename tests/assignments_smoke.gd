extends SceneTree
## Contract tests for solvable hard cases, save migration, unlocks and replay.
const Cases = preload("res://scripts/scenarios/case_catalog.gd")
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
var checks := 0
var errors: Array[String] = []
const TEMP_SAVE = "user://ministry_assignments_test.json"

func _check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		errors.append(reason)

func _initialize() -> void:
	var sim = Simulation.new(101, false)
	_check(sim.case_id == "fowl", "New games begin with the goose election")
	_check(not sim.case_unlocked("bakery") and not sim.case_unlocked("thursday") and not sim.case_unlocked("apology"), "Advanced assignments begin locked")
	_check(not sim.start_new_run(101, "apology"), "Locked assignments cannot be selected through game API")
	_check(sim.case_id == "fowl", "Refusing a locked case does not replace the current case")
	for id in Cases.ORDER:
		var spec: Dictionary = Cases.description(id)
		var recipes: Array = Cases.rules(id)
		_check(not recipes.is_empty(), "%s has real events" % id)
		_check(spec["win_facts"].size() == spec["requirement_labels"].size(), "%s lists every objective" % id)
		_check(int(spec["deadline"]) >= 7 and int(spec["required_support"]) > 0, "%s has a measurable challenge" % id)
		var event_ids: Dictionary = {}
		var possible: Dictionary = {}
		for rule in recipes:
			var event_id: String = str(rule["id"])
			_check(not event_ids.has(event_id), "No duplicated rule ID %s in %s" % [event_id, id])
			event_ids[event_id] = true
		# Conservative causal closure: only authored facts can enable another
		# event. If a required fact is missing from closure the case is impossible.
		for pass_index in range(recipes.size() + 1):
			for rule in recipes:
				var all_done: bool = true
				for required in rule["all"]:
					if not possible.has(required): all_done = false
				var any_done: bool = (rule["any"] as Array).is_empty()
				for possible_req in rule["any"]:
					if possible.has(possible_req): any_done = true
				if all_done and any_done:
					for created in rule["facts"]:
						possible[created] = true
					for created in rule["misfile_facts"]:
						possible[created] = true
		for fact in spec["win_facts"]:
			_check(possible.has(fact), "%s win condition must be reachable by authored rules: %s" % [id, fact])
		sim.profile["completed"] = int(spec["unlock_cases"])
		_check(sim.case_unlocked(id), "%s unlocks at its published threshold" % id)
		_check(sim.start_new_run(205, id), "%s can be started when unlocked" % id)
		_check(sim.case_id == id and sim.case_info["id"] == id, "%s uses correct contract" % id)
		_check(sim.rules.size() == recipes.size(), "%s loads its case-specific catalog" % id)
		_check(sim.case_objective_progress().size() == spec["win_facts"].size(), "%s objective progress is displayed" % id)
		_check(not sim.case_objectives_met(), "%s cannot be completed with no causal outcomes" % id)
		# A case cannot succeed solely on accumulated momentum; all named
		# outcome facts are mandatory, including the final official act.
		sim.support = 999
		_check(not sim.case_objectives_met(), "%s requires actual goals even with excess momentum" % id)
		sim.support = 0
		var replica = Simulation.new(205, false)
		replica.profile["completed"] = int(spec["unlock_cases"])
		replica.start_new_run(205, id)
		for day_index in range(int(spec["deadline"])):
			sim.advance_day()
			replica.advance_day()
		_check(JSON.stringify(sim.history) == JSON.stringify(replica.history), "%s replays identically with same seed and actions" % id)
		_check(sim.status == replica.status, "%s resolves deterministically" % id)
		_check(sim.reward_paid, "%s awards Merit at most once" % id)
		var previous_merit: int = int(sim.profile["merit"])
		sim.advance_day()
		_check(int(sim.profile["merit"]) == previous_merit, "%s never pays a second reward after resolution" % id)
	_check(Cases.ORDER.size() >= 4, "At least three challenging new assignments ship")
	_check(not sim.case_unlocked("made_up_case"), "Unknown assignments cannot be selected")
	# v2 migration: load a simulated old file without case_id and with owned
	# departments, then confirm no corruption and fowl remains the current case.
	var saved = Simulation.new(303, true, TEMP_SAVE)
	saved.profile["merit"] = 41
	saved.profile["completed"] = 6
	saved.profile["departments"] = {"lost_property": true}
	saved.profile["equipped"] = ["lost_property"]
	saved.save_game()
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TEMP_SAVE))
	legacy["version"] = 2
	legacy.erase("case_id")
	(legacy["profile"] as Dictionary).erase("case_wins")
	var file := FileAccess.open(TEMP_SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var recovered = Simulation.new(-1, true, TEMP_SAVE)
	_check(recovered.case_id == "fowl" and recovered.case_info["id"] == "fowl", "Old saves load the original election")
	_check(int(recovered.profile["merit"]) == 41 and int(recovered.profile["completed"]) == 6, "Old Merit and completed cases are preserved")
	_check(recovered.department_owned("lost_property") and recovered.case_unlocked("thursday"), "Department licenses and advanced assignment unlocks survive migration")
	recovered.start_new_run(99, "thursday")
	recovered.save_game()
	var again = Simulation.new(-1, true, TEMP_SAVE)
	_check(again.case_id == "thursday" and again.case_info["win_facts"].size() == 3, "v3 persists the selected challenge for resume")
	_check(again.seed == 99 and again.day == 1 and again.has_department("lost_property"), "v3 restores the case seed and active offices")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SAVE))
	if errors.is_empty():
		print("PASS: %d assignment contracts, unlocks, deterministic replay and save migration checks" % checks)
		quit(0)
	else:
		for error in errors: printerr("FAIL: ", error)
		printerr("FAILED: %d of %d checks" % [errors.size(), checks])
		quit(1)
