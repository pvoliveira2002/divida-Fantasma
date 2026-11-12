extends CharacterBody2D

signal defeated
signal reinforcement_requested(stage: int)
enum State { APPROACH, WINDUP, DASHING, RECOVERY, DEAD }
enum Attack { VOLLEY, DASH, SLAM }

const PROJECTILE := preload("res://scenes/enemy_projectile.tscn")
const ATTACK_PARTICLES := preload("res://scenes/boss_attack_particles.tscn")
@export var max_health := 36
@export var move_speed := 120.0
@export var windup_duration := 0.75
@export var recovery_duration := 0.85
@export var slam_radius := 130.0
@export var dash_speed := 780.0
@export var dash_duration := 0.36
@export var projectile_speed := 270.0

@export_category("Visual")
@export var base_texture: Texture2D
@export var idle_texture: Texture2D
@export var walk_texture: Texture2D
@export var dash_texture: Texture2D
@export var slam_texture: Texture2D
@export var volley_texture: Texture2D
@export var idle_animation_fps := 2.4
@export var walk_animation_fps := 5.5
@export var base_sheet_scale := Vector2(0.23, 0.23)
@export var animation_sheet_scale := Vector2(0.46, 0.46)
@export var attack_contact_pose_duration := 0.18

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
var facing_direction := Vector2.LEFT
var visual_animation_time := 0.0
var visual_animation_frame := 0
var dash_particle_time := 0.0
var dash_plasma_phase := 0.0
@onready var character_visual: Sprite2D = $CharacterVisual


func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	target = get_parent().get_node("Player") as CharacterBody2D
	_update_character_visual(0.0)


func _physics_process(delta: float) -> void:
	if state == State.DEAD or not is_instance_valid(target) or target.is_dead:
		return
	flash_left = maxf(0.0, flash_left - delta)
	impact_left = maxf(0.0, impact_left - delta)
	state_time -= delta
	match state:
		State.APPROACH:
			var offset := target.global_position - global_position
			if offset.length_squared() > 0.001:
				facing_direction = offset.normalized()
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
			dash_plasma_phase += delta * 12.0
			dash_particle_time -= delta
			if dash_particle_time <= 0.0:
				dash_particle_time = 0.075
				_spawn_attack_particles(0, global_position - locked_direction * 28.0, locked_direction)
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
	_update_character_visual(delta)
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
	facing_direction = locked_direction
	attack_origin = global_position
	dash_has_hit = false
	queue_redraw()
	return true


func _update_character_visual(delta: float = 0.0) -> void:
	if not is_instance_valid(character_visual):
		return
	var walking := state == State.APPROACH and velocity.length_squared() > 4.0
	var can_idle := state == State.APPROACH
	var attacking := state in [State.WINDUP, State.DASHING, State.RECOVERY]
	var attack_texture := base_texture
	if attack == Attack.DASH:
		attack_texture = dash_texture
	elif attack == Attack.SLAM:
		attack_texture = slam_texture
	elif attack == Attack.VOLLEY:
		attack_texture = volley_texture
	var selected_texture := attack_texture if attacking else (walk_texture if walking else idle_texture)
	var uses_animation_sheet := selected_texture != base_texture
	if character_visual.texture != selected_texture:
		character_visual.texture = selected_texture
		visual_animation_time = 0.0
		visual_animation_frame = 0
	character_visual.hframes = 4 if uses_animation_sheet else 2
	character_visual.vframes = 4 if uses_animation_sheet else 2
	# A folha 4x4 tem celulas com metade das dimensoes da base 2x2.
	character_visual.scale = animation_sheet_scale if uses_animation_sheet else base_sheet_scale
	if uses_animation_sheet:
		if attacking:
			if state == State.WINDUP:
				var windup_progress := 1.0 - clampf(state_time / maxf(windup_duration, 0.001), 0.0, 1.0)
				visual_animation_frame = 0 if windup_progress < 0.52 else 1
			elif state == State.DASHING:
				visual_animation_frame = 2
			else:
				var active_recovery_duration := recovery_duration * (0.65 if enraged else 1.0)
				var recovery_elapsed := active_recovery_duration - state_time
				visual_animation_frame = 2 if recovery_elapsed < attack_contact_pose_duration else 3
		else:
			var fps := walk_animation_fps if walking else idle_animation_fps
			visual_animation_time += delta * maxf(fps, 0.0)
			visual_animation_frame = int(floor(visual_animation_time)) % 4
	var looks_left := facing_direction.x < 0.0
	var looks_back := facing_direction.y < 0.0
	var direction_index := 0
	if looks_back:
		direction_index = 3 if looks_left else 1
	else:
		direction_index = 2 if looks_left else 0
	character_visual.frame = direction_index * 4 + visual_animation_frame if uses_animation_sheet else direction_index
	if flash_left > 0.0:
		character_visual.modulate = Color(1.8, 1.8, 1.8, 1.0)
	elif enraged:
		character_visual.modulate = Color(1.18, 0.82, 0.72, 1.0)
	else:
		character_visual.modulate = Color.WHITE


func _execute_attack() -> void:
	match attack:
		Attack.VOLLEY:
			var hand_side := locked_direction.orthogonal() * 18.0
			_spawn_attack_particles(2, global_position + locked_direction * 38.0 + hand_side, locked_direction)
			_spawn_attack_particles(2, global_position + locked_direction * 38.0 - hand_side, locked_direction)
			for angle in [-0.30, 0.0, 0.30]:
				var direction := locked_direction.rotated(angle)
				var projectile = PROJECTILE.instantiate()
				projectile.speed = projectile_speed
				projectile.lifetime = 2.6
				projectile.enable_blue_plasma()
				get_parent().add_child(projectile)
				projectile.global_position = global_position + direction * 48.0
				projectile.setup(direction)
			_enter_recovery()
		Attack.DASH:
			state = State.DASHING
			state_time = dash_duration
			dash_particle_time = 0.0
			dash_plasma_phase = 0.0
			_spawn_attack_particles(0, global_position - locked_direction * 28.0, locked_direction)
			_spawn_attack_particles(3, global_position + locked_direction * 32.0, locked_direction)
		Attack.SLAM:
			impact_left = 0.22
			_spawn_attack_particles(1, attack_origin, locked_direction)
			if target.global_position.distance_to(attack_origin) <= slam_radius:
				target.receive_enemy_hit(1)
			_enter_recovery()


func _spawn_attack_particles(kind: int, world_position: Vector2, effect_direction: Vector2) -> void:
	var effect := ATTACK_PARTICLES.instantiate()
	get_parent().add_child(effect)
	effect.global_position = world_position
	effect.setup(kind, effect_direction)


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
	draw_set_transform(Vector2(0, 12), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 48, Color(0, 0, 0, 0.48))
	draw_set_transform(Vector2.ZERO)
	if state == State.RECOVERY:
		draw_arc(Vector2.ZERO, 48, 0, TAU, 40, Color("49f4ff"), 2, true)
