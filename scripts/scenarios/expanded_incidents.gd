extends RefCounted
## Case-aware story incidents. Each new lead is earned by a recorded earlier
## event; no new start-of-day clutter and no disconnected flavour-only rolls.
## The original episode is left untouched for existing saves and fixed seeds.

const SHARED_IDS: Array[String] = [
	"overdue_memo", "soggy_ledger", "tram_delay", "bakery_samples",
	"fair_ribbon", "page_three", "clerk_suspicion", "poster_debris",
	"parade_minutes", "borrowed_umbrella", "reprinted_notices",
	"public_hearing", "sergeant_copy", "town_clerk_inspection",
	"late_delivery", "gazette_correction"
]

static func shared_rules() -> Array:
	return [
		_event("overdue_memo", "The Memo Sent Somewhere Else", "A memo intended for the council turns up in a hatbox. The hatbox is duly registered.", .43, ["postal_mixup"], [], ["misdirected_memo"], 0, "Post Office"),
		_event("soggy_ledger", "The Waterlogged Ledger", "An official ledger swells in the rain, obscuring exactly the wrong column.", .41, ["rain"], [], ["water_damaged_forms"], 0, "Town Hall"),
		_event("tram_delay", "The Town Runs Nine Minutes Late", "A missed bus causes Oddford to agree that every clock is nine minutes fast.", .40, ["traffic"], [], ["town_running_late"], 0, "High Street"),
		_event("bakery_samples", "The Unscheduled Bread Sampling", "Nora leaves free rolls on a window ledge. No form records who takes them.", .44, ["sandwich"], [], ["food_samples"], 0, "Bakery"),
		_event("fair_ribbon", "A Ribbon for an Empty Pedestal", "The judges award a ribbon before anyone checks who entered the competition.", .44, ["fair"], [], ["awards_ceremony"], 0, "Public Gardens"),
		_event("page_three", "A Reporter Needs a Third Page", "The Gazette needs another local story. An entire crowd offers its services.", .43, ["crowd"], [], ["gazette_interest"], 0, "High Street"),
		_event("clerk_suspicion", "The Clerk Requests an Audit", "A coffee stain looks alarmingly like a forged signature.", .42, ["coffee_spilled"], [], ["audit_suspicion"], 0, "Town Hall"),
		_event("poster_debris", "The Noticeboard Changes Its Mind", "A misplaced poster hides a notice that nobody had intended to obey.", .39, ["wind"], [], ["noticeboard_confusion"], 0, "High Street"),
		_event("parade_minutes", "Minutes from the Parade", "Someone records the indoor parade as an emergency council meeting.", .39, ["indoor_parade"], [], ["parade_minutes"], 0, "Town Hall"),
		_event("borrowed_umbrella", "The Umbrella with Two Owners", "Two residents shelter beneath the same umbrella and both insist it is theirs.", .43, ["rain"], ["sandwich", "coffee_spilled"], ["shared_shelter"], 0, "Bakery"),
		_event("reprinted_notices", "A Fresh Batch of Official Notices", "The postmistress reprints the notices, preserving a remarkably convenient error.", .45, [], ["postal_mixup", "noticeboard_confusion"], ["reprinted_notices"], 0, "Post Office"),
		_event("public_hearing", "A Meeting Nobody Called", "A gathering is mistaken for a public hearing. The clerk produces a minute book.", .43, [], ["fair", "gazette_interest"], ["public_hearing"], 0, "Town Hall"),
		_event("sergeant_copy", "A Spare Copy from the Archives", "The police sergeant produces a dry copy of the damp register.", .44, ["water_damaged_forms"], [], ["duplicate_register"], 0, "Post Office"),
		_event("town_clerk_inspection", "An Inspection by Appointment", "The clerk arrives to examine the delay and instead discovers a new form.", .42, [], ["audit_suspicion", "town_running_late"], ["clerk_investigation"], 0, "Town Hall"),
		_event("late_delivery", "The Last Delivery Arrives First", "A delayed letter is sorted ahead of the morning post. Its recipient is puzzled.", .44, [], ["misdirected_memo", "town_running_late"], ["late_delivery"], 0, "Post Office"),
		_event("gazette_correction", "The Gazette Prints a Correction", "The correction occupies more space than the original story.", .43, [], ["gazette_interest", "reprinted_notices"], ["official_correction"], 0, "High Street"),
	]

