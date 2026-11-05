extends Node2D

@export var duration := 0.18
var time_left := 0.0


func _ready() -> void:
	time_left = duration
	queue_redraw()


func _process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := 1.0 - time_left / duration
	var alpha := 1.0 - progress
	for index in 8:
		var direction := Vector2.RIGHT.rotated(index * TAU / 8.0 + 0.18)
		var start := direction * (8.0 + progress * 14.0)
		var finish := direction * (22.0 + progress * 30.0)
		draw_line(start, finish, Color(1.0, 0.85, 0.25, alpha), 4.0 * alpha + 1.0, true)
	draw_circle(Vector2.ZERO, 10.0 * alpha, Color(1.0, 1.0, 0.75, alpha))

