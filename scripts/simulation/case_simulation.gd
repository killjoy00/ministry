extends RefCounted
class_name CaseSimulation
## UI-independent, seeded rules simulation. All outcomes and provenance are journaled.

const Cases = preload("res://scripts/scenarios/case_catalog.gd")
const Departments = preload("res://scripts/simulation/department_catalog.gd")
const SAVE_PATH = "user://ministry_case_save.json"
const SAVE_VERSION = 3
const STAMPS = {
	"nudge": {"name": "Nudge", "cost": 2, "strain": 2, "description": "+55% chance today"},
	"misfile": {"name": "Misfile", "cost": 3, "strain": 3, "description": "+40% chance; redirect outcome"},
	"reschedule": {"name": "Reschedule", "cost": 2, "strain": 1, "description": "Guarantee event tomorrow"},
	"domino": {"name": "Domino Permit", "cost": 3, "strain": 3, "description": "+25%; force first new consequence"}
}
const STAMP_ORDER = ["nudge", "misfile", "reschedule", "domino"]
const CORRECTIONS = [
	{"id": "gust", "title": "CORRECTION: A Stiff Bureaucratic Breeze", "text": "Reality discharges an unexpected gust. Several campaign posters become airborne.", "facts": ["wind", "posters_loose"]},
	{"id": "shower", "title": "CORRECTION: Unseasonal Shower", "text": "The sky issues a formal notice of excessive moisture.", "facts": ["rain", "pavement_wet"]},
	{"id": "letter", "title": "CORRECTION: Office Mail Misrouted", "text": "An urgent letter arrives at exactly the wrong desk.", "facts": ["postal_mixup", "misdirected_mail"]}
]

var persist: bool = true
var save_path: String = SAVE_PATH
var rng := RandomNumberGenerator.new()
var seed: int = 0
var rules: Array = []
var case_id: String = "fowl"
var case_info: Dictionary = {}
var profile: Dictionary = {"merit": 0, "completed": 0, "desk": 0, "ink": 0, "audit": 0, "departments": {}, "equipped": [], "case_wins": {}}
var day: int = 1
var status: String = "active"
var facts: Dictionary = {}
var fact_sources: Dictionary = {}
var fired: Dictionary = {}
var history: Array = []
var support: int = 0
var influence: int = 4
var strain: int = 0
var pending: Dictionary = {}
var second_pending: Dictionary = {}
var run_departments: Array = []
var scheduled: Dictionary = {}
var corrections: Array = []
var reward_paid: bool = false
var last_outcome: String = ""

func _init(custom_seed: int = -1, enable_persistence: bool = true, custom_save_path: String = "") -> void:
	persist = enable_persistence
	if not custom_save_path.is_empty():
		save_path = custom_save_path
	rules = Cases.rules(case_id)
	case_info = Cases.description(case_id)
	if persist and custom_seed < 0 and load_game():
		return
	start_new_run(custom_seed)

# Permanent licenses are earned with Merit; only the selected offices operate
# on a given case. This prevents twelve effects from all stacking automatically.
func owned_department_count() -> int:
	return (profile.get("departments", {}) as Dictionary).size()

func department_slots() -> int:
	var owned: int = owned_department_count()
	return 2 + int(owned >= 4) + int(owned >= 8) + int(owned >= 12)

func has_department(id: String) -> bool:
	return run_departments.has(id)

func department_owned(id: String) -> bool:
	return bool((profile.get("departments", {}) as Dictionary).get(id, false))

func buy_department(id: String) -> bool:
	if status == "active" or not Departments.is_known(id) or department_owned(id):
		return false
	var details: Dictionary = Departments.get_department(id)
	if int(profile.get("completed", 0)) < int(details["cases"]):
		return false
	var price: int = int(details["cost"])
	if int(profile.get("merit", 0)) < price:
		return false
	profile["merit"] = int(profile["merit"]) - price
	var licenses: Dictionary = profile.get("departments", {})
	licenses[id] = true
	profile["departments"] = licenses
	var equipped: Array = profile.get("equipped", [])
	if equipped.size() < department_slots():
		equipped.append(id)
	profile["equipped"] = equipped
	save_game()
	return true

