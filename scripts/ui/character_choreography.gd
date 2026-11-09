extends RefCounted
## Stage blocking for documented event IDs only; no new game events or facts.
const PORTRAITS := {
	"gerald": "res://assets/illustrated/portrait_gerald.webp",
	"clerk": "res://assets/illustrated/portrait_clerk.webp",
	"mayor": "res://assets/illustrated/portrait_mayor.webp",
	"reporter": "res://assets/illustrated/portrait_reporter.webp",
	"organizer": "res://assets/illustrated/portrait_organizer.webp",
	"baker": "res://assets/illustrated/portrait_baker.webp"
}
const HOME := {
	"gerald": Vector2(0.24, 0.70), "clerk": Vector2(0.56, 0.65),
	"mayor": Vector2(0.62, 0.58), "reporter": Vector2(0.37, 0.73),
	"organizer": Vector2(0.20, 0.72), "baker": Vector2(0.85, 0.73)
}

static func scene_type(event_id: String) -> String:
	if event_id == "goose_stage": return "stage"
	if event_id in ["goose_hungry", "sandwich", "endorsement"]: return "sandwich"
	if event_id in ["post", "wrong_invitation", "rulebook", "petition"]: return "letter"
	if event_id in ["rain", "indoor_parade", "mayor_late", "fair"]: return "parade"
	if event_id in ["camera", "front_page", "goose_viral", "poll"]: return "press"
	if event_id in ["wind", "torn_posters", "windfall"] or event_id.begins_with("correction_"): return "wind"
	if event_id in ["nomination", "special_council", "debate", "fair_prize"]: return "civic"
	if event_id in ["speech_ruined", "scandal", "coffee"]: return "mayor"
	return "local"

static func _walk(role: String, first: Vector2, last: Vector2, wait: float = 0.0, duration: float = 1.20, mood: String = "") -> Dictionary:
	return {"role": role, "from": first, "to": last, "delay": wait, "duration": duration, "mood": mood}

static func actors_for(event_id: String, place: String) -> Array[Dictionary]:
	match scene_type(event_id):
		"stage":
			return [
				_walk("gerald", Vector2(0.28, 0.82), Vector2(0.51, 0.55), 0.05, 1.25, "proud"),
				_walk("mayor", Vector2(0.51, 0.60), Vector2(0.67, 0.78), 0.10, 1.10, "surprised"),
				_walk("reporter", Vector2(0.28, 0.78), Vector2(0.43, 0.75), 0.34, 0.95, "cheer"),
				_walk("baker", Vector2(0.81, 0.77), Vector2(0.73, 0.77), 0.52, 0.75, "cheer")
			]
		"sandwich":
			return [
				_walk("gerald", Vector2(0.40, 0.80), Vector2(0.78, 0.75), 0.10, 1.36, "proud"),
				_walk("baker", Vector2(0.90, 0.70), Vector2(0.84, 0.71), 0.52, 0.65, "surprised")
			]
		"letter":
			return [
				_walk("organizer", Vector2(0.48, 0.82), Vector2(0.19, 0.73), 0.05, 1.38, "surprised"),
				_walk("clerk", Vector2(0.18, 0.70), Vector2(0.24, 0.71), 0.45, 0.60, "inspect")
			]
		"parade":
			return [
				_walk("mayor", Vector2(0.27, 0.83), Vector2(0.50, 0.65), 0.05, 1.20, "proud"),
				_walk("reporter", Vector2(0.74, 0.81), Vector2(0.61, 0.70), 0.20, 0.88, "inspect"),
				_walk("clerk", Vector2(0.64, 0.75), Vector2(0.58, 0.67), 0.35, 0.70, "inspect")
			]
		"press":
			return [
				_walk("reporter", Vector2(0.20, 0.76), Vector2(0.46, 0.72), 0.05, 1.25, "cheer"),
				_walk("gerald", Vector2(0.60, 0.75), Vector2(0.55, 0.70), 0.28, 0.74, "proud"),
				_walk("organizer", Vector2(0.69, 0.78), Vector2(0.66, 0.78), 0.46, 0.55, "surprised")
			]
		"wind":
			return [
				_walk("mayor", Vector2(0.53, 0.72), Vector2(0.72, 0.81), 0.04, 1.30, "surprised"),
				_walk("clerk", Vector2(0.40, 0.76), Vector2(0.52, 0.73), 0.24, 1.00, "inspect")
			]
		"civic":
			return [
				_walk("gerald", Vector2(0.38, 0.80), Vector2(0.52, 0.68), 0.05, 1.15, "proud"),
				_walk("clerk", Vector2(0.62, 0.75), Vector2(0.57, 0.68), 0.32, 0.88, "inspect"),
				_walk("mayor", Vector2(0.73, 0.79), Vector2(0.68, 0.76), 0.44, 0.60, "surprised")
			]
		"mayor":
			return [
				_walk("mayor", Vector2(0.52, 0.68), Vector2(0.57, 0.71), 0.05, 0.85, "surprised"),
				_walk("reporter", Vector2(0.66, 0.77), Vector2(0.63, 0.74), 0.35, 0.65, "inspect")
			]
		_:
			var resident: String = "gerald"
			if place == "Bakery": resident = "baker"
			elif place == "Post Office": resident = "organizer"
			elif place == "Town Hall": resident = "clerk"
			elif place == "Parade Hall": resident = "mayor"
			elif place == "High Street": resident = "reporter"
			var p: Vector2 = HOME[resident]
			return [_walk(resident, p + Vector2(-0.07, 0.0), p, 0.0, 0.80, "inspect")]

static func validate_specs(specs: Array[Dictionary]) -> bool:
	for spec in specs:
		if not PORTRAITS.has(str(spec.get("role", ""))): return false
		if float(spec.get("duration", 0.0)) <= 0.0: return false
		for coordinate in [spec.get("from", Vector2(-1, -1)), spec.get("to", Vector2(-1, -1))]:
			if not (coordinate is Vector2): return false
			if coordinate.x < 0.08 or coordinate.x > 0.95 or coordinate.y < 0.15 or coordinate.y > 0.94: return false
	return true