static func case_rules(id: String) -> Array:
	match id:
		"fowl": return _election()
		"bakery": return _bakery()
		"thursday": return _thursday()
		"apology": return _apology()
	return []

static func _election() -> Array:
	return [
		_event("empty_podium", "The Empty Podium Is Noticed", "Huxley's absence makes the lectern look available for public use.", .43, ["mayor_late"], [], ["vacant_podium"], 0, "Town Hall"),
		_event("goose_wanders_in", "An Unexpected Stand-In", "Gerald occupies the unattended lectern. The town assumes he was scheduled.", .41, ["vacant_podium", "goose_at_hall"], [], ["goose_on_stage"], 1, "Town Hall"),
		_event("the_perch", "A Perch Installed for the Speaker", "Officials lower the microphone to goose height without asking why.", .47, ["goose_on_stage"], [], ["goose_perch"], 0, "Town Hall"),
		_event("press_wire", "A Telegraph Operator Mishears the Name", "The news wire identifies the quietest speaker as the most popular.", .40, ["goose_perch"], ["gazette_interest", "goose_photo"], ["goose_headline"], 0, "Post Office"),
		_event("archivists_vote", "The Archivists Declare a Preference", "Town archivists favor anyone who has never misplaced a document.", .46, ["goose_perch"], [], ["civic_appeal"], 0, "Town Hall"),
		_event("stamp_petition", "A Petition Arrives Already Stamped", "A request for a more restrained candidate gathers the required signatures.", .42, ["civic_appeal"], ["goose_headline", "goose_viral"], ["goose_petition"], 1, "High Street"),
		_event("council_exception", "An Exception for Quiet Candidates", "A clerk discovers the by-law has no minimum requirement for speeches.", .38, ["civic_appeal", "clerk_investigation"], [], ["goose_eligible"], 0, "Town Hall"),
		_event("decorated_crust", "A Medal Made of Bread", "The bakery awards Gerald a ceremonial roll on a ribbon.", .43, ["food_samples", "goose_at_hall"], [], ["goose_bread_badge"], 1, "Bakery"),
		_event("crumbled_speech", "Huxley's Speech Is Eaten", "The mayor's notes disappear beneath an entirely innocent beak.", .43, ["goose_bread_badge"], ["coffee_spilled", "mayor_late"], ["mayor_embarrassed"], 0, "Town Hall"),
		_event("sash_fitting", "An Unplanned Sash Fitting", "A parade marshal mistakes Gerald's bread ribbon for civic regalia.", .46, ["goose_bread_badge"], [], ["goose_sash"], 1, "Public Gardens"),
		_event("goose_yardstick", "A Goose Becomes the Standard", "The town adopts Gerald's unusually calm demeanor as the standard for candidates.", .43, ["goose_sash"], [], ["goose_viral"], 0, "High Street"),
		_event("baker_petition", "The Bakery Starts a Petition", "Nora collects signatures in the queue for tomorrow's bread.", .43, [], ["goose_endorsed", "goose_sash"], ["goose_petition"], 1, "Bakery"),
		_event("duplicate_ballot", "A Duplicate Ballot Is Discovered", "The registrar discovers an empty candidate line on a copied ballot.", .42, ["duplicate_register"], [], ["ballot_duplicate"], 0, "Post Office"),
		_event("beak_option", "The Ballot Has an Extra Box", "A typesetter mistakes a picture of Gerald for a legitimate candidate symbol.", .38, ["ballot_duplicate", "goose_photo"], [], ["goose_eligible"], 0, "Town Hall"),
		_event("charter_misread", "The Charter Contains a Footnote", "A missing memo reveals that candidates need only reside in Oddford.", .40, ["misdirected_memo", "goose_viral"], [], ["goose_eligible"], 0, "Town Hall"),
		_event("postal_club", "The Postal Workers Form a Committee", "A late Gazette delivery inspires a petition with impeccable handwriting.", .41, ["late_delivery", "goose_headline"], [], ["goose_petition"], 0, "Post Office"),
		_event("wildlife_clause", "A Candidate Clause Is Reprinted", "The reprinted rules accidentally retain the section on domesticated waterfowl.", .36, ["reprinted_notices", "goose_sash"], [], ["goose_eligible"], 0, "Town Hall"),
		_event("prize_ribbon", "First Prize Is Awarded Twice", "A spare prize ribbon is placed around the wrong animal.", .43, ["awards_ceremony", "goose_at_hall"], [], ["goose_prize"], 1, "Public Gardens"),
		_event("queens_commendation", "A Commendation Reaches the Council", "The fair's records describe Gerald as remarkably civic-minded.", .42, ["goose_prize", "parade_minutes"], [], ["civic_appeal"], 0, "Town Hall"),
		_event("council_quorum", "The Council Finds a Quorum", "The councillors accept a waterfowl nomination to avoid another hearing.", .38, ["public_hearing", "civic_appeal"], [], ["goose_eligible"], 0, "Town Hall"),
		_event("vote_train", "The Commuters Back Gerald", "Late buses leave plenty of time for a petition at the station.", .40, ["goose_viral", "goose_eligible"], [], ["goose_petition"], 1, "High Street"),
		_event("gazette_special", "A Special Edition Is Misprinted", "A Gazette correction identifies Gerald as the sole interviewee.", .43, ["official_correction", "goose_photo"], [], ["goose_headline"], 1, "Post Office"),
		_event("campaign_anthem", "The Campaign Acquires a Theme Song", "A brass band performs a tune nobody remembers commissioning.", .44, ["goose_candidate", "fair"], [], ["goose_viral"], 1, "Public Gardens"),
		_event("goose_chair", "A Chair Is Reserved for the Candidate", "Gerald occupies the only empty chair and wins by declining to speak.", .45, ["goose_candidate", "vacant_podium"], [], ["goose_debate"], 0, "Town Hall"),
	]

