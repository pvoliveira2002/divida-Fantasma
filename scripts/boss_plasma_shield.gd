extends Node2D

@onready var boss: CharacterBody2D = get_parent() as CharacterBody2D


func _process(_delta: float) -> void:
	visible = boss.state == boss.State.DASHING
	if visible:
		queue_redraw()


func _draw() -> void:
	if boss.state != boss.State.DASHING:
		return
	var phase: float = float(boss.dash_plasma_phase)
	var shield_center: Vector2 = Vector2(0.0, -55.0) + Vector2(boss.locked_direction) * 38.0
	var shield_pulse: float = 0.5 + sin(phase) * 0.5
	var shield_radius: float = 70.0 + shield_pulse * 6.0
	draw_set_transform(shield_center, 0.0, Vector2(0.58, 1.0))
	draw_circle(Vector2.ZERO, shield_radius, Color(0.08, 0.38, 1.0, 0.14 + shield_pulse * 0.07))
	draw_arc(Vector2.ZERO, shield_radius, 0.0, TAU, 40, Color(0.30, 0.78, 1.0, 0.90), 5.5, true)
	draw_arc(Vector2.ZERO, shield_radius - 10.0, phase * 0.12, phase * 0.12 + 4.7, 32, Color(0.68, 0.94, 1.0, 0.70), 2.5, true)
	for index in 5:
		var spark_angle: float = phase * 0.35 + float(index) * TAU / 5.0
		var spark_position := Vector2.RIGHT.rotated(spark_angle) * shield_radius
		draw_circle(spark_position, 2.5, Color("b9efff"))
	draw_set_transform(Vector2.ZERO)
