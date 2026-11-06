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
	var scene := load("res://scenes/main.tscn") as PackedScene
	var arena = scene.instantiate()
	root.add_child(arena)
	await physics_frame
	var player = arena.player
	var upgrades = arena.upgrades
	_assert(not upgrades.offer(0), "Não deve haver recompensa antes de limpar a sala.")
	var original_cooldown: float = player.dodge_cooldown
	var original_invulnerability_duration: float = player.dodge_duration
	for room_index in 3:
		await _clear_waves(arena)
		_assert(upgrades.visible and upgrades.pending_room == room_index, "Limpar a sala deve abrir três opções.")
		_assert(not player.controls_enabled, "A seleção deve bloquear controles de combate.")
		_assert(not player.start_attack(Vector2.RIGHT) and not player.start_dodge(Vector2.RIGHT), "Ataque e esquiva não podem ocorrer durante seleção.")
		var position_before: Vector2 = player.position
		Input.action_press("move_right")
		await physics_frame
		await physics_frame
		Input.action_release("move_right")
		_assert(player.position == position_before, "O personagem deve ficar parado durante seleção.")
		_assert(not upgrades.choose(-1) and not upgrades.choose(3), "Opções inválidas não devem consumir a recompensa.")
		var choice := 0 if room_index < 2 else 2
		if room_index == 0:
			upgrades.buttons[choice].pressed.emit()
			_assert(upgrades.pending_room == -1, "O cartão deve instalar o protocolo correspondente.")
		else:
			_assert(upgrades.choose(choice), "A escolha válida deve aplicar o bônus.")
		_assert(not upgrades.choose(choice) and not upgrades.offer(room_index), "A mesma recompensa não pode ser aplicada duas vezes.")
		_assert(upgrades.ranks[0] == mini(room_index + 1, 2), "Repetir uma melhoria em salas distintas deve acumular níveis.")
		_assert(arena.protocols.ranks == upgrades.ranks, "Níveis instalados devem corresponder às escolhas.")
		_assert(player.attack_damage == 1, "Protocolos não devem alterar o dano básico.")
		if room_index < 2:
			# Exercise upgraded damage through the actual target path, twice in one swing.
			var target = load("res://scenes/melee_enemy.tscn").instantiate()
			target.max_health = 20
			arena.add_child(target)
			target.set_physics_process(false)
			player.attack_state = player.AttackState.ACTIVE
			player.hit_targets.clear()
			player._try_damage_target(target)
			player._try_damage_target(target)
			_assert(target.health == 20 - player.attack_damage, "Dano melhorado deve ocorrer uma única vez por golpe.")
			target.queue_free()
			await process_frame
			player.position = Vector2(400, 0)
			_assert(arena.rooms.try_advance(), "A escolha deve liberar a passagem.")
			await process_frame
			await physics_frame
			_assert(arena.protocols.ranks == upgrades.ranks, "Protocolos devem permanecer entre salas.")
	_assert(is_equal_approx(player.dodge_cooldown, original_cooldown), "Protocolos não devem alterar a recarga básica.")
	_assert(player.dodge_duration == original_invulnerability_duration, "A duração de invulnerabilidade não deve aumentar.")
	_assert(arena.run_state == 0 and not upgrades.visible and arena.rooms.reward_selected, "Após a última escolha deve liberar o caminho para o chefe.")
	arena.queue_free()
	await process_frame
	arena = scene.instantiate()
	root.add_child(arena)
	await physics_frame
	_assert(arena.upgrades.ranks == [0, 0, 0] and arena.upgrades.rewarded_rooms.is_empty(), "Nova tentativa deve remover níveis e recompensas antigas.")
	_assert(arena.protocols.ranks == [0, 0, 0], "Reiniciar deve remover todos os protocolos.")
	_assert(arena.player.attack_damage == 1 and is_equal_approx(arena.player.dodge_cooldown, original_cooldown), "Nova tentativa deve restaurar atributos básicos.")
	await _clear_waves(arena)
	var recovery_before: float = arena.player.recovery_duration
	# Exercise the real keyboard selection path.
	var key := InputEventKey.new()
	key.physical_keycode = KEY_2
	key.pressed = true
	arena.upgrades._unhandled_input(key)
	await process_frame
	_assert(arena.protocols.ranks[1] == 1, "Tecla 2 deve instalar Rastro Fantasma.")
	_assert(is_equal_approx(arena.player.recovery_duration, recovery_before), "Instalar protocolo não altera o tempo básico de ataque.")
	arena.player.receive_enemy_hit(99)
	_assert(not arena.upgrades.offer(1) and not arena.upgrades.choose(0), "Derrota não pode conceder melhorias.")
	arena.queue_free()
	await process_frame
	if not failed:
		print("PHASE9_UPGRADES_TEST: PASS")
	quit(1 if failed else 0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("PHASE9_UPGRADES_TEST: " + message)
