extends Node2D

const ATTRACT_RADIUS := 135.0
const COLLECT_RADIUS := 22.0
const ATTRACT_SPEED := 285.0
const DROP_DURATION := 0.38
const LIFETIME := 12.0

var target: CharacterBody2D
var age := 0.0
var scatter_velocity := Vector2.ZERO
var collected := false


func setup(player: CharacterBody2D, scatter_angle: float) -> void:
	target = player
	scatter_velocity = Vector2.RIGHT.rotated(scatter_angle) * 68.0


func _ready() -> void:
	add_to_group("memory_fragment")
	z_index = 4
	queue_redraw()


func _process(delta: float) -> void:
	if collected:
		return
	age += delta
	if age < DROP_DURATION:
		position += scatter_velocity * delta
		scatter_velocity = scatter_velocity.move_toward(Vector2.ZERO, 150.0 * delta)
	elif is_instance_valid(target):
		var distance := global_position.distance_to(target.global_position)
		if distance <= COLLECT_RADIUS:
			collect()
			return
		if distance <= ATTRACT_RADIUS:
			global_position = global_position.move_toward(target.global_position, ATTRACT_SPEED * delta)
	if age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func collect() -> void:
	if collected:
		return
	collected = true
	var arena = get_parent()
	if arena.has_method("collect_memory_fragment"):
		arena.collect_memory_fragment(self)
	queue_free()


func _draw() -> void:
	var drop_progress := clampf(age / DROP_DURATION, 0.0, 1.0)
	var vertical_offset := -sin(drop_progress * PI) * 22.0
	if age >= DROP_DURATION:
		vertical_offset = -8.0 + sin(age * 4.2) * 3.0
	var blink := 1.0
	if age > LIFETIME - 3.0:
		blink = 0.35 if int(age * 9.0) % 2 == 0 else 1.0
	var pulse := 0.5 + sin(age * 5.5) * 0.5
	draw_set_transform(Vector2(0.0, 1.0), 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, 10.0 - vertical_offset * 0.04, Color(0.0, 0.0, 0.0, 0.30 * blink))
	draw_set_transform(Vector2.ZERO)
	var center := Vector2(0.0, vertical_offset)
	draw_circle(center, 13.0 + pulse * 3.0, Color(0.12, 0.95, 1.0, (0.08 + pulse * 0.08) * blink))
	var shard := PackedVector2Array([
		center + Vector2(0.0, -10.0), center + Vector2(7.0, -2.0),
		center + Vector2(3.0, 9.0), center + Vector2(-6.0, 4.0),
		center + Vector2(0.0, -10.0),
	])
	draw_colored_polygon(shard, Color(0.10, 0.78, 0.92, 0.95 * blink))
	draw_polyline(shard, Color(0.72, 1.0, 1.0, blink), 1.5, true)
	draw_line(center + Vector2(-1.0, -6.0), center + Vector2(2.0, 5.0), Color(0.90, 1.0, 1.0, 0.9 * blink), 2.0, true)
