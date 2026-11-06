extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _settle() -> void:
	for frame in 4:
		await process_frame

func _key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)

func _run() -> void:
	var menu = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu.start_run()
	await _settle()
	var arena = current_scene
	for room_index in 4:
		_assert(arena.rooms.room_index == room_index, "Fluxo deve visitar todas as salas e o chefe.")
		_key(KEY_ESCAPE)
		await _settle()
		_assert(paused, "Esc deve pausar em qualquer sala.")
		_key(KEY_ESCAPE)
		await _settle()
		_assert(not paused, "Esc deve retomar em qualquer sala.")
		# Deterministic combat-path exercise; this does not measure manual difficulty.
		for enemy in get_nodes_in_group("enemy"):
			enemy.set_physics_process(false)
			while not enemy.is_queued_for_deletion():
				arena.player.reset_combat_pose()
				arena.player.start_attack(enemy.position - arena.player.position)
				arena.player.attack_state = arena.player.AttackState.ACTIVE
				arena.player._try_damage_target(enemy)
				arena._finish_hit_stop()
		await _settle()
		if room_index < 3:
			_assert(arena.upgrades.visible, "Sala normal deve oferecer protocolos.")
			_key([KEY_1, KEY_2, KEY_3][room_index])
			await _settle()
			_assert(arena.protocols.ranks[room_index] == 1, "Atalho deve instalar cada protocolo.")
			arena.player.position = Vector2(400, 0)
			_key(KEY_E)
			await _settle()
	_assert(arena.run_state == arena.RunState.VICTORY and arena.result_overlay.visible, "Derrotar encontro final deve mostrar vitória.")
	arena.menus.return_to_menu()
	await _settle()
	_assert(current_scene.page == "start", "Vitória deve permitir voltar ao início.")
	current_scene.start_run()
	await _settle()
	arena = current_scene
	_assert(arena.rooms.room_index == 0 and arena.protocols.ranks == [0,0,0], "Nova tentativa após vitória deve começar limpa.")
	arena.player.receive_enemy_hit(99)
	_assert(arena.run_state == arena.RunState.DEFEAT, "Derrota deve permanecer funcional.")
	_key(KEY_R)
	await _settle()
	_assert(current_scene.run_state == 0 and current_scene.player.current_health == 5, "R após derrota deve restaurar a partida.")
	current_scene.queue_free()
	await _settle()
	await create_timer(0.3).timeout
	if not failed:
		print("PHASE11_FULL_RUN_TEST: PASS")
	quit(1 if failed else 0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("PHASE11_FULL_RUN_TEST: " + message)
