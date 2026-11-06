extends SceneTree

var failed := false
const EXPECTED_WAVES := [[2, 3, 4], [3, 4, 5], [4, 5, 6]]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var arena = scene.instantiate()
	root.add_child(arena)
	await physics_frame
	await physics_frame
	var player = arena.get_node("Player")
	var rooms = arena.rooms
	player.current_health = 3
	player.position = Vector2(360, 0)
	_assert(not rooms.try_advance(), "A porta não pode permitir passagem com inimigos vivos.")
	_assert(not rooms.gate_collision.disabled, "A porta fechada deve ter colisão.")
	for enemy in get_nodes_in_group("enemy"):
		enemy.set_physics_process(false)
	player.start_dodge(Vector2.RIGHT)
	for frame in 14:
		await physics_frame
	_assert(player.position.x < 385.0, "A esquiva não deve atravessar a porta fechada.")
	for room_index in 3:
		_assert(rooms.room_index == room_index, "A ordem das salas deve ser preservada.")
		var projectile = load("res://scenes/enemy_projectile.tscn").instantiate()
		projectile.position = Vector2(0, -250)
		arena.add_child(projectile)
		for expected_size in EXPECTED_WAVES[room_index]:
			_assert(get_nodes_in_group("enemy").size() == expected_size, "Cada onda deve ter a composição planejada.")
			for enemy in get_nodes_in_group("enemy"):
				enemy.set_physics_process(false)
				enemy.queue_free()
			await process_frame
			await process_frame
			await physics_frame
		_assert(rooms.room_cleared, "A sala deve liberar após o último inimigo.")
		_assert(get_nodes_in_group("enemy_projectile").is_empty(), "Projéteis antigos devem ser removidos.")
		_assert(not rooms.try_advance(), "A porta deve aguardar a escolha da melhoria.")
		_assert(arena.upgrades.choose(1), "Cada sala deve permitir uma escolha.")
		_assert(arena.run_state == 0, "Salas intermediárias não devem dar vitória.")
		player.position = Vector2.ZERO
		_assert(not rooms.try_advance(), "A passagem exige proximidade da porta.")
		player.position = Vector2(400, 0)
		player.start_attack(Vector2.RIGHT)
		arena._start_hit_stop(0.045)
		_assert(rooms.try_advance(), "Porta liberada deve permitir transição.")
		_assert(not rooms.try_advance(), "Entrada repetida não pode pular salas.")
		await process_frame
		await physics_frame
		_assert(player.current_health == 3, "A passagem deve preservar a vida restante.")
		_assert(player.position.distance_to(Vector2(-320, 0)) < 1.0, "Entrada deve posicionar o jogador em local seguro.")
		_assert(player.hit_targets.is_empty() and player.attack_state == player.AttackState.READY, "Ataques e referências antigas devem ser limpos.")
		_assert(arena.frozen_nodes.is_empty() and player.is_physics_processing(), "A transição deve limpar a pausa de impacto.")
		_assert(arena.get_node_or_null("TrainingTarget") == null, "O alvo de treino deve ficar somente na primeira sala.")
	_assert(rooms.room_index == 3 and is_instance_valid(rooms.boss), "A última porta deve levar ao chefe.")
	_assert(get_nodes_in_group("enemy").size() == 3, "O encontro final deve conter o chefe e dois guardas.")
	_assert(arena.run_state == 0 and not rooms.try_advance(), "O chefe vivo deve impedir vitória e passagem.")
	for enemy in get_nodes_in_group("enemy"):
		if enemy != rooms.boss:
			enemy.take_damage(999, Vector2.RIGHT)
	await process_frame
	rooms.boss.take_damage(12, Vector2.RIGHT)
	await process_frame
	_assert(get_nodes_in_group("enemy").size() == 3, "Ao perder um terço da vida, o chefe deve repor dois guardas.")
	var boss_projectile = load("res://scenes/enemy_projectile.tscn").instantiate()
	boss_projectile.position = Vector2(0, -250)
	arena.add_child(boss_projectile)
	rooms.boss.take_damage(999, Vector2.RIGHT)
	await process_frame
	await process_frame
	_assert(arena.run_state == 0, "Guardas vivos devem impedir vitória mesmo após derrotar o chefe.")
	_assert(get_nodes_in_group("enemy_projectile").is_empty(), "Morte do chefe deve limpar seus projéteis.")
	for enemy in get_nodes_in_group("enemy"):
		enemy.take_damage(999, Vector2.RIGHT)
	await process_frame
	await process_frame
	_assert(arena.run_state == 1, "Vitória deve ocorrer somente após o encontro final.")
	_assert(not rooms.try_advance(), "A vitória não pode iniciar outra sala.")
	var final_position: Vector2 = player.position
	Input.action_press("move_right")
	for frame in 4:
		await physics_frame
	Input.action_release("move_right")
	_assert(player.position == final_position, "O resultado deve bloquear o movimento.")
	arena.queue_free()
	await process_frame
	var restarted = scene.instantiate()
	root.add_child(restarted)
	await physics_frame
	_assert(restarted.rooms.room_index == 0 and not restarted.rooms.room_cleared, "Reiniciar deve restaurar a primeira sala fechada.")
	_assert(restarted.player.current_health == restarted.player.max_health, "Reiniciar deve restaurar a vida.")
	restarted.player.receive_enemy_hit(99)
	_assert(restarted.run_state == 2 and not restarted.rooms.try_advance(), "A derrota deve impedir transições.")
	restarted.queue_free()
	await process_frame
	if not failed:
		print("PHASE8_ROOMS_TEST: PASS")
	quit(1 if failed else 0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("PHASE8_ROOMS_TEST: " + message)
