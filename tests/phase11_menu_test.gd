extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _settle() -> void:
	for frame in 4:
		await process_frame

func _clear_waves(arena) -> void:
	while not arena.rooms.room_cleared:
		for enemy in get_nodes_in_group("enemy"):
			enemy.queue_free()
		await _settle()

func _run() -> void:
	var original_db := AudioServer.get_bus_volume_db(0)
	var original_mute := AudioServer.is_bus_mute(0)
	var menu = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	_assert(menu.page == "start" and menu.panel.visible, "O jogo deve iniciar no menu.")
	menu.open_details("controls")
	_assert(menu.page == "controls" and menu.return_page == "start", "Controles devem permitir voltar ao menu inicial.")
	# The protected test environment cannot write user://; use ignored project cache for this isolated persistence check.
	menu.settings_path = "res://.godot/phase11_test_preferences.cfg"
	menu.show_page("volume")
	menu.set_volume(0)
	_assert(AudioServer.is_bus_mute(0), "Volume zero deve silenciar.")
	menu.set_volume(37)
	_assert(not AudioServer.is_bus_mute(0) and absf(db_to_linear(AudioServer.get_bus_volume_db(0)) - 0.37) < 0.01, "Slider deve aplicar o volume selecionado.")
	AudioServer.set_bus_volume_db(0, 0)
	menu._load_volume()
	_assert(absf(db_to_linear(AudioServer.get_bus_volume_db(0)) - 0.37) < 0.01, "Volume salvo deve ser recarregado.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(menu.settings_path))
	menu.start_run()
	menu.start_run()
	await _settle()
	var arena = current_scene
	_assert(arena.scene_file_path == "res://scenes/main.tscn", "Iniciar deve abrir a partida uma única vez.")
	var player = arena.player
	player.start_dodge(Vector2.RIGHT)
	arena.protocols.install(1)
	arena.protocols._on_dodge()
	var dodge_before: float = player.dodge_time_left
	var ghost_before: float = arena.protocols.effects[0].time
	var position_before: Vector2 = player.position
	arena.menus.open_pause()
	await create_timer(0.15).timeout
	_assert(paused and arena.menus.panel.visible, "Pausa deve congelar a árvore de jogo.")
	_assert(player.position == position_before and player.dodge_time_left == dodge_before, "Pausa deve preservar posição e temporizador da esquiva.")
	_assert(arena.protocols.effects[0].time == ghost_before, "Explosões pendentes devem congelar durante pausa.")
	arena.menus.open_details("controls")
	arena.menus.show_page("pause")
	arena.menus.resume_game()
	_assert(not paused and not arena.menus.panel.visible, "Continuar deve remover a pausa.")
	await create_timer(0.1).timeout
	_assert(player.dodge_time_left < dodge_before, "Continuar deve retomar os temporizadores.")
	await _clear_waves(arena)
	_assert(arena.upgrades.visible, "Sala limpa deve abrir seleção de protocolo.")
	arena.menus.open_pause()
	arena.menus.resume_game()
	_assert(arena.upgrades.visible and not player.controls_enabled, "Retomar durante seleção deve manter a escolha e o bloqueio de combate.")
	arena.menus.open_pause()
	arena.menus.start_run()
	await _settle()
	arena = current_scene
	_assert(not paused and arena.player.current_health == arena.player.max_health and arena.protocols.ranks == [0,0,0], "Reiniciar pela pausa deve restaurar a tentativa.")
	arena.player.receive_enemy_hit(99)
	_assert(arena.result_overlay.visible, "Derrota deve mostrar o resultado.")
	arena.menus.return_to_menu()
	await _settle()
	_assert(current_scene.scene_file_path == "res://scenes/menu.tscn" and not paused, "Resultado deve permitir retornar ao menu sem deixar pausa ativa.")
	current_scene.start_run()
	await _settle()
	arena = current_scene
	_assert(arena.rooms.room_index == 0 and get_nodes_in_group("enemy").size() == 2, "Nova partida deve iniciar limpa após voltar ao menu.")
	arena._end_run(arena.RunState.VICTORY)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_R
	key.pressed = true
	Input.parse_input_event(key)
	await _settle()
	_assert(current_scene.run_state == 0, "R deve reiniciar a partida, sem voltar ao menu inicial.")
	current_scene.queue_free()
	await _settle()
	AudioServer.set_bus_volume_db(0, original_db)
	AudioServer.set_bus_mute(0, original_mute)
	await create_timer(0.3).timeout
	if not failed:
		print("PHASE11_MENU_TEST: PASS")
	quit(1 if failed else 0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("PHASE11_MENU_TEST: " + message)