func toggle_department(id: String) -> bool:
	if status == "active" or not department_owned(id):
		return false
	var equipped: Array = profile.get("equipped", [])
	if equipped.has(id):
		equipped.erase(id)
	elif equipped.size() < department_slots():
		equipped.append(id)
	else:
		return false
	profile["equipped"] = equipped
	save_game()
	return true

func rank_title() -> String:
	var owned: int = owned_department_count()
	if owned >= 12: return "ACTING DEPUTY TO THE UNIVERSE"
	if owned >= 8: return "UNDERSECRETARY OF IMPROBABILITY"
	if owned >= 4: return "REGIONAL DIRECTOR OF HAPPENSTANCE"
	if owned >= 2: return "SENIOR COINCIDENCE OFFICER"
	return "JUNIOR CLERK"

# Later assignments are unlocked by cases filed, including older save files.
# The selection is locked at run start, alongside the department loadout.
func case_unlocked(id: String) -> bool:
	if not Cases.is_known(id):
		return false
	return int(profile.get("completed", 0)) >= int(Cases.description(id)["unlock_cases"])

func case_objectives_met() -> bool:
	if support < int(case_info["required_support"]):
		return false
	for fact_id in case_info["win_facts"]:
		if not has_fact(str(fact_id)):
			return false
	return true

func case_objective_progress() -> Array:
	var progress: Array = []
	var requirements: Array = case_info["win_facts"]
	var labels: Array = case_info["requirement_labels"]
	for index in range(requirements.size()):
		progress.append({"label": str(labels[index]), "done": has_fact(str(requirements[index]))})
	return progress

func _department_note(id: String, message: String) -> void:
	_note("DEPARTMENT / " + str(Departments.get_department(id)["name"]).to_upper(), message, "", [])

func maximum_influence() -> int:
	return 8 + int(profile.get("desk", 0)) * 2

func starting_influence() -> int:
	return min(maximum_influence(), 4 + int(profile.get("ink", 0)))

func start_new_run(requested_seed: int = -1, requested_case_id: String = "") -> bool:
	if not requested_case_id.is_empty():
		if not case_unlocked(requested_case_id):
			return false
		case_id = requested_case_id
	if not Cases.is_known(case_id):
		case_id = "fowl"
	rules = Cases.rules(case_id)
	case_info = Cases.description(case_id)
	if requested_seed >= 0:
		seed = requested_seed
	else:
		seed = int(Time.get_unix_time_from_system()) + int(profile.get("completed", 0)) * 101 + rng.randi_range(1, 100000)
	rng.seed = seed
	day = 1
	status = "active"
	facts = {}
	fact_sources = {}
	fired = {}
	history = []
	support = 0
	influence = starting_influence()
	strain = 0
	pending = {}
	second_pending = {}
	run_departments = []
	var equipped: Array = profile.get("equipped", [])
	for department_id in equipped:
		var id: String = str(department_id)
		if Departments.is_known(id) and department_owned(id) and not run_departments.has(id) and run_departments.size() < department_slots():
			run_departments.append(id)
	scheduled = {}
	corrections = []
	reward_paid = false
	last_outcome = ""
	# Each assignment has its own bureaucracy, but the same deterministic RNG.
	var notes: Array = case_info["open_notes"]
	_note("CASE OPENED: " + str(case_info["title"]), str(notes[rng.randi_range(0, notes.size() - 1)]), "", [])
	save_game()
	return true

func has_fact(fact_id: String) -> bool:
	return bool(facts.get(fact_id, false))

func _eligible(rule: Dictionary) -> bool:
	if fired.has(rule["id"]):
		return false
	for fact_id in rule["all"]:
		if not has_fact(str(fact_id)):
			return false
	if not (rule["any"] as Array).is_empty():
		var found := false
		for fact_id in rule["any"]:
			if has_fact(str(fact_id)):
				found = true
		if not found:
			return false
	return true

func available_events() -> Array:
	var result: Array = []
	for rule in rules:
		if _eligible(rule):
			result.append(rule)
	return result

