extends RefCounted
## Hand-authored *composable* events. No fixed chain is required to win.

static func description() -> Dictionary:
	return {
		"title": "A Fowl Election",
		"brief": "Make Gerald the Goose the duly elected mayor of Little Wittering by Sunday.",
		"memo": "Directly appointing a goose is strictly forbidden under Regulation 19-B.",
		"deadline": 7,
		"required_support": 15,
		"locations": ["Town Hall", "Parade Hall", "High Street", "Post Office", "Bakery", "Public Gardens"],
		"residents": ["Gerald the Goose", "Mayor Huxley", "Mrs. Flit the Postmistress", "Nora the Baker", "Clive the Photographer", "Pip the Courier", "Councillor Fenn", "The Local Reporter"]
	}

static func rules() -> Array:
	var r: Array = []
	# Small incidents — no requirements. Multiple independent starting paths.
	r.append(_event("rain", "An Inconvenient Shower", "A short, deeply disrespectful rainstorm drenches the high street.", 0.35, [], [], ["rain"], 0, "High Street"))
	r.append(_event("sandwich", "An Abandoned Sandwich", "An excellent sandwich is abandoned outside the bakery.", 0.46, [], [], ["sandwich"], 0, "Bakery"))
	r.append(_event("post", "A Mislaid Delivery", "Mrs. Flit accidentally opens the mayoral postbag.", 0.40, [], [], ["postal_mixup"], 0, "Post Office"))
	r.append(_event("traffic", "The Bus Takes the Long Way", "The mayor's bus becomes trapped behind an unusually dignified tractor.", 0.40, [], [], ["traffic"], 0, "High Street"))
	r.append(_event("wind", "A Gust of Administrative Wind", "An irritating gust rearranges the town's campaign posters.", 0.28, [], [], ["wind"], 0, "Public Gardens"))
	r.append(_event("fair", "The Village Fair Opens", "A respectable crowd gathers for an entirely unremarkable village fair.", 0.49, [], [], ["fair"], 0, "Town Hall"))
	r.append(_event("coffee", "A Spilled Coffee", "The mayor deposits his coffee onto the draft of his own speech.", 0.33, [], [], ["coffee_spilled"], 0, "Town Hall"))

	# Conditional consequences — facts provide causal evidence for the log.
	r.append(_event("indoor_parade", "Parade Moved Indoors", "Officials relocate the parade into the echoing Town Hall.", 0.69, ["rain"], [], ["indoor_parade"], 0, "Town Hall"))
	r.append(_event("goose_hungry", "Gerald Follows His Nose", "A hungry goose follows a promising scent toward the crowd.", 0.74, ["sandwich"], [], ["goose_at_hall"], 0, "Bakery"))
	r.append(_event("mayor_late", "The Mayor Misses His Entrance", "Huxley is late enough for his absence to become noticeable.", 0.62, [], ["traffic", "indoor_parade"], ["mayor_late"], 0, "Town Hall"))
	r.append(_event("wrong_invitation", "A Formal Invitation Goes Astray", "An invitation is filed under the wrong name, as is customary.", 0.48, ["postal_mixup"], [], ["mayor_invited"], 0, "Post Office", ["goose_invited"], 1, "The invitation is addressed to Gerald instead of the mayor."))
	r.append(_event("torn_posters", "Campaign Posters Go Flying", "A poster lands on the bakery door, where everyone reads it.", 0.56, ["wind"], [], ["mayor_posters"], 0, "High Street", ["goose_posters"], 2, "Gerald's portrait replaces the mayor's face on every poster."))
	r.append(_event("crowd", "A Respectable Crowd Forms", "A knot of locals forms in a place where cameras can see them.", 0.68, [], ["fair", "indoor_parade"], ["crowd"], 0, "Town Hall"))
	r.append(_event("speech_ruined", "Speech Abandoned", "With his notes in ruins, the mayor gives an alarming improvisation.", 0.63, [], ["coffee_spilled", "mayor_late"], ["mayor_embarrassed"], 1, "Town Hall"))
	r.append(_event("goose_stage", "An Unscheduled Speaker", "Gerald wanders onto the stage and receives unexpectedly warm applause.", 0.52, ["crowd"], ["goose_at_hall", "goose_invited"], ["goose_on_stage"], 1, "Town Hall"))
	r.append(_event("fair_prize", "First Prize in the Wrong Category", "Gerald wins Best in Show despite being entered as an ornamental shrub.", 0.55, ["fair", "goose_at_hall"], [], ["goose_prize"], 2, "Public Gardens"))
	r.append(_event("camera", "The Photographer Notices", "Clive accidentally photographs Gerald instead of the candidate.", 0.70, [], ["goose_on_stage", "goose_prize"], ["goose_photo"], 1, "Town Hall"))
	r.append(_event("front_page", "A Front-Page Mix-up", "The Gazette prints Gerald's portrait above the words 'A New Direction'.", 0.54, ["goose_photo"], [], ["goose_headline"], 2, "Post Office"))
	r.append(_event("windfall", "The Wind Collects Its Dues", "A runaway campaign banner settles neatly around Gerald like a sash.", 0.62, ["wind", "goose_photo"], [], ["goose_sash"], 2, "Public Gardens"))
	r.append(_event("goose_viral", "Word Gets Around", "The town begins repeating a story about a civic-minded goose.", 0.55, [], ["goose_headline", "goose_sash", "goose_prize"], ["goose_viral"], 2, "High Street"))
	r.append(_event("rulebook", "The Eligibility Regulations Are Misread", "A councillor discovers that the ballot rules never specifically mention wings.", 0.47, ["postal_mixup"], [], ["goose_eligible"], 0, "Town Hall", ["goose_eligible"], 1, "A stamped exception makes Gerald's eligibility official."))
	r.append(_event("special_council", "An Extraordinary By-law", "The council approves candidates possessing a strong sense of direction and/or a beak.", 0.51, ["goose_viral"], [], ["goose_eligible"], 0, "Town Hall"))
	r.append(_event("petition", "An Entirely Serious Petition", "The residents nominate Gerald as the only candidate who has listened to them.", 0.67, [], ["goose_headline", "goose_prize", "goose_viral"], ["goose_petition"], 2, "High Street"))
	r.append(_event("nomination", "Candidacy Certified", "The town clerk reluctantly certifies Gerald's candidacy.", 0.76, ["goose_petition", "goose_eligible"], [], ["goose_candidate"], 1, "Town Hall"))
	r.append(_event("debate", "The Candidate Declines to Comment", "Gerald wins the public debate by maintaining a dignified silence.", 0.64, ["goose_candidate"], [], ["goose_debate"], 2, "Town Hall"))
	r.append(_event("endorsement", "A Surprising Endorsement", "The baker endorses Gerald as the only candidate with a sincere interest in bread.", 0.58, ["goose_candidate"], ["goose_at_hall", "goose_prize"], ["goose_endorsed"], 2, "Bakery"))
	r.append(_event("scandal", "The Mayor's Remarks Are Quoted Accurately", "Huxley's improvisation becomes the least popular speech in local history.", 0.58, ["mayor_embarrassed"], [], ["mayor_scandal"], 1, "Town Hall"))
	r.append(_event("poll", "Pollsters Spot an Upset", "An opinion poll reveals a troubling number of people prefer the goose.", 0.72, ["goose_candidate"], ["goose_debate", "goose_viral", "mayor_scandal"], ["goose_poll"], 2, "Post Office"))
	return r

static func _event(id: String, title: String, text: String, probability: float, all_facts: Array, any_facts: Array, output_facts: Array, support: int, place: String, misfile_facts: Array = [], misfile_support: int = 0, misfile_text: String = "") -> Dictionary:
	return {"id": id, "title": title, "text": text, "chance": probability, "all": all_facts, "any": any_facts, "facts": output_facts, "support": support, "place": place, "misfile_facts": misfile_facts, "misfile_support": misfile_support, "misfile_text": misfile_text}
