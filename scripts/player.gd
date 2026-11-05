extends CharacterBody2D

signal died
signal health_changed(current: int, maximum: int)
signal attack_landed(world_position: Vector2)
signal player_damaged
signal dodge_started

enum AttackState {
	READY,
	WINDUP,
	ACTIVE,
	RECOVERY,
}

@export_category("Movimento")
@export var move_speed: float = 300.0
@export var acceleration: float = 2200.0
@export var deceleration: float = 2800.0

@export_category("Visual")
@export var idle_texture: Texture2D
@export var run_texture: Texture2D
@export var run_animation_fps: float = 10.0
@export var idle_breath_amount: float = 0.8
@export var idle_breath_speed: float = 0.9

@export_category("Vida")
@export var max_health: int = 5

@export_category("Ataque básico")
@export var attack_damage: int = 1
@export var windup_duration: float = 0.07
@export var active_duration: float = 0.10
@export var recovery_duration: float = 0.20

@export_category("Esquiva")
@export var dodge_speed: float = 820.0
@export var dodge_duration: float = 0.16
@export var dodge_cooldown: float = 0.55
@export var dodge_grants_invulnerability: bool = true

@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var character_visual: Sprite2D = $CharacterVisual

var facing_direction := Vector2.DOWN
var attack_state := AttackState.READY
var attack_time_left := 0.0
var hit_targets: Array[Node2D] = []
var is_dodging := false
var dodge_time_left := 0.0
var dodge_cooldown_left := 0.0
var dodge_direction := Vector2.DOWN
var debug_hits_received := 0
var damage_flash_left := 0.0
var current_health: int
var is_dead := false
var controls_enabled := true
var visual_horizontal_direction := 1
var visual_animation_frame := 0
var visual_animation_time := 0.0
var visual_breath_time := 0.0
var visual_is_running := false

const VISUAL_BASE_POSITION := Vector2(0.0, -29.0)
const IDLE_VISUAL_SCALE := Vector2(0.12, 0.12)
const RUN_VISUAL_SCALE := Vector2(0.22, 0.22)
const RUN_FRAME_OFFSETS := [
	[Vector2(0.0, 0.0), Vector2(0.9, 9.2), Vector2(1.5, 1.1), Vector2(3.6, 2.6)],
	[Vector2(0.0, 0.0), Vector2(1.5, 1.8), Vector2(2.6, 0.0), Vector2(5.5, 0.0)],
	[Vector2(0.0, 0.0), Vector2(0.7, 8.6), Vector2(1.1, 0.2), Vector2(2.9, 3.7)],
	[Vector2(0.0, 0.0), Vector2(2.2, 0.7), Vector2(4.4, 0.2), Vector2(4.1, 0.0)],
]


func _ready() -> void:
	current_health = max_health
	add_to_group("player")
	attack_area.area_entered.connect(_on_attack_area_entered)
	attack_area.body_entered.connect(_on_attack_body_entered)
	_update_character_visual()


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled or is_dead:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			start_attack(get_global_mouse_position() - global_position)
	elif event is InputEventKey:
		if event.physical_keycode in [KEY_SHIFT, KEY_CTRL] and event.pressed and not event.echo:
			var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
			start_dodge(input_direction)
		elif event.physical_keycode == KEY_SPACE and event.pressed and not event.echo:
			start_attack(facing_direction)


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		_update_character_visual(delta)
		return
	damage_flash_left = maxf(damage_flash_left - delta, 0.0)
	dodge_cooldown_left = maxf(dodge_cooldown_left - delta, 0.0)
	_update_attack(delta)
	_update_dodge(delta)

	if is_dodging:
		velocity = dodge_direction * dodge_speed
		move_and_slide()
		_update_character_visual(delta)
		queue_redraw()
		return

	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction != Vector2.ZERO:
		if attack_state == AttackState.READY:
			facing_direction = input_direction
			if absf(input_direction.x) > 0.1:
				visual_horizontal_direction = 1 if input_direction.x > 0.0 else -1
		velocity = velocity.move_toward(input_direction * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)

	move_and_slide()
	_update_character_visual(delta)
	queue_redraw()


func start_attack(direction: Vector2) -> bool:
	if not controls_enabled or is_dead or attack_state != AttackState.READY or is_dodging:
		return false

	if direction.length_squared() > 0.001:
		facing_direction = direction.normalized()
		if absf(facing_direction.x) > 0.1:
			visual_horizontal_direction = 1 if facing_direction.x > 0.0 else -1

	attack_state = AttackState.WINDUP
	attack_time_left = windup_duration
	attack_area.rotation = facing_direction.angle()
	hit_targets.clear()
	_update_character_visual()
	queue_redraw()
	return true


func start_dodge(direction: Vector2) -> bool:
	if not controls_enabled or is_dead or is_dodging or dodge_cooldown_left > 0.0 or attack_state != AttackState.READY:
		return false

	dodge_direction = direction.normalized() if direction.length_squared() > 0.001 else facing_direction
	facing_direction = dodge_direction
	if absf(facing_direction.x) > 0.1:
		visual_horizontal_direction = 1 if facing_direction.x > 0.0 else -1
	is_dodging = true
	dodge_time_left = dodge_duration
	dodge_cooldown_left = dodge_cooldown
	dodge_started.emit()
	_update_character_visual()
	queue_redraw()
	return true


