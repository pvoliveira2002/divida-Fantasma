extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arena = load("res://scenes/main.tscn").instantiate()
	root.add_child(arena)
	await physics_frame
	arena.rooms.set_process(false)
	for enemy in get_nodes_in_group("enemy"):
		enemy.queue_free()
	await process_frame
	var player = arena.player
	player.set_physics_process(false)
	player.max_health = 50
	player.current_health = 50
	var boss = load("res://scenes/boss.tscn").instantiate()
	arena.add_child(boss)
	boss.set_physics_process(false)
	boss.position = Vector2.ZERO
	player.position = Vector2(80, 0)
	var boss_visual := boss.get_node_or_null("CharacterVisual") as Sprite2D
	_assert(boss_visual != null and boss_visual.texture != null, "O Cobrador deve carregar seu visual direcional.")
	var plasma_shield := boss.get_node_or_null("PlasmaShield") as Node2D
	_assert(plasma_shield != null and plasma_shield.get_script() != null and plasma_shield.z_index > boss_visual.z_index, "O escudo de plasma deve carregar acima do personagem.")
	var visual_test_position: Vector2 = boss.position
	var visual_directions := [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	var visual_expected_frames := [0, 4, 8, 12]
	for direction_index in visual_directions.size():
		boss.facing_direction = visual_directions[direction_index]
		boss._update_character_visual()
		_assert(boss_visual.frame == visual_expected_frames[direction_index], "O Cobrador deve selecionar a vista correta para cada direcao.")
	_assert(boss_visual.texture == boss.idle_texture, "O Cobrador parado deve usar sua animacao pesada.")
	boss.velocity = Vector2.RIGHT * boss.move_speed
	boss._update_character_visual(0.25)
	_assert(boss_visual.texture == boss.walk_texture and boss_visual.frame % 4 > 0, "O Cobrador em movimento deve usar passos pesados.")
	var animated_cell_size: Vector2 = Vector2(boss_visual.texture.get_size()) / 4.0 * boss_visual.scale
	boss.state = boss.State.WINDUP
	boss._update_character_visual()
	var attack_cell_size: Vector2 = Vector2(boss_visual.texture.get_size()) / 4.0 * boss_visual.scale
	_assert(animated_cell_size.is_equal_approx(attack_cell_size), "Parado, caminhada e ataque devem preservar o mesmo tamanho aparente.")
	for attack_kind in [boss.Attack.VOLLEY, boss.Attack.DASH, boss.Attack.SLAM]:
		boss.attack = attack_kind
		boss.state = boss.State.WINDUP
		boss.state_time = boss.windup_duration * 0.4
		boss._update_character_visual()
		var expected_texture: Texture2D = [boss.volley_texture, boss.dash_texture, boss.slam_texture][attack_kind]
		_assert(boss_visual.texture == expected_texture and boss_visual.frame % 4 == 1, "Cada ataque deve ter uma preparacao visual propria.")
		boss.state = boss.State.DASHING if attack_kind == boss.Attack.DASH else boss.State.RECOVERY
		boss.state_time = boss.dash_duration if attack_kind == boss.Attack.DASH else boss.recovery_duration
		boss._update_character_visual()
		_assert(boss_visual.frame % 4 == 2, "O quadro de contato deve coincidir com a execucao do ataque.")
	_assert(boss.position == visual_test_position, "A troca de vista do Cobrador nao deve mover seu corpo fisico.")
	boss.state = boss.State.APPROACH
	boss.velocity = Vector2.ZERO
	var reinforcement_stages: Array[int] = []
	boss.reinforcement_requested.connect(func(stage: int) -> void: reinforcement_stages.append(stage))
	boss.take_damage(12)
	_assert(reinforcement_stages == [1], "O chefe deve solicitar reforços ao chegar a dois terços da vida.")
	boss.take_damage(12)
	_assert(reinforcement_stages == [1, 2], "O chefe deve solicitar nova escolta ao chegar a um terço da vida.")
	boss.health = boss.max_health
	boss.reinforcement_stage = 0
	boss.enraged = false
	_assert(boss.start_attack(boss.Attack.SLAM), "O chefe deve preparar o golpe de área.")
	var health_before: int = player.current_health
	boss._physics_process(0.4)
	_assert(boss.state == boss.State.WINDUP and player.current_health == health_before, "A preparação não deve causar dano.")
	boss._physics_process(0.5)
	_assert(player.current_health == health_before - 1, "O golpe de área deve causar um dano após o aviso.")
	boss._physics_process(0.1)
	_assert(player.current_health == health_before - 1, "O golpe não pode repetir dano durante recuperação.")
	_assert(boss.state == boss.State.RECOVERY and boss.state_time > 0.7, "Deve existir janela clara de contra-ataque.")
	boss.state = boss.State.APPROACH
	boss.start_attack(boss.Attack.SLAM)
	player.dodge_cooldown_left = 0
	player.start_dodge(Vector2.RIGHT)
	boss._physics_process(0.9)
	_assert(player.current_health == health_before - 1, "A esquiva deve proteger contra o golpe de área.")
	player.reset_combat_pose()
	boss.state = boss.State.APPROACH
	boss.start_attack(boss.Attack.VOLLEY)
	var locked: Vector2 = boss.locked_direction
	player.position = Vector2(0, 150)
	boss._physics_process(0.4)
	_assert(get_nodes_in_group("enemy_projectile").is_empty(), "O leque não deve disparar antes do aviso.")
	boss._physics_process(0.5)
	_assert(get_nodes_in_group("enemy_projectile").size() == 3, "O leque deve disparar exatamente três projéteis.")
	_assert(boss.locked_direction == locked, "A mira não deve perseguir o jogador depois de sinalizada.")
	for boss_projectile in get_nodes_in_group("enemy_projectile"):
		_assert(boss_projectile.blue_plasma and not boss_projectile.get_node("Polygon2D").visible, "As tres rajadas do chefe devem usar plasma azul com rastro proprio.")
		_assert(is_equal_approx(boss_projectile.speed, 270.0), "O plasma do chefe deve usar a velocidade moderadamente aumentada.")
	for projectile in get_nodes_in_group("enemy_projectile"):
		projectile.queue_free()
	await process_frame
	boss.state = boss.State.APPROACH
	boss.position = Vector2.ZERO
	player.position = Vector2(60, 0)
	boss.start_attack(boss.Attack.DASH)
	boss._physics_process(0.9)
	_assert(boss.state == boss.State.DASHING, "A investida deve começar somente após o aviso.")
	health_before = player.current_health
	_assert(not get_nodes_in_group("boss_attack_effect").is_empty(), "Os ataques do Cobrador devem criar particulas visuais.")
	var shoulder_sparks_found := false
	for attack_effect in get_nodes_in_group("boss_attack_effect"):
		if attack_effect.effect == attack_effect.Effect.SHOULDER:
			shoulder_sparks_found = true
	_assert(shoulder_sparks_found, "A ombrada deve criar uma rajada propria de faiscas no ombro.")
	for frame in 30:
		boss._physics_process(1.0 / 60.0)
	_assert(player.current_health == health_before - 1, "A investida deve atingir uma única vez por ativação.")
	boss.state = boss.State.APPROACH
	boss.position = Vector2(470, 0)
	player.position = Vector2(650, 0)
	boss.start_attack(boss.Attack.DASH)
	boss._physics_process(0.9)
	for frame in 30:
		boss._physics_process(1.0 / 60.0)
	_assert(boss.position.x < 520.0, "A investida não pode atravessar a borda da arena.")
	boss.take_damage(18)
	_assert(not boss.enraged, "Metade exata da vida ainda não ativa a segunda fase.")
	boss.take_damage(1)
	_assert(boss.enraged, "Abaixo de metade da vida deve ativar a segunda fase.")
	boss._enter_recovery()
	_assert(is_equal_approx(boss.state_time, boss.recovery_duration * 0.65), "A segunda fase deve reduzir a recuperação sem removê-la.")
	_assert(is_equal_approx(boss.windup_duration, 0.75), "A segunda fase deve preservar o tempo de aviso.")
	# Protocol damage uses the same enemy contract as basic attacks.
	boss.position = Vector2(60, 0)
	player.position = Vector2.ZERO
	player.facing_direction = Vector2.RIGHT
	player.reset_combat_pose()
	arena.protocols.install(2)
	for index in 4:
		player.reset_combat_pose()
		player.start_attack(Vector2.RIGHT)
		player.attack_state = player.AttackState.ACTIVE
		player._try_damage_target(boss)
		player._try_damage_target(boss)
		arena._finish_hit_stop()
	_assert(boss.health == 11, "Quatro socos e uma onda devem remover seis pontos de vida do chefe.")
	boss.take_damage(99)
	_assert(boss.state == boss.State.DEAD and not boss.take_damage(1), "Chefe derrotado não deve receber dano duplicado.")
	_assert(boss.collision_layer == 0 and boss.collision_mask == 0, "A derrota deve desativar a colisão do chefe imediatamente.")
	boss._physics_process(0.1)
	_assert(is_instance_valid(boss) and boss.death_animation_time > 0.0, "O chefe deve permanecer brevemente para exibir sua destruição.")
	boss._physics_process(boss.death_animation_duration)
	await process_frame
	_assert(not is_instance_valid(boss), "O chefe deve sair da cena ao terminar a animação de destruição.")
	var surviving_boss = load("res://scenes/boss.tscn").instantiate()
	arena.add_child(surviving_boss)
	player.receive_enemy_hit(999)
	_assert(arena.run_state == 2 and not surviving_boss.is_physics_processing(), "A derrota deve congelar o chefe imediatamente.")
	arena.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	if not failed:
		print("PHASE10_BOSS_TEST: PASS")
	quit(1 if failed else 0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("PHASE10_BOSS_TEST: " + message)
