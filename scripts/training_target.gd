extends Area2D

@export var max_health: int = 3
@export var reset_delay: float = 0.8

var current_health: int
var hit_count: int = 0
var is_resetting := false
var flash_time := 0.0


func _ready() -> void:
	current_health = max_health
	queue_redraw()


func _process(delta: float) -> void:
	if flash_time > 0.0:
		flash_time = maxf(flash_time - delta, 0.0)
		queue_redraw()


func take_damage(amount: int, _hit_direction := Vector2.ZERO) -> bool:
	if is_resetting:
		return false

	hit_count += 1
	current_health = maxi(current_health - amount, 0)
	flash_time = 0.12
	queue_redraw()

	if current_health == 0:
		_reset_after_delay()
	return true


func _reset_after_delay() -> void:
	is_resetting = true
	monitorable = false
	visible = false
	await get_tree().create_timer(reset_delay).timeout
	current_health = max_health
	is_resetting = false
	monitorable = true
	visible = true
	queue_redraw()


func _draw() -> void:
	var target_color := Color("fff4b0") if flash_time > 0.0 else Color("38d6ff")
	draw_circle(Vector2.ZERO, 29.0, Color("08101f"))
	draw_arc(Vector2.ZERO, 29.0, 0.0, TAU, 40, target_color, 4.0, true)
	draw_line(Vector2(-18, 0), Vector2(18, 0), target_color, 3.0, true)
	draw_line(Vector2(0, -18), Vector2(0, 18), target_color, 3.0, true)

	for index in max_health:
		var pip_color := Color("ff3f81") if index < current_health else Color("30384c")
		draw_rect(Rect2(-24.0 + index * 18.0, -43.0, 13.0, 6.0), pip_color, true)

