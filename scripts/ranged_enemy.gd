extends CharacterBody2D

const HIT_SPARK_SCENE := preload("res://scenes/hit_spark.tscn")
const VISUAL_BASE_SCALE := Vector2(0.21, 0.21)
const VISUAL_BASE_POSITION := Vector2(0.0, -29.0)

enum State { POSITIONING, WINDUP, RECOVERY, DEAD }
enum VisualMovement { IDLE, ADVANCE, RETREAT }

@export var projectile_scene: PackedScene
@export var max_health := 3
@export var move_speed := 90.0
@export var preferred_distance := 260.0
@export var distance_tolerance := 45.0
@export var windup_duration := 0.75
@export var recovery_duration := 1.0

@export_category("Visual")
@export var idle_texture: Texture2D
@export var advance_texture: Texture2D
@export var backpedal_texture: Texture2D
@export var shoot_texture: Texture2D
@export var idle_animation_fps := 3.0
@export var movement_animation_fps := 8.0
@export var shot_recoil_duration := 0.16
@export var death_animation_duration := 0.46

var health: int
var state := State.POSITIONING
var state_time := 0.0
var target: CharacterBody2D
var locked_direction := Vector2.LEFT
var locked_target_position := Vector2.ZERO
var shot_flash_left := 0.0
var flash_left := 0.0
var knockback_velocity := Vector2.ZERO
@export var knockback_strength := 230.0
@export var knockback_deceleration := 1400.0
@onready var character_visual: Sprite2D = $CharacterVisual

var facing_direction := Vector2.LEFT
var visual_movement := VisualMovement.IDLE
var visual_animation_time := 0.0
var visual_animation_frame := 0
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
	shot_flash_left = maxf(shot_flash_left - delta, 0.0)
	character_visual.modulate = Color(1.8, 1.8, 1.8, 1.0) if flash_left > 0.0 else Color.WHITE
	if state == State.DEAD:
		death_animation_time = minf(death_animation_time + delta, death_animation_duration)
		_update_death_visual()
		queue_redraw()
		if death_animation_time >= death_animation_duration:
			queue_free()
		return
	if not is_instance_valid(target):
		visual_movement = VisualMovement.IDLE
		_update_character_visual(delta)
		return
	if knockback_velocity.length_squared() > 4.0:
		visual_movement = VisualMovement.IDLE
		velocity = knockback_velocity
		move_and_slide()
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_deceleration * delta)
		_update_character_visual(delta)
		queue_redraw()
		return
	var to_target := target.global_position - global_position
	var distance := to_target.length()
	if to_target.length_squared() > 0.001 and state == State.POSITIONING:
		facing_direction = to_target.normalized()
	match state:
		State.POSITIONING:
			if distance < preferred_distance - distance_tolerance:
				visual_movement = VisualMovement.RETREAT
				velocity = -to_target.normalized() * move_speed
				move_and_slide()
			elif distance > preferred_distance + distance_tolerance:
				visual_movement = VisualMovement.ADVANCE
				velocity = to_target.normalized() * move_speed
				move_and_slide()
			else:
				visual_movement = VisualMovement.IDLE
				velocity = Vector2.ZERO
				start_windup()
		State.WINDUP:
			visual_movement = VisualMovement.IDLE
			velocity = Vector2.ZERO
			state_time -= delta
			if state_time <= 0.0:
				_fire()
				state = State.RECOVERY
				state_time = recovery_duration
		State.RECOVERY:
			visual_movement = VisualMovement.IDLE
			velocity = Vector2.ZERO
			state_time -= delta
			if state_time <= 0.0:
				state = State.POSITIONING
	_update_character_visual(delta)
	queue_redraw()


func start_windup() -> void:
	if state != State.POSITIONING or not is_instance_valid(target):
		return
	state = State.WINDUP
	state_time = windup_duration
	locked_direction = (target.global_position - global_position).normalized()
	locked_target_position = target.global_position
	facing_direction = locked_direction
	visual_movement = VisualMovement.IDLE
	_update_character_visual(0.0)
	queue_redraw()


