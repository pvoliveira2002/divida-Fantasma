extends Area2D

@export var speed := 280.0
@export var lifetime := 3.0
var direction := Vector2.RIGHT
var blue_plasma := false
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
	$Polygon2D.hide()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if blue_plasma:
		plasma_phase += delta * 15.0
		plasma_trail.push_front(global_position)
		if plasma_trail.size() > 9:
			plasma_trail.pop_back()
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
	elif blue_plasma:
		queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("receive_enemy_hit"):
		body.receive_enemy_hit(1)
	queue_free()


func _draw() -> void:
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

