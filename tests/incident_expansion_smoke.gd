extends SceneTree
## The new incident branches are reachable, truly causal, and seeded.
const Cases = preload("res://scripts/scenarios/case_catalog.gd")
const Expanded = preload("res://scripts/scenarios/expanded_incidents.gd")
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
const SEEDS: int = 45
var checks: int = 0
var problems: Array[String] = []

func _initialize() -> void:
	_run()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		problems.append(message)

func _run() -> void:
	var total_new: int = Expanded.shared_rules().size()
	_check(Expanded.SHARED_IDS.size() == Expanded.shared_rules().size(), "Shared ID index covers the complete shared extension")
	for case_id in Cases.ORDER:
		total_new += Expanded.case_rules(str(case_id)).size()
	var unique_new: Dictionary = {}
	for rule in Expanded.shared_rules():
		unique_new[str(rule["id"])] = true
	for case_id in Cases.ORDER:
		for rule in Expanded.case_rules(str(case_id)):
			var id: String = str(rule["id"])
			_check(not unique_new.has(id), "Incident has globally unique ID: " + id)
			unique_new[id] = true
	_check(total_new >= 105, "At least 105 substantial new incident rules, not reused descriptions")
	for case_id in Cases.ORDER:
		var id: String = str(case_id)
		var catalog: Array = Cases.rules(id)
		var local_ids: Dictionary = {}
		var source_facts: Dictionary = {}
		var original_starts: int = 0
		var new_count: int = 0
		for rule in catalog:
			var name: String = str(rule["id"])
			_check(not local_ids.has(name), "No duplicate IDs in " + id + ": " + name)
			local_ids[name] = true
			_check(float(rule["chance"]) > 0.0 and float(rule["chance"]) < 1.0, "Valid event chance: " + name)
			_check(not str(rule["title"]).is_empty() and str(rule["text"]).length() >= 28 and not str(rule["place"]).is_empty(), "Authored title, scene and location: " + name)
			if (rule["all"] as Array).is_empty() and (rule["any"] as Array).is_empty():
				original_starts += 1
			for fact in rule["facts"]:
				source_facts[str(fact)] = true
			for fact in rule["misfile_facts"]:
				source_facts[str(fact)] = true
			if unique_new.has(name):
				new_count += 1
				_check(not ((rule["all"] as Array).is_empty() and (rule["any"] as Array).is_empty()), "No new incident bloats the first-turn incident tray: " + name)
				_check(int(rule["support"]) <= 1, "New support does not bypass case planning: " + name)
		_check(original_starts <= 11, "First-turn incident list stays navigable in " + id)
		_check(new_count >= 37, "At least 37 genuinely new branch rules appear in " + id)
		# A fact must be a consequence of a real authored event (or an explicit
		# departmental effect / scheduled reality correction, never a magic fact).
		var permitted_external: Array[String] = ["public_gossip", "public_interest", "rumour_spread", "correction_gust", "correction_reassignment", "correction_shower", "posters_shifted"]
		for rule in catalog:
			for fact in (rule["all"] as Array) + (rule["any"] as Array):
				_check(source_facts.has(str(fact)) or permitted_external.has(str(fact)), "Prerequisite has an authored producer in " + id + ": " + str(fact))
		# Possible reachability: start from root incidents and close over all
		# authored normal and Misfile outputs, without assuming a lucky random run.
		var reachable: Dictionary = {}
		var reached_events: Dictionary = {}
		for step in range(catalog.size() + 2):
			var changed: bool = false
			for rule in catalog:
				var name: String = str(rule["id"])
				if reached_events.has(name): continue
				var qualifies: bool = true
				for fact in rule["all"]:
					if not reachable.has(str(fact)):
						qualifies = false
				if not (rule["any"] as Array).is_empty():
					var any_match: bool = false
					for fact in rule["any"]:
						if reachable.has(str(fact)):
							any_match = true
					if not any_match: qualifies = false
				if not qualifies: continue
				reached_events[name] = true
				for fact in (rule["facts"] as Array) + (rule["misfile_facts"] as Array):
					reachable[str(fact)] = true
				changed = true
			if not changed: break
		for rule in catalog:
			if unique_new.has(str(rule["id"])):
				_check(reached_events.has(str(rule["id"])), "New story incident has a possible chain from a natural root: " + id + " / " + str(rule["id"]))
		for win_fact in Cases.description(id)["win_facts"]:
			_check(reachable.has(str(win_fact)), "Original case objective remains achievable: " + str(win_fact))
		var observed: Dictionary = {}
		var total_seen: int = 0
		for seed in range(SEEDS):
			var sim = Simulation.new(10000 + seed, false)
			sim.profile["completed"] = 20
			sim.start_new_run(10000 + seed, id)
			for day in range(int(sim.case_info["deadline"])):
				# Different deterministic choices favor different branches rather
				# than always steering into an incumbent winning script.
				var candidates: Array = sim.available_events()
				if not candidates.is_empty():
					var chosen: Dictionary = candidates[(seed + day * 3) % candidates.size()]
					if sim.can_stamp("nudge", str(chosen["id"])):
						sim.stage_stamp("nudge", str(chosen["id"]))
				sim.advance_day()
			for record in sim.history:
				var name: String = str(record.get("id", ""))
				if unique_new.has(name):
					observed[name] = true
					total_seen += 1
		_check(observed.size() >= 8, "At least eight new incident types actually fire over seeded play in " + id)
		print("INCIDENT ATLAS %s: %d total, %d new, %d root, %d unique new seen / %d fired in %d playthroughs" % [id, catalog.size(), new_count, original_starts, observed.size(), total_seen, SEEDS])
		# Fixing the seed and interventions must reproduce the story identically.
		var one = Simulation.new(81811, false)
		var two = Simulation.new(81811, false)
		one.profile["completed"] = 20
		two.profile["completed"] = 20
		one.start_new_run(81811, id)
		two.start_new_run(81811, id)
		for day in range(int(one.case_info["deadline"])):
			for s in [one, two]:
				var avail: Array = s.available_events()
				if not avail.is_empty() and s.can_stamp("nudge", str(avail[0]["id"])):
					s.stage_stamp("nudge", str(avail[0]["id"]))
				s.advance_day()
		_check(JSON.stringify(one.history) == JSON.stringify(two.history), "Seeded event chain remains deterministic in " + id)
		_check(one.support == two.support and one.status == two.status, "Seeded outcomes remain deterministic in " + id)
	if problems.is_empty():
		print("PASS: %d incident expansion, provenance and repeat-play assertions (%d new authored rules)" % [checks, total_new])
		quit(0)
	else:
		for failure in problems: printerr("FAIL: " + failure)
		printerr("FAILED: %d of %d assertions" % [problems.size(), checks])
		quit(1)