func get_rule(rule_id: String) -> Dictionary:
	for rule in rules:
		if rule["id"] == rule_id:
			return rule
	return {}

func missing_requirements(rule: Dictionary) -> Array:
	var missing: Array = []
	for fact_id in rule["all"]:
		if not has_fact(str(fact_id)):
			missing.append(str(fact_id).replace("_", " "))
	if not (rule["any"] as Array).is_empty():
		var has_one := false
		for fact_id in rule["any"]:
			if has_fact(str(fact_id)):
				has_one = true
		if not has_one:
			missing.append("one of: " + ", ".join(PackedStringArray(rule["any"])))
	return missing

func can_stamp(stamp_id: String, event_id: String) -> bool:
	if status != "active" or not STAMPS.has(stamp_id):
		return false
	var rule := get_rule(event_id)
	if rule.is_empty() or not _eligible(rule):
		return false
	if stamp_id == "misfile" and (rule["misfile_facts"] as Array).is_empty():
		return false
	if has_department("double_booking") and not pending.is_empty():
		if str(pending.get("target", "")) == event_id:
			return false
		return influence >= int(STAMPS[stamp_id]["cost"]) + int(STAMPS[pending["stamp"]]["cost"])
	return influence >= int(STAMPS[stamp_id]["cost"])

func stage_stamp(stamp_id: String, event_id: String) -> bool:
	if not can_stamp(stamp_id, event_id):
		return false
	if has_department("double_booking") and not pending.is_empty():
		second_pending = {"stamp": stamp_id, "target": event_id}
	else:
		pending = {"stamp": stamp_id, "target": event_id}
		second_pending = {}
	save_game()
	return true

func clear_stamp() -> void:
	pending = {}
	second_pending = {}
	save_game()

func forecast() -> String:
	if corrections.is_empty():
		return "No correction currently forecast."
	for entry in corrections:
		if int(entry["day"]) >= day:
			return "Day %d: %s" % [int(entry["day"]), str(entry["title"])]
	return "No correction currently forecast."

func advance_day() -> void:
	if status != "active":
		return
	var interventions: Array = []
	if not pending.is_empty():
		interventions.append(pending.duplicate(true))
	if not second_pending.is_empty() and has_department("double_booking"):
		interventions.append(second_pending.duplicate(true))
	pending = {}
	second_pending = {}
	var appointment_used: bool = false
	for intervention in interventions:
		var stamp: Dictionary = STAMPS[intervention["stamp"]]
		influence -= int(stamp["cost"])
		strain += max(1, int(stamp["strain"]) - int(profile.get("audit", 0)))
		_note("APPROVED", "%s approved for %s." % [stamp["name"], get_rule(str(intervention["target"]))["title"]], "", [])
		if intervention["stamp"] == "reschedule":
			var target: String = str(intervention["target"])
			scheduled[target] = day + 1
			_note("RESCHEDULED", "An event has been moved to tomorrow's diary.", "", [])
			if has_department("appointment_bureau") and not appointment_used:
				var place: String = str(get_rule(target)["place"])
				for rule in available_events():
					var sibling: String = str(rule["id"])
					if sibling != target and str(rule["place"]) == place and not scheduled.has(sibling):
						scheduled[sibling] = day + 1
						appointment_used = true
						_department_note("appointment_bureau", "A second appointment was booked at %s for Day %d." % [place, day + 1])
						break
		if strain >= 6:
			strain -= 6
			var correction: Dictionary = CORRECTIONS[rng.randi_range(0, CORRECTIONS.size() - 1)]
			corrections.append({"day": day + 1, "title": correction["title"], "id": correction["id"]})
			_note("CORRECTION FORECAST", "%s is scheduled for Day %d." % [correction["title"], day + 1], "", [])
	var correction_facts: Array = _resolve_corrections()
	_resolve_events(interventions, correction_facts)
	if day >= int(case_info["deadline"]):
		if case_objectives_met():
			status = "won"
			last_outcome = str(case_info["success"])
		else:
			status = "lost"
			last_outcome = str(case_info["failure"])
		_settle_case()
	else:
		day += 1
		influence = min(maximum_influence(), influence + int(case_info.get("regen", 2)))
	save_game()

