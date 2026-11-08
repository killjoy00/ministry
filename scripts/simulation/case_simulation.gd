extends RefCounted
class_name CaseSimulation
## UI-independent, seeded rules simulation. All outcomes and provenance are journaled.

const Scenario = preload("res://scripts/scenarios/fowl_election.gd")
const SAVE_PATH = "user://ministry_case_save.json"
const SAVE_VERSION = 1
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
var case_info: Dictionary = {}
var profile: Dictionary = {"merit": 0, "completed": 0, "desk": 0, "ink": 0, "audit": 0}
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
var scheduled: Dictionary = {}
var corrections: Array = []
var reward_paid: bool = false
var last_outcome: String = ""

func _init(custom_seed: int = -1, enable_persistence: bool = true, custom_save_path: String = "") -> void:
	persist = enable_persistence
	if not custom_save_path.is_empty():
		save_path = custom_save_path
	rules = Scenario.rules()
	case_info = Scenario.description()
	if persist and custom_seed < 0 and load_game():
		return
	start_new_run(custom_seed)

func maximum_influence() -> int:
	return 8 + int(profile.get("desk", 0)) * 2

func starting_influence() -> int:
	return min(maximum_influence(), 4 + int(profile.get("ink", 0)))

func start_new_run(requested_seed: int = -1) -> void:
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
	scheduled = {}
	corrections = []
	reward_paid = false
	last_outcome = ""
	# Seed-dependent flavor, without concealing or blocking any required route.
	var descriptions = [
		"Mayor Huxley enjoys speeches. Gerald enjoys sandwiches.",
		"The Gazette has mislaid its fact-checking department.",
		"The town's election committee is unusually open-minded."
	]
	_note("CASE OPENED", descriptions[rng.randi_range(0, descriptions.size() - 1)], "", [])
	save_game()

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
	return influence >= int(STAMPS[stamp_id]["cost"])

func stage_stamp(stamp_id: String, event_id: String) -> bool:
	if not can_stamp(stamp_id, event_id):
		return false
	pending = {"stamp": stamp_id, "target": event_id}
	save_game()
	return true

func clear_stamp() -> void:
	pending = {}
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
	var intervention: Dictionary = pending.duplicate(true)
	pending = {}
	if not intervention.is_empty():
		var stamp: Dictionary = STAMPS[intervention["stamp"]]
		influence -= int(stamp["cost"])
		strain += max(1, int(stamp["strain"]) - int(profile.get("audit", 0)))
		_note("APPROVED", "%s approved for %s." % [stamp["name"], get_rule(str(intervention["target"]))["title"]], "", [])
		if intervention["stamp"] == "reschedule":
			scheduled[intervention["target"]] = day + 1
			_note("RESCHEDULED", "An event has been moved to tomorrow's diary.", "", [])
		if strain >= 6:
			strain -= 6
			var correction: Dictionary = CORRECTIONS[rng.randi_range(0, CORRECTIONS.size() - 1)]
			corrections.append({"day": day + 1, "title": correction["title"], "id": correction["id"]})
			_note("CORRECTION FORECAST", "%s is scheduled for Day %d." % [correction["title"], day + 1], "", [])
	var correction_facts: Array = _resolve_corrections()
	_resolve_events(intervention, correction_facts)
	if day >= int(case_info["deadline"]):
		if has_fact("goose_candidate") and support >= int(case_info["required_support"]):
			status = "won"
			last_outcome = "Gerald is elected. The town has questions; the Ministry does not."
		else:
			status = "lost"
			last_outcome = "The election concludes without a goose in office. Paperwork will follow."
		_settle_case()
	else:
		day += 1
		influence = min(maximum_influence(), influence + 2)
	save_game()

func _resolve_corrections() -> Array:
	var newly_created: Array = []
	var leftovers: Array = []
	for item in corrections:
		if int(item["day"]) != day:
			leftovers.append(item)
			continue
		for correction in CORRECTIONS:
			if correction["id"] == item["id"]:
				for fact_id in correction["facts"]:
					if not has_fact(str(fact_id)):
						newly_created.append(fact_id)
				_record_event("correction_" + correction["id"] + "_" + str(day), correction["title"], correction["text"], correction["facts"], 0, [])
				break
	corrections = leftovers
	return newly_created

