extends Node2D

enum RunState { PLAYING, VICTORY, DEFEAT }

var floor_points := PackedVector2Array([
	Vector2(0, -300),
	Vector2(540, 0),
	Vector2(0, 300),
	Vector2(-540, 0),
])

const FLOOR_COLOR := Color("101a32")
const GRID_COLOR := Color("1b4963")
const BORDER_COLOR := Color("2fffd5")
const FLOOR_TEXTURE := preload("res://assets/environments/arena/cyber_floor_base_v1.png")
const ROOM_VISUAL_ACCENTS := [
	Color("36f2dd"),
	Color("b27aff"),
	Color("52f6b5"),
	Color("ff9b45"),
]
const HIT_SPARK_SCENE := preload("res://scenes/hit_spark.tscn")
const ROOM_SEQUENCE := preload("res://scripts/room_sequence.gd")
const RUN_UPGRADES := preload("res://scripts/run_upgrades.gd")
const COMBAT_PROTOCOLS := preload("res://scripts/combat_protocols.gd")
const GAME_MENU := preload("res://scripts/game_menu.gd")

@onready var player = $Player
@onready var health_label: Label = $Interface/Health
@onready var result_overlay: Control = $Interface/ResultOverlay
@onready var result_title: Label = $Interface/ResultOverlay/ResultTitle
@onready var camera: Camera2D = $Player/Camera2D
@onready var hit_audio: AudioStreamPlayer = $Audio/Hit
@onready var damage_audio: AudioStreamPlayer = $Audio/Damage
@onready var dodge_audio: AudioStreamPlayer = $Audio/Dodge
@onready var result_audio: AudioStreamPlayer = $Audio/Result

var run_state := RunState.PLAYING
var hit_stop_left := 0.0
var frozen_nodes: Dictionary = {}
var shake_left := 0.0
var shake_strength := 0.0
var random := RandomNumberGenerator.new()
var rooms: Node2D
var upgrades: Control
var protocols: Node2D
var menus: CanvasLayer


func _ready() -> void:
	player.died.connect(_on_player_died)
	player.attack_landed.connect(_on_attack_landed)
	player.player_damaged.connect(_on_player_damaged)
	player.dodge_started.connect(_on_dodge_started)
	hit_audio.stream = _make_tone(190.0, 0.055, 0.45)
	damage_audio.stream = _make_tone(95.0, 0.11, 0.30)
	dodge_audio.stream = _make_tone(420.0, 0.075, 0.12)
	result_audio.stream = _make_tone(620.0, 0.22, 0.0)
	_update_health_display()
	rooms = ROOM_SEQUENCE.new()
	rooms.name = "RoomSequence"
	rooms.sequence_completed.connect(func(): _end_run(RunState.VICTORY))
	add_child(rooms)
	upgrades = RUN_UPGRADES.new()
	upgrades.name = "UpgradeChoice"
	upgrades.arena = self
	$Interface.add_child(upgrades)
	upgrades.chosen.connect(rooms.on_upgrade_chosen)
	protocols = COMBAT_PROTOCOLS.new()
	protocols.name = "CombatProtocols"
	add_child(protocols)
	menus = GAME_MENU.new()
	menus.name = "GameMenu"
	menus.in_game = true
	add_child(menus)
	menus.attach_result_buttons(result_overlay)
	if GAME_MENU.start_at_boss:
		GAME_MENU.start_at_boss = false
		rooms.start_boss_test()
	queue_redraw()


func _process(delta: float) -> void:
	_update_hit_stop(delta)
	_update_camera_shake(delta)
	_update_health_display()


func _unhandled_input(event: InputEvent) -> void:
	if run_state == RunState.PLAYING:
		return
	if event is InputEventKey and event.physical_keycode == KEY_R and event.pressed and not event.echo:
		menus.start_run()


func _on_player_died() -> void:
	_end_run(RunState.DEFEAT)


func _on_attack_landed(world_position: Vector2) -> void:
	var spark = HIT_SPARK_SCENE.instantiate()
	add_child(spark)
	spark.global_position = world_position
	hit_audio.play()
	_start_hit_stop(0.045)
	_start_camera_shake(1.5, 0.07)


func _on_player_damaged() -> void:
	damage_audio.play()
	_start_camera_shake(2.4, 0.10)


func _on_dodge_started() -> void:
	dodge_audio.play()


