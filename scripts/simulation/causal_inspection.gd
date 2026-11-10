extends RefCounted
## Read-only, authored-rule inspection. A possible link is NEVER evidence that
## an incident occurred. Recorded parents come only from simulation.history.

static func pretty_fact(value: String) -> String:
	return value.replace("_", " ").capitalize()

static func _recorded(game: CaseSimulation, id: String) -> Dictionary:
	for item in game.history:
		if str(item.get("id", "")) == id and (item.get("facts", []) as Array).size() > 0:
			return item
	return {}

static func _event_name(game: CaseSimulation, id: String) -> String:
	var rule: Dictionary = game.get_rule(id)
	if not rule.is_empty():
		return str(rule["title"])
	for item in game.history:
		if str(item.get("id", "")) == id:
			return str(item.get("title", id))
	return pretty_fact(id)

static func inspect(game: CaseSimulation, id: String) -> Dictionary:
	var rule: Dictionary = game.get_rule(id)
	if rule.is_empty():
		return {}
	var occurred: Dictionary = _recorded(game, id)
	var conditions: Array = []
	for fact in rule["all"]:
		conditions.append(_condition(game, str(fact), "ALL"))
	for fact in rule["any"]:
		conditions.append(_condition(game, str(fact), "ANY"))
	var outcomes: Array = []
	for fact in rule["facts"]:
		outcomes.append(pretty_fact(str(fact)))
	var alternate: Array = []
	for fact in rule["misfile_facts"]:
		alternate.append(pretty_fact(str(fact)))
	var parents: Array = []
	if not occurred.is_empty():
		for source in occurred.get("causes", []):
			parents.append({"id": str(source), "title": _event_name(game, str(source))})
	var branches: Array = _branches(game, id, rule["facts"], "NORMAL")
	# Misfile uses REPLACEMENT facts, not both sets of outcomes. Keep these
	# alternate branches labelled separately to avoid inventing probabilities.
	if not (rule["misfile_facts"] as Array).is_empty():
		for alternate_path in _branches(game, id, rule["misfile_facts"], "MISFILE"):
			branches.append(alternate_path)
	return {
		"id": id, "title": str(rule["title"]), "description": str(rule["text"]),
		"place": str(rule["place"]), "chance": float(rule["chance"]),
		"eligible": game._eligible(rule), "occurred": not occurred.is_empty(),
		"conditions": conditions, "outcomes": outcomes, "alternative": alternate,
		"momentum": int(rule["support"]), "parents": parents,
		"actual_record": occurred, "branches": branches,
		"nudge": minf(0.98, float(rule["chance"]) + 0.55),
		"domino": minf(0.98, float(rule["chance"]) + 0.25),
		"misfile": minf(0.98, float(rule["chance"]) + 0.40),
		"misfile_allowed": not (rule["misfile_facts"] as Array).is_empty()
	}

static func _branches(game: CaseSimulation, origin_id: String, outputs: Array, route: String) -> Array:
	var branches: Array = []
	for other in game.rules:
		if str(other["id"]) == origin_id:
			continue
		var shared: Array = []
		for fact in outputs:
			if (other["all"] as Array).has(fact) or (other["any"] as Array).has(fact):
				shared.append(pretty_fact(str(fact)))
		if shared.is_empty():
			continue
		var blockers: Array = []
		for fact in other["all"]:
			if not game.has_fact(str(fact)) and not outputs.has(fact):
				blockers.append(pretty_fact(str(fact)))
		if not (other["any"] as Array).is_empty():
			var has_any: bool = false
			for fact in other["any"]:
				if game.has_fact(str(fact)) or outputs.has(fact):
					has_any = true
			if not has_any:
				blockers.append("One of: " + ", ".join(_pretty(other["any"])))
		branches.append({
			"id": str(other["id"]), "title": str(other["title"]),
			"because": shared, "still_needed": blockers, "route": route,
			"already_occurred": game.fired.has(other["id"]),
			"chance": float(other["chance"])
		})
	return branches

static func _condition(game: CaseSimulation, fact: String, kind: String) -> Dictionary:
	var origin: String = str(game.fact_sources.get(fact, ""))
	return {
		"fact": pretty_fact(fact), "kind": kind, "met": game.has_fact(fact),
		"source": _event_name(game, origin) if not origin.is_empty() else "",
		"source_id": origin
	}

static func _pretty(values: Array) -> Array:
	var names: Array = []
	for v in values:
		names.append(pretty_fact(str(v)))
	return names
