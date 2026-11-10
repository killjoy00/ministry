extends SceneTree
## The stamp-slam, postcard sequence, summary and causal ribbons use real data
## and cannot influence the simulation, scores or permanent progression.
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
const Theater = preload("res://scripts/ui/causality_theater.gd")
const Threads = preload("res://scripts/ui/theater_threads.gd")
var checks: int = 0
var problems: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok: problems.append(description)
func _find(parent: Node, sought: String) -> Node:
	if parent.name == sought: return parent
	for child in parent.get_children():
		var result: Node = _find(child, sought)
		if result != null: return result
	return null
func _run() -> void:
	var t := Threads.new()
	var unrelated: Array = [
		{"id":"root", "causes":[]}, {"id":"other", "causes":[]},
		{"id":"child", "causes":["root"]}, {"id":"last", "causes":["other"]}
	]
	t.configure(unrelated)
	_check(t.links.size() == 2, "No invented links between adjacent unrelated incidents")
	_check(int(t.links[0]["from"]) == 0 and int(t.links[0]["to"]) == 2,"Actual nonadjacent cause gets linked")
	_check(int(t.links[1]["from"]) == 1 and int(t.links[1]["to"]) == 3,"Second real cause gets linked")
	t.set_revealed(2)
	_check(t.revealed_count == 2,"Thread reveal is bounded by card count")
	t.free()
	var fake: Array = [
		{"id":"early", "support":0, "causes":[]},
		{"id":"mid", "support":3, "causes":["early"]},
		{"id":"unrelated", "support":0, "causes":[]},
		{"id":"stamped", "support":0, "causes":["mid"]},
		{"id":"late", "support":4, "causes":["stamped"]}
	]
	var selected: Array = Theater._choose_events(fake,[{"stamp":"nudge","target":"stamped"}],4)
	_check(selected.size()==4,"Only 4 cards shown in short replay")
	_check(selected.any(func(e):return str(e["id"])=="stamped"),"Stamped actual incident prioritized")
	var copy: Array = []
	for e in selected: copy.append(fake.find(e))
	_check(copy==copy.duplicate().duplicate(),"Event subset is stable")
	var game: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.sim = Simulation.new(1, false)
	game._render()
	await process_frame
	var earlier: int = game.sim.history.size()
	var old_day: int = game.sim.day
	var old_support: int = game.sim.support
	var old_influence: int = game.sim.influence
	game._approve_stamp()
	var filed: Dictionary = game.sim.pending.duplicate(true)
	game._advance_day()
	await process_frame
	await process_frame
	var theater: Control = game.gallery_overlay
	_check(theater != null and theater.name == "DailyCausalityTheater", "Advancing opens short Causality Theater")
	if theater != null:
		_check(theater.day_number == old_day,"Daily label reflects resolved day")
		_check(theater.recorded.size() > 0, "Only actual incidents animate")
		var real: Array = []
		for e in game.sim.history.slice(earlier):
			if not game.sim.get_rule(str(e.get("id", ""))).is_empty() or str(e.get("id", "")).begins_with("correction_"):
				real.append(e)
		_check(theater.recorded==real,"Reconstruction exactly matches resolved simulation log")
		_check(theater.filings.size()==1 and theater.filings[0]==filed,"Stamped target retained before engine clears it")
		_check(_find(theater,"DailyStampSlam") is TextureRect,"Physical stamp slam is visible")
		_check(_find(theater,"CausalityTownImage") is TextureRect,"Illustrated town backs replay")
		_check(_find(theater,"ActualCausalThreads")!=null,"Real causal connectors present")
		_check(_find(theater,"FullTownReplay") is Button,"Optional full chronology is available")
		_check(_find(theater,"ReturnFromDailyTheater") is Button,"Continue control is reachable")
		_check(game.get_viewport().get_visible_rect().size==Vector2(1280,800),"Steam Deck resolution unchanged")
		for which in ["FullTownReplay","ReturnFromDailyTheater","SkipDailyAnimation"]:
			var b := _find(theater,which) as Button
			_check(b!=null and b.get_global_rect().end.y<=800 and b.get_global_rect().position.y>=0,which+" visible on Deck")
		for i in range(theater.featured.size()):
			theater._reveal(i)
			theater.visible_count=i+1
		_check(theater.featured.size() <= 4, "Animation uses up to 4 actual postcard beats")
		theater._finish_animation()
		_check(theater.completed and theater.summary_label.visible,"Skippable animation shows real daily summary")
		_check(theater.summary_label.text.contains("%d INCIDENTS" % real.size()),"Daily summary counts actual incidents")
		_check(theater.summary_label.text.contains("%+d MOMENTUM" % (game.sim.support-old_support)),"Daily summary uses true support change")
		_check(game.sim.influence <= old_influence + 2,"Presentation does not change Influence")
		var snapshot: String = JSON.stringify(game.sim.history)
		theater._finish_animation()
		_check(snapshot==JSON.stringify(game.sim.history),"Repeat skip does not mutate history")
		theater._view_full_replay()
		await process_frame
		var full: Control = game.gallery_overlay
		_check(full != null and full.name == "LivingOddford", "Full replay opens existing town visualization")
		if full != null:
			_check(full.replay_events.size()==real.size(),"Full replay still has every real event")
		game._close_gallery()
	for i in range(3):
		game._advance_day()
		if game.gallery_overlay != null: game._close_gallery()
	_check(game.sim.day > old_day,"Normal gameplay continues after replay")
	root.remove_child(game)
	game.free()
	if problems.is_empty():
		print("PASS: %d daily Causality Theater assertions" % checks)
		quit(0)
		return
	for problem in problems: printerr("FAIL: ",problem)
	quit(1)
