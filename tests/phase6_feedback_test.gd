extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main = main_scene.instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame

	var player = main.get_node("Player")
	var melee = main.get_node("MeleeEnemy")
	var initial_position: Vector2 = melee.position
	melee.take_damage(1, Vector2.RIGHT)
	for _frame in 5:
		await physics_frame
	_assert(melee.position.x > initial_position.x, "O inimigo deve recuar na direção do golpe.")

	main._on_attack_landed(Vector2(40, 20))
	_assert(main.hit_stop_left > 0.0, "O acerto deve iniciar uma pausa curta de impacto.")
	_assert(main.shake_left > 0.0, "O acerto deve iniciar tremor de câmera.")
	_assert(main.get_node_or_null("HitSpark") != null, "O acerto deve criar faíscas visuais.")
	_assert(main.get_node("Audio/Hit").stream != null, "O som provisório de impacto deve existir.")

	for _frame in 8:
		await physics_frame
	_assert(main.hit_stop_left <= 0.0, "A pausa de impacto deve terminar rapidamente.")
	_assert(player.is_physics_processing(), "O jogador deve voltar a processar após a pausa.")

	if failed:
		quit(1)
	else:
		print("PHASE6_FEEDBACK_TEST: PASS")
		quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PHASE6_FEEDBACK_TEST: " + message)