func is_invulnerable() -> bool:
	return is_dodging and dodge_grants_invulnerability


func receive_enemy_hit(damage: int = 1) -> bool:
	if is_dead or is_invulnerable():
		return false
	debug_hits_received += 1
	current_health = maxi(current_health - damage, 0)
	damage_flash_left = 0.16
	health_changed.emit(current_health, max_health)
	player_damaged.emit()
	if current_health == 0:
		_die()
	queue_redraw()
	return true


func _die() -> void:
	is_dead = true
	controls_enabled = false
	velocity = Vector2.ZERO
	attack_collision.set_deferred("disabled", true)
	died.emit()
	queue_redraw()


func _update_dodge(delta: float) -> void:
	if not is_dodging:
		return

	dodge_time_left -= delta
	if dodge_time_left <= 0.0:
		is_dodging = false
		dodge_time_left = 0.0
		velocity = dodge_direction * move_speed
		queue_redraw()


func _update_attack(delta: float) -> void:
	if attack_state == AttackState.READY:
		return

	attack_time_left -= delta
	if attack_time_left > 0.0:
		return

	match attack_state:
		AttackState.WINDUP:
			attack_state = AttackState.ACTIVE
			attack_time_left = active_duration
			attack_collision.set_deferred("disabled", false)
		AttackState.ACTIVE:
			attack_state = AttackState.RECOVERY
			attack_time_left = recovery_duration
			attack_collision.set_deferred("disabled", true)
		AttackState.RECOVERY:
			attack_state = AttackState.READY
			attack_time_left = 0.0
	queue_redraw()


func _on_attack_area_entered(target: Area2D) -> void:
	_try_damage_target(target)


func _on_attack_body_entered(target: Node2D) -> void:
	_try_damage_target(target)


func _try_damage_target(target: Node2D) -> void:
	if attack_state != AttackState.ACTIVE or target in hit_targets:
		return

	hit_targets.append(target)
	if target.has_method("take_damage"):
		var damage_applied = target.take_damage(attack_damage, facing_direction)
		if damage_applied != false:
			attack_landed.emit(target.global_position)


func _update_character_visual(delta: float = 0.0) -> void:
	var should_run := is_dodging or velocity.length_squared() > 400.0
	if should_run != visual_is_running:
		visual_is_running = should_run
		visual_animation_frame = 0
		visual_animation_time = 0.0

	character_visual.texture = run_texture if visual_is_running else idle_texture
	if delta > 0.0 and visual_is_running:
		visual_animation_time += delta
		var frame_duration := 1.0 / maxf(run_animation_fps, 0.1)
		while visual_animation_time >= frame_duration:
			visual_animation_time -= frame_duration
			visual_animation_frame = (visual_animation_frame + 1) % 4
	elif delta > 0.0:
		visual_breath_time += delta

	var faces_down := facing_direction.y >= 0.0
	var direction_row := 0
	if faces_down:
		direction_row = 0 if visual_horizontal_direction > 0 else 2
	else:
		direction_row = 1 if visual_horizontal_direction > 0 else 3
	if visual_is_running:
		character_visual.hframes = 4
		character_visual.vframes = 4
		character_visual.scale = RUN_VISUAL_SCALE
		character_visual.frame = direction_row * 4 + visual_animation_frame
		character_visual.position = VISUAL_BASE_POSITION + RUN_FRAME_OFFSETS[direction_row][visual_animation_frame]
	else:
		character_visual.hframes = 2
		character_visual.vframes = 2
		character_visual.scale = IDLE_VISUAL_SCALE
		character_visual.frame = direction_row
		var breath_offset := sin(visual_breath_time * TAU * idle_breath_speed) * idle_breath_amount
		character_visual.position = VISUAL_BASE_POSITION + Vector2(0.0, breath_offset)

	if is_dead:
		character_visual.modulate = Color(0.45, 0.48, 0.55, 0.8)
	elif damage_flash_left > 0.0:
		character_visual.modulate = Color(1.0, 0.55, 0.55)
	elif is_dodging:
		character_visual.modulate = Color(0.65, 1.0, 1.0, 0.85)
	else:
		character_visual.modulate = Color.WHITE


func _draw() -> void:
	# Formas provisórias: sombra, corpo e indicador da direção atual.
	draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 24.0, Color(0.0, 0.0, 0.0, 0.35))
	draw_set_transform(Vector2.ZERO)

	if attack_state != AttackState.READY:
		var attack_color := Color("fff4b0") if attack_state == AttackState.ACTIVE else Color(1.0, 0.35, 0.65, 0.55)
		var direction_angle := facing_direction.angle()
		draw_arc(Vector2.ZERO, 76.0, direction_angle - 0.48, direction_angle + 0.48, 18, attack_color, 7.0, true)

	if is_dodging:
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 24, Color("9fffea"), 4.0, true)
		draw_line(-dodge_direction * 26.0, -dodge_direction * 58.0, Color(0.3, 1.0, 0.85, 0.65), 6.0, true)
