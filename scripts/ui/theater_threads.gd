extends Control
## Gold-ink links are drawn only when an event records another on-screen
## incident as an actual causal parent. Adjacent cards are NOT automatically linked.

var links: Array[Dictionary] = []
var revealed_count: int = 0

func configure(entries: Array) -> void:
	links.clear()
	var positions: Dictionary = {}
	for i in range(entries.size()):
		positions[str(entries[i].get("id", ""))] = i
	for child_index in range(entries.size()):
		for source_id in entries[child_index].get("causes", []):
			var id: String = str(source_id)
			if positions.has(id) and int(positions[id]) < child_index:
				links.append({"from": int(positions[id]), "to": child_index, "id": id})
	queue_redraw()

func set_revealed(count: int) -> void:
	revealed_count = count
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	for link in links:
		var a: int = int(link["from"])
		var b: int = int(link["to"])
		if b >= revealed_count:
			continue
		# Stage cards occupy 269 px with a 13 px gap, starting at 0.
		# Curved arrows travel ABOVE cards rather than crossing their text.
		var start := Vector2(139.0 + a * 282.0, 35.0)
		var finish := Vector2(139.0 + b * 282.0, 35.0)
		var rise: float = 21.0 + 8.0 * float(b - a)
		var control := (start + finish) * 0.5 + Vector2(0.0, -rise)
		var points := PackedVector2Array()
		for step in range(25):
			var t: float = float(step) / 24.0
			points.append(start * (1.0 - t) * (1.0 - t) + control * 2.0 * t * (1.0 - t) + finish * t * t)
		for step in range(1, points.size()):
			if step % 4 != 0:
				draw_line(points[step - 1], points[step], Color("#a67a47"), 3.0, true)
		var tail: Vector2 = (finish - points[points.size() - 3]).normalized()
		draw_line(finish, finish + tail.rotated(2.55) * 11.0, Color("#a67a47"), 2.4, true)
		draw_line(finish, finish + tail.rotated(-2.55) * 11.0, Color("#a67a47"), 2.4, true)
