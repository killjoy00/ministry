extends RefCounted
## Authored assignment contracts built from the same composable causal rules.
## Existing election rules are never edited by a new case.

const Election = preload("res://scripts/scenarios/fowl_election.gd")
const Expanded = preload("res://scripts/scenarios/expanded_incidents.gd")
const ORDER = ["fowl", "bakery", "thursday", "apology"]
const SHARED_IDS = [
	"rain", "sandwich", "post", "traffic", "wind", "fair", "coffee",
	"indoor_parade", "mayor_late", "wrong_invitation", "torn_posters",
	"crowd", "speech_ruined", "gossip_column", "rumour_circulates"
]

static func is_known(id: String) -> bool:
	return ORDER.has(id)

static func description(id: String) -> Dictionary:
	match id:
		"bakery":
			return {
				"id": "bakery", "title": "The Bakery That Bought the Bank",
				"brief": "Help Nora's bakery legally acquire Oddford Bank before the board's final meeting.",
				"memo": "You must secure capital, demonstrate solvency and complete the transfer.",
				"deadline": 8, "required_support": 19, "spontaneous_per_day": 1, "daily_event_limit": 9, "regen": 2, "metric": "FINANCIAL LEVERAGE",
				"win_facts": ["bakery_solvent", "backers_verified", "bank_transfer"],
				"requirement_labels": ["Solvent bakery", "Verified backers", "Signed bank transfer"],
				"unlock_cases": 2, "difficulty": "INTERMEDIATE", "merit_bonus": 4,
				"portrait": "baker", "illustration": "incident_letter",
				"success": "Nora has purchased Oddford Bank. The loan officer now reports to the pastry counter.",
				"failure": "The bank remains independent. The bakery's financial ambitions have been filed for reconsideration.",
				"open_notes": ["A cake sale is not ordinarily considered a hostile takeover.", "The bank is solvent, though its board of directors is increasingly nervous."],
			}
		"thursday":
			return {
				"id": "thursday", "title": "Thursday Has Been Cancelled",
				"brief": "Get the entire town to skip Thursday without causing a constitutional incident.",
				"memo": "Requires a revised calendar, public compliance, and an officially canceled day.",
				"deadline": 8, "required_support": 22, "spontaneous_per_day": 1, "daily_event_limit": 7, "regen": 1, "metric": "CIVIC CONSENSUS",
				"win_facts": ["calendar_revised", "public_compliance", "thursday_canceled"],
				"requirement_labels": ["Revised calendar", "Public compliance", "Canceled Thursday"],
				"unlock_cases": 5, "difficulty": "ADVANCED", "merit_bonus": 7,
				"portrait": "clerk", "illustration": "incident_rain",
				"success": "Thursday has been officially removed. The Ministry will issue a replacement weekday in due course.",
				"failure": "Despite several persuasive forms, Thursday occurred as usual. The public is disappointed.",
				"open_notes": ["The town calendar is unusually susceptible to clerical errors.", "Tuesday and Friday have both lodged formal objections."],
			}
		"apology":
			return {
				"id": "apology", "title": "The World's Unlikeliest Apology",
				"brief": "Reconcile two feuding bakers without ordering either one to apologize.",
				"memo": "An apology must be delivered, accepted, and sealed by a public reconciliation.",
				"deadline": 8, "required_support": 21, "spontaneous_per_day": 1, "daily_event_limit": 5, "regen": 1, "metric": "PUBLIC GOODWILL",
				"win_facts": ["apology_delivered", "apology_accepted", "rivals_reconciled"],
				"requirement_labels": ["Apology delivered", "Apology accepted", "Rivals reconciled"],
				"unlock_cases": 9, "difficulty": "EXCEPTIONAL", "merit_bonus": 11,
				"portrait": "reporter", "illustration": "incident_sandwich",
				"success": "The bakers have exchanged apologies and recipes. Their new joint venture is already a public nuisance.",
				"failure": "The rivalry remains uncomfortably cordial. A second mediation request is pending.",
				"open_notes": ["The pastry dispute started with an unflattering review of a custard tart.", "Official mediation is prohibited unless it happens by accident."],
			}
		_:
			var original: Dictionary = Election.description().duplicate(true)
			original.merge({
				"id": "fowl", "metric": "PUBLIC SUPPORT", "win_facts": ["goose_candidate"],
				"requirement_labels": ["Certified goose candidate"], "unlock_cases": 0,
				"difficulty": "ROUTINE", "merit_bonus": 0,
				"portrait": "gerald", "illustration": "incident_election",
				"success": "Gerald is elected. The town has questions; the Ministry does not.",
				"failure": "The election concludes without a goose in office. Paperwork will follow.",
				"open_notes": ["Mayor Huxley enjoys speeches. Gerald enjoys sandwiches.", "The Gazette has mislaid its fact-checking department."]
			}, true)
			return original

