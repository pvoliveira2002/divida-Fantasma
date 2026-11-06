extends CharacterBody2D

signal defeated
signal reinforcement_requested(stage: int)
enum State { APPROACH, WINDUP, DASHING, RECOVERY, DEAD }
enum Attack { VOLLEY, DASH, SLAM }

const PROJECTILE := preload("res://scenes/enemy_projectile.tscn")
@export var max_health := 36
@export var move_speed := 120.0
@export var windup_duration := 0.75
@export var recovery_duration := 0.85
@export var slam_radius := 130.0
@export var dash_speed := 780.0
@export var dash_duration := 0.36
@export var projectile_speed := 240.0

var health: int
var state := State.APPROACH
var attack := Attack.VOLLEY
var next_attack := Attack.VOLLEY
var state_time := 1.0
var locked_direction := Vector2.LEFT
var attack_origin := Vector2.ZERO
var dash_has_hit := false
var enraged := false
var flash_left := 0.0
var impact_left := 0.0
var target: CharacterBody2D
var reinforcement_stage := 0


func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	target = get_parent().get_node("Player") as CharacterBody2D


func _physics_process(delta: float) -> void:
	if state == State.DEAD or not is_instance_valid(target) or target.is_dead:
		return
	flash_left = maxf(0.0, flash_left - delta)
	impact_left = maxf(0.0, impact_left - delta)
	state_time -= delta
	match state:
		State.APPROACH:
			var offset := target.global_position - global_position
			if offset.length() > 95.0:
				velocity = offset.normalized() * move_speed * (1.15 if enraged else 1.0)
				move_and_slide()
			else:
				velocity = Vector2.ZERO
			if state_time <= 0.0:
				start_attack(next_attack)
				next_attack = (next_attack + 1) % 3
		State.WINDUP:
			if state_time <= 0.0:
				_execute_attack()
		State.DASHING:
			var previous := global_position
			velocity = locked_direction * dash_speed
			move_and_slide()
			# Swept distance prevents the charge from skipping the player at low FPS.
			var nearest := Geometry2D.get_closest_point_to_segment(target.global_position, previous, global_position)
			if not dash_has_hit and nearest.distance_to(target.global_position) <= 48.0:
				dash_has_hit = true
				target.receive_enemy_hit(1)
			if state_time <= 0.0 or get_slide_collision_count() > 0:
				_enter_recovery()
		State.RECOVERY:
			if state_time <= 0.0:
				state = State.APPROACH
				state_time = 0.45
	queue_redraw()


func start_attack(kind: int) -> bool:
	if state != State.APPROACH or not is_instance_valid(target) or target.is_dead:
		return false
	attack = kind as Attack
	state = State.WINDUP
	state_time = windup_duration
	velocity = Vector2.ZERO
	locked_direction = (target.global_position - global_position).normalized()
	if locked_direction.is_zero_approx():
		locked_direction = Vector2.LEFT
	attack_origin = global_position
	dash_has_hit = false
	queue_redraw()
	return true


func _execute_attack() -> void:
	match attack:
		Attack.VOLLEY:
			for angle in [-0.30, 0.0, 0.30]:
				var direction := locked_direction.rotated(angle)
				var projectile = PROJECTILE.instantiate()
				projectile.speed = projectile_speed
				projectile.lifetime = 2.6
				get_parent().add_child(projectile)
				projectile.global_position = global_position + direction * 48.0
				projectile.setup(direction)
			_enter_recovery()
		Attack.DASH:
			state = State.DASHING
			state_time = dash_duration
		Attack.SLAM:
			impact_left = 0.22
			if target.global_position.distance_to(attack_origin) <= slam_radius:
				target.receive_enemy_hit(1)
			_enter_recovery()


func _enter_recovery() -> void:
	state = State.RECOVERY
	state_time = recovery_duration * (0.65 if enraged else 1.0)
	velocity = Vector2.ZERO


func take_damage(amount: int, _hit_direction := Vector2.ZERO) -> bool:
	if state == State.DEAD:
		return false
	health = maxi(0, health - amount)
	flash_left = 0.10
	if health > 0 and reinforcement_stage == 0 and health * 3 <= max_health * 2:
		reinforcement_stage = 1
		reinforcement_requested.emit(reinforcement_stage)
	elif health > 0 and reinforcement_stage == 1 and health * 3 <= max_health:
		reinforcement_stage = 2
		reinforcement_requested.emit(reinforcement_stage)
	# The second phase changes pacing only; warning time and damage stay readable.
	enraged = health > 0 and health * 2 < max_health
	if health == 0:
		state = State.DEAD
		velocity = Vector2.ZERO
		defeated.emit()
		queue_free()
	queue_redraw()
	return true


func _draw() -> void:
	var danger := Color("ff496c")
	if state == State.WINDUP:
		var progress := 1.0 - clampf(state_time / windup_duration, 0.0, 1.0)
		match attack:
			Attack.SLAM:
				draw_circle(Vector2.ZERO, slam_radius, Color(danger, 0.12))
				draw_arc(Vector2.ZERO, slam_radius, 0, TAU, 64, danger, 3, true)
				draw_arc(Vector2.ZERO, slam_radius * progress, 0, TAU, 48, Color(danger, 0.6), 2, true)
			Attack.DASH:
				var end := locked_direction * dash_speed * dash_duration
				var side := locked_direction.orthogonal() * 32
				draw_colored_polygon(PackedVector2Array([-side, side, end + side, end - side]), Color(danger, 0.16))
				draw_line(side, end + side, danger, 2, true)
				draw_line(-side, end - side, danger, 2, true)
				draw_line(Vector2.ZERO, end, danger, 3, true)
			Attack.VOLLEY:
				for angle in [-0.30, 0.0, 0.30]:
					draw_line(Vector2.ZERO, locked_direction.rotated(angle) * 420.0, Color(danger, 0.65), 2, true)
	if impact_left > 0:
		draw_arc(to_local(attack_origin), slam_radius, 0, TAU, 64, Color(danger, impact_left / 0.22), 7, true)
	var armor := Color("ff804e") if enraged else Color("9f90ef")
	if flash_left > 0:
		armor = Color.WHITE
	draw_set_transform(Vector2(0, 12), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 45, Color(0, 0, 0, 0.5))
	draw_set_transform(Vector2.ZERO)
	var body := PackedVector2Array([Vector2(0,-55), Vector2(32,-38), Vector2(38,8), Vector2(20,28), Vector2(-20,28), Vector2(-38,8), Vector2(-32,-38)])
	draw_colored_polygon(body, Color("15162b"))
	draw_polyline(body + PackedVector2Array([body[0]]), armor, 4, true)
	for side in [-1, 1]:
		draw_rect(Rect2(Vector2(side * 40 - 10, -24), Vector2(20, 38)), Color("25233b"))
		draw_rect(Rect2(Vector2(side * 40 - 10, -24), Vector2(20, 38)), armor, false, 3)
	draw_rect(Rect2(-17, -37, 34, 7), danger)
	draw_circle(Vector2(0, -9), 11, armor)
	draw_line(Vector2(-13, 13), Vector2(13, 13), armor, 3)
	if state == State.RECOVERY:
		draw_arc(Vector2.ZERO, 48, 0, TAU, 40, Color("49f4ff"), 2, true)
