extends SceneTree
## Run with: godot --headless --path . --script res://tests/smoke.gd

const Simulation = preload("res://scripts/simulation/case_simulation.gd")
const TEST_SAVE = "user://ministry_test_save.json"
var assertions: int = 0
var failures: Array = []

func _initialize() -> void:
	_test_main_scene_load()
	_test_seed_replay()
	_test_requirements_and_once_only()
	_test_stamps()
	_test_reality_correction()
	_test_settlement_and_save()
	_test_causality_bounded()
	if failures.is_empty():
		print("PASS: %d assertions / Ministry of Coincidences" % assertions)
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		printerr("FAILED: %d of %d assertions" % [failures.size(), assertions])
		quit(1)

func _test_main_scene_load() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	_check(scene != null, "Main UI scene must parse and load")
	if scene == null:
		return
	var instance: Node = scene.instantiate()
	_check(instance != null, "Main UI scene must instantiate")
	if instance == null:
		return
	root.add_child(instance)
	_check(instance.get_child_count() >= 2, "Main scene builds controller-first interface")
	instance.queue_free()

func _check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)

func _test_seed_replay() -> void:
	var a = Simulation.new(4141, false)
	var b = Simulation.new(4141, false)
	for game in [a, b]:
		game.stage_stamp("nudge", "rain")
		for i in range(7):
			game.advance_day()
	_check(JSON.stringify(a.history) == JSON.stringify(b.history), "fixed seed and actions must replay identically")
	_check(a.support == b.support and a.status == b.status, "same seed must produce same result")

func _test_requirements_and_once_only() -> void:
	var game = Simulation.new(13, false)
	_check(not game._eligible(game.get_rule("goose_stage")), "complex event cannot start without prerequisites")
	for i in range(7):
		game.advance_day()
	var seen: Dictionary = {}
	for e in game.history:
		if game.get_rule(str(e["id"])).is_empty():
			continue
		_check(not seen.has(e["id"]), "rule fired twice: " + e["id"])
		seen[e["id"]] = true
	_check(game.day == 7, "case resolves on day 7")

func _test_stamps() -> void:
	var game = Simulation.new(22, false)
	_check(game.can_stamp("nudge", "rain"), "nudge allowed on starting event")
	_check(not game.can_stamp("misfile", "rain"), "misfile rejects unredirectable event")
	_check(game.stage_stamp("reschedule", "rain"), "reschedule approved")
	game.advance_day()
	_check(not game.has_fact("rain"), "rescheduled event must not happen on first day")
	_check(game.scheduled.has("rain"), "rescheduled event appears in diary")
	game.advance_day()
	_check(game.has_fact("rain"), "rescheduled event guaranteed next day")
	var saw_misfile := false
	for seed_id in range(80):
		var alt = Simulation.new(seed_id, false)
		alt.facts["postal_mixup"] = true
		alt.fact_sources["postal_mixup"] = "post"
		_check(alt.can_stamp("misfile", "wrong_invitation"), "misfile has valid target")
		alt.stage_stamp("misfile", "wrong_invitation")
		alt.advance_day()
		if alt.fired.has("wrong_invitation"):
			_check(alt.has_fact("goose_invited") and not alt.has_fact("mayor_invited"), "misfile must redirect, not simply relabel")
			saw_misfile = true
			break
	_check(saw_misfile, "at least one seeded misfile triggered")
	var saw_domino := false
	for seed_id in range(80):
		var domino = Simulation.new(seed_id, false)
		domino.facts["sandwich"] = true
		domino.fact_sources["sandwich"] = "sandwich"
		domino.facts["crowd"] = true
		domino.fact_sources["crowd"] = "crowd"
		domino.stage_stamp("domino", "goose_hungry")
		domino.advance_day()
		for e in domino.history:
			if e["title"] == "DOMINO ACTIVATED":
				saw_domino = true
	_check(saw_domino, "Domino must guarantee a newly enabled eligible consequence")

func _test_reality_correction() -> void:
	var game = Simulation.new(6, false)
	game.strain = 5
	game.stage_stamp("nudge", "rain")
	game.advance_day()
	_check(not game.corrections.is_empty(), "reality strain threshold schedules a correction")
	_check(int(game.corrections[0]["day"]) == 2, "correction is telegraphed for the next day")
	game.advance_day()
	_check(game.corrections.is_empty(), "scheduled correction must be resolved")
	var has_correction := false
	for e in game.history:
		if str(e["id"]).begins_with("correction_"):
			has_correction = true
	_check(has_correction, "correction must have a visible chronicle record")

func _test_settlement_and_save() -> void:
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	var game = Simulation.new(104, true, TEST_SAVE)
	# Arrange a success through explicit state to test settlement independent of RNG.
	game.facts["goose_candidate"] = true
	game.fact_sources["goose_candidate"] = "nomination"
	game.support = 16
	for i in range(7):
		game.advance_day()
	_check(game.status == "won", "sufficient support and legitimate candidacy result in victory")
	_check(game.reward_paid and int(game.profile["completed"]) == 1, "case reward paid once")
	var merit_before: int = int(game.profile["merit"])
	game.advance_day()
	_check(int(game.profile["merit"]) == merit_before, "case cannot double-pay Merit")
	var loaded = Simulation.new(-1, true, TEST_SAVE)
	_check(loaded.status == "won" and loaded.support == game.support, "save restores settled run")
	_check(int(loaded.profile["merit"]) == merit_before, "save restores permanent Merit")
	_check(loaded.buy_upgrade("desk"), "Merit can buy a permanent upgrade")
	var reloaded = Simulation.new(-1, true, TEST_SAVE)
	_check(int(reloaded.profile["desk"]) == 1, "permanent upgrade survives reload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))

func _test_causality_bounded() -> void:
	for seed_id in range(25):
		var game = Simulation.new(seed_id, false)
		for d in range(7):
			game.advance_day()
		_check(game.history.size() < 256, "seed %d had unbounded event chain" % seed_id)
		for e in game.history:
			for parent in e["causes"]:
				_check(not str(parent).is_empty(), "causal source ID cannot be empty")