func _resolve_corrections() -> Array:
	var newly_created: Array = []
	var leftovers: Array = []
	var diverted: bool = false
	for item in corrections:
		if int(item["day"]) != day:
			leftovers.append(item)
			continue
		for index in range(CORRECTIONS.size()):
			var correction: Dictionary = CORRECTIONS[index]
			if correction["id"] == item["id"]:
				for fact_id in correction["facts"]:
					if not has_fact(str(fact_id)) and not newly_created.has(fact_id):
						newly_created.append(fact_id)
				var original_id: String = "correction_" + str(correction["id"]) + "_" + str(day)
				_record_event(original_id, correction["title"], correction["text"], correction["facts"], 0, [])
				if has_department("reality_reconciliation") and not diverted:
					var counterpart: Dictionary = CORRECTIONS[(index + 1) % CORRECTIONS.size()]
					var extra_id: String = "correction_reconciled_" + str(day)
					for fact_id in counterpart["facts"]:
						if not has_fact(str(fact_id)) and not newly_created.has(fact_id):
							newly_created.append(fact_id)
					_record_event(extra_id, "CORRECTION RECONCILED", "A second predictable correction is properly recorded: " + str(counterpart["text"]), counterpart["facts"], 0, [original_id])
					_department_note("reality_reconciliation", "Two different reality adjustments have been accepted into the ledger.")
					diverted = true
				break
	corrections = leftovers
	return newly_created

