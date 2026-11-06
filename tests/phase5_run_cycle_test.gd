extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _clear_waves(arena) -> void:
	while not arena.rooms.room_cleared:
		for enemy in get_nodes_in_group("enemy"):
			enemy.queue_free()
		await process_frame
		await process_frame
		await physics_frame


func _run() -> void:
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	_assert(main_scene != null, "A cena principal deve carregar.")
	if main_scene == null:
		quit(1)
		return

	# Derrota ao perder toda a vida.
	var defeat_run = main_scene.instantiate()
	root.add_child(defeat_run)
	await physics_frame
	await physics_frame
	var defeat_player = defeat_run.get_node("Player")
	var sprite := defeat_player.get_node("CharacterVisual") as Sprite2D
	var body_position: Vector2 = defeat_player.position
	_assert(defeat_player.receive_enemy_hit(1), "O primeiro dano deve ser aplicado.")
	_assert(sprite.modulate.g < 1.0, "O dano deve produzir feedback visual imediatamente.")
	_assert(defeat_player.position == body_position, "O recuo visual não deve mover o corpo físico.")
	for _frame in 14:
		await physics_frame
	_assert(sprite.modulate == Color.WHITE, "O visual deve recuperar a cor após o dano.")
	_assert(is_zero_approx(sprite.rotation), "A reação ao dano não deve deixar inclinação residual.")
	_assert(defeat_player.start_attack(Vector2.RIGHT), "O dano não deve bloquear novos ataques.")
	for _hit in range(defeat_player.current_health):
		defeat_player.receive_enemy_hit(1)
	_assert(defeat_player.current_health == 0, "A vida deve chegar a zero.")
	_assert(defeat_player.is_dead, "O jogador deve entrar no estado de morte.")
	_assert(defeat_run.run_state == 2, "A arena deve entrar no estado de derrota.")
	_assert(defeat_run.get_node("Interface/ResultOverlay").visible, "A tela de resultado deve aparecer na derrota.")
	_assert(defeat_player.attack_state == defeat_player.AttackState.READY, "A morte deve cancelar o golpe em andamento.")
	_assert(not defeat_player.start_attack(Vector2.RIGHT), "O jogador morto não deve atacar.")
	_assert(not defeat_player.start_dodge(Vector2.RIGHT), "O jogador morto não deve esquivar.")
	_assert(not defeat_player.receive_enemy_hit(1), "O jogador morto não deve receber novo dano.")
	var death_position: Vector2 = defeat_player.position
	for _frame in 35:
		await physics_frame
	_assert(absf(sprite.rotation) > 1.0, "A animação de queda deve avançar mesmo após a derrota.")
	_assert(defeat_player.position == death_position, "A queda não deve mover o corpo físico.")
	_assert(defeat_player.get_node("AttackArea/CollisionShape2D").disabled, "A colisão de ataque deve permanecer desligada após a morte.")
	var fallen_position: Vector2 = sprite.position
	for _frame in 4:
		await physics_frame
	_assert(sprite.position.is_equal_approx(fallen_position), "A pose final de morte deve permanecer estável.")

	defeat_run.queue_free()
	await process_frame
	await physics_frame

	# Vitória ao remover todos os inimigos que contam para o combate.
	var victory_run = main_scene.instantiate()
	root.add_child(victory_run)
	await physics_frame
	await physics_frame
	for room_index in 3:
		await _clear_waves(victory_run)
		_assert(victory_run.upgrades.choose(1), "Cada sala deve oferecer uma melhoria antes de continuar.")
		if room_index < 3:
			_assert(victory_run.run_state == 0, "Limpar uma sala intermediária não deve encerrar a tentativa.")
			victory_run.get_node("Player").position = Vector2(400, 0)
			_assert(victory_run.rooms.try_advance(), "A porta liberada deve permitir avançar.")
			await process_frame
			await physics_frame
	_assert(victory_run.run_state == 0, "As três salas devem levar ao chefe, sem vitória antecipada.")
	for enemy in get_nodes_in_group("enemy"):
		enemy.take_damage(999, Vector2.RIGHT)
	await process_frame
	await process_frame
	_assert(victory_run.run_state == 1, "Derrotar o encontro final deve dar vitória.")
	_assert(victory_run.get_node("Interface/ResultOverlay").visible, "A tela de resultado deve aparecer na vitória.")

	victory_run.queue_free()
	await process_frame
	await physics_frame

	# Uma nova instância representa o estado limpo obtido pelo reinício da cena.
	var restarted_run = main_scene.instantiate()
	root.add_child(restarted_run)
	await physics_frame
	await physics_frame
	var restarted_player = restarted_run.get_node("Player")
	_assert(restarted_player.current_health == restarted_player.max_health, "Uma nova tentativa deve restaurar toda a vida.")
	_assert(get_nodes_in_group("enemy").size() == 2, "Uma nova tentativa deve restaurar os dois inimigos.")
	_assert(restarted_run.run_state == 0, "Uma nova tentativa deve começar em andamento.")
	_assert(not restarted_player.is_dead and restarted_player.death_animation_time == 0.0, "O reinício deve limpar a animação de morte.")
	_assert(is_zero_approx(restarted_player.get_node("CharacterVisual").rotation), "O reinício deve restaurar a postura normal.")

	if failed:
		quit(1)
	else:
		print("PHASE5_RUN_CYCLE_TEST: PASS")
		quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PHASE5_RUN_CYCLE_TEST: " + message)
