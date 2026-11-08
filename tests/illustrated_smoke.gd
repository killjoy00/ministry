extends SceneTree
## Verify the image-generated world is part of the playable Godot scene.
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
var checked: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, description: String) -> void:
	checked += 1
	if not condition:
		failures.append(description)

func _count_images(root_node: Node) -> int:
	var count: int = 0
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if node is TextureRect and (node as TextureRect).texture != null:
			count += 1
	return count

func _run() -> void:
	var names: Array[String] = [
		"oddford_square", "oddford_banner", "oddford_cast",
		"portrait_gerald", "portrait_clerk", "portrait_mayor",
		"portrait_reporter", "portrait_organizer", "portrait_baker",
		"stamp_nudge", "stamp_misfile", "stamp_reschedule", "stamp_domino",
		"incident_letter", "incident_rain", "incident_sandwich",
		"incident_wind", "incident_newspaper", "incident_election"
	]
	for asset_name in names:
		var path := "res://assets/illustrated/%s.webp" % asset_name
		_check(FileAccess.file_exists(path), "Missing production illustration: " + asset_name)
		_check(load(path) is Texture2D, "Illustration failed Godot import: " + asset_name)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.sim = Simulation.new(4242, false)
	scene._render()
	await process_frame
	await process_frame
	_check(_count_images(scene) >= 5, "Case scene must show portraits, town and chosen incident art")
	scene._open_gallery("cast")
	await process_frame
	await process_frame
	_check(scene.gallery_overlay != null and _count_images(scene.gallery_overlay) >= 6, "Cast register must show all six portraits")
	scene._close_gallery()
	scene._open_gallery("town")
	await process_frame
	await process_frame
	_check(scene.gallery_overlay != null and _count_images(scene.gallery_overlay) >= 1, "Town gallery must show Oddford panorama")
	scene._close_gallery()
	for day in range(7):
		scene._advance_day()
	await process_frame
	await process_frame
	_check(scene.sim.status != "active", "Illustrated case must still finish after seven days")
	_check(_count_images(scene) >= 2, "Result scene must retain illustrated outcome artwork")
	root.remove_child(scene)
	scene.free()
	if failures.is_empty():
		print("PASS: %d production-art and playable-gallery assertions" % checked)
		quit(0)
	else:
		for problem in failures:
			printerr("FAIL: " + problem)
		quit(1)