func is_telegraphing() -> bool:
	return state == State.WINDUP


func _fire() -> void:
	if projectile_scene == null:
		return
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.enable_sniper_bolt()
	projectile.global_position = global_position + _muzzle_offset()
	projectile.setup(locked_direction)
	shot_flash_left = shot_recoil_duration
	queue_redraw()


func _muzzle_offset() -> Vector2:
	return Vector2(0.0, -22.0) + locked_direction * 30.0


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
	spark.global_position = global_position + Vector2(0.0, -20.0)


func _leave_combat_group() -> void:
	remove_from_group("enemy")


func _update_character_visual(delta: float = 0.0) -> void:
	if not is_instance_valid(character_visual):
		return
	var selected_texture := idle_texture
	var fps := idle_animation_fps
	var shooting := state == State.WINDUP or state == State.RECOVERY
	if shooting and shoot_texture != null:
		selected_texture = shoot_texture
		fps = 0.0
	elif visual_movement == VisualMovement.ADVANCE:
		selected_texture = advance_texture
		fps = movement_animation_fps
	elif visual_movement == VisualMovement.RETREAT:
		selected_texture = backpedal_texture
		fps = movement_animation_fps
	if character_visual.texture != selected_texture:
		character_visual.texture = selected_texture
		visual_animation_time = 0.0
		visual_animation_frame = 0
	character_visual.hframes = 4
	character_visual.vframes = 4
	visual_animation_time += delta * maxf(fps, 0.0)
	visual_animation_frame = int(floor(visual_animation_time)) % 4
	var looks_left := facing_direction.x < 0.0
	var looks_back := facing_direction.y < 0.0
	var direction_row := 0
	if looks_back:
		direction_row = 3 if looks_left else 1
	else:
		direction_row = 2 if looks_left else 0
	var selected_frame := visual_animation_frame
	if shooting and shoot_texture != null:
		if state == State.WINDUP:
			var windup_progress := 1.0 - clampf(state_time / maxf(windup_duration, 0.001), 0.0, 1.0)
			selected_frame = mini(int(floor(windup_progress * 3.0)), 2)
		else:
			var recovery_elapsed := recovery_duration - state_time
			if recovery_elapsed < shot_recoil_duration:
				selected_frame = 3
			elif recovery_elapsed < recovery_duration * 0.58:
				selected_frame = 2
			else:
				selected_frame = 1
	character_visual.frame = direction_row * 4 + selected_frame
	character_visual.scale = VISUAL_BASE_SCALE
	character_visual.position = VISUAL_BASE_POSITION
	character_visual.rotation = 0.0
	if shot_flash_left > 0.0:
		var recoil_strength := shot_flash_left / maxf(shot_recoil_duration, 0.001)
		character_visual.position -= locked_direction * 5.0 * recoil_strength
		character_visual.rotation = -locked_direction.x * 0.08 * recoil_strength
	if flash_left > 0.0:
		var damage_strength := clampf(flash_left / 0.12, 0.0, 1.0)
		character_visual.position -= damage_direction * 5.0 * damage_strength
		character_visual.rotation = sin((1.0 - damage_strength) * TAU) * 0.12 * damage_strength


func _update_death_visual() -> void:
	var progress := clampf(death_animation_time / maxf(death_animation_duration, 0.001), 0.0, 1.0)
	var fall := progress * progress * (3.0 - 2.0 * progress)
	character_visual.texture = death_visual_texture
	character_visual.hframes = 4
	character_visual.vframes = 4
	character_visual.frame = death_visual_frame
	character_visual.position = VISUAL_BASE_POSITION + Vector2(death_fall_direction * 10.0, 14.0) * fall
	character_visual.rotation = death_fall_direction * 0.92 * fall
	character_visual.scale = VISUAL_BASE_SCALE * Vector2(1.0 + 0.08 * fall, lerpf(1.0, 0.48, fall))
	var flicker := 0.58 if int(death_animation_time * 42.0) % 2 == 0 else 1.0
	var fade := clampf((progress - 0.66) / 0.34, 0.0, 1.0)
	character_visual.modulate = Color(0.44, 0.20, 0.58, flicker).lerp(Color(0.18, 0.08, 0.24, 0.0), fade)


