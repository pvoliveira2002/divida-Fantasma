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
const HIT_SPARK_SCENE := preload("res://scenes/hit_spark.tscn")

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
var enemies_were_present := false
var hit_stop_left := 0.0
var frozen_nodes: Dictionary = {}
var shake_left := 0.0
var shake_strength := 0.0
var random := RandomNumberGenerator.new()


func _ready() -> void:
	player.died.connect(_on_player_died)
	player.attack_landed.connect(_on_attack_landed)
	player.player_damaged.connect(_on_player_damaged)
	player.dodge_started.connect(_on_dodge_started)
	hit_audio.stream = _make_tone(190.0, 0.055, 0.45)
	damage_audio.stream = _make_tone(95.0, 0.11, 0.30)
	dodge_audio.stream = _make_tone(420.0, 0.075, 0.12)
	result_audio.stream = _make_tone(620.0, 0.22, 0.0)
	enemies_were_present = not get_tree().get_nodes_in_group("enemy").is_empty()
	_update_health_display()
	queue_redraw()


func _process(delta: float) -> void:
	_update_hit_stop(delta)
	_update_camera_shake(delta)
	_update_health_display()
	if run_state == RunState.PLAYING and enemies_were_present and get_tree().get_nodes_in_group("enemy").is_empty():
		_end_run(RunState.VICTORY)


func _unhandled_input(event: InputEvent) -> void:
	if run_state == RunState.PLAYING:
		return
	if event is InputEventKey and event.physical_keycode == KEY_R and event.pressed and not event.echo:
		get_tree().reload_current_scene()


func _on_player_died() -> void:
	_end_run(RunState.DEFEAT)


func _on_attack_landed(world_position: Vector2) -> void:
	var spark = HIT_SPARK_SCENE.instantiate()
	add_child(spark)
	spark.global_position = world_position
	hit_audio.play()
	_start_hit_stop(0.045)
	_start_camera_shake(5.0, 0.10)


func _on_player_damaged() -> void:
	damage_audio.play()
	_start_camera_shake(8.0, 0.16)


func _on_dodge_started() -> void:
	dodge_audio.play()


func _end_run(result: RunState) -> void:
	if run_state != RunState.PLAYING:
		return
	run_state = result
	_finish_hit_stop()
	player.controls_enabled = false
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
	draw_colored_polygon(floor_points, FLOOR_COLOR)
	_draw_isometric_grid()
	draw_polyline(floor_points + PackedVector2Array([floor_points[0]]), BORDER_COLOR, 5.0, true)


func _draw_isometric_grid() -> void:
	for offset in range(-450, 451, 90):
		var start_a := Vector2(offset - 270, 150)
		var end_a := Vector2(offset + 270, -150)
		var start_b := Vector2(offset - 270, -150)
		var end_b := Vector2(offset + 270, 150)
		draw_line(start_a, end_a, GRID_COLOR, 1.0, true)
		draw_line(start_b, end_b, GRID_COLOR, 1.0, true)
