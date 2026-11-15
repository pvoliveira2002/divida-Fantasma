extends CharacterBody2D

signal died
signal health_changed(current: int, maximum: int)
signal attack_landed(world_position: Vector2)
signal combo_finisher_landed(world_position: Vector2)
signal heavy_attack_landed(world_position: Vector2)
signal player_damaged
signal dodge_started
signal protocol_hit(target: Node2D, impact: Vector2, swing: int)
signal hatch_entry_finished

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
@export var attack_texture: Texture2D
@export var combo_texture: Texture2D
@export var combo_back_right_texture: Texture2D
@export var combo_front_left_texture: Texture2D
@export var combo_back_left_texture: Texture2D
@export var hatch_entry_texture: Texture2D
@export var run_animation_fps: float = 10.0
@export var idle_breath_amount: float = 0.8
@export var idle_breath_speed: float = 0.9
@export var death_animation_duration: float = 0.45
@export var hatch_entry_duration: float = 0.72

@export_category("Vida")
@export var max_health: int = 5

@export_category("Ataque básico")
@export var attack_damage: int = 1
@export var windup_duration: float = 0.07
@export var active_duration: float = 0.10
@export var recovery_duration: float = 0.20
@export var combo_chain_recovery: float = 0.10
@export var combo_input_buffer_window: float = 0.04
@export var combo_finisher_damage: int = 2
@export var combo_finisher_recovery: float = 0.28

@export_category("Ataque pesado")
@export var heavy_charge_threshold: float = 0.45
@export var heavy_damage: int = 3
@export var heavy_windup_duration: float = 0.10
@export var heavy_active_duration: float = 0.13
@export var heavy_recovery_duration: float = 0.36
@export var heavy_range_scale: float = 1.25
@export var heavy_move_speed_multiplier: float = 0.45
@export var heavy_recovery_move_multiplier: float = 0.82
@export var heavy_knockback_multiplier: float = 1.65

@export_category("Esquiva")
@export var dodge_speed: float = 820.0
@export var dodge_duration: float = 0.16
@export var dodge_cooldown: float = 0.65
@export var dodge_grants_invulnerability: bool = true

@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
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
var death_animation_time := 0.0
var attack_serial := 0
var combo_step := 0
var combo_queued := false
var combo_queued_direction := Vector2.ZERO
var is_charging_heavy := false
var heavy_charge_time := 0.0
var heavy_charge_direction := Vector2.RIGHT
var attack_is_heavy := false
var buffered_attack_after_heavy := 0
var buffered_attack_direction := Vector2.RIGHT
var attack_collision_base_position := Vector2.ZERO
var attack_collision_base_scale := Vector2.ONE
var circuit_visual_charge := 0
var overload_visual_charge := 0
var is_hatch_transitioning := false
var hatch_entry_time := 0.0
var hatch_entry_offset := Vector2.ZERO
var hatch_entry_signal_sent := false

const VISUAL_BASE_POSITION := Vector2(0.0, -29.0)
const IDLE_VISUAL_SCALE := Vector2(0.12, 0.12)
const RUN_VISUAL_SCALE := Vector2(0.22, 0.22)
const HATCH_VISUAL_SCALE := Vector2(0.17, 0.17)
const COMBO_VISUAL_SCALE := Vector2(0.18, 0.18)
const GROUND_SHADOW_OFFSET := Vector2(0.0, -7.0)
const COMBO_LAST_STEP := 3
const RUN_FRAME_OFFSETS := [
	[Vector2(0.0, 0.0), Vector2(0.9, 9.2), Vector2(1.5, 1.1), Vector2(3.6, 2.6)],
	[Vector2(0.0, 0.0), Vector2(1.5, 1.8), Vector2(2.6, 0.0), Vector2(5.5, 0.0)],
	[Vector2(0.0, 0.0), Vector2(0.7, 8.6), Vector2(1.1, 0.2), Vector2(2.9, 3.7)],
	[Vector2(0.0, 0.0), Vector2(2.2, 0.7), Vector2(4.4, 0.2), Vector2(4.1, 0.0)],
]
const BACK_RUN_FRAME_SEQUENCE := [0, 0, 2, 2]


