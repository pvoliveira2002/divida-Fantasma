extends Node2D

enum State { SEALED, UNLOCKING, READY, ENTERING }

var state := State.SEALED
var accent := Color("36f2dd")
var open_amount := 0.0
var open_target := 0.0
var phase := 0.0


func _ready() -> void:
	z_index = 1
	set_process(true)
	queue_redraw()


func configure(world_position: Vector2, room_accent: Color) -> void:
	position = world_position
	accent = room_accent
	state = State.SEALED
	open_amount = 0.0
	open_target = 0.0
	visible = true
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
	if not is_equal_approx(previous, open_amount) or state != State.SEALED:
		queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + sin(phase) * 0.5
	var frame := PackedVector2Array([
		Vector2(-48.0, -30.0), Vector2(42.0, -30.0), Vector2(55.0, -19.0),
		Vector2(55.0, 19.0), Vector2(43.0, 30.0), Vector2(-43.0, 30.0),
		Vector2(-55.0, 19.0), Vector2(-55.0, -19.0), Vector2(-48.0, -30.0),
	])
	var opening := PackedVector2Array([
		Vector2(-42.0, -21.0), Vector2(38.0, -21.0), Vector2(46.0, -14.0),
		Vector2(46.0, 15.0), Vector2(37.0, 22.0), Vector2(-37.0, 22.0),
		Vector2(-46.0, 14.0), Vector2(-46.0, -14.0),
	])
	# Sombra curta, moldura de ferro fundido e vão profundo.
	draw_set_transform(Vector2(4.0, 5.0), 0.0, Vector2(1.0, 0.78))
	draw_colored_polygon(frame, Color(0.0, 0.0, 0.0, 0.34))
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(frame, Color("34373a"))
	draw_polyline(frame, Color("111315"), 6.0, true)
	draw_polyline(frame, Color("77736c"), 2.0, true)
	draw_colored_polygon(opening, Color("050708"))
	draw_polyline(opening + PackedVector2Array([opening[0]]), Color("17191a"), 3.0, true)

	# Escada industrial aparece progressivamente quando a tampa deixa o vão livre.
	var lid_open := smoothstep(0.42, 1.0, open_amount)
	if lid_open > 0.08:
		var ladder_color := Color(0.48, 0.43, 0.35, lid_open * 0.85)
		draw_line(Vector2(-17.0, -13.0), Vector2(-17.0, 18.0), ladder_color, 3.0, true)
		draw_line(Vector2(17.0, -13.0), Vector2(17.0, 18.0), ladder_color, 3.0, true)
		for y in [-8.0, 1.0, 10.0, 19.0]:
			draw_line(Vector2(-17.0, y), Vector2(17.0, y), ladder_color, 2.5, true)
		draw_set_transform(Vector2(0.0, 2.0), 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, 36.0, Color(accent.r, accent.g, accent.b, lid_open * (0.05 + pulse * 0.035)))
		draw_set_transform(Vector2.ZERO)

	# Tampa única recua para a dobradiça superior, como uma peça antiga e pesada.
	var unlock_shake := sin(phase * 4.0) * 1.2 if state == State.UNLOCKING else 0.0
	var lid_center := Vector2(unlock_shake, lerpf(0.0, -50.0, lid_open))
	var lid_half_height := lerpf(20.0, 10.0, lid_open)
	var lid := PackedVector2Array([
		lid_center + Vector2(-39.0, -lid_half_height), lid_center + Vector2(35.0, -lid_half_height),
		lid_center + Vector2(43.0, -lid_half_height + 7.0), lid_center + Vector2(43.0, lid_half_height - 7.0),
		lid_center + Vector2(34.0, lid_half_height), lid_center + Vector2(-34.0, lid_half_height),
		lid_center + Vector2(-43.0, lid_half_height - 7.0), lid_center + Vector2(-43.0, -lid_half_height + 7.0),
	])
	draw_colored_polygon(lid, Color("3d3b38"))
	draw_polyline(lid + PackedVector2Array([lid[0]]), Color("171716"), 4.0, true)
	draw_polyline(lid + PackedVector2Array([lid[0]]), Color("777067"), 1.5, true)
	# Faixa de segurança e corrosão tornam a peça antiga sem perder a identidade original.
	draw_line(lid_center + Vector2(-25.0, lid_half_height * 0.30), lid_center + Vector2(25.0, lid_half_height * 0.30), Color("9b6128"), 5.0, true)
	for x in [-31.0, -10.0, 11.0, 32.0]:
		draw_line(lid_center + Vector2(x - 5.0, lid_half_height * 0.30 + 3.0), lid_center + Vector2(x + 3.0, lid_half_height * 0.30 - 3.0), Color("d28a32"), 2.5, true)
	var rust_offsets: Array[Vector2] = [Vector2(-24, -8), Vector2(18, -5), Vector2(29, 9), Vector2(-9, 12)]
	for rust_offset: Vector2 in rust_offsets:
		draw_circle(lid_center + rust_offset * Vector2(1.0, lerpf(1.0, 0.45, lid_open)), 3.5, Color("70432d"))
	# Puxador central e rebites acompanham a tampa.
	draw_arc(lid_center + Vector2(0.0, -2.0), 10.0, PI, TAU, 12, Color("171716"), 5.0, true)
	draw_arc(lid_center + Vector2(0.0, -2.0), 10.0, PI, TAU, 12, Color("8b8276"), 2.0, true)
	var rivets: Array[Vector2] = [Vector2(-34, -13), Vector2(34, -13), Vector2(-34, 13), Vector2(34, 13)]
	for rivet: Vector2 in rivets:
		var rivet_position: Vector2 = lid_center + rivet * Vector2(1.0, lerpf(1.0, 0.5, lid_open))
		draw_circle(rivet_position, 2.6, Color("151515"))
		draw_circle(rivet_position + Vector2(-0.7, -0.7), 1.2, Color("958d80"))

	# Quatro travas reformadas recebem energia ciano conforme o desbloqueio avança.
	var latch_positions: Array[Vector2] = [Vector2(-45, -24), Vector2(45, -24), Vector2(-45, 24), Vector2(45, 24)]
	for index in latch_positions.size():
		var latch_color := Color("784238")
		if float(index + 1) / float(latch_positions.size()) <= maxf(open_amount, 0.05):
			latch_color = Color(accent.r, accent.g, accent.b, 0.68 + pulse * 0.25)
		draw_rect(Rect2(latch_positions[index] - Vector2(4.0, 2.5), Vector2(8.0, 5.0)), Color("151719"), true)
		draw_line(latch_positions[index] - Vector2(2.5, 0.0), latch_positions[index] + Vector2(2.5, 0.0), latch_color, 2.0, true)
	# Dobradiças permanecem no piso e deixam claro o sentido da abertura.
	for x in [-26.0, 26.0]:
		draw_rect(Rect2(Vector2(x - 8.0, -34.0), Vector2(16.0, 8.0)), Color("1b1c1c"), true)
		draw_line(Vector2(x - 6.0, -30.0), Vector2(x + 6.0, -30.0), Color("8a8175"), 2.0, true)

	if state in [State.READY, State.ENTERING]:
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
		# Letra E vetorial: legível sem depender de fonte ou resolução da interface.
		draw_line(prompt_center + Vector2(-4.0, -7.0), prompt_center + Vector2(-4.0, 7.0), accent, 2.5, true)
		for y in [-7.0, 0.0, 7.0]:
			draw_line(prompt_center + Vector2(-4.0, y), prompt_center + Vector2(5.0, y), accent, 2.5, true)