func _resolve_events(intervention: Dictionary, correction_facts: Array) -> void:
	# One selected intervention, due scheduled events, two spontaneous events,
	# and children newly enabled by any of these. This prevents the world from
	# solving every assignment automatically by rolling every rule each day.
	var queue: Array = []
	var queued: Dictionary = {}
	var tried: Dictionary = {}
	var event_count: int = 0
	var domino_target: String = ""
	if not intervention.is_empty() and intervention["stamp"] == "domino":
		domino_target = str(intervention["target"])

	# Bring forward the guaranteed appointments, unless the prerequisites vanished.
	for rule in rules:
		var id: String = rule["id"]
		if scheduled.has(id) and int(scheduled[id]) == day and _eligible(rule):
			queue.append({"id": id, "force": true})
			queued[id] = true

	# Approving a stamp commits an active attempt. Reschedule instead delays it.
	if not intervention.is_empty() and intervention["stamp"] != "reschedule":
		var target: String = str(intervention["target"])
		if not queued.has(target):
			queue.append({"id": target, "force": false})
			queued[target] = true

	# Reality corrections may open brand-new causal edges.
	for rule in rules:
		var id: String = rule["id"]
		if not queued.has(id) and _eligible(rule) and _depends_on_any(rule, correction_facts):
			queue.append({"id": id, "force": false})
			queued[id] = true

	# A small amount of ordinary life continues without Ministry intervention.
	var spontaneous: Array = []
	for rule in available_events():
		var id: String = rule["id"]
		if not queued.has(id) and not (scheduled.has(id) and int(scheduled[id]) > day):
			spontaneous.append(id)
	for draw in range(mini(2, spontaneous.size())):
		var index: int = rng.randi_range(0, spontaneous.size() - 1)
		var pick: String = str(spontaneous[index])
		spontaneous.remove_at(index)
		queue.append({"id": pick, "force": false})
		queued[pick] = true

	while not queue.is_empty() and event_count < 32:
		var next: Dictionary = queue.pop_front()
		var id: String = str(next["id"])
		var rule := get_rule(id)
		if tried.has(id) or rule.is_empty() or not _eligible(rule):
			continue
		if scheduled.has(id) and int(scheduled[id]) > day:
			continue
		tried[id] = true
		var probability: float = float(rule["chance"])
		var misfile := false
		if not intervention.is_empty() and str(intervention["target"]) == id:
			match str(intervention["stamp"]):
				"nudge": probability += 0.55
				"misfile":
					probability += 0.40
					misfile = true
				"domino": probability += 0.25
		var guaranteed: bool = bool(next["force"])
		if not guaranteed and rng.randf() >= minf(probability, 0.98):
			continue
		if scheduled.has(id):
			scheduled.erase(id)
		var output_facts: Array = rule["facts"]
		var output_support: int = int(rule["support"])
		var narration: String = rule["text"]
		if misfile:
			output_facts = rule["misfile_facts"]
			output_support = int(rule["misfile_support"])
			narration = rule["misfile_text"]
		var newly_created: Array = []
		for fact_id in output_facts:
			if not has_fact(str(fact_id)):
				newly_created.append(fact_id)
		_record_event(id, rule["title"], narration, output_facts, output_support, _sources_for_rule(rule))
		fired[id] = true
		event_count += 1

		# Only consequences connected to a *new fact* are auto-considered.
		var first_child: bool = true
		for candidate in rules:
			var child_id: String = candidate["id"]
			if queued.has(child_id) or tried.has(child_id) or not _eligible(candidate):
				continue
			if not _depends_on_any(candidate, newly_created):
				continue
			var compel: bool = id == domino_target and first_child
			queue.append({"id": child_id, "force": compel})
			queued[child_id] = true
			if compel:
				_note("DOMINO ACTIVATED", "A connected consequence has been legally compelled.", id, [])
				first_child = false
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
		merit += 7
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
		"version": SAVE_VERSION, "seed": str(seed), "rng_state": str(rng.state),
		"day": day, "status": status, "facts": facts, "fact_sources": fact_sources,
		"fired": fired, "history": history, "support": support, "influence": influence,
		"strain": strain, "pending": pending, "scheduled": scheduled,
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
	if not (parsed is Dictionary) or int(parsed.get("version", -1)) != SAVE_VERSION:
		return false
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
	scheduled = parsed.get("scheduled", {})
	corrections = parsed.get("corrections", [])
	profile = parsed.get("profile", profile)
	reward_paid = bool(parsed.get("reward_paid", false))
	last_outcome = str(parsed.get("last_outcome", ""))
	return true