static func rules(id: String) -> Array:
	if id == "fowl" or not is_known(id):
		return Election.rules()
	var shared: Array = []
	for event in Election.rules():
		if SHARED_IDS.has(str(event["id"])) or Expanded.SHARED_IDS.has(str(event["id"])):
			shared.append(event.duplicate(true))
	match id:
		"bakery": shared.append_array(_bakery_rules())
		"thursday": shared.append_array(_thursday_rules())
		"apology": shared.append_array(_apology_rules())
	shared.append_array(Expanded.case_rules(id))
	return shared

static func _event(id: String, title: String, text: String, chance: float, all_facts: Array, any_facts: Array, outputs: Array, points: int, place: String, alternate: Array = [], alt_points: int = 0, alt_text: String = "") -> Dictionary:
	return {"id": id, "title": title, "text": text, "chance": chance, "all": all_facts,
		"any": any_facts, "facts": outputs, "support": points, "place": place,
		"misfile_facts": alternate, "misfile_support": alt_points, "misfile_text": alt_text}

static func _bakery_rules() -> Array:
	return [
		_event("bank_audit", "An Unwelcome Bank Audit", "An auditor discovers that the bank's records include a missing page.", .43, [], [], ["bank_books"], 0, "Town Hall"),
		_event("morning_rush", "Pastries, Unexpectedly Popular", "The bakery's queue stretches around the block.", .49, [], [], ["bakery_queue"], 2, "Bakery"),
		_event("receipt_misplaced", "A Receipt Is Misplaced", "A bank receipt wanders into the mayoral postbag.", .52, [], [], ["receipt_lost"], 0, "Post Office", ["receipt_recovered"], 1, "Nora receives a receipt revealing an unclaimed bank account."),
		_event("bank_statement", "Financial Correspondence Redirected", "An official statement arrives in the wrong filing cabinet.", .63, [], ["postal_mixup", "receipt_lost"], ["bank_statement_lost"], 0, "Post Office", ["bank_weakness"], 1, "The statement is misfiled with Nora, revealing the bank's overdrawn reserve."),
		_event("rainy_bakery", "An Emergency Bread Rush", "The rain sends hundreds of hungry residents into Nora's bakery.", .63, ["rain"], [], ["bakery_queue"], 2, "Bakery"),
		_event("fair_bakeoff", "The Great Bake-Off", "Nora wins a golden rolling pin and a modest fortune in advance orders.", .59, ["fair"], [], ["bakeoff_win"], 2, "Public Gardens"),
		_event("bakery_accounts", "An Unreasonably Healthy Balance Sheet", "A clerk verifies that the bakery can cover the bank's liabilities.", .59, [], ["bakery_queue", "bakeoff_win", "receipt_recovered"], ["bakery_solvent"], 2, "Bakery"),
		_event("bakery_press", "Pastry-Based Investor Confidence", "The Gazette describes Nora's bank proposal as surprisingly delicious.", .58, [], ["bakeoff_win", "bakery_solvent", "rumour_spread"], ["investor_interest"], 2, "High Street"),
		_event("sponsor_meeting", "A Benefactor with a Sweet Tooth", "Local residents commit their savings to Nora's improbable acquisition.", .58, [], ["investor_interest", "receipt_recovered", "bakery_solvent"], ["backers_verified"], 2, "Town Hall"),
		_event("bank_inspection", "A Loophole in the Ledger", "The town discovers that Oddford Bank is technically available for purchase.", .60, [], ["bank_books", "bank_statement_lost"], ["bank_weakness"], 1, "Town Hall"),
		_event("bakery_bid", "A Bid on Bank Letterhead", "An impeccably typed takeover offer arrives before tea.", .57, ["backers_verified"], ["bank_weakness", "receipt_recovered"], ["bakery_bid_filed"], 2, "Post Office"),
		_event("bank_transfer", "Bank Ownership Transferred", "A bewildered board of directors signs the deed behind a plate of buns.", .56, ["bakery_bid_filed", "bakery_solvent"], [], ["bank_transfer"], 3, "Town Hall")
	]

