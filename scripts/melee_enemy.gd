extends CharacterBody2D

const HIT_SPARK_SCENE := preload("res://scenes/hit_spark.tscn")
const VISUAL_BASE_SCALE := Vector2(0.2, 0.2)
const VISUAL_BASE_POSITION := Vector2(0.0, -27.0)
const IMPACT_VISUAL_DURATION := 0.18

enum State { CHASE, WINDUP, RECOVERY, DEAD }

@export var max_health := 3
@export var move_speed := 115.0
@export var attack_range := 72.0
@export var windup_duration := 0.55
@export var recovery_duration := 0.65

@export_category("Visual")
@export var idle_texture: Texture2D
@export var run_texture: Texture2D
@export var attack_texture: Texture2D
@export var idle_animation_fps := 3.0
@export var run_animation_fps := 8.0
@export var death_animation_duration := 0.42

var health: int
var state := State.CHASE
var state_time := 0.0
var target: CharacterBody2D
var flash_left := 0.0
var knockback_velocity := Vector2.ZERO
@export var knockback_strength := 230.0
@export var knockback_deceleration := 1400.0
@onready var character_visual: Sprite2D = $CharacterVisual

var facing_direction := Vector2.DOWN
var visual_animation_time := 0.0
var visual_animation_frame := 0
var visual_is_running := false
var attack_impact_left := 0.0
var damage_direction := Vector2.ZERO
var death_animation_time := 0.0
var death_fall_direction := 1.0
var death_visual_texture: Texture2D
var death_visual_frame := 0


func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	target = get_tree().get_first_node_in_group("player") as CharacterBody2D
	_update_character_visual(0.0)


func _physics_process(delta: float) -> void:
	flash_left = maxf(flash_left - delta, 0.0)
	attack_impact_left = maxf(attack_impact_left - delta, 0.0)
	character_visual.modulate = Color(1.8, 1.8, 1.8, 1.0) if flash_left > 0.0 else Color.WHITE
	if state == State.DEAD:
		death_animation_time = minf(death_animation_time + delta, death_animation_duration)
		_update_death_visual()
		queue_redraw()
		if death_animation_time >= death_animation_duration:
			queue_free()
		return
	if not is_instance_valid(target):
		_update_character_visual(delta)
		return
	if knockback_velocity.length_squared() > 4.0:
		velocity = knockback_velocity
		move_and_slide()
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_deceleration * delta)
		_update_character_visual(delta)
		queue_redraw()
		return

	var to_target := target.global_position - global_position
	if to_target.length_squared() > 0.001 and state == State.CHASE:
		facing_direction = to_target.normalized()
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
				_trigger_attack_impact()
				if to_target.length() <= attack_range + 18.0:
					target.receive_enemy_hit(1)
				state = State.RECOVERY
				state_time = recovery_duration
		State.RECOVERY:
			velocity = Vector2.ZERO
			state_time -= delta
			if state_time <= 0.0:
				state = State.CHASE
	_update_character_visual(delta)
	queue_redraw()


func _update_character_visual(delta: float = 0.0) -> void:
	if not is_instance_valid(character_visual):
		return
	var running := state == State.CHASE and velocity.length_squared() > 4.0 and knockback_velocity.length_squared() <= 4.0
	var attacking := state == State.WINDUP or state == State.RECOVERY
	if running != visual_is_running:
		visual_is_running = running
		visual_animation_time = 0.0
		visual_animation_frame = 0
	var selected_texture := attack_texture if attacking else (run_texture if running else idle_texture)
	if selected_texture != null:
		character_visual.texture = selected_texture
		character_visual.hframes = 4
		character_visual.vframes = 4
	if state == State.WINDUP:
		var windup_progress := 1.0 - clampf(state_time / maxf(windup_duration, 0.001), 0.0, 1.0)
		visual_animation_frame = 0 if windup_progress < 0.5 else 1
	elif state == State.RECOVERY:
		var recovery_progress := 1.0 - clampf(state_time / maxf(recovery_duration, 0.001), 0.0, 1.0)
		visual_animation_frame = 2 if recovery_progress < 0.4 else 3
	else:
		var fps := run_animation_fps if running else idle_animation_fps
		visual_animation_time += delta * maxf(fps, 0.0)
		visual_animation_frame = int(floor(visual_animation_time)) % 4
	var looks_left := facing_direction.x < 0.0
	var looks_back := facing_direction.y < 0.0
	var direction_row := 0
	if looks_back:
		direction_row = 3 if looks_left else 1
	else:
		direction_row = 2 if looks_left else 0
	character_visual.frame = direction_row * 4 + visual_animation_frame
	var impact_strength := clampf(attack_impact_left / IMPACT_VISUAL_DURATION, 0.0, 1.0)
	character_visual.scale = VISUAL_BASE_SCALE * Vector2(1.0 + impact_strength * 0.08, 1.0 - impact_strength * 0.10)
	character_visual.position = VISUAL_BASE_POSITION
	character_visual.rotation = 0.0
	if flash_left > 0.0:
		var damage_strength := clampf(flash_left / 0.12, 0.0, 1.0)
		character_visual.position -= damage_direction * 4.0 * damage_strength
		character_visual.rotation = sin((1.0 - damage_strength) * TAU) * 0.10 * damage_strength


