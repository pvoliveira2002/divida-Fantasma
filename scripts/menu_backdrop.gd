extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("070d19"))
	var center := size * Vector2(0.77, 0.52)
	for index in 8:
		var radius := 55.0 + index * 33.0
		var points := PackedVector2Array([center + Vector2(0,-radius * 0.55), center + Vector2(radius,0), center + Vector2(0,radius * 0.55), center + Vector2(-radius,0), center + Vector2(0,-radius * 0.55)])
		draw_polyline(points, Color(0.15, 0.85, 0.8, 0.26 - index * 0.025), 2.0, true)
	for index in 7:
		var y := size.y * 0.15 + index * 74.0
		draw_polyline(PackedVector2Array([Vector2(size.x * 0.60,y), Vector2(size.x * 0.69,y), Vector2(size.x * 0.75,y+28), Vector2(size.x,y+28)]), Color(0.4,0.3,0.7,0.16), 2, true)
		draw_circle(Vector2(size.x * 0.60,y), 3, Color("345469"))
