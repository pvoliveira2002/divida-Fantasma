extends CharacterBody2D

enum State { POSITIONING, WINDUP, RECOVERY, DEAD }

@export var projectile_scene: PackedScene
@export var max_health := 3
@export var move_speed := 90.0
@export var preferred_distance := 260.0
@export var distance_tolerance := 45.0
@export var windup_duration := 0.75
@export var recovery_duration := 1.0

var health: int
var state := State.POSITIONING
var state_time := 0.0
var target: CharacterBody2D
var locked_direction := Vector2.LEFT
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
	var distance := to_target.length()
	match state:
		State.POSITIONING:
			if distance < preferred_distance - distance_tolerance:
				velocity = -to_target.normalized() * move_speed
				move_and_slide()
			elif distance > preferred_distance + distance_tolerance:
				velocity = to_target.normalized() * move_speed
				move_and_slide()
			else:
				start_windup()
		State.WINDUP:
			velocity = Vector2.ZERO
			state_time -= delta
			if state_time <= 0.0:
				_fire()
				state = State.RECOVERY
				state_time = recovery_duration
		State.RECOVERY:
			state_time -= delta
			if state_time <= 0.0:
				state = State.POSITIONING
	queue_redraw()


func start_windup() -> void:
	if state != State.POSITIONING or not is_instance_valid(target):
		return
	state = State.WINDUP
	state_time = windup_duration
	locked_direction = (target.global_position - global_position).normalized()
	queue_redraw()


func is_telegraphing() -> bool:
	return state == State.WINDUP


func _fire() -> void:
	if projectile_scene == null:
		return
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + locked_direction * 35.0
	projectile.setup(locked_direction)


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
	var color := Color("ffffff") if flash_left > 0.0 else Color("a970ff")
	draw_circle(Vector2.ZERO, 24.0, Color("110b20"))
	draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 6, color, 5.0, true)
	draw_circle(Vector2.ZERO, 7.0, color)
	if state == State.WINDUP:
		draw_line(Vector2.ZERO, locked_direction * 360.0, Color(1.0, 0.25, 0.45, 0.65), 4.0, true)
		draw_circle(Vector2.ZERO, 33.0, Color(1.0, 0.2, 0.5, 0.12))