func _ready() -> void:
	current_health = max_health
	add_to_group("player")
	attack_area.area_entered.connect(_on_attack_area_entered)
	attack_area.body_entered.connect(_on_attack_body_entered)
	attack_collision_base_position = attack_collision.position
	attack_collision_base_scale = attack_collision.scale
	_update_character_visual()


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled or is_dead:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_direction := get_global_mouse_position() - global_position
			if event.pressed:
				# Durante um combo, o clique continua enfileirando o golpe seguinte
				# imediatamente. Depois de um pesado, porem, a duracao do novo
				# pressionamento decide entre outro pesado e um toque leve.
				if attack_is_heavy and attack_state in [AttackState.ACTIVE, AttackState.RECOVERY]:
					begin_attack_charge(mouse_direction)
				elif attack_state != AttackState.READY:
					start_attack(mouse_direction)
				else:
					begin_attack_charge(mouse_direction)
			else:
				release_attack_charge(mouse_direction)
	elif event is InputEventMouseMotion and is_charging_heavy:
		_update_heavy_charge_direction(get_global_mouse_position() - global_position)
	elif event is InputEventKey:
		if event.physical_keycode in [KEY_SHIFT, KEY_CTRL] and event.pressed and not event.echo:
			var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
			start_dodge(input_direction)
		elif event.physical_keycode == KEY_SPACE and event.pressed and not event.echo:
			start_attack(facing_direction)


func _physics_process(delta: float) -> void:
	if is_hatch_transitioning:
		velocity = Vector2.ZERO
		hatch_entry_time = minf(hatch_entry_time + delta, hatch_entry_duration)
		_update_hatch_entry_visual()
		queue_redraw()
		if hatch_entry_time >= hatch_entry_duration and not hatch_entry_signal_sent:
			hatch_entry_signal_sent = true
			hatch_entry_finished.emit()
		return
	if is_dead:
		velocity = Vector2.ZERO
		death_animation_time = minf(death_animation_time + delta, maxf(death_animation_duration, 0.001))
		_update_character_visual(delta)
		return
	if not controls_enabled:
		velocity = Vector2.ZERO
		_update_character_visual(delta)
		return
	damage_flash_left = maxf(damage_flash_left - delta, 0.0)
	dodge_cooldown_left = maxf(dodge_cooldown_left - delta, 0.0)
	_update_attack_charge(delta)
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
			if not is_charging_heavy:
				facing_direction = input_direction
				if absf(input_direction.x) > 0.1:
					visual_horizontal_direction = 1 if input_direction.x > 0.0 else -1
			var target_speed := move_speed * (heavy_move_speed_multiplier if is_charging_heavy else 1.0)
			velocity = velocity.move_toward(input_direction * target_speed, acceleration * delta)
		elif attack_is_heavy and attack_state == AttackState.RECOVERY:
			# Depois do impacto o jogador recupera direcao imediatamente, sem ser
			# arrastado pela velocidade reduzida que existia durante a carga.
			var recovery_speed_multiplier := heavy_move_speed_multiplier if is_charging_heavy else heavy_recovery_move_multiplier
			velocity = velocity.move_toward(input_direction * move_speed * recovery_speed_multiplier, acceleration * delta)
		elif attack_is_heavy:
			velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)

	move_and_slide()
	_update_character_visual(delta)
	queue_redraw()


func start_attack(direction: Vector2) -> bool:
	if not controls_enabled or is_dead or is_dodging or is_charging_heavy:
		return false
	if attack_state != AttackState.READY:
		var late_windup_buffer := attack_state == AttackState.WINDUP and attack_time_left <= combo_input_buffer_window
		var can_queue_combo := attack_state in [AttackState.ACTIVE, AttackState.RECOVERY] or late_windup_buffer
		if can_queue_combo and combo_step < COMBO_LAST_STEP and not combo_queued:
			combo_queued = true
			combo_queued_direction = direction.normalized() if direction.length_squared() > 0.001 else facing_direction
			# Uma entrada feita durante a recuperacao nao precisa esperar a janela
			# completa de um golpe isolado para continuar a sequencia.
			if attack_state == AttackState.RECOVERY:
				attack_time_left = minf(attack_time_left, combo_chain_recovery)
			return true
		return false

	combo_step = 0
	combo_queued = false
	attack_is_heavy = false
	_restore_attack_collision_transform()
	_begin_combo_swing(direction)
	return true