func _draw() -> void:
	var death_progress := clampf(death_animation_time / maxf(death_animation_duration, 0.001), 0.0, 1.0) if state == State.DEAD else 0.0
	draw_set_transform(Vector2(0.0, 1.0), 0.0, Vector2(1.0 - death_progress * 0.42, 0.27 - death_progress * 0.10))
	draw_circle(Vector2.ZERO, 19.0, Color(0.0, 0.0, 0.0, 0.23 * (1.0 - death_progress)))
	draw_set_transform(Vector2(0.0, -1.0), 0.0, Vector2(1.0 - death_progress * 0.48, 0.16 - death_progress * 0.06))
	draw_circle(Vector2.ZERO, 10.0, Color(0.0, 0.0, 0.0, 0.48 * (1.0 - death_progress)))
	draw_set_transform(Vector2.ZERO)
	if state == State.DEAD:
		var glitch_alpha := 1.0 - death_progress
		for index in 4:
			var offset := Vector2(death_fall_direction * (8.0 + index * 7.0), -28.0 + index * 13.0)
			draw_line(offset, offset + Vector2(death_fall_direction * (12.0 + death_progress * 18.0), 0.0), Color(0.94, 0.20, 1.0, glitch_alpha), 3.0, true)
	if state == State.WINDUP:
		var windup_progress := 1.0 - clampf(state_time / maxf(windup_duration, 0.001), 0.0, 1.0)
		var focus := smoothstep(0.0, 1.0, windup_progress)
		var telegraph_muzzle := _muzzle_offset()
		var target_point := to_local(locked_target_position)
		draw_line(telegraph_muzzle, target_point, Color(0.16, 0.01, 0.10, 0.82), 7.0, true)
		draw_line(telegraph_muzzle, target_point, Color(1.0, 0.16, 0.55, 0.30 + focus * 0.62), 1.5 + focus * 1.5, true)
		var reticle_radius := lerpf(25.0, 11.0, focus)
		draw_arc(target_point, reticle_radius, 0.0, TAU, 32, Color(1.0, 0.18, 0.55, 0.55 + focus * 0.4), 2.0, true)
		for index in 4:
			var marker_direction := Vector2.RIGHT.rotated(float(index) * TAU / 4.0)
			var marker_start := target_point + marker_direction * (reticle_radius + 4.0)
			draw_line(marker_start, marker_start + marker_direction * 7.0, Color(0.55, 0.95, 1.0, 0.75 + focus * 0.25), 2.0, true)
		draw_circle(telegraph_muzzle, 8.0 + focus * 6.0, Color(1.0, 0.08, 0.45, 0.12 + focus * 0.16))
		draw_circle(telegraph_muzzle, 2.0 + focus * 3.0, Color(0.65, 1.0, 1.0, 0.7 + focus * 0.3))
	if shot_flash_left > 0.0:
		var flash_strength := shot_flash_left / maxf(shot_recoil_duration, 0.001)
		var flash_muzzle := _muzzle_offset()
		draw_circle(flash_muzzle, 18.0 * flash_strength, Color(1.0, 0.10, 0.48, 0.30 * flash_strength))
		draw_circle(flash_muzzle, 8.0 * flash_strength, Color(0.72, 1.0, 1.0, 0.9 * flash_strength))
		draw_line(flash_muzzle, flash_muzzle + locked_direction * 34.0, Color(0.75, 1.0, 1.0, flash_strength), 4.0, true)