func _resolve_events(interventions: Array, correction_facts: Array) -> void:
	# One or two paid stamps, tomorrow's appointments, two natural opportunities,
	# plus rule-valid departmental reactions. Every event is still bounded and
	# recorded with its real prerequisite provenance.
	var queue: Array = []
	var queued: Dictionary = {}
	var tried: Dictionary = {}
	var used: Dictionary = {}
	var event_count: int = 0
	var domino_targets: Dictionary = {}
	var automatic_links: int = 0
	# Even a fully staffed Ministry may rubber-stamp at most two FREE outcomes
	# per day. Selecting a department should amplify planning, not replace it.
	var automatic_approvals: int = 0
	for intervention in interventions:
		if intervention["stamp"] == "domino":
			domino_targets[str(intervention["target"])] = true
	for rule in rules:
		var id: String = str(rule["id"])
		if scheduled.has(id) and int(scheduled[id]) == day and _eligible(rule):
			queue.append({"id": id, "force": true})
			queued[id] = true
	for intervention in interventions:
		if intervention["stamp"] == "reschedule":
			continue
		var target: String = str(intervention["target"])
		if not queued.has(target):
			queue.append({"id": target, "force": false})
			queued[target] = true
	for rule in rules:
		var id: String = str(rule["id"])
		if not queued.has(id) and _eligible(rule) and _depends_on_any(rule, correction_facts):
			queue.append({"id": id, "force": false})
			queued[id] = true
	var spontaneous: Array = []
	for rule in available_events():
		var id: String = str(rule["id"])
		if not queued.has(id) and not (scheduled.has(id) and int(scheduled[id]) > day):
			spontaneous.append(id)
	for draw in range(mini(int(case_info.get("spontaneous_per_day", 2)), spontaneous.size())):
		var index: int = rng.randi_range(0, spontaneous.size() - 1)
		var pick: String = str(spontaneous[index])
		spontaneous.remove_at(index)
		queue.append({"id": pick, "force": false})
		queued[pick] = true

	while not queue.is_empty() and event_count < int(case_info.get("daily_event_limit", 32)):
		var next: Dictionary = queue.pop_front()
		var id: String = str(next["id"])
		var rule := get_rule(id)
		if tried.has(id) or rule.is_empty() or not _eligible(rule):
			continue
		if scheduled.has(id) and int(scheduled[id]) > day:
			continue
		tried[id] = true
		var probability: float = float(rule["chance"])
		var misfile: bool = false
		var stamped: bool = false
		for intervention in interventions:
			if str(intervention["target"]) != id:
				continue
			stamped = true
			match str(intervention["stamp"]):
				"nudge": probability += 0.55
				"misfile":
					probability += 0.40
					misfile = true
				"domino": probability += 0.25
		var guaranteed: bool = bool(next["force"])
		if not guaranteed and rng.randf() >= minf(probability, 0.98):
			if stamped and has_department("second_chances") and not used.has("second_chances") and day < int(case_info["deadline"]):
				scheduled[id] = day + 1
				used["second_chances"] = true
				_department_note("second_chances", "%s has been granted a guaranteed appeal tomorrow." % rule["title"])
			continue
		if scheduled.has(id):
			scheduled.erase(id)
		var output_facts: Array = (rule["facts"] as Array).duplicate()
		var output_support: int = int(rule["support"])
		var narration: String = str(rule["text"])
		if misfile:
			output_facts = (rule["misfile_facts"] as Array).duplicate()
			output_support = int(rule["misfile_support"])
			narration = str(rule["misfile_text"])
		elif has_department("lost_property") and not used.has("lost_property") and (rule["misfile_facts"] as Array).size() > 0 and ["Post Office", "High Street"].has(str(rule["place"])):
			output_facts = (rule["misfile_facts"] as Array).duplicate()
			output_support = int(rule["misfile_support"])
			narration = str(rule["misfile_text"])
			used["lost_property"] = true
			_department_note("lost_property", "The alternative delivery of %s was authorized automatically." % rule["title"])
		elif has_department("echo_chamber") and not used.has("echo_chamber") and (rule["misfile_facts"] as Array).size() > 0:
			for fact_id in rule["misfile_facts"]:
				if not output_facts.has(fact_id):
					output_facts.append(fact_id)
			used["echo_chamber"] = true
			_department_note("echo_chamber", "Both registered outcomes of %s occurred in parallel." % rule["title"])
		if has_department("embarrassments") and not used.has("embarrassments") and ["coffee", "mayor_late", "scandal", "mayor_embarrassed"].has(id):
			if not has_fact("public_gossip"):
				output_facts.append("public_gossip")
			influence = mini(maximum_influence(), influence + 1)
			used["embarrassments"] = true
			_department_note("embarrassments", "A social blunder created public gossip and restored one Influence.")
		if has_department("rumour_mill") and not used.has("rumour_mill") and output_support > 0:
			if not has_fact("public_interest"):
				output_facts.append("public_interest")
			used["rumour_mill"] = true
			_department_note("rumour_mill", "A piece of public interest was circulated to every newsroom.")
		var newly_created: Array = []
		for fact_id in output_facts:
			if not has_fact(str(fact_id)) and not newly_created.has(fact_id):
				newly_created.append(fact_id)
		_record_event(id, str(rule["title"]), narration, output_facts, output_support, _sources_for_rule(rule))
		fired[id] = true
		event_count += 1

		# Synchronization is an administrative coincidence, not a claim of
		# prerequisite causality: normal event records retain only true parents.
		if has_department("fortuitous_timing") and not used.has("fortuitous_timing") and automatic_approvals < 2:
			for candidate in rules:
				var other_id: String = str(candidate["id"])
				if other_id == id or str(candidate["place"]) != str(rule["place"]):
					continue
				if queued.has(other_id) or tried.has(other_id) or not _eligible(candidate) or (scheduled.has(other_id) and int(scheduled[other_id]) > day):
					continue
				queue.append({"id": other_id, "force": true})
				queued[other_id] = true
				used["fortuitous_timing"] = true
				automatic_approvals += 1
				_department_note("fortuitous_timing", "%s was synchronized with another appointment at %s." % [rule["title"], rule["place"]])
				break
		if has_department("postal_inspector") and not used.has("postal_inspector") and automatic_approvals < 2 and str(rule["place"]) == "Post Office":
			for candidate in rules:
				var child_id: String = str(candidate["id"])
				if queued.has(child_id) or tried.has(child_id) or not _eligible(candidate) or not _depends_on_any(candidate, newly_created):
					continue
				queue.append({"id": child_id, "force": true})
				queued[child_id] = true
				used["postal_inspector"] = true
				automatic_approvals += 1
				_department_note("postal_inspector", "The postal consequence %s was compulsorily processed." % candidate["title"])
				break
		var first_domino: bool = true
		for candidate in rules:
			var child_id: String = str(candidate["id"])
			if queued.has(child_id) or tried.has(child_id) or not _eligible(candidate):
				continue
			if not _depends_on_any(candidate, newly_created):
				continue
			var compel: bool = domino_targets.has(id) and first_domino
			if compel:
				_note("DOMINO ACTIVATED", "A connected consequence has been legally compelled.", id, [])
				first_domino = false
			if has_department("chain_reactions") and not used.has("chain_reactions") and automatic_approvals < 2:
				compel = true
				used["chain_reactions"] = true
				automatic_approvals += 1
				_department_note("chain_reactions", "The first consequence became mandatory under a standing permit.")
			var requires: int = (candidate["all"] as Array).size() + int(not (candidate["any"] as Array).is_empty())
			if has_department("automatic_paperwork") and requires >= 2 and automatic_links < 2 and automatic_approvals < 2:
				compel = true
				automatic_links += 1
				automatic_approvals += 1
				_department_note("automatic_paperwork", "A multi-prerequisite file completed itself: %s." % candidate["title"])
			queue.append({"id": child_id, "force": compel})
			queued[child_id] = true
	if event_count == 0:
		_note("AN UNEVENTFUL DAY", "The town remains disappointingly normal.", "", [])
	else:
		_note("DAILY REGISTER", "%d coincidence%s recorded today." % [event_count, "" if event_count == 1 else "s"], "", [])