func begin_attack_charge(direction: Vector2) -> bool:
	var can_buffer_after_heavy := attack_is_heavy and attack_state in [AttackState.ACTIVE, AttackState.RECOVERY]
	if not controls_enabled or is_dead or is_dodging or is_charging_heavy or (attack_state != AttackState.READY and not can_buffer_after_heavy):
		return false
	is_charging_heavy = true
	heavy_charge_time = 0.0
	_update_heavy_charge_direction(direction)
	velocity *= heavy_move_speed_multiplier
	_update_character_visual()
	queue_redraw()
	return true


func release_attack_charge(direction: Vector2 = Vector2.ZERO) -> bool:
	if not is_charging_heavy:
		return false
	if direction.length_squared() > 0.001:
		_update_heavy_charge_direction(direction)
	var charged_enough := heavy_charge_time >= heavy_charge_threshold
	var released_direction := heavy_charge_direction
	is_charging_heavy = false
	heavy_charge_time = 0.0
	if attack_state != AttackState.READY:
		buffered_attack_after_heavy = 2 if charged_enough else 1
		buffered_attack_direction = released_direction
		queue_redraw()
		return true
	if charged_enough:
		return start_heavy_attack(released_direction)
	return start_attack(released_direction)


func start_heavy_attack(direction: Vector2) -> bool:
	if not controls_enabled or is_dead or is_dodging or is_charging_heavy or attack_state != AttackState.READY:
		return false
	combo_step = 0
	combo_queued = false
	attack_is_heavy = true
	if direction.length_squared() > 0.001:
		facing_direction = direction.normalized()
		if absf(facing_direction.x) > 0.1:
			visual_horizontal_direction = 1 if facing_direction.x > 0.0 else -1
	attack_state = AttackState.WINDUP
	attack_serial += 1
	attack_time_left = heavy_windup_duration
	# A carga nunca pode vazar movimento para o golpe. O jogador volta a mover
	# durante a recuperacao usando a entrada atual, nao a direcao antiga.
	velocity = Vector2.ZERO
	attack_area.rotation = facing_direction.angle()
	attack_collision.position = attack_collision_base_position + Vector2((heavy_range_scale - 1.0) * 30.0, 0.0)
	attack_collision.scale = attack_collision_base_scale * Vector2(heavy_range_scale, 1.12)
	attack_collision.set_deferred("disabled", true)
	hit_targets.clear()
	_update_character_visual()
	queue_redraw()
	return true


func _update_attack_charge(delta: float) -> void:
	if not is_charging_heavy:
		return
	heavy_charge_time = minf(heavy_charge_time + delta, heavy_charge_threshold * 2.0)
	_update_heavy_charge_direction(get_global_mouse_position() - global_position)
	queue_redraw()


func _update_heavy_charge_direction(direction: Vector2) -> void:
	if direction.length_squared() <= 0.001:
		return
	heavy_charge_direction = direction.normalized()
	facing_direction = heavy_charge_direction
	if absf(facing_direction.x) > 0.1:
		visual_horizontal_direction = 1 if facing_direction.x > 0.0 else -1


func _cancel_attack_charge() -> void:
	is_charging_heavy = false
	heavy_charge_time = 0.0
	buffered_attack_after_heavy = 0


func _restore_attack_collision_transform() -> void:
	attack_collision.position = attack_collision_base_position
	attack_collision.scale = attack_collision_base_scale


func _begin_combo_swing(direction: Vector2) -> void:
	if direction.length_squared() > 0.001:
		facing_direction = direction.normalized()
		if absf(facing_direction.x) > 0.1:
			visual_horizontal_direction = 1 if facing_direction.x > 0.0 else -1
	attack_state = AttackState.WINDUP
	attack_serial += 1
	attack_time_left = windup_duration
	attack_area.rotation = facing_direction.angle()
	attack_collision.set_deferred("disabled", true)
	hit_targets.clear()
	_update_character_visual()
	queue_redraw()


