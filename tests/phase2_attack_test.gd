extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	_assert(main_scene != null, "A cena principal deve carregar.")
	if main_scene == null:
		quit(1)
		return

	var main := main_scene.instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame

	var player := main.get_node_or_null("Player")
	var target := main.get_node_or_null("TrainingTarget")
	_assert(player != null, "O personagem deve existir.")
	_assert(target != null, "O alvo de treinamento deve existir.")
	if player == null or target == null:
		quit(1)
		return

	player.position = Vector2.ZERO
	target.position = Vector2(70, 0)
	var initial_health: int = target.current_health
	var attack_started: bool = player.start_attack(Vector2.RIGHT)
	var repeated_attack_blocked: bool = not player.start_attack(Vector2.RIGHT)
	_assert(attack_started, "O primeiro ataque deve iniciar.")
	_assert(repeated_attack_blocked, "Um novo ataque deve ser bloqueado durante o intervalo atual.")
	_assert(player.combo_chain_recovery < player.recovery_duration, "Uma sequencia preparada deve recuperar mais rapido que um golpe isolado.")

	for frame in 20:
		await physics_frame

	_assert(target.current_health == initial_health - 1, "Um golpe deve causar exatamente um ponto de dano.")
	_assert(target.hit_count == 1, "O mesmo golpe não pode acertar o alvo mais de uma vez.")

	for _frame in 30:
		if player.attack_state == player.AttackState.READY:
			break
		await physics_frame
	_assert(player.attack_state == player.AttackState.READY, "O golpe isolado deve encerrar antes do teste do combo.")

	target.max_health = 10
	target.current_health = 10
	target.hit_count = 0
	var player_visual := player.get_node("CharacterVisual") as Sprite2D
	_assert(player.start_attack(Vector2(1.0, 0.35)), "O primeiro golpe do combo deve iniciar.")
	for expected_step in 4:
		_assert(player.combo_step == expected_step, "O combo deve avancar exatamente um estagio por entrada valida.")
		player._update_character_visual()
		_assert(player_visual.texture == player.combo_texture and player_visual.frame / 4 == expected_step, "A direcao frontal direita deve usar a linha visual correspondente ao golpe atual.")
		_assert(not player_visual.flip_h, "A folha do combo nao pode ser espelhada nem trocar o braco cibernetico.")
		if expected_step < 3:
			for _frame in 20:
				if player.attack_state == player.AttackState.ACTIVE:
					break
				await physics_frame
			_assert(player.start_attack(Vector2(1.0, 0.35)), "Uma entrada durante o impacto deve preparar o proximo golpe.")
			for _frame in 40:
				if player.combo_step == expected_step + 1:
					break
				await physics_frame
	for _frame in 50:
		if player.attack_state == player.AttackState.READY:
			break
		await physics_frame
	_assert(target.hit_count == 4, "Os quatro golpes devem acertar o alvo uma unica vez cada.")
	_assert(target.current_health == 5, "Os tres primeiros golpes devem causar um dano e o finalizador deve causar dois.")
	_assert(player.combo_step == 0 and not player.combo_queued, "O combo deve voltar ao primeiro golpe quando a sequencia termina.")
	_assert(player.start_attack(Vector2.LEFT), "Um novo ataque deve continuar disponivel em outras direcoes.")
	player._update_character_visual()
	_assert(player_visual.texture == player.combo_front_left_texture, "O ataque para a esquerda deve usar sua folha propria do combo.")
	player.reset_combat_pose()

	# O fim da preparacao aceita a proxima entrada sem permitir que dois cliques
	# imediatos pulem a leitura do primeiro golpe.
	_assert(player.start_attack(Vector2.RIGHT), "O teste do buffer deve iniciar um golpe limpo.")
	player.attack_time_left = player.combo_input_buffer_window
	_assert(player.start_attack(Vector2.RIGHT) and player.combo_queued, "A janela final da preparacao deve guardar o proximo golpe.")
	player.attack_state = player.AttackState.ACTIVE
	player.attack_time_left = 0.0
	player._update_attack(0.0)
	_assert(is_equal_approx(player.attack_time_left, player.combo_chain_recovery), "Um golpe enfileirado deve usar a recuperacao curta do combo.")
	player.reset_combat_pose()

	main.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	if failed:
		quit(1)
	else:
		print("PHASE2_ATTACK_TEST: PASS")
		quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PHASE2_ATTACK_TEST: " + message)