static func _thursday_rules() -> Array:
	return [
		_event("almanac_misprint", "An Almanac Misprint", "The printer accidentally produces a week with six days.", .48, [], [], ["calendar_error"], 0, "Post Office"),
		_event("town_clock", "The Town Clock Refuses Thursday", "The clock tower skips an entire rotation without explanation.", .44, [], [], ["clock_disputed"], 0, "Town Hall"),
		_event("school_trip", "An Extra School Holiday", "A teaching assistant books a field trip for a day nobody can locate.", .44, [], [], ["school_agenda"], 1, "Public Gardens"),
		_event("clock_timetable", "The Timetable Disagrees with Reality", "Buses stop on the wrong day and refuse to apologize.", .63, [], ["traffic", "clock_disputed"], ["schedule_confused"], 1, "High Street"),
		_event("gazette_week", "The Gazette Prints Six Days", "This week's paper omits a rather prominent weekday.", .60, [], ["calendar_error", "postal_mixup"], ["six_day_calendar"], 2, "Post Office"),
		_event("calendar_petition", "A Petition Against Thursday", "The town submits 300 signatures to remove the offending day.", .57, [], ["six_day_calendar", "school_agenda", "schedule_confused"], ["weekday_petition"], 2, "High Street"),
		_event("office_agenda", "The Council Convenes on Friday", "The councillors arrive on Friday for the Thursday meeting.", .54, [], ["clock_disputed", "calendar_error", "six_day_calendar"], ["council_confusion"], 2, "Town Hall"),
		_event("official_decree", "A Properly Stamped Calendar Exception", "The clerk signs a temporary exemption for the missing day.", .58, [], ["council_confusion", "weekday_petition"], ["thursday_decree"], 2, "Town Hall"),
		_event("school_consensus", "The Schools Agree to Skip Thursday", "Schools accept the new timetable and order extra Friday pencils.", .63, [], ["school_agenda", "weekday_petition"], ["schools_compliant"], 2, "Public Gardens"),
		_event("calendar_revision", "The Calendar Is Officially Revised", "The Ministry formally replaces Thursday with an extended Wednesday.", .56, ["thursday_decree"], ["six_day_calendar", "schools_compliant"], ["calendar_revised"], 3, "Town Hall"),
		_event("residents_skip", "Everyone Stays Home on Thursday", "Residents politely refuse to acknowledge the missing weekday.", .59, ["calendar_revised"], ["schools_compliant", "weekday_petition"], ["public_compliance"], 3, "High Street"),
		_event("thursday_deleted", "Thursday Is Removed from the Register", "The Gazette's front page confirms that the week is now legally shorter.", .56, ["calendar_revised"], ["public_compliance", "six_day_calendar"], ["thursday_canceled"], 3, "Post Office")
	]

static func _apology_rules() -> Array:
	return [
		_event("bakery_feud", "A Bitter Custard Dispute", "A review alleges that Nora's custard has insufficient moral character.", .47, [], [], ["feud_public"], 0, "Bakery"),
		_event("rival_arrives", "The Rival Baker Returns", "Nora's former apprentice opens a shop across the street.", .50, [], [], ["rival_present"], 0, "High Street"),
		_event("swapped_recipe", "A Recipe Sent to the Wrong Baker", "Two secret recipes are exchanged by mistake.", .57, [], ["postal_mixup", "rival_present"], ["recipes_misplaced"], 0, "Post Office", ["recipes_shared"], 2, "Both bakers receive each other's recipes and discover an unexpected similarity."),
		_event("spontaneous_kindness", "An Accidentally Kind Gesture", "One baker offers the other a sandwich while looking the wrong way.", .62, [], ["sandwich", "coffee_spilled"], ["first_kindness"], 2, "Bakery"),
		_event("shared_disaster", "A Shared Pastry Emergency", "Both bakers shelter from the same weather and rescue the same cakes.", .56, [], ["rain", "wind"], ["joint_misfortune"], 2, "High Street"),
		_event("joint_tasting", "An Unplanned Recipe Exchange", "A town tasting panel discovers the bakers' pastries complement one another.", .57, [], ["recipes_shared", "first_kindness", "joint_misfortune"], ["trust_restored"], 2, "Public Gardens"),
		_event("public_forum", "An Unscheduled Town Mediation", "The crowd assembles for a pie demonstration and finds itself mediating.", .58, [], ["fair", "crowd", "feud_public"], ["mediation_open"], 2, "Town Hall"),
		_event("gossip_softens", "An Uplifting Local Scandal", "The Gazette accidentally reports that the bakers have reconciled.", .60, [], ["public_gossip", "joint_misfortune", "trust_restored"], ["feud_doubts"], 2, "Post Office"),
		_event("apology_drafted", "An Apology Is Accidentally Drafted", "An administrative form acquires the words 'I was wrong'.", .59, ["mediation_open"], ["trust_restored", "feud_doubts", "first_kindness"], ["apology_draft"], 1, "Post Office"),
		_event("apology_delivered", "An Unlikely Public Apology", "The rivals each believe the other has apologised first.", .56, ["apology_draft"], [], ["apology_delivered"], 3, "Town Hall"),
		_event("apology_accepted", "Apology Accepted by Both Parties", "After a long pause, both bakers shake hands across the counter.", .57, ["apology_delivered"], ["trust_restored", "joint_misfortune", "first_kindness"], ["apology_accepted"], 3, "Bakery"),
		_event("rivals_reconciled", "A Joint Bakery Opens", "Two lifelong rivals announce a shared shop and one extremely large custard tart.", .55, ["apology_accepted"], ["recipes_shared", "feud_doubts", "trust_restored"], ["rivals_reconciled"], 3, "High Street")
	]