func start_dodge(direction: Vector2) -> bool:
	if not controls_enabled or is_dead or is_dodging or dodge_cooldown_left > 0.0 or attack_state != AttackState.READY:
		return false

	_cancel_attack_charge()
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
	_update_character_visual()
	queue_redraw()
	return true


func _die() -> void:
	is_dead = true
	controls_enabled = false
	velocity = Vector2.ZERO
	attack_state = AttackState.READY
	attack_time_left = 0.0
	combo_step = 0
	combo_queued = false
	_cancel_attack_charge()
	attack_is_heavy = false
	hit_targets.clear()
	is_dodging = false
	dodge_time_left = 0.0
	damage_flash_left = 0.0
	death_animation_time = 0.0
	attack_collision.set_deferred("disabled", true)
	_restore_attack_collision_transform()
	died.emit()
	queue_redraw()


func reset_combat_pose() -> void:
	is_hatch_transitioning = false
	hatch_entry_time = 0.0
	hatch_entry_offset = Vector2.ZERO
	hatch_entry_signal_sent = false
	velocity = Vector2.ZERO
	attack_state = AttackState.READY
	attack_time_left = 0.0
	combo_step = 0
	combo_queued = false
	_cancel_attack_charge()
	attack_is_heavy = false
	hit_targets.clear()
	is_dodging = false
	dodge_time_left = 0.0
	damage_flash_left = 0.0
	body_collision.set_deferred("disabled", false)
	attack_collision.set_deferred("disabled", true)
	_restore_attack_collision_transform()
	character_visual.visible = true
	character_visual.modulate = Color.WHITE
	_update_character_visual()
	queue_redraw()


func begin_hatch_entry(hatch_world_position: Vector2) -> bool:
	if is_dead or is_hatch_transitioning or not controls_enabled:
		return false
	reset_combat_pose()
	controls_enabled = false
	is_hatch_transitioning = true
	hatch_entry_time = 0.0
	hatch_entry_offset = to_local(hatch_world_position)
	hatch_entry_signal_sent = false
	if hatch_entry_offset.length_squared() > 0.001:
		facing_direction = hatch_entry_offset.normalized()
		if absf(facing_direction.x) > 0.1:
			visual_horizontal_direction = 1 if facing_direction.x > 0.0 else -1
	body_collision.set_deferred("disabled", true)
	attack_collision.set_deferred("disabled", true)
	_update_hatch_entry_visual()
	queue_redraw()
	return true


func _update_hatch_entry_visual() -> void:
	var progress := clampf(hatch_entry_time / maxf(hatch_entry_duration, 0.001), 0.0, 1.0)
	var travel := smoothstep(0.16, 0.76, progress)
	var leap_progress := clampf((progress - 0.18) / 0.62, 0.0, 1.0)
	var arc_height := sin(leap_progress * PI) * 14.0
	var disappear := smoothstep(0.76, 1.0, progress)
	character_visual.texture = hatch_entry_texture if hatch_entry_texture != null else run_texture
	character_visual.hframes = 4
	character_visual.vframes = 2 if hatch_entry_texture != null else 4
	character_visual.frame = mini(int(floor(progress * 8.0)), 7) if hatch_entry_texture != null else (0 if progress < 0.20 else 2)
	character_visual.position = VISUAL_BASE_POSITION + hatch_entry_offset * travel + Vector2(0.0, -arc_height + disappear * 9.0)
	var vanish_scale := lerpf(1.0, 0.18, disappear)
	character_visual.scale = (HATCH_VISUAL_SCALE if hatch_entry_texture != null else RUN_VISUAL_SCALE) * vanish_scale
	character_visual.rotation = facing_direction.x * sin(leap_progress * PI) * 0.04
	character_visual.modulate = Color(0.72, 1.0, 1.0, 1.0 - disappear)


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
			attack_time_left = heavy_active_duration if attack_is_heavy else active_duration
			attack_collision.set_deferred("disabled", false)
		AttackState.ACTIVE:
			attack_state = AttackState.RECOVERY
			if attack_is_heavy:
				attack_time_left = heavy_recovery_duration
			elif combo_step == COMBO_LAST_STEP:
				attack_time_left = combo_finisher_recovery
			else:
				attack_time_left = combo_chain_recovery if combo_queued else recovery_duration
			attack_collision.set_deferred("disabled", true)
		AttackState.RECOVERY:
			if combo_queued and combo_step < COMBO_LAST_STEP:
				combo_step += 1
				combo_queued = false
				_begin_combo_swing(combo_queued_direction)
			else:
				attack_state = AttackState.READY
				attack_time_left = 0.0
				combo_step = 0
				combo_queued = false
				attack_is_heavy = false
				_restore_attack_collision_transform()
				var buffered_attack := buffered_attack_after_heavy
				var buffered_direction := buffered_attack_direction
				buffered_attack_after_heavy = 0
				if buffered_attack == 2:
					start_heavy_attack(buffered_direction)
				elif buffered_attack == 1:
					start_attack(buffered_direction)
	queue_redraw()


