extends Node2D
## Small illustrated paper actors, with footsteps, bobbing and reactions.
const Choreography = preload("res://scripts/ui/character_choreography.gd")
var role: String = ""
var portrait: Sprite2D
var walking: bool = false
var reduced_motion: bool = false
var mood: String = ""
var phase: float = 0.0
var _base_pos := Vector2(0.0, -31.0)

func configure(who: String, motion_reduced: bool = false) -> void:
	role = who
	reduced_motion = motion_reduced
	name = "Puppet" + who.capitalize()

func _ready() -> void:
	portrait = Sprite2D.new()
	portrait.name = "IllustratedPortrait"
	portrait.texture = load(str(Choreography.PORTRAITS[role])) as Texture2D
	portrait.scale = Vector2(0.34, 0.34)
	portrait.position = _base_pos
	add_child(portrait)
	queue_redraw()

func set_action(new_mood: String) -> void:
	mood = new_mood
	queue_redraw()

func set_walking(moving: bool) -> void:
	walking = moving and not reduced_motion
	queue_redraw()

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if enabled:
		walking = false
		phase = 0.0
		if portrait != null:
			portrait.position = _base_pos
			portrait.rotation = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if portrait == null or reduced_motion: return
	phase += minf(delta, 0.1)
	if walking:
		portrait.position = _base_pos + Vector2(0.0, sin(phase * 15.0) * 2.8)
		portrait.rotation = sin(phase * 15.0) * 0.045
	elif mood == "cheer":
		portrait.position = _base_pos + Vector2(0.0, -absf(sin(phase * 6.5)) * 4.0)
		portrait.rotation = sin(phase * 6.5) * 0.032
	elif mood == "surprised":
		portrait.position = _base_pos
		portrait.rotation = sin(phase * 3.0) * 0.04
	else:
		portrait.position = _base_pos + Vector2(0, sin(phase * 2.0) * 0.9)
		portrait.rotation = 0.0
	queue_redraw()

func _draw() -> void:
	var dark := Color("#443a34")
	var feet := Color("#e1a45a") if role == "gerald" else Color("#54473e")
	draw_set_transform(Vector2(0.0, 16.0), 0.0, Vector2(1.45, 0.25))
	draw_circle(Vector2.ZERO, 22.0, Color("#543c3c55"))
	draw_set_transform(Vector2.ZERO)
	var stride: float = sin(phase * 15.0) * 7.0 if walking and not reduced_motion else 0.0
	draw_line(Vector2(-10, -4), Vector2(-9 - stride, 14), dark, 3.0, true)
	draw_line(Vector2(10, -4), Vector2(9 + stride, 14), dark, 3.0, true)
	draw_line(Vector2(-9 - stride, 14), Vector2(-23 - stride, 14), feet, 5.0, true)
	draw_line(Vector2(9 + stride, 14), Vector2(23 + stride, 14), feet, 5.0, true)
	if mood == "surprised":
		draw_line(Vector2(35, -63), Vector2(42, -77), Color("#9d6062"), 3.0, true)
		draw_line(Vector2(42, -61), Vector2(57, -68), Color("#9d6062"), 3.0, true)
	elif mood == "proud":
		draw_circle(Vector2(36, -66), 4.0, Color("#ffdc8b"))
		draw_line(Vector2(36, -75), Vector2(36, -83), Color("#ffdc8b"), 2.0)
