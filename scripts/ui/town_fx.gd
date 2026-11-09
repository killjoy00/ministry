extends Control
## Small, deterministic paper-and-ink animation layer for the illustrated town.
## Never invents incidents: the parent chooses the effect from a logged event.

var kind: String = ""
var elapsed: float = 0.0
var reduced_motion: bool = false
# Only the simulation's logged parent IDs authorize a direct-cause arrow.
var causal_origins: Array[Vector2] = []
var causal_target: Vector2 = Vector2.ZERO

func set_causal_links(origins: Array, target: Vector2) -> void:
	causal_origins.clear()
	for origin in origins:
		if origin is Vector2:
			causal_origins.append(origin)
	causal_target = target
	queue_redraw()

func set_incident(new_kind: String) -> void:
	kind = new_kind
	elapsed = 0.0
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not reduced_motion and not kind.is_empty():
		elapsed += minf(delta, 0.1)
		queue_redraw()

func _draw() -> void:
	if not causal_origins.is_empty():
		for source in causal_origins:
			_draw_causal_arrow(source, causal_target)
	if kind.is_empty():
		return
	var w: float = size.x
	var h: float = size.y
	if w < 10.0 or h < 10.0:
		return
	match kind:
		"rain":
			for i in range(86):
				var x: float = fposmod(float(i * 79) + elapsed * 180.0, w)
				var y: float = fposmod(float(i * 53) + elapsed * 290.0, h)
				draw_line(Vector2(x, y), Vector2(x - 9.0, y + 22.0), Color("#e1f2edb3"), 2.0)
		"wind":
			for i in range(11):
				var x: float = fposmod(float(i * 122) + elapsed * 123.0, w + 75.0) - 35.0
				var y: float = 70.0 + fposmod(float(i * 47), h - 100.0) + sin(elapsed * 2.4 + i) * 10.0
				draw_arc(Vector2(x, y), 24.0 + (i % 3) * 9.0, 0.5, 2.6, 15, Color("#fff3d9bb"), 3.0, true)
				draw_rect(Rect2(x - 2.0, y, 13.0, 9.0), Color("#f7e4b9"))
		"letter":
			for i in range(7):
				var p: float = fposmod(elapsed * 0.21 + i * 0.23, 1.0)
				var pos := Vector2(35.0 + w * p, 90.0 + float(i * 39) + sin(p * TAU * 2.0) * 23.0)
				draw_rect(Rect2(pos, Vector2(24, 15)), Color("#f6e7c4"))
				draw_line(pos, pos + Vector2(12, 9), Color("#90595c"), 1.4)
				draw_line(pos + Vector2(24, 0), pos + Vector2(12, 9), Color("#90595c"), 1.4)
		"sandwich":
			var p: float = 0.5 if reduced_motion else fposmod(elapsed * 0.55, 1.0)
			var center := Vector2(w * (0.32 + p * 0.4), h * 0.72 - sin(p * PI) * 58.0)
			draw_rect(Rect2(center - Vector2(24, 7), Vector2(48, 14)), Color("#f5d999"))
			draw_line(center + Vector2(-20, 1), center + Vector2(20, 1), Color("#54805a"), 5.0)
		"newspaper":
			for i in range(13):
				var s := (sin(elapsed * 3.2 + float(i) * 2.6) + 1.0) * 0.5
				var angle: float = float(i) * TAU / 13.0
				var pos := Vector2(w * 0.56, h * 0.48) + Vector2(cos(angle), sin(angle)) * (55.0 + 105.0 * s)
				draw_line(pos + Vector2(-7.0, 0), pos + Vector2(7.0, 0), Color("#fff1b8"), 3.0)
				draw_line(pos + Vector2(0, -7.0), pos + Vector2(0, 7.0), Color("#fff1b8"), 3.0)
		"election":
			for i in range(76):
				var x: float = fposmod(float(i * 71) + sin(elapsed * 1.8 + i) * 20.0, w)
				var y: float = fposmod(float(i * 41) + elapsed * (35.0 + (i % 5) * 14.0), h)
				var color: Color = Color("#9b4d55") if i % 3 == 0 else (Color("#f4d58d") if i % 3 == 1 else Color("#fff3d8"))
				draw_rect(Rect2(x, y, 7, 12), color)

func _draw_causal_arrow(source: Vector2, target: Vector2) -> void:
	# A curved, dotted brass link from a real causal parent to the event location.
	if source.distance_to(target) < 12.0:
		draw_arc(target + Vector2(0, -18), 15.0, 0.0, TAU * 0.8, 24, Color("#fff2b7"), 3.0, true)
		return
	var mid: Vector2 = (source + target) * 0.5 + Vector2(0, -45.0)
	var previous: Vector2 = source
	var point: Vector2 = source
	for i in range(1, 28):
		var t: float = float(i) / 27.0
		point = source * pow(1.0 - t, 2) + mid * (2.0 * t * (1.0 - t)) + target * (t * t)
		if i % 3 != 0:
			draw_line(previous, point, Color("#ffe8ac"), 3.0, true)
		previous = point
	var normal: Vector2 = (point - mid).normalized()
	draw_line(point, point + normal.rotated(2.55) * 13.0, Color("#ffe8ac"), 3.0, true)
	draw_line(point, point + normal.rotated(-2.55) * 13.0, Color("#ffe8ac"), 3.0, true)