func _on_attack_area_entered(target: Area2D) -> void:
	_try_damage_target(target)


func _on_attack_body_entered(target: Node2D) -> void:
	_try_damage_target(target)


func _try_damage_target(target: Node2D) -> void:
	if is_dead or attack_state != AttackState.ACTIVE or target in hit_targets:
		return

	hit_targets.append(target)
	if target.has_method("take_damage"):
		var swing_damage := heavy_damage if attack_is_heavy else (combo_finisher_damage if combo_step == COMBO_LAST_STEP else attack_damage)
		var damage_applied = target.take_damage(swing_damage, facing_direction)
		if damage_applied != false:
			if attack_is_heavy:
				if target.has_method("apply_heavy_knockback"):
					target.apply_heavy_knockback(facing_direction, heavy_knockback_multiplier)
				heavy_attack_landed.emit(target.global_position)
			elif combo_step == COMBO_LAST_STEP:
				combo_finisher_landed.emit(target.global_position)
			else:
				attack_landed.emit(target.global_position)
			protocol_hit.emit(target, target.global_position, attack_serial)


func _update_character_visual(delta: float = 0.0) -> void:
	if is_dead:
		_update_death_visual()
		return
	var showing_heavy_charge := is_charging_heavy and attack_state == AttackState.READY
	var visual_is_attacking := attack_state != AttackState.READY or showing_heavy_charge
	var selected_combo_texture := _combo_texture_for_direction()
	var should_run := not visual_is_attacking and not is_dodging and velocity.length_squared() > 400.0
	if should_run != visual_is_running:
		visual_is_running = should_run
		visual_animation_frame = 0
		visual_animation_time = 0.0

	character_visual.rotation = 0.0
	if is_dodging:
		character_visual.texture = run_texture
	elif visual_is_attacking:
		character_visual.texture = selected_combo_texture if selected_combo_texture != null else attack_texture
	else:
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
	if is_dodging:
		# Visual-only impulse: physics and invulnerability keep their original timing.
		var progress := clampf(1.0 - dodge_time_left / maxf(dodge_duration, 0.001), 0.0, 1.0)
		var compression := sin(progress * PI)
		character_visual.hframes = 4
		character_visual.vframes = 4
		var dodge_frame := 0 if progress < 0.2 or progress >= 0.8 else 2
		character_visual.frame = direction_row * 4 + dodge_frame
		character_visual.scale = RUN_VISUAL_SCALE * Vector2(1.0 + 0.08 * compression, 1.0 - 0.22 * compression)
		character_visual.rotation = dodge_direction.x * 0.18 * compression
		character_visual.position = VISUAL_BASE_POSITION + RUN_FRAME_OFFSETS[direction_row][dodge_frame] + Vector2(0.0, 7.0 * compression)
	elif visual_is_attacking:
		character_visual.hframes = 4
		character_visual.vframes = 4
		var uses_combo_art := selected_combo_texture != null
		character_visual.scale = COMBO_VISUAL_SCALE if uses_combo_art else RUN_VISUAL_SCALE
		var attack_frame := 0
		if showing_heavy_charge:
			var charge_progress := clampf(heavy_charge_time / maxf(heavy_charge_threshold, 0.001), 0.0, 1.0)
			attack_frame = 0 if charge_progress < 0.55 else 1
			character_visual.scale *= 1.0 + sin(charge_progress * PI * 0.5) * 0.035
		else:
			match attack_state:
				AttackState.WINDUP:
					var current_windup := heavy_windup_duration if attack_is_heavy else windup_duration
					attack_frame = 0 if attack_time_left > current_windup * 0.5 else 1
				AttackState.ACTIVE:
					attack_frame = 2
				AttackState.RECOVERY:
					attack_frame = 3
		var visual_combo_step := COMBO_LAST_STEP if showing_heavy_charge or attack_is_heavy else combo_step
		character_visual.frame = visual_combo_step * 4 + attack_frame if uses_combo_art else direction_row * 4 + attack_frame
		character_visual.position = VISUAL_BASE_POSITION
	elif visual_is_running:
		character_visual.hframes = 4
		character_visual.vframes = 4
		character_visual.scale = RUN_VISUAL_SCALE
		var displayed_run_frame := visual_animation_frame
		if direction_row == 1 or direction_row == 3:
			displayed_run_frame = BACK_RUN_FRAME_SEQUENCE[visual_animation_frame]
		character_visual.frame = direction_row * 4 + displayed_run_frame
		character_visual.position = VISUAL_BASE_POSITION + RUN_FRAME_OFFSETS[direction_row][displayed_run_frame]
	else:
		character_visual.hframes = 2
		character_visual.vframes = 2
		character_visual.scale = IDLE_VISUAL_SCALE
		character_visual.frame = direction_row
		var breath_offset := sin(visual_breath_time * TAU * idle_breath_speed) * idle_breath_amount
		character_visual.position = VISUAL_BASE_POSITION + Vector2(0.0, breath_offset)

	if damage_flash_left > 0.0:
		# Recoil stays on the sprite, preserving movement and attack timing.
		var strength := clampf(damage_flash_left / 0.16, 0.0, 1.0)
		character_visual.position -= facing_direction * 4.0 * strength
		character_visual.rotation += sin((1.0 - strength) * TAU) * 0.12 * strength
		character_visual.modulate = Color(1.0, 0.55, 0.55)
	elif is_dodging:
		character_visual.modulate = Color(0.65, 1.0, 1.0, 0.85)
	elif showing_heavy_charge:
		var charge_glow := clampf(heavy_charge_time / maxf(heavy_charge_threshold, 0.001), 0.0, 1.0)
		character_visual.modulate = Color.WHITE.lerp(Color(0.55, 1.0, 1.0), charge_glow * 0.32)
	else:
		character_visual.modulate = Color.WHITE