func _update_death_visual() -> void:
	var progress := clampf(death_animation_time / maxf(death_animation_duration, 0.001), 0.0, 1.0)
	var fall := progress * progress * (3.0 - 2.0 * progress)
	character_visual.texture = death_visual_texture
	character_visual.hframes = 4
	character_visual.vframes = 4
	character_visual.frame = death_visual_frame
	character_visual.position = VISUAL_BASE_POSITION + Vector2(death_fall_direction * 8.0, 12.0) * fall
	character_visual.rotation = death_fall_direction * 0.82 * fall
	character_visual.scale = VISUAL_BASE_SCALE * Vector2(1.0 + 0.10 * fall, lerpf(1.0, 0.58, fall))
	var fade := clampf((progress - 0.68) / 0.32, 0.0, 1.0)
	character_visual.modulate = Color.WHITE.lerp(Color(0.32, 0.55, 0.68, 0.0), fade)


func _trigger_attack_impact() -> void:
	attack_impact_left = IMPACT_VISUAL_DURATION
	var spark := HIT_SPARK_SCENE.instantiate()
	get_parent().add_child(spark)
	spark.global_position = global_position + facing_direction * 46.0
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
	damage_direction = hit_direction.normalized()
	knockback_velocity = damage_direction * knockback_strength
	flash_left = 0.12
	if health == 0:
		_begin_death()
	queue_redraw()
	return true


func apply_heavy_knockback(hit_direction: Vector2, multiplier: float) -> void:
	if state == State.DEAD:
		return
	var direction := hit_direction.normalized()
	if direction.is_zero_approx():
		direction = damage_direction
	knockback_velocity = direction * knockback_strength * maxf(multiplier, 1.0)


func _begin_death() -> void:
	state = State.DEAD
	if get_parent().has_method("spawn_memory_fragment"):
		get_parent().spawn_memory_fragment(global_position)
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	attack_impact_left = 0.0
	death_animation_time = 0.0
	death_fall_direction = 1.0 if damage_direction.x >= 0.0 else -1.0
	death_visual_texture = character_visual.texture
	death_visual_frame = character_visual.frame
	_leave_combat_group.call_deferred()
	collision_layer = 0
	collision_mask = 0
	$CollisionShape2D.set_deferred("disabled", true)
	var spark := HIT_SPARK_SCENE.instantiate()
	get_parent().add_child(spark)
	spark.global_position = global_position + Vector2(0.0, -18.0)


func _leave_combat_group() -> void:
	remove_from_group("enemy")


func _draw() -> void:
	# Sombra ambiente e núcleo de contato ficam alinhados ao ponto físico dos pés.
	var death_progress := clampf(death_animation_time / maxf(death_animation_duration, 0.001), 0.0, 1.0) if state == State.DEAD else 0.0
	draw_set_transform(Vector2(0.0, 1.0), 0.0, Vector2(1.0 - death_progress * 0.35, 0.28 - death_progress * 0.10))
	draw_circle(Vector2.ZERO, 22.0, Color(0.0, 0.0, 0.0, 0.24 * (1.0 - death_progress)))
	draw_set_transform(Vector2(0.0, -1.0), 0.0, Vector2(1.0 - death_progress * 0.42, 0.17 - death_progress * 0.07))
	draw_circle(Vector2.ZERO, 12.0, Color(0.0, 0.0, 0.0, 0.50 * (1.0 - death_progress)))
	draw_set_transform(Vector2.ZERO)
	if state == State.WINDUP:
		draw_circle(Vector2.ZERO, attack_range, Color(1.0, 0.2, 0.15, 0.12))
		draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 40, Color("ff493d"), 4.0, true)
	if attack_impact_left > 0.0:
		var progress := 1.0 - attack_impact_left / IMPACT_VISUAL_DURATION
		var alpha := 1.0 - progress
		var impact_center := facing_direction * 42.0
		var impact_angle := facing_direction.angle()
		draw_arc(impact_center, 28.0 + progress * 24.0, impact_angle - 1.0, impact_angle + 1.0, 18, Color(0.12, 0.62, 1.0, alpha), 7.0 * alpha + 2.0, true)
		draw_arc(impact_center, 18.0 + progress * 16.0, impact_angle - 0.8, impact_angle + 0.8, 14, Color(0.62, 0.92, 1.0, alpha), 4.0 * alpha + 1.0, true)

