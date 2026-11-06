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
	await process_frame
	_assert(not is_instance_valid(boss), "O chefe deve sair da cena após morrer.")
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
