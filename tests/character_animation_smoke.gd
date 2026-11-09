extends SceneTree
## A real Godot test of the paper actors, recorded parent arrows, and
## controller-friendly reduced motion. No simulation data is changed.
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
const Town = preload("res://scripts/ui/living_town.gd")
const Choreography = preload("res://scripts/ui/character_choreography.gd")
var checks: int = 0
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(valid: bool, explanation: String) -> void:
	checks += 1
	if not valid: errors.append(explanation)

func _run() -> void:
	var sim = Simulation.new(81, false)
	for role in Choreography.PORTRAITS.keys():
		_check(ResourceLoader.exists(str(Choreography.PORTRAITS[role])), "Portrait bundled: " + str(role))
	for rule in sim.rules:
		var specs: Array[Dictionary] = Choreography.actors_for(str(rule["id"]), str(rule["place"]))
		_check(not specs.is_empty() and Choreography.validate_specs(specs), "Valid stage blocking: " + str(rule["id"]))
	_check(Choreography.scene_type("goose_stage") == "stage", "Gerald gets a distinct entrance scene")
	_check(Choreography.scene_type("indoor_parade") != "stage", "A parade never fabricates a stage entrance")
	_check(Choreography.scene_type("front_page") == "press", "The Gazette is depicted as a press scene")
	_check(Choreography.scene_type("correction_gust_4") == "wind", "Correction wind is visually distinct")
	var stage_specs: Array[Dictionary] = Choreography.actors_for("goose_stage", "Town Hall")
	_check(stage_specs[0]["role"] == "gerald" and stage_specs[0]["from"] != stage_specs[0]["to"], "Gerald actually walks onto the stage")
	var record := {"id":"goose_stage","day":4,"title":"An Unscheduled Speaker","text":"Gerald wanders onto the stage and receives unexpectedly warm applause.","support":1,"causes":["crowd","goose_hungry"]}
	var town = Town.new()
	town.configure(sim, [record], true)
	root.add_child(town)
	await process_frame
	await process_frame
	_check(town.find_child("OfficialPaperActors", true, false) != null, "The paper actors render over the town")
	_check(town._actors.size() == 4 and town._actors.has("gerald") and town._actors.has("mayor"), "The stage scene has a goose and responding residents")
	_check(town.effect_layer.causal_origins.size() == 2, "Only two recorded causes produce arrows")
	_check(town.causal_label.visible, "Documented causes are labelled")
	_check(town.find_child("RecordedSupportGain", true, false) != null, "Support feedback comes from the recorded event")
	_check(town.location_buttons.all(func(button): return not button.visible), "Location pins cannot cover actors during replay")
	_check(town.motion_button != null and town.motion_button.text.contains("MOTION"), "Reduced-motion button is accessible")
	var start: Vector2 = Vector2(town.MAP_SIZE.x * stage_specs[0]["from"].x, town.MAP_SIZE.y * stage_specs[0]["from"].y)
	var finish: Vector2 = Vector2(town.MAP_SIZE.x * stage_specs[0]["to"].x, town.MAP_SIZE.y * stage_specs[0]["to"].y)
	var actor = town._actors["gerald"]
	_check(actor.position.distance_to(start) < 2.0, "Gerald begins away from the stage")
	await create_timer(0.50).timeout
	_check(actor.position.distance_to(start) > 4.0, "Gerald physically moves before the report ends")
	town._toggle_reduced_motion()
	_check(town.reduced_motion, "Reduced motion can be turned on")
	_check(town._actors["gerald"].position.distance_to(finish) < 2.0, "Reduced motion snaps the story to the final pose")
	_check(not town._actors["gerald"].walking, "Reduced motion disables walking")
	var preferences := ConfigFile.new()
	_check(preferences.load(town.VISUAL_SETTINGS) == OK and bool(preferences.get_value("accessibility","reduced_motion",false)), "Reduced motion is saved locally")
	town._show_location("Bakery")
	_check(town.effect_layer.causal_origins.is_empty(), "Town exploration never retains a previous causal arrow")
	_check(town._actors.size() == 6, "Residents are present in exploration mode")
	town._show_replay()
	_check(town.effect_layer.causal_origins.size() == 2, "Revisiting restores actual, not invented, causes")
	town._toggle_reduced_motion()
	root.remove_child(town)
	town.free()
	if errors.is_empty():
		print("PASS: %d illustrated-character, cause-and-effect and motion assertions" % checks)
		quit(0)
	else:
		for err in errors: printerr("FAIL: ", err)
		quit(1)