func _combo_texture_for_direction() -> Texture2D:
	var faces_down := facing_direction.y >= 0.0
	if faces_down:
		return combo_texture if visual_horizontal_direction > 0 else combo_front_left_texture
	return combo_back_right_texture if visual_horizontal_direction > 0 else combo_back_left_texture


func _update_death_visual() -> void:
	var progress := clampf(death_animation_time / maxf(death_animation_duration, 0.001), 0.0, 1.0)
	var fall := progress * progress * (3.0 - 2.0 * progress)
	var direction_row := (0 if visual_horizontal_direction > 0 else 2) if facing_direction.y >= 0.0 else (1 if visual_horizontal_direction > 0 else 3)
	character_visual.texture = idle_texture
	character_visual.hframes = 2
	character_visual.vframes = 2
	character_visual.frame = direction_row
	character_visual.scale = IDLE_VISUAL_SCALE * Vector2(1.0, lerpf(1.0, 0.75, fall))
	character_visual.rotation = visual_horizontal_direction * PI * 0.48 * fall
	# Rotate around the feet instead of spinning around the sprite's center.
	character_visual.position = Vector2(0.0, 5.0) + Vector2(0.0, -34.0 * lerpf(1.0, 0.75, fall)).rotated(character_visual.rotation)
	character_visual.modulate = Color.WHITE.lerp(Color(0.45, 0.48, 0.55, 0.8), fall)