func _end_run(result: RunState) -> void:
	if run_state != RunState.PLAYING:
		return
	run_state = result
	_finish_hit_stop()
	player.controls_enabled = false
	upgrades.hide()
	protocols.clear_room()
	player.reset_combat_pose()
	result_title.text = "MEMÓRIAS RECUPERADAS" if result == RunState.VICTORY else "CONEXÃO INTERROMPIDA"
	result_title.modulate = Color("2fffd5") if result == RunState.VICTORY else Color("ff496c")
	result_overlay.visible = true
	result_audio.pitch_scale = 1.25 if result == RunState.VICTORY else 0.65
	result_audio.play()

	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.set_physics_process(false)
	for projectile in get_tree().get_nodes_in_group("enemy_projectile"):
		projectile.set_physics_process(false)


func _start_hit_stop(duration: float) -> void:
	if hit_stop_left > 0.0:
		return
	hit_stop_left = duration
	frozen_nodes.clear()
	var nodes: Array[Node] = [player]
	nodes.append_array(get_tree().get_nodes_in_group("enemy"))
	nodes.append_array(get_tree().get_nodes_in_group("enemy_projectile"))
	for node in nodes:
		if is_instance_valid(node):
			frozen_nodes[node] = node.is_physics_processing()
			node.set_physics_process(false)


func _update_hit_stop(delta: float) -> void:
	if hit_stop_left <= 0.0:
		return
	hit_stop_left -= delta
	if hit_stop_left <= 0.0:
		_finish_hit_stop()


func _finish_hit_stop() -> void:
	hit_stop_left = 0.0
	for node in frozen_nodes:
		if is_instance_valid(node):
			node.set_physics_process(frozen_nodes[node])
	frozen_nodes.clear()


func _start_camera_shake(strength: float, duration: float) -> void:
	shake_strength = maxf(shake_strength, strength)
	shake_left = maxf(shake_left, duration)


func _update_camera_shake(delta: float) -> void:
	if shake_left <= 0.0:
		camera.offset = Vector2.ZERO
		shake_strength = 0.0
		return
	shake_left -= delta
	camera.offset = Vector2(random.randf_range(-shake_strength, shake_strength), random.randf_range(-shake_strength, shake_strength))


func _make_tone(frequency: float, duration: float, noise_amount: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var sample_count := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	for index in sample_count:
		var envelope := 1.0 - float(index) / float(sample_count)
		var wave := sin(TAU * frequency * float(index) / float(stream.mix_rate))
		var noise := random.randf_range(-1.0, 1.0) * noise_amount
		var sample := clampf((wave * (1.0 - noise_amount) + noise) * envelope, -1.0, 1.0)
		data[index] = int(sample * 127.0 + 128.0)
	stream.data = data
	return stream


func _update_health_display() -> void:
	var filled := "◆".repeat(player.current_health)
	var empty := "◇".repeat(player.max_health - player.current_health)
	health_label.text = "MEMÓRIA  %s%s" % [filled, empty]


func _draw() -> void:
	var floor_color := FLOOR_COLOR
	var room_index := 0
	if is_instance_valid(rooms):
		room_index = clampi(rooms.room_index, 0, ROOM_VISUAL_ACCENTS.size() - 1)
		floor_color = rooms.ROOM_COLORS[rooms.room_index]
	var accent: Color = ROOM_VISUAL_ACCENTS[room_index]
	_draw_platform_depth(accent)
	# A cor inferior preserva a identidade das salas nas pequenas áreas transparentes.
	draw_colored_polygon(floor_points, floor_color)
	draw_texture_rect(FLOOR_TEXTURE, Rect2(-540.0, -300.0, 1080.0, 600.0), false)
	draw_colored_polygon(floor_points, Color(accent.r, accent.g, accent.b, 0.045))
	_draw_room_identity(room_index, accent)
	_draw_boundary_modules(accent)
	# O contorno fino coincide com os quatro SegmentShape2D existentes.
	draw_polyline(floor_points + PackedVector2Array([floor_points[0]]), accent, 2.5, true)


func _draw_platform_depth(accent: Color) -> void:
	# Laterais inferiores dão espessura à plataforma sem invadir a área jogável.
	var side_color := Color("090d17")
	var side_edge := Color(accent.r, accent.g, accent.b, 0.28)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-540.0, 0.0), Vector2(0.0, 300.0), Vector2(0.0, 318.0), Vector2(-540.0, 18.0),
	]), side_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, 300.0), Vector2(540.0, 0.0), Vector2(540.0, 18.0), Vector2(0.0, 318.0),
	]), side_color.lightened(0.035))
	draw_line(Vector2(-540.0, 18.0), Vector2(0.0, 318.0), side_edge, 2.0, true)
	draw_line(Vector2(0.0, 318.0), Vector2(540.0, 18.0), side_edge, 2.0, true)


