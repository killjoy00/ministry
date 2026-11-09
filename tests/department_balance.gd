extends SceneTree
## Real-engine seeded runs. Guards deterministic bounds and that departments
## actually change strategic outcomes without granting an automatic win.
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
const Catalog = preload("res://scripts/simulation/department_catalog.gd")
const SAMPLES = 250
var errors: Array[String] = []
func _initialize() -> void:
	var empty_wins: int = 0
	var office_wins: int = 0
	var empty_events: int = 0
	var office_events: int = 0
	var office_fires: int = 0
	var max_history: int = 0
	for seed_id in range(SAMPLES):
		var plain = Simulation.new(seed_id, false)
		var staffed = Simulation.new(seed_id, false)
		staffed.profile["departments"] = {}
		for id in ["lost_property", "fortuitous_timing", "postal_inspector", "chain_reactions", "automatic_paperwork"]:
			(staffed.profile["departments"] as Dictionary)[id] = true
		staffed.profile["equipped"] = ["lost_property", "fortuitous_timing", "postal_inspector", "chain_reactions", "automatic_paperwork"]
		staffed.start_new_run(seed_id)
		for day in range(7):
			plain.advance_day()
			staffed.advance_day()
		if plain.status == "won": empty_wins += 1
		if staffed.status == "won": office_wins += 1
		for e in plain.history:
			if not plain.get_rule(str(e["id"])).is_empty(): empty_events += 1
		for e in staffed.history:
			if not staffed.get_rule(str(e["id"])).is_empty(): office_events += 1
			if str(e["title"]).begins_with("DEPARTMENT /"): office_fires += 1
		max_history = maxi(max_history, staffed.history.size())
		if staffed.history.size() > 300:
			errors.append("Unbounded department chain on seed %d" % seed_id)
		for entry in staffed.history:
			for parent_id in entry["causes"]:
				var found: bool = false
				for earlier in staffed.history:
					if str(earlier["id"]) == str(parent_id) and int(earlier["day"]) <= int(entry["day"]):
						found = true
						break
				if not found:
					errors.append("Phantom cause: " + str(parent_id))
	print("Department baseline: unstaffed %d/%d wins, %.1f real incidents/run" % [empty_wins, SAMPLES, float(empty_events)/SAMPLES])
	print("Department equipped: %d/%d wins, %.1f real incidents/run, %.1f office actions/run; max ledger %d" % [office_wins, SAMPLES, float(office_events)/SAMPLES, float(office_fires)/SAMPLES, max_history])
	if office_events <= empty_events:
		errors.append("Offices must actually generate more causal incidents")
	if office_fires < SAMPLES:
		errors.append("Chosen departments must regularly have observable effects")
	if office_wins >= SAMPLES:
		errors.append("Even well staffed runs should not all win without interventions")
	if errors.is_empty():
		print("PASS: seeded department balance, finite simulation and factual causality")
		quit(0)
	else:
		for err in errors.slice(0, 12): printerr("FAIL: ", err)
		printerr("FAILED: %d violations" % errors.size())
		quit(1)