func _draw() -> void:
	# Duas camadas mantêm uma sombra suave sem separar visualmente as solas do piso.
	var shadow_center := Vector2.ZERO
	var shadow_size := 1.0
	if is_hatch_transitioning:
		var hatch_progress := clampf(hatch_entry_time / maxf(hatch_entry_duration, 0.001), 0.0, 1.0)
		shadow_center = hatch_entry_offset * smoothstep(0.18, 0.72, hatch_progress)
		shadow_size = lerpf(1.0, 0.08, smoothstep(0.62, 1.0, hatch_progress))
	# A origem fisica fica entre os pes, mas as margens transparentes das folhas
	# fazem uma sombra centrada nela parecer distante. O deslocamento aproxima a
	# elipse das solas sem mover colisao, personagem ou animacoes aprovadas.
	draw_set_transform(shadow_center + GROUND_SHADOW_OFFSET + Vector2(0.0, 1.0), 0.0, Vector2(shadow_size, 0.28 * shadow_size))
	draw_circle(Vector2.ZERO, 22.0, Color(0.0, 0.0, 0.0, 0.24))
	draw_set_transform(shadow_center + GROUND_SHADOW_OFFSET + Vector2(0.0, -1.0), 0.0, Vector2(shadow_size, 0.18 * shadow_size))
	draw_circle(Vector2.ZERO, 12.0, Color(0.0, 0.0, 0.0, 0.52))
	draw_set_transform(Vector2.ZERO)

	if is_charging_heavy and attack_state == AttackState.READY:
		var charge_progress := clampf(heavy_charge_time / maxf(heavy_charge_threshold, 0.001), 0.0, 1.0)
		var charge_angle := heavy_charge_direction.angle()
		var charge_color := Color(0.25, 0.9, 1.0, 0.35 + charge_progress * 0.55)
		draw_arc(Vector2.ZERO, lerpf(50.0, 76.0, charge_progress), charge_angle - 0.58, charge_angle + 0.58, 18, charge_color, lerpf(3.0, 8.0, charge_progress), true)
		draw_circle(heavy_charge_direction * lerpf(38.0, 54.0, charge_progress), lerpf(3.0, 7.0, charge_progress), Color(0.72, 1.0, 1.0, 0.75))

	if attack_state != AttackState.READY:
		var finisher := combo_step == COMBO_LAST_STEP or attack_is_heavy
		var attack_color := Color("7dffff") if finisher and attack_state == AttackState.ACTIVE else (Color("fff4b0") if attack_state == AttackState.ACTIVE else Color(1.0, 0.35, 0.65, 0.55))
		var direction_angle := facing_direction.angle()
		draw_arc(Vector2.ZERO, 90.0 if attack_is_heavy else (82.0 if finisher else 76.0), direction_angle - 0.52, direction_angle + 0.52, 18, attack_color, 12.0 if attack_is_heavy else (10.0 if finisher else 7.0), true)

	if is_dodging:
		var dodge_progress := clampf(1.0 - dodge_time_left / maxf(dodge_duration, 0.001), 0.0, 1.0)
		var trail_fade := pow(1.0 - dodge_progress, 0.65)
		var side_direction := Vector2(-dodge_direction.y, dodge_direction.x)
		for trail_index in range(-1, 2):
			var lateral := float(trail_index)
			var near_point := -dodge_direction * (18.0 + absf(lateral) * 3.0) + side_direction * lateral * 9.0
			var far_point := -dodge_direction * (54.0 + absf(lateral) * 6.0) + side_direction * lateral * 13.0
			var trail_alpha := trail_fade * (0.72 if trail_index == 0 else 0.42)
			var trail_width := 5.0 if trail_index == 0 else 2.5
			draw_line(far_point, near_point, Color(0.3, 1.0, 0.85, trail_alpha), trail_width, true)

		# Um crescente traseiro marca o impulso inicial sem envolver o personagem
		# como um escudo. Ele some cedo para nao competir com o Rastro Fantasma.
		var burst_fade := clampf(1.0 - dodge_progress / 0.55, 0.0, 1.0)
		if burst_fade > 0.0:
			var dodge_angle := dodge_direction.angle()
			draw_arc(
				-dodge_direction * 8.0,
				lerpf(24.0, 36.0, dodge_progress),
				dodge_angle + PI * 0.62,
				dodge_angle + PI * 1.38,
				14,
				Color(0.62, 1.0, 0.93, burst_fade * 0.75),
				3.0,
				true
			)
