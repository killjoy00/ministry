extends SceneTree
## Seeded behavioral audit of escalating assignments and operational departments.
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
const Cases = preload("res://scripts/scenarios/case_catalog.gd")
const SAMPLES: int = 240
const PRIORITIES = {
	"bakery": ["bank_transfer", "bakery_bid", "sponsor_meeting", "bakery_accounts", "bank_inspection", "bank_statement", "bakery_press", "fair_bakeoff", "rainy_bakery", "receipt_misplaced", "morning_rush", "bank_audit", "fair", "post", "sandwich"],
	"thursday": ["thursday_deleted", "residents_skip", "calendar_revision", "official_decree", "school_consensus", "office_agenda", "calendar_petition", "gazette_week", "clock_timetable", "almanac_misprint", "town_clock", "school_trip", "traffic", "post"],
	"apology": ["rivals_reconciled", "apology_accepted", "apology_delivered", "apology_drafted", "joint_tasting", "gossip_softens", "public_forum", "swapped_recipe", "spontaneous_kindness", "shared_disaster", "rival_arrives", "bakery_feud", "sandwich", "post", "rain"],
	"fowl": ["nomination", "petition", "rulebook", "special_council", "front_page", "goose_stage", "goose_hungry", "fair_prize", "camera", "goose_viral", "endorsement", "debate", "poll", "post", "sandwich", "fair"]
}
const EQUIPMENT = ["fortuitous_timing", "postal_inspector", "chain_reactions", "automatic_paperwork", "second_chances"]

func _initialize() -> void:
	var plain_guided: Dictionary = {}
	for id in Cases.ORDER:
		var none := 0
		var guided := 0
		var staffed := 0
		var complexity: float = 0.0
		for seed_id in range(SAMPLES):
			var a = _run(str(id), seed_id, false, false)
			var b = _run(str(id), seed_id, true, false)
			var c = _run(str(id), seed_id, true, true)
			if a.status == "won": none += 1
			if b.status == "won": guided += 1
			if c.status == "won": staffed += 1
			complexity += float(c.history.size())
		print("CASE %s: unassisted=%d/%d, nudge=%d/%d, departments+nudge=%d/%d; staffed ledger %.1f" % [id, none, SAMPLES, guided, SAMPLES, staffed, SAMPLES, complexity / float(SAMPLES)])
		plain_guided[id] = guided
		if id != "fowl":
			if none >= SAMPLES / 8:
				printerr("FAIL: Advanced case can succeed on autopilot too frequently: " + id)
				quit(1)
				return
			if guided <= 0 or staffed <= guided + 35 or staffed >= SAMPLES:
				printerr("FAIL: Advanced case needs a real player and meaningful department power: " + id)
				quit(1)
				return
	if not (int(plain_guided["fowl"]) > int(plain_guided["bakery"]) and int(plain_guided["bakery"]) > int(plain_guided["thursday"]) and int(plain_guided["thursday"]) > int(plain_guided["apology"])):
		printerr("FAIL: The advanced assignments must escalate in difficulty under the same strategy.")
		quit(1)
	else:
		print("PASS: escalating case difficulty with strategic departmental improvement")
		quit(0)

func _run(id: String, seed_value: int, strategic: bool, with_offices: bool):
	var game = Simulation.new(seed_value, false)
	game.profile["completed"] = 20
	if with_offices:
		game.profile["departments"] = {}
		for dept_id in EQUIPMENT:
			(game.profile["departments"] as Dictionary)[dept_id] = true
		game.profile["equipped"] = EQUIPMENT.duplicate()
	game.start_new_run(seed_value, id)
	for d in range(int(game.case_info["deadline"])):
		if strategic:
			var available: Array = game.available_events()
			for wanted in PRIORITIES[id]:
				if game.can_stamp("nudge", str(wanted)):
					game.stage_stamp("nudge", str(wanted))
					break
		game.advance_day()
	return game
