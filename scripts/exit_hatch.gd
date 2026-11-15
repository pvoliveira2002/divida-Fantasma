extends Node2D

enum State { SEALED, UNLOCKING, READY, ENTERING }

const CLOSED_HATCH_TEXTURE := preload("res://assets/environments/hatch/cyber_hatch_closed_v1.png")
const CLOSED_VISUAL_SCALE := Vector2(0.075, 0.075)
const OPEN_FRAME_HALF_SIZE := Vector2(54.0, 36.0)
const OPENING_HALF_SIZE := Vector2(46.0, 30.0)

var state := State.SEALED
var accent := Color("36f2dd")
var open_amount := 0.0
var open_target := 0.0
var phase := 0.0
var closed_visual: Sprite2D


func _ready() -> void:
	z_index = 1
	closed_visual = Sprite2D.new()
	closed_visual.name = "ClosedVisual"
	closed_visual.texture = CLOSED_HATCH_TEXTURE
	closed_visual.scale = CLOSED_VISUAL_SCALE
	closed_visual.position = Vector2(0.0, -2.0)
	closed_visual.z_index = 1
	add_child(closed_visual)
	set_process(true)
	_update_closed_visual()
	queue_redraw()


func configure(world_position: Vector2, room_accent: Color) -> void:
	position = world_position
	accent = room_accent
	state = State.SEALED
	open_amount = 0.0
	open_target = 0.0
	visible = true
	_update_closed_visual()
	queue_redraw()


func begin_unlock() -> void:
	if state != State.SEALED:
		return
	state = State.UNLOCKING
	open_target = 0.42
	queue_redraw()


func open() -> void:
	if state == State.ENTERING:
		return
	state = State.READY
	open_target = 1.0
	queue_redraw()


func begin_entry() -> void:
	if not is_ready():
		return
	state = State.ENTERING
	open_target = 1.0
	queue_redraw()


func is_ready() -> bool:
	return state == State.READY and open_amount >= 0.92


func _process(delta: float) -> void:
	phase += delta * (5.2 if state in [State.READY, State.ENTERING] else 2.4)
	var previous := open_amount
	open_amount = move_toward(open_amount, open_target, delta * 1.9)
	_update_closed_visual()
	if not is_equal_approx(previous, open_amount) or state != State.SEALED:
		queue_redraw()


func _update_closed_visual() -> void:
	if not is_instance_valid(closed_visual):
		return
	var lid_open := smoothstep(0.42, 1.0, open_amount)
	var reveal := smoothstep(0.0, 0.32, lid_open)
	var unlock_shake := sin(phase * 4.0) * 1.2 if state == State.UNLOCKING else 0.0
	closed_visual.visible = reveal < 0.995
	closed_visual.position = Vector2(unlock_shake, -2.0 - 8.0 * reveal)
	closed_visual.scale = CLOSED_VISUAL_SCALE * Vector2(1.0, lerpf(1.0, 0.92, reveal))
	closed_visual.modulate = Color(1.0, 1.0, 1.0, 1.0 - reveal)


func is_procedural_body_visible() -> bool:
	return not is_instance_valid(closed_visual) or not closed_visual.visible


func get_procedural_footprint_size() -> Vector2:
	return OPEN_FRAME_HALF_SIZE * 2.0


func _diamond(half_size: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -half_size.y),
		Vector2(half_size.x, 0.0),
		Vector2(0.0, half_size.y),
		Vector2(-half_size.x, 0.0),
	])


func _draw() -> void:
	if not is_procedural_body_visible():
		return
	var pulse := 0.5 + sin(phase) * 0.5
	var lid_open := smoothstep(0.42, 1.0, open_amount)
	var opening_progress := smoothstep(0.24, 1.0, lid_open)
	var frame := _diamond(OPEN_FRAME_HALF_SIZE)
	var opening_size := Vector2(
		lerpf(34.0, OPENING_HALF_SIZE.x, opening_progress),
		lerpf(22.0, OPENING_HALF_SIZE.y, opening_progress)
	)
	var opening := _diamond(opening_size)
	var frame_outline := frame + PackedVector2Array([frame[0]])
	var opening_outline := opening + PackedVector2Array([opening[0]])

	# Isometric square matching the footprint of the closed hatch sprite.
	draw_set_transform(Vector2(3.0, 4.0), 0.0, Vector2.ONE)
	draw_colored_polygon(frame, Color(0.0, 0.0, 0.0, 0.34))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_colored_polygon(frame, Color("2b2e31"))
	draw_polyline(frame_outline, Color("111315"), 6.0, true)
	draw_polyline(frame_outline, Color("77736c"), 2.0, true)
	draw_colored_polygon(opening, Color("050708"))
	draw_colored_polygon(opening, Color(accent.r, accent.g, accent.b, 0.035 + pulse * 0.025))
	draw_polyline(opening_outline, Color("111416"), 4.0, true)
	draw_polyline(opening_outline, Color(accent.r, accent.g, accent.b, 0.38 + pulse * 0.18), 1.5, true)

	# Ladder and energy locks stay entirely inside the diamond opening.
	var ladder_color := Color(0.48, 0.43, 0.35, 0.72 + pulse * 0.12)
	draw_line(Vector2(-14.0, -12.0), Vector2(-14.0, 17.0), ladder_color, 3.0, true)
	draw_line(Vector2(14.0, -12.0), Vector2(14.0, 17.0), ladder_color, 3.0, true)
	for y in [-8.0, 0.0, 8.0, 16.0]:
		draw_line(Vector2(-14.0, y), Vector2(14.0, y), ladder_color, 2.5, true)
	var latch_positions: Array[Vector2] = [
		Vector2(0.0, -31.0), Vector2(47.0, 0.0),
		Vector2(0.0, 31.0), Vector2(-47.0, 0.0),
	]
	for latch_position: Vector2 in latch_positions:
		draw_circle(latch_position, 3.2, Color("111719"))
		draw_circle(latch_position, 1.7, Color(accent.r, accent.g, accent.b, 0.72 + pulse * 0.24))

	if state in [State.READY, State.ENTERING]:
		_draw_interaction_prompt(pulse)


func _draw_interaction_prompt(pulse: float) -> void:
	var bob := sin(phase * 1.3) * 4.0
	var indicator_alpha := 0.68 + pulse * 0.25
	for index in 3:
		var y := -58.0 - float(index) * 11.0 + bob
		draw_polyline(PackedVector2Array([
			Vector2(-11.0, y - 5.0), Vector2(0.0, y + 3.0), Vector2(11.0, y - 5.0),
		]), Color(accent.r, accent.g, accent.b, indicator_alpha - float(index) * 0.14), 2.5, true)
	var prompt_center := Vector2(0.0, -102.0 + bob)
	draw_circle(prompt_center, 14.0, Color(0.02, 0.04, 0.08, 0.86))
	draw_arc(prompt_center, 14.0, 0.0, TAU, 24, Color(accent.r, accent.g, accent.b, indicator_alpha), 2.5, true)
	draw_line(prompt_center + Vector2(-4.0, -7.0), prompt_center + Vector2(-4.0, 7.0), accent, 2.5, true)
	for y in [-7.0, 0.0, 7.0]:
		draw_line(prompt_center + Vector2(-4.0, y), prompt_center + Vector2(5.0, y), accent, 2.5, true)