func _draw_boundary_modules(accent: Color) -> void:
	var modules := [
		[Vector2(-280.0, -145.0), -0.507],
		[Vector2(280.0, -145.0), 0.507],
		[Vector2(-280.0, 145.0), 0.507],
		[Vector2(280.0, 145.0), -0.507],
	]
	for module in modules:
		draw_set_transform(module[0], module[1])
		draw_rect(Rect2(-34.0, -7.0, 68.0, 14.0), Color("111827"), true)
		draw_rect(Rect2(-34.0, -7.0, 68.0, 14.0), Color("5c6878"), false, 2.0)
		draw_line(Vector2(-20.0, 0.0), Vector2(20.0, 0.0), Color(accent.r, accent.g, accent.b, 0.72), 3.0, true)
	draw_set_transform(Vector2.ZERO)


func _draw_room_identity(room_index: int, accent: Color) -> void:
	var line_color := Color(accent.r, accent.g, accent.b, 0.52)
	var soft_color := Color(accent.r, accent.g, accent.b, 0.23)
	match room_index:
		0:
			# Canal de entrada: conduz o olhar da ponta esquerda para o combate.
			for y in [-18.0, 18.0]:
				draw_line(Vector2(-455.0, y), Vector2(-280.0, y), line_color, 2.0, true)
			for x in [-420.0, -370.0, -320.0]:
				draw_polyline(PackedVector2Array([Vector2(x - 12.0, -10.0), Vector2(x, 0.0), Vector2(x - 12.0, 10.0)]), line_color, 2.0, true)
		1:
			# Arquivo: nós de dados nas faixas externas, longe do centro de combate.
			for y in [-172.0, 172.0]:
				draw_line(Vector2(-300.0, y), Vector2(300.0, y), soft_color, 2.0, true)
				for x in [-260.0, -130.0, 0.0, 130.0, 260.0]:
					_draw_floor_diamond(Vector2(x, y), Vector2(15.0, 8.0), line_color)
		2:
			# Núcleo: ramificações simétricas sugerem distribuição de energia.
			var branches := [
				PackedVector2Array([Vector2(-430, -12), Vector2(-340, -62), Vector2(-215, -62)]),
				PackedVector2Array([Vector2(-430, 12), Vector2(-340, 62), Vector2(-215, 62)]),
				PackedVector2Array([Vector2(430, -12), Vector2(340, -62), Vector2(215, -62)]),
				PackedVector2Array([Vector2(430, 12), Vector2(340, 62), Vector2(215, 62)]),
			]
			for branch in branches:
				draw_polyline(branch, line_color, 2.5, true)
				draw_circle(branch[2], 5.0, soft_color)
		3:
			# Confronto final: chevrons industriais persistentes, distintos dos avisos vermelhos.
			for y in [-194.0, 194.0]:
				for x in [-240.0, -120.0, 0.0, 120.0, 240.0]:
					var direction := 1.0 if y < 0.0 else -1.0
					draw_polyline(PackedVector2Array([Vector2(x - 20.0, y), Vector2(x, y + 10.0 * direction), Vector2(x + 20.0, y)]), line_color, 3.0, true)
			for x in [-365.0, 365.0]:
				draw_line(Vector2(x, -55.0), Vector2(x, 55.0), soft_color, 5.0, true)


func _draw_floor_diamond(center: Vector2, radius: Vector2, color: Color) -> void:
	draw_polyline(PackedVector2Array([
		center + Vector2(0.0, -radius.y),
		center + Vector2(radius.x, 0.0),
		center + Vector2(0.0, radius.y),
		center + Vector2(-radius.x, 0.0),
		center + Vector2(0.0, -radius.y),
	]), color, 2.0, true)


func _draw_isometric_grid() -> void:
	for offset in range(-450, 451, 90):
		var start_a := Vector2(offset - 270, 150)
		var end_a := Vector2(offset + 270, -150)
		var start_b := Vector2(offset - 270, -150)
		var end_b := Vector2(offset + 270, 150)
		draw_line(start_a, end_a, GRID_COLOR, 1.0, true)
		draw_line(start_b, end_b, GRID_COLOR, 1.0, true)