func _depends_on_any(rule: Dictionary, new_facts: Array) -> bool:
	for fact_id in rule["all"]:
		if new_facts.has(fact_id):
			return true
	for fact_id in rule["any"]:
		if new_facts.has(fact_id):
			return true
	return false

func _sources_for_rule(rule: Dictionary) -> Array:
	var parents: Array = []
	for fact_id in rule["all"]:
		if fact_sources.has(fact_id) and not parents.has(fact_sources[fact_id]):
			parents.append(fact_sources[fact_id])
	for fact_id in rule["any"]:
		if fact_sources.has(fact_id) and not parents.has(fact_sources[fact_id]):
			parents.append(fact_sources[fact_id])
	return parents

func _record_event(event_id: String, heading: String, description: String, produced_facts: Array, support_gain: int, causes: Array) -> void:
	support += support_gain
	for fact_id in produced_facts:
		if not facts.has(fact_id):
			facts[fact_id] = true
			fact_sources[fact_id] = event_id
	history.append({"day": day, "id": event_id, "title": heading, "text": description, "facts": produced_facts.duplicate(), "support": support_gain, "causes": causes.duplicate()})

func _note(title: String, description: String, source: String, causes: Array) -> void:
	history.append({"day": day, "id": source, "title": title, "text": description, "facts": [], "support": 0, "causes": causes.duplicate()})

func history_summary(limit: int = 11) -> Array:
	var recent: Array = []
	for index in range(history.size() - 1, max(-1, history.size() - limit - 1), -1):
		var e: Dictionary = history[index]
		if e["title"] == "DAILY REGISTER":
			continue
		var parent_titles: Array = []
		for parent_id in e["causes"]:
			var rule := get_rule(str(parent_id))
			if rule.is_empty():
				parent_titles.append(str(parent_id).replace("_", " "))
			else:
				parent_titles.append(str(rule["title"]))
		recent.append({"day": e["day"], "title": e["title"], "text": e["text"], "support": e["support"], "because": ", ".join(PackedStringArray(parent_titles))})
	return recent

func _settle_case() -> void:
	if reward_paid:
		return
	reward_paid = true
	var merit: int = 2 + int(support / 3)
	if status == "won":
		merit += 7 + int(case_info.get("merit_bonus", 0))
		var case_wins: Dictionary = profile.get("case_wins", {})
		case_wins[case_id] = int(case_wins.get(case_id, 0)) + 1
		profile["case_wins"] = case_wins
	profile["merit"] = int(profile.get("merit", 0)) + merit
	profile["completed"] = int(profile.get("completed", 0)) + 1
	_note("CASE " + ("CLOSED" if status == "won" else "FILED AS INCOMPLETE"), "%s Civil Service Merit awarded. %s" % [merit, last_outcome], "", [])