static func _bakery() -> Array:
	return [
		_event("queue_accountant", "The Queue Is Counted as Revenue", "A retired accountant counts every customer waiting for Nora's buns.", .43, ["bakery_queue"], [], ["cash_till_record"], 0, "Bakery"),
		_event("bookkeeper_witness", "The Sales Have a Witness", "A free sample becomes a signed, notarized proof of the bakery's trading volume.", .38, ["food_samples", "cash_till_record"], [], ["bakery_verified_sales"], 0, "Bakery"),
		_event("wholesale_proposal", "The Fair Orders a Thousand Buns", "A committee orders catering for a ceremony that may already be over.", .42, ["awards_ceremony", "bakery_queue"], [], ["bulk_orders"], 0, "Public Gardens"),
		_event("bakery_cashbook", "The Cashbook Balances for Once", "The bakery's orders and receipts finally agree on a number.", .46, [], ["bulk_orders", "bakery_verified_sales"], ["audited_bakery_income"], 1, "Bakery"),
		_event("tax_refund", "An Unusually Prompt Tax Refund", "The council returns an overpayment before Nora has time to protest.", .39, [], ["receipt_recovered", "audited_bakery_income"], ["tax_refund"], 1, "Town Hall"),
		_event("solvency_hearing", "A Hearing on Bakery Solvency", "An auditor reluctantly certifies that the buns could cover the bank's debts.", .38, ["audited_bakery_income", "bank_books"], [], ["bakery_solvent"], 1, "Town Hall"),
		_event("bank_vault_moth", "The Bank Vault Has a Moth Problem", "An inspector finds the vault's inventory filed under insect control.", .41, ["bank_books"], [], ["vault_inventory_doubt"], 0, "Town Hall"),
		_event("auditor_umbrella", "An Auditor Borrows the Wrong Umbrella", "A damp set of forms schedules an inspection of the bank's reserve.", .43, ["water_damaged_forms"], [], ["auditor_appointment"], 0, "Town Hall"),
		_event("reserve_count", "The Reserve Count Is Off", "An inspection reveals the bank has been counting its own furniture as capital.", .38, [], ["vault_inventory_doubt", "auditor_appointment"], ["bank_weakness"], 0, "Town Hall"),
		_event("quiet_account", "The Forgotten Savings Account", "An archival copy reveals a bank account nobody remembers opening.", .39, ["duplicate_register", "bank_books"], [], ["bank_weakness"], 0, "Post Office"),
		_event("radio_bun", "A Local Radio Presenter Tries a Bun", "The announcer devotes the entire weather report to pastry.", .42, ["gazette_interest", "bakery_queue"], [], ["bakery_press_clippings"], 1, "High Street"),
		_event("backers_tea", "Investors Attend an Accidental Tea", "Nora's balance sheet is mistaken for the menu at an investor lunch.", .40, ["bakery_press_clippings", "bakery_solvent"], [], ["investor_interest"], 1, "Bakery"),
		_event("milkman_shares", "The Milkman Offers Shares", "The morning milk delivery becomes a subscription to the bakery's bank bid.", .42, [], ["bulk_orders", "bakery_press_clippings"], ["milkman_pledge"], 0, "High Street"),
		_event("subscription_book", "A Book of Very Small Investors", "The postmistress logs dozens of contributions, each no larger than a shilling.", .43, [], ["milkman_pledge", "investor_interest"], ["pledges_collected"], 0, "Post Office"),
		_event("backer_roll", "The Subscriber List Is Verified", "A civic clerk counts the pledges twice and signs off on the total.", .40, ["pledges_collected", "bakery_solvent"], [], ["backers_verified"], 1, "Town Hall"),
		_event("clerks_lunch", "The Bank Board Meets for Lunch", "An invitation intended for a baker opens the directors' meeting.", .43, ["bank_weakness", "shared_shelter"], [], ["bank_meeting_open"], 0, "Town Hall"),
		_event("bank_receipts", "A Bid Is Certified in Blue Ink", "The bakery's recovered receipt proves an offer can be filed legally.", .39, ["bakery_solvent", "receipt_recovered"], [], ["bank_bid_legal"], 0, "Post Office"),
		_event("blue_ink_offer", "The Offer Is Filed Before Lunch", "The bank board receives a proper bid with the amount written out in words.", .41, ["bank_bid_legal", "backers_verified"], [], ["bakery_bid_filed"], 1, "Post Office"),
		_event("legal_signature", "The Board's Signature Is Witnessed", "A notary witnesses the transfer during an unrelated cake tasting.", .36, ["bakery_bid_filed", "bank_meeting_open"], [], ["bank_transfer"], 1, "Town Hall"),
		_event("auction_docket", "The Bank Appears on an Auction List", "A balance sheet and signed backer list put the bank on the sale docket.", .38, ["bank_weakness", "backers_verified"], [], ["bank_meeting_open"], 0, "Town Hall"),
		_event("mysterious_deed", "A Deed Emerges from the Filing Cabinet", "A typed deed proves the bakery's takeover offer has been properly executed.", .36, ["bakery_bid_filed", "bakery_solvent"], [], ["bank_transfer"], 1, "Post Office"),
		_event("bank_tea_tasting", "The Bank Requests a Pastry Tasting", "The directors mistake free bread for an invitation to negotiate.", .44, ["food_samples", "bank_books"], [], ["bank_meeting_open"], 0, "Bakery"),
	]

