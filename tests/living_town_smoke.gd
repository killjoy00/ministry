extends SceneTree
## Regression: interactive town is faithful to simulation, controller-friendly,
## skippable, and compatible with the original (offline) Ministry case.
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
var checks: int = 0
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _expect(ok: bool, what: String) -> void:
	checks += 1
	if not ok: errors.append(what)

func _run() -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.sim = Simulation.new(2501, false)
	scene._render()
	await process_frame
	await process_frame
	var music = root.get_node_or_null("MusicDirector")
	_expect(music != null, "Original waltz must be an autoloaded local music system")
	if music != null:
		_expect(music.get("player") is AudioStreamPlayer, "Waltz has an AudioStreamPlayer")
		_expect(music.get("stamp_player") is AudioStreamPlayer, "Stamp audio is available")
		music.set_music_enabled(false)
		_expect(not music.music_enabled, "Music can be muted from settings")
		music.set_music_enabled(true)
		music.set_music_volume(0.35)
		_expect(absf(music.music_volume - 0.35) < 0.01, "Music volume can be adjusted")
		music.play_stamp_effect()
		var sampled: float = 0.0
		for i in range(40):
			sampled += absf(float(music._music_sample(float(i) * 0.011 + 0.002)))
		_expect(sampled > 0.01, "The original waltz synthesizes audible, nonzero music")
		_expect(absf(float(music._music_sample(0.12))) < 1.0, "Waltz mix does not clip")
	_expect(scene.find_child("MusicToggle", true, false) != null, "Handheld screen exposes music toggle")
	_expect(scene.find_child("MusicVolumeDown", true, false) != null, "Music has a volume down control")
	_expect(scene.find_child("MusicVolumeUp", true, false) != null, "Music has a volume up control")
	scene._open_gallery("town")
	await process_frame
	await process_frame
	var town: Control = scene.gallery_overlay
	_expect(town != null and town.name == "LivingOddford", "Town is an interactive scene")
	if town != null:
		_expect(town.location_buttons.size() == 6, "Six inspectable locations exist")
		_expect(town.find_child("LivingTownImage", true, false) != null, "Town backdrop is part of real scene")
		town._show_location("Bakery")
		_expect(town.selected_location == "Bakery", "Location selection changes spotlight")
		_expect(town._selected_eligible_id == "sandwich", "Bakery reveals a real, eligible incident")
		town._investigate()
	await process_frame
	_expect(scene.gallery_overlay == null, "Inspecting an incident returns to case file")
	_expect(scene.selected_event == "sandwich", "Inspection selects the actual pending incident")
	var old_size: int = scene.sim.history.size()
	scene._advance_day()
	await process_frame
	await process_frame
	var report: Control = scene.gallery_overlay
	_expect(report != null, "Every new day shows a report scene")
	if report != null:
		_expect(report.replay_mode, "Day report runs in replay mode")
		var exact_events: Array = []
		for item in scene.sim.history.slice(old_size):
			var event_id: String = str(item.get("id", ""))
			if not scene.sim.get_rule(event_id).is_empty() or event_id.begins_with("correction_"):
				exact_events.append(item)
		_expect(report.replay_events.size() == exact_events.size(), "Only actual simulation events are replayed, not internal notes")
		if not exact_events.is_empty():
			_expect(str(report.replay_events[0]["id"]) == str(exact_events[0]["id"]), "First replay source event matches history")
			report._skip_replay()
			_expect(report.replay_paused, "Replay can be skipped immediately")
			report._previous_event()
			_expect(report.replay_paused, "Player can inspect earlier causes")
		scene._close_gallery()
	for d in range(6):
		scene._advance_day()
		if scene.gallery_overlay != null:
			scene._close_gallery()
	await process_frame
	_expect(scene.sim.status != "active", "Run completes after seven days with replays enabled")
	_expect(scene.find_child("MusicToggle", true, false) != null, "Music controls remain on result screen")
	root.remove_child(scene)
	scene.free()
	if errors.is_empty():
		print("PASS: %d living-town, causal-replay and sound assertions" % checks)
		quit(0)
	else:
		for problem in errors: printerr("FAIL: ", problem)
		printerr("FAILED: %d / %d" % [errors.size(), checks])
		quit(1)