func upgrade_cost(kind: String) -> int:
	match kind:
		"desk": return 5 + int(profile.get("desk", 0)) * 5
		"ink": return 4 + int(profile.get("ink", 0)) * 4
		"audit": return 7 + int(profile.get("audit", 0)) * 6
	return 9999

func buy_upgrade(kind: String) -> bool:
	if status == "active" or not ["desk", "ink", "audit"].has(kind):
		return false
	if int(profile.get(kind, 0)) >= 3:
		return false
	var price := upgrade_cost(kind)
	if int(profile.get("merit", 0)) < price:
		return false
	profile["merit"] = int(profile["merit"]) - price
	profile[kind] = int(profile.get(kind, 0)) + 1
	save_game()
	return true

func save_game() -> void:
	if not persist:
		return
	var data := {
		"version": SAVE_VERSION, "case_id": case_id, "seed": str(seed), "rng_state": str(rng.state),
		"day": day, "status": status, "facts": facts, "fact_sources": fact_sources,
		"fired": fired, "history": history, "support": support, "influence": influence,
		"strain": strain, "pending": pending, "second_pending": second_pending,
		"run_departments": run_departments.duplicate(), "scheduled": scheduled,
		"corrections": corrections, "profile": profile, "reward_paid": reward_paid,
		"last_outcome": last_outcome
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not (parsed is Dictionary):
		return false
	var version: int = int(parsed.get("version", -1))
	if not [1, 2, SAVE_VERSION].has(version):
		return false
	case_id = str(parsed.get("case_id", "fowl"))
	if not Cases.is_known(case_id):
		case_id = "fowl"
	rules = Cases.rules(case_id)
	case_info = Cases.description(case_id)
	seed = int(parsed.get("seed", "0"))
	rng.seed = seed
	rng.state = int(parsed.get("rng_state", str(rng.state)))
	day = int(parsed.get("day", 1))
	status = str(parsed.get("status", "active"))
	facts = parsed.get("facts", {})
	fact_sources = parsed.get("fact_sources", {})
	fired = parsed.get("fired", {})
	history = parsed.get("history", [])
	support = int(parsed.get("support", 0))
	influence = int(parsed.get("influence", 4))
	strain = int(parsed.get("strain", 0))
	pending = parsed.get("pending", {})
	second_pending = parsed.get("second_pending", {})
	scheduled = parsed.get("scheduled", {})
	corrections = parsed.get("corrections", [])
	var old_profile: Dictionary = parsed.get("profile", {})
	profile = {"merit": int(old_profile.get("merit", 0)), "completed": int(old_profile.get("completed", 0)), "desk": int(old_profile.get("desk", 0)), "ink": int(old_profile.get("ink", 0)), "audit": int(old_profile.get("audit", 0)), "departments": {}, "equipped": [], "case_wins": {}}
	var wins: Dictionary = old_profile.get("case_wins", {})
	for id in Cases.ORDER:
		if int(wins.get(id, 0)) > 0:
			(profile["case_wins"] as Dictionary)[id] = int(wins[id])
	var licenses: Dictionary = old_profile.get("departments", {})
	for id in Departments.ORDER:
		if bool(licenses.get(id, false)):
			(profile["departments"] as Dictionary)[id] = true
	var choices: Array = old_profile.get("equipped", [])
	for dept_id in choices:
		var id: String = str(dept_id)
		if department_owned(id) and not (profile["equipped"] as Array).has(id) and (profile["equipped"] as Array).size() < department_slots():
			(profile["equipped"] as Array).append(id)
	run_departments = []
	for dept_id in parsed.get("run_departments", []):
		var id: String = str(dept_id)
		if department_owned(id) and not run_departments.has(id) and run_departments.size() < department_slots():
			run_departments.append(id)
	# v1 saves continue without departments until the next case starts.
	if not has_department("double_booking"):
		second_pending = {}
	reward_paid = bool(parsed.get("reward_paid", false))
	last_outcome = str(parsed.get("last_outcome", ""))
	return true
