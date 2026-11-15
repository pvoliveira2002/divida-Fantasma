extends Area2D

const HIT_SPARK_SCENE := preload("res://scenes/hit_spark.tscn")
const SNIPER_SPEED := 380.0

@export var speed := 280.0
@export var lifetime := 3.0
var direction := Vector2.RIGHT
var blue_plasma := false
var sniper_bolt := false
var plasma_phase := 0.0
var plasma_trail: Array[Vector2] = []


func _ready() -> void:
	add_to_group("enemy_projectile")
	body_entered.connect(_on_body_entered)


func setup(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	rotation = direction.angle()


func enable_blue_plasma() -> void:
	blue_plasma = true
	sniper_bolt = false
	$Polygon2D.hide()
	queue_redraw()


func enable_sniper_bolt() -> void:
	sniper_bolt = true
	blue_plasma = false
	speed = SNIPER_SPEED
	lifetime = 2.2
	$Polygon2D.hide()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if blue_plasma or sniper_bolt:
		plasma_phase += delta * 15.0
		plasma_trail.push_front(global_position)
		var trail_limit := 12 if sniper_bolt else 9
		if plasma_trail.size() > trail_limit:
			plasma_trail.pop_back()
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
	elif blue_plasma or sniper_bolt:
		queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("receive_enemy_hit"):
		body.receive_enemy_hit(1)
	if sniper_bolt:
		_spawn_sniper_impact()
	queue_free()


func _draw() -> void:
	if sniper_bolt:
		_draw_sniper_bolt()
		return
	if not blue_plasma:
		return
	for index in range(plasma_trail.size() - 1, 0, -1):
		var alpha := (1.0 - float(index) / float(plasma_trail.size())) * 0.55
		var from := to_local(plasma_trail[index])
		var to := to_local(plasma_trail[index - 1])
		draw_line(from, to, Color(0.10, 0.38, 1.0, alpha), 9.0 * alpha + 2.0, true)
		draw_line(from, to, Color(0.45, 0.84, 1.0, alpha), 3.0, true)
	var pulse := 0.5 + sin(plasma_phase) * 0.5
	draw_circle(Vector2.ZERO, 14.0 + pulse * 2.0, Color(0.08, 0.30, 1.0, 0.20))
	draw_circle(Vector2.ZERO, 10.0 + pulse, Color("3388ff"))
	draw_circle(Vector2.ZERO, 5.0 + pulse, Color("d2f4ff"))
	for index in 4:
		var angle := plasma_phase * (0.65 if index % 2 == 0 else -0.52) + float(index) * TAU / 4.0
		var orbit := Vector2.RIGHT.rotated(angle) * (14.0 + float(index % 2) * 3.0)
		draw_circle(orbit, 2.0, Color(0.42, 0.83, 1.0, 0.85))


func _draw_sniper_bolt() -> void:
	for index in range(plasma_trail.size() - 1, 0, -1):
		var from_point := to_local(plasma_trail[index])
		var to_point := to_local(plasma_trail[index - 1])
		var strength := 1.0 - float(index) / float(max(plasma_trail.size(), 1))
		draw_line(from_point, to_point, Color(1.0, 0.12, 0.58, strength * 0.52), 6.0 * strength + 1.0, true)
		draw_line(from_point, to_point, Color(0.35, 0.95, 1.0, strength * 0.72), 2.0, true)
	var pulse := sin(plasma_phase)
	var dart := PackedVector2Array([
		Vector2(-18.0, -5.0), Vector2(12.0, -3.5), Vector2(22.0, 0.0),
		Vector2(12.0, 3.5), Vector2(-18.0, 5.0), Vector2(-18.0, -5.0)
	])
	draw_colored_polygon(dart, Color(1.0, 0.08, 0.48, 0.9))
	draw_polyline(dart, Color(1.0, 0.72, 0.9, 1.0), 1.5, true)
	draw_line(Vector2(-14.0, 0.0), Vector2(16.0, 0.0), Color(0.7, 1.0, 1.0, 1.0), 3.0 + pulse)
	draw_circle(Vector2(13.0, 0.0), 3.0 + pulse * 0.35, Color(0.9, 1.0, 1.0, 1.0))


func _spawn_sniper_impact() -> void:
	var spark := HIT_SPARK_SCENE.instantiate()
	spark.duration = 0.22
	spark.ray_color = Color(1.0, 0.12, 0.58, 1.0)
	spark.core_color = Color(0.55, 1.0, 1.0, 1.0)
	get_parent().add_child(spark)
	spark.global_position = global_position

