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

	# Derrota ao perder toda a vida.
	var defeat_run = main_scene.instantiate()
	root.add_child(defeat_run)
	await physics_frame
	await physics_frame
	var defeat_player = defeat_run.get_node("Player")
	for _hit in defeat_player.max_health:
		defeat_player.receive_enemy_hit(1)
	_assert(defeat_player.current_health == 0, "A vida deve chegar a zero.")
	_assert(defeat_player.is_dead, "O jogador deve entrar no estado de morte.")
	_assert(defeat_run.run_state == 2, "A arena deve entrar no estado de derrota.")
	_assert(defeat_run.get_node("Interface/ResultOverlay").visible, "A tela de resultado deve aparecer na derrota.")

	defeat_run.queue_free()
	await process_frame
	await physics_frame

	# Vitória ao remover todos os inimigos que contam para o combate.
	var victory_run = main_scene.instantiate()
	root.add_child(victory_run)
	await physics_frame
	await physics_frame
	for enemy in get_nodes_in_group("enemy"):
		enemy.queue_free()
	await process_frame
	await process_frame
	_assert(victory_run.run_state == 1, "A arena deve entrar no estado de vitória.")
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
