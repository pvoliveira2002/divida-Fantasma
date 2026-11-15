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
	_assert(player != null and target != null, "Jogador e alvo de treino devem existir.")
	if player == null or target == null:
		quit(1)
		return

	player.position = Vector2.ZERO
	target.position = Vector2(82.0, 0.0)
	target.max_health = 20
	target.current_health = 20
	target.hit_count = 0
	var heavy_impacts := [0]
	player.heavy_attack_landed.connect(func(_position: Vector2): heavy_impacts[0] += 1)

	_assert(player.begin_attack_charge(Vector2.RIGHT), "M1 pressionado deve iniciar a carga em postura livre.")
	player.velocity = Vector2(80.0, 40.0)
	player.heavy_charge_time = player.heavy_charge_threshold
	_assert(player.release_attack_charge(Vector2.RIGHT), "Soltar uma carga completa deve iniciar o golpe pesado.")
	_assert(player.attack_is_heavy and player.attack_state == player.AttackState.WINDUP, "A carga completa deve selecionar o ataque pesado.")
	_assert(player.velocity == Vector2.ZERO, "Soltar o pesado deve eliminar a velocidade antiga da carga.")
	_assert(player.attack_collision.scale.x > player.attack_collision_base_scale.x, "O pesado deve possuir alcance maior que o golpe leve.")

	for _frame in 20:
		if player.attack_state == player.AttackState.RECOVERY:
			break
		await physics_frame
	Input.action_press("move_up")
	for _frame in 3:
		await physics_frame
	Input.action_release("move_up")
	_assert(player.velocity.y < 0.0 and absf(player.velocity.x) < 0.01, "A recuperacao deve responder a uma nova direcao sem continuar o movimento antigo.")
	for _frame in 35:
		if player.attack_state == player.AttackState.READY:
			break
		await physics_frame
	_assert(target.current_health == 17 and target.hit_count == 1, "O pesado deve causar tres de dano apenas uma vez.")
	_assert(heavy_impacts[0] == 1, "O pesado deve emitir um unico impacto proprio.")
	_assert(player.attack_state == player.AttackState.READY and not player.attack_is_heavy, "O pesado deve encerrar e liberar os controles.")
	_assert(player.attack_collision.scale == player.attack_collision_base_scale, "A colisao deve voltar ao alcance normal depois do pesado.")

	# Pressionar durante a recuperacao pesada nao pode cair no buffer do combo
	# leve. O tempo segurado deve continuar decidindo o proximo ataque.
	_assert(player.start_heavy_attack(Vector2.RIGHT), "Um novo pesado direto deve iniciar o teste de encadeamento.")
	player.attack_state = player.AttackState.RECOVERY
	player.attack_time_left = 0.12
	_assert(player.begin_attack_charge(Vector2.UP), "A recuperacao pesada deve aceitar a carga do proximo golpe.")
	player.heavy_charge_time = player.heavy_charge_threshold
	_assert(player.release_attack_charge(Vector2.UP), "Soltar a segunda carga durante a recuperacao deve criar um buffer pesado.")
	_assert(player.buffered_attack_after_heavy == 2 and not player.combo_queued, "O buffer deve guardar pesado sem enfileirar um golpe leve.")
	player.attack_time_left = 0.0
	player._update_attack(0.0)
	_assert(player.attack_is_heavy and player.attack_state == player.AttackState.WINDUP, "Ao terminar a recuperacao, o segundo golpe deve continuar sendo pesado.")
	_assert(player.facing_direction.is_equal_approx(Vector2.UP), "O segundo pesado deve respeitar a nova direcao.")
	player.reset_combat_pose()

	# Um toque curto continua sendo o primeiro golpe leve do combo aprovado.
	target.current_health = 20
	target.hit_count = 0
	_assert(player.begin_attack_charge(Vector2.RIGHT), "Um novo toque deve ser aceito depois da recuperacao.")
	player.heavy_charge_time = player.heavy_charge_threshold * 0.4
	_assert(player.release_attack_charge(Vector2.RIGHT), "Soltar cedo deve iniciar o ataque leve.")
	_assert(not player.attack_is_heavy, "Um toque curto nao pode virar ataque pesado.")
	for _frame in 30:
		await physics_frame
	_assert(target.current_health == 19 and target.hit_count == 1, "O toque curto deve preservar um dano do golpe leve.")

	for _frame in 30:
		if player.attack_state == player.AttackState.READY:
			break
		await physics_frame
	player.dodge_cooldown_left = 0.0
	_assert(player.begin_attack_charge(Vector2.RIGHT), "A carga deve iniciar antes do teste de cancelamento.")
	_assert(player.start_dodge(Vector2.UP), "A esquiva deve cancelar uma carga em preparacao.")
	_assert(not player.is_charging_heavy and player.is_dodging, "Cancelar deve remover a carga e manter a esquiva.")

	main.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	if failed:
		quit(1)
	else:
		print("PHASE15_HEAVY_ATTACK_TEST: PASS")
		quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PHASE15_HEAVY_ATTACK_TEST: " + message)
