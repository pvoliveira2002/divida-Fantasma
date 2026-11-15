extends Node2D

const EDGE_LIGHTS := [
	Vector2(-365.0, -168.0), Vector2(365.0, -168.0),
	Vector2(-365.0, 168.0), Vector2(365.0, 168.0),
]
const AMBIENT_MOTES := [
	[Vector2(-438.0, -54.0), 0.3], [Vector2(-386.0, 92.0), 1.7],
	[Vector2(-284.0, -164.0), 2.6], [Vector2(-176.0, 206.0), 4.2],
	[Vector2(178.0, -205.0), 5.1], [Vector2(286.0, 162.0), 0.9],
	[Vector2(388.0, -90.0), 3.4], [Vector2(438.0, 56.0), 5.8],
]
const ROOM_HUM_FREQUENCIES := [48.0, 54.0, 60.0, 42.0]
const AMBIENT_VOLUME_DB := -32.0
const SILENT_VOLUME_DB := -60.0
const AUDIO_FADE_SPEED := 22.0

var room_index := -1
var accent := Color("36f2dd")
var ambient_time := 0.0
var redraw_accumulator := 0.0
var audio_players: Array[AudioStreamPlayer] = []
var active_audio_index := -1


func _ready() -> void:
	z_index = 2
	_create_audio_players()
	_update_room_identity()
	queue_redraw()


func _exit_tree() -> void:
	for player in audio_players:
		player.stop()
		player.stream = null


func _process(delta: float) -> void:
	ambient_time += delta
	redraw_accumulator += delta
	_update_room_identity()
	_update_ambient_audio(delta)
	# Trinta atualizacoes por segundo mantem o efeito suave sem redesenhar a arena inteira.
	if redraw_accumulator >= 1.0 / 30.0:
		redraw_accumulator = 0.0
		queue_redraw()


func _update_room_identity() -> void:
	var arena = get_parent()
	if not is_instance_valid(arena.rooms):
		return
	var next_room: int = clampi(arena.rooms.room_index, 0, arena.ROOM_VISUAL_ACCENTS.size() - 1)
	if next_room == room_index:
		return
	room_index = next_room
	accent = arena.ROOM_VISUAL_ACCENTS[room_index]
	_transition_room_audio(room_index)
	queue_redraw()


func _create_audio_players() -> void:
	for index in 2:
		var player := AudioStreamPlayer.new()
		player.name = "AmbientHum%d" % (index + 1)
		player.volume_db = SILENT_VOLUME_DB
		add_child(player)
		audio_players.append(player)


func _transition_room_audio(next_room: int) -> void:
	if audio_players.is_empty():
		return
	active_audio_index = 0 if active_audio_index != 0 else 1
	var next_player := audio_players[active_audio_index]
	next_player.stop()
	next_player.stream = _make_ambient_loop(next_room)
	next_player.volume_db = SILENT_VOLUME_DB
	next_player.play()


func _update_ambient_audio(delta: float) -> void:
	var arena = get_parent()
	var should_play: bool = is_instance_valid(arena) and arena.run_state == arena.RunState.PLAYING
	for index in audio_players.size():
		var player := audio_players[index]
		var target_volume := AMBIENT_VOLUME_DB if should_play and index == active_audio_index else SILENT_VOLUME_DB
		player.volume_db = move_toward(player.volume_db, target_volume, AUDIO_FADE_SPEED * delta)
		if index != active_audio_index and player.volume_db <= SILENT_VOLUME_DB + 0.1 and player.playing:
			player.stop()


func _make_ambient_loop(for_room: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 11025
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	var sample_count := stream.mix_rate * 2
	stream.loop_begin = 0
	stream.loop_end = sample_count
	var data := PackedByteArray()
	data.resize(sample_count)
	var frequency: float = ROOM_HUM_FREQUENCIES[clampi(for_room, 0, ROOM_HUM_FREQUENCIES.size() - 1)]
	var modulation_frequency := 2.0 + float(for_room)
	for sample_index in sample_count:
		var time := float(sample_index) / float(stream.mix_rate)
		var low_hum := sin(TAU * frequency * time) * 0.42
		var machinery := sin(TAU * frequency * 2.0 * time + 0.35) * 0.22
		var electric_texture := sin(TAU * frequency * 3.0 * time + sin(TAU * modulation_frequency * time) * 0.35) * 0.09
		var gate := 0.82 + sin(TAU * modulation_frequency * time) * 0.08
		var sample := clampf((low_hum + machinery + electric_texture) * gate * 0.48, -1.0, 1.0)
		data[sample_index] = int(sample * 127.0 + 128.0)
	stream.data = data
	return stream


func _draw() -> void:
	_draw_edge_glows()
	_draw_energy_sweeps()
	_draw_motes()


func _draw_edge_glows() -> void:
	for index in EDGE_LIGHTS.size():
		var pulse := 0.5 + sin(ambient_time * 1.55 + float(index) * 1.8) * 0.5
		var position: Vector2 = EDGE_LIGHTS[index]
		for layer in range(4, 0, -1):
			var radius := 9.0 + float(layer) * 7.0
			var alpha := (0.008 + pulse * 0.007) * float(5 - layer)
			draw_circle(position, radius, Color(accent.r, accent.g, accent.b, alpha))
		draw_circle(position, 2.2 + pulse * 1.2, Color(accent.r, accent.g, accent.b, 0.62 + pulse * 0.20))


func _draw_energy_sweeps() -> void:
	var travel := fmod(ambient_time * 92.0, 760.0)
	var upper_start := Vector2(-380.0 + travel, -192.0)
	var lower_start := Vector2(380.0 - travel, 192.0)
	for sweep_start in [upper_start, lower_start]:
		if absf(sweep_start.x) > 380.0:
			continue
		draw_line(sweep_start - Vector2(32.0, 0.0), sweep_start, Color(accent.r, accent.g, accent.b, 0.05), 7.0, true)
		draw_line(sweep_start - Vector2(18.0, 0.0), sweep_start, Color(accent.r, accent.g, accent.b, 0.34), 2.0, true)


func _draw_motes() -> void:
	for mote in AMBIENT_MOTES:
		var base_position: Vector2 = mote[0]
		var phase: float = mote[1]
		var drift := Vector2(sin(ambient_time * 0.7 + phase) * 5.0, -fmod(ambient_time * 5.0 + phase * 9.0, 18.0))
		var visibility := 0.5 + sin(ambient_time * 1.3 + phase) * 0.5
		var mote_position := base_position + drift
		draw_circle(mote_position, 1.2 + visibility, Color(accent.r, accent.g, accent.b, 0.14 + visibility * 0.34))
		draw_line(mote_position + Vector2(0.0, 3.0), mote_position + Vector2(0.0, 8.0), Color(accent.r, accent.g, accent.b, visibility * 0.12), 1.0, true)