static func _thursday() -> Array:
	return [
		_event("railway_calendar", "The Timetable Loses a Thursday", "A late train has no scheduled arrival on the printed calendar.", .43, ["town_running_late"], [], ["railway_calendar_changed"], 0, "High Street"),
		_event("faded_sign", "The Day Vanishes from a Damp Notice", "The council noticeboard can no longer display the fourth day of the week.", .43, ["water_damaged_forms"], [], ["weekday_omission"], 0, "Town Hall"),
		_event("clock_survey", "The Clockmaker Files a Complaint", "The civic clock is one weekday out of sync with the market bell.", .41, ["clock_disputed"], [], ["clock_dispute_filed"], 0, "Town Hall"),
		_event("printer_double_shift", "The Printer Copies the Wrong Week", "A misdirected memo commissions a second run of the six-day calendar.", .40, ["misdirected_memo"], [], ["printer_receipt"], 0, "Post Office"),
		_event("timetable_witness", "The Drivers Sign a Statement", "The bus drivers agree that their timetable is neither Thursday nor Friday.", .40, [], ["railway_calendar_changed", "clock_dispute_filed"], ["public_timing_doubt"], 0, "High Street"),
		_event("drivers_petition", "The Drivers Demand a Real Weekday", "An account of lost working hours prompts the transport depot to file a petition.", .34, ["public_timing_doubt", "public_hearing"], [], ["weekday_petition"], 0, "Town Hall"),
		_event("amended_almanac", "A Six-Day Almanac Is Approved", "The printer delivers calendars with a neatly missing weekday.", .42, [], ["printer_receipt", "weekday_omission"], ["six_day_calendar"], 1, "Post Office"),
		_event("almanac_stamp", "The Missing Day Is Backdated", "The registrar certifies that the calendar error existed last Tuesday.", .39, ["six_day_calendar", "duplicate_register"], [], ["calendar_error"], 0, "Town Hall"),
		_event("clock_register", "The Clock's Objection Is Filed", "A clockmaker's complaint arrives before the council can dismiss it.", .40, ["clock_dispute_filed", "six_day_calendar"], [], ["council_confusion"], 1, "Town Hall"),
		_event("school_note", "Parents Receive a Day-Off Notice", "A shared umbrella becomes a makeshift noticeboard for the school trip.", .43, ["shared_shelter", "school_agenda"], [], ["parents_notified"], 0, "Public Gardens"),
		_event("bus_strike", "All Thursday Buses Are Reassigned", "The depot books every Thursday bus onto Friday's schedule.", .41, ["railway_calendar_changed", "schedule_confused"], [], ["bus_rerouted"], 0, "High Street"),
		_event("children_petition", "Children Petition for an Extra Wednesday", "A school petition receives enough signatures to embarrass the council.", .41, ["parents_notified", "public_hearing"], [], ["weekday_petition"], 1, "Town Hall"),
		_event("market_day", "Market Day Is Moved onto Wednesday", "The traders pack up a day early and sell out of buns.", .40, ["food_samples", "weekday_petition"], [], ["market_closed_thursday"], 1, "High Street"),
		_event("commuters_vote", "The Commuters Reject Thursday", "Bus passengers agree to stop turning up for a day the council cannot define.", .31, ["bus_rerouted", "weekday_petition"], [], ["public_compliance"], 1, "High Street"),
		_event("joint_timetable", "The Schools and Shops Agree", "A shared timetable leaves Thursday conspicuously blank.", .32, ["schools_compliant", "market_closed_thursday"], [], ["public_compliance"], 0, "Public Gardens"),
		_event("clerk_appeal", "The Clerk Submits a Calendar Appeal", "Miss Quill discovers the exact form needed to cancel a weekday.", .32, ["clerk_investigation", "weekday_petition"], [], ["thursday_decree"], 0, "Town Hall"),
		_event("council_hearing", "The Council Votes to Shorten the Week", "An emergency council session records seven members present on a six-day week.", .31, ["public_hearing", "council_confusion"], [], ["thursday_decree"], 0, "Town Hall"),
		_event("village_reprint", "A New Calendar Is Issued", "The council reprints the calendar with proper authorization and no Thursday.", .29, ["six_day_calendar", "thursday_decree"], [], ["calendar_revised"], 1, "Post Office"),
		_event("clockmakers_approval", "The Clockmaker Accepts the New Week", "The civic clock switches to a timetable officially lacking Thursday.", .29, ["clock_dispute_filed", "thursday_decree"], [], ["calendar_revised"], 0, "Town Hall"),
		_event("date_notice", "A Correction Everyone Understands", "The Gazette's correction instructs residents to proceed directly to Friday.", .32, ["official_correction", "calendar_revised"], [], ["public_compliance"], 1, "High Street"),
		_event("school_shutdown", "The Schools Close for the Missing Day", "Teachers accept a day off supported by official paperwork.", .40, ["parents_notified", "calendar_revised"], [], ["schools_compliant"], 0, "Public Gardens"),
		_event("ledger_seal", "Thursday Is Struck from the Ledger", "The registry crosses out the weekday and stamps the margin.", .28, ["calendar_revised", "public_compliance"], [], ["thursday_canceled"], 1, "Town Hall"),
		_event("press_writ", "A Legal Notice Omits Thursday", "The Gazette publishes the last council resolution containing seven days.", .28, ["official_correction", "public_compliance", "thursday_decree"], [], ["thursday_canceled"], 1, "Post Office"),
		_event("bank_holiday", "The Bank Declares a Missing-Day Holiday", "A business notice persuades the remaining shops to observe the absence.", .31, ["market_closed_thursday", "thursday_decree"], [], ["public_compliance"], 0, "High Street"),
	]

