extends CharacterBody2D

enum State { CHASE, WINDUP, RECOVERY, DEAD }

@export var max_health := 3
@export var move_speed := 115.0
@export var attack_range := 72.0
@export var windup_duration := 0.55
@export var recovery_duration := 0.65

var health: int
var state := State.CHASE
var state_time := 0.0
var target: CharacterBody2D
var flash_left := 0.0
var knockback_velocity := Vector2.ZERO
@export var knockback_strength := 230.0
@export var knockback_deceleration := 1400.0


func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	target = get_tree().get_first_node_in_group("player") as CharacterBody2D


func _physics_process(delta: float) -> void:
	flash_left = maxf(flash_left - delta, 0.0)
	if not is_instance_valid(target) or state == State.DEAD:
		return
	if knockback_velocity.length_squared() > 4.0:
		velocity = knockback_velocity
		move_and_slide()
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_deceleration * delta)
		queue_redraw()
		return

	var to_target := target.global_position - global_position
	match state:
		State.CHASE:
			if to_target.length() <= attack_range:
				start_windup()
			else:
				velocity = to_target.normalized() * move_speed
				move_and_slide()
		State.WINDUP:
			velocity = Vector2.ZERO
			state_time -= delta
			if state_time <= 0.0:
				if to_target.length() <= attack_range + 18.0:
					target.receive_enemy_hit(1)
				state = State.RECOVERY
				state_time = recovery_duration
		State.RECOVERY:
			state_time -= delta
			if state_time <= 0.0:
				state = State.CHASE
	queue_redraw()


func start_windup() -> void:
	if state != State.CHASE:
		return
	state = State.WINDUP
	state_time = windup_duration
	queue_redraw()


func is_telegraphing() -> bool:
	return state == State.WINDUP


func take_damage(amount: int, hit_direction := Vector2.ZERO) -> bool:
	if state == State.DEAD:
		return false
	health = maxi(health - amount, 0)
	knockback_velocity = hit_direction.normalized() * knockback_strength
	flash_left = 0.12
	if health == 0:
		state = State.DEAD
		queue_free()
	queue_redraw()
	return true


func _draw() -> void:
	var color := Color("ffffff") if flash_left > 0.0 else Color("ff9f43")
	draw_circle(Vector2.ZERO, 25.0, Color("180d12"))
	draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 32, color, 5.0, true)
	draw_line(Vector2(-14, -10), Vector2(14, 10), color, 5.0, true)
	if state == State.WINDUP:
		draw_circle(Vector2.ZERO, attack_range, Color(1.0, 0.2, 0.15, 0.12))
		draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 40, Color("ff493d"), 4.0, true)