static func _apology() -> Array:
	return [
		_event("custard_receipt", "The Original Custard Receipt", "An archival review reveals the feud began over one unpaid tart.", .42, ["feud_public"], [], ["historic_resentment"], 0, "Bakery"),
		_event("rival_postcard", "A Postcard from Their Apprenticeship", "The postmistress discovers the bakers once promised to work together.", .41, ["misdirected_memo", "rival_present"], [], ["old_pledge_found"], 0, "Post Office"),
		_event("cutting_board", "The Same Cutting Board", "A misplaced board shows that both bakeries trained under the same chef.", .43, ["food_samples", "rival_present"], [], ["shared_equipment"], 0, "Bakery"),
		_event("flour_cloud", "Flour Blows Across the Street", "A gust coats both storefronts in the same badly labeled flour.", .42, ["wind", "rival_present"], [], ["flour_mishap"], 0, "High Street"),
		_event("rainy_tent", "The Shared Awning", "A borrowed umbrella forces the rivals into the same dry doorway.", .43, ["shared_shelter", "rival_present"], [], ["sheltered_together"], 0, "Bakery"),
		_event("fruit_delivery", "A Delivery for Two Addresses", "The last fruit delivery is dropped precisely between both bakeries.", .44, ["late_delivery", "rival_present"], [], ["joint_delivery"], 0, "High Street"),
		_event("custard_confession", "The First Complaint Is Withdrawn", "The old receipt reveals that neither baker wrote the offending review.", .39, ["historic_resentment", "old_pledge_found"], [], ["feud_doubts"], 1, "Bakery"),
		_event("baker_rescue", "One Baker Helps the Other", "An overturned delivery inspires the rival to retrieve every fallen plum.", .41, ["flour_mishap", "joint_delivery"], [], ["first_kindness"], 1, "High Street"),
		_event("shared_mixer", "An Accidental Shared Mixing Bowl", "A borrowed kitchen reveals the supposed rivals have the same secret recipe.", .40, ["shared_equipment", "sheltered_together"], [], ["recipes_shared"], 1, "Bakery"),
		_event("jam_spill", "A Jar of Jam Changes Hands", "One baker catches a falling jar before the other's cakes are ruined.", .41, ["shared_equipment", "joint_misfortune"], [], ["trust_restored"], 0, "Bakery"),
		_event("radio_recipe", "The Gazette Prints Both Recipes", "The paper places the rival recipes side by side, forcing an honest comparison.", .42, ["recipes_shared", "gazette_interest"], [], ["trust_restored"], 0, "High Street"),
		_event("choir_quiet", "The Parade Hall Falls Silent", "The meeting minutes accidentally record a solemn mediation between bakers.", .40, ["parade_minutes", "feud_public"], [], ["mediation_open"], 0, "Town Hall"),
		_event("queue_mediation", "The Town Forms a Mediation Committee", "A public hearing turns into a vote on whether the bakers should talk.", .42, ["public_hearing", "historic_resentment"], [], ["mediation_open"], 0, "Town Hall"),
		_event("neutral_taster", "A Neutral Taster Finds Common Ground", "The town's least interested resident finds the pastries equally excellent.", .42, ["first_kindness", "mediation_open"], [], ["trust_restored"], 0, "Public Gardens"),
		_event("regret_typewriter", "The Typewriter Suggests an Apology", "A clerk notices the feuding parties have both written the word sorry.", .40, ["feud_doubts", "mediation_open"], [], ["apology_draft"], 1, "Post Office"),
		_event("second_copy", "A Duplicate Apology Is Filed", "A registry clerk copies the apology and addresses it to both bakeries.", .43, ["duplicate_register", "apology_draft"], [], ["second_apology_copy"], 0, "Post Office"),
		_event("courier_misread", "A Courier Delivers Both Letters", "An urgent delivery deposits two apologies at the same doorway.", .39, ["second_apology_copy", "recipes_shared"], [], ["apology_delivered"], 1, "High Street"),
		_event("postmark", "An Apology Reaches the Correct Address", "A late postmark certifies that an apology was sent in good faith.", .40, ["apology_draft", "late_delivery"], [], ["apology_delivered"], 0, "Post Office"),
		_event("rival_recipe", "The Rival Accepts the Offer", "A handwritten recipe accompanies a reply that does not contain insults.", .39, ["apology_delivered", "recipes_shared"], [], ["apology_accepted"], 1, "Bakery"),
		_event("public_pie", "The Town Witnesses a Handshake", "The bakers exchange apologies while rescuing a collapsing tart display.", .39, ["apology_delivered", "joint_misfortune"], [], ["apology_accepted"], 0, "Public Gardens"),
		_event("joint_oven", "A Two-Bakery Oven Is Commissioned", "The rivals jointly purchase an oven with an unnecessarily wide door.", .35, ["apology_accepted", "trust_restored"], [], ["rivals_reconciled"], 1, "Bakery"),
		_event("joint_till", "The Bakers Share a Till", "The second apology copy becomes the founding document of a joint venture.", .36, ["apology_accepted", "second_apology_copy"], [], ["rivals_reconciled"], 0, "High Street"),
		_event("ceremonial_tart", "A Tart Is Cut in Front of Witnesses", "The public hearing concludes with the two bakers signing a shared menu.", .35, ["apology_accepted", "public_hearing"], [], ["rivals_reconciled"], 1, "Town Hall"),
	]

static func _event(id: String, title: String, text: String, chance: float, all_facts: Array, any_facts: Array, outputs: Array, points: int, place: String, alternate: Array = [], alt_points: int = 0, alt_text: String = "") -> Dictionary:
	return {"id": id, "title": title, "text": text, "chance": chance, "all": all_facts,
		"any": any_facts, "facts": outputs, "support": points, "place": place,
		"misfile_facts": alternate, "misfile_support": alt_points, "misfile_text": alt_text}
