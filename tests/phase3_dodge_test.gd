extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var player_scene := load("res://scenes/player.tscn") as PackedScene
	_assert(player_scene != null, "A cena do personagem deve carregar.")
	if player_scene == null:
		quit(1)
		return

	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main := main_scene.instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame

	var player = main.get_node("Player")
	player.position = Vector2.ZERO
	var dodge_started: bool = player.start_dodge(Vector2.RIGHT)
	_assert(dodge_started, "A primeira esquiva deve iniciar.")
	_assert(player.is_invulnerable(), "A esquiva deve conceder invulnerabilidade quando configurada.")
	_assert(not player.start_dodge(Vector2.RIGHT), "Não deve ser possível repetir a esquiva imediatamente.")

	for _frame in 14:
		await physics_frame

	_assert(player.position.x > 70.0, "A esquiva deve deslocar o personagem.")
	_assert(not player.is_invulnerable(), "A invulnerabilidade deve terminar junto com a esquiva.")
	_assert(not player.start_dodge(Vector2.RIGHT), "A recarga deve continuar após o fim do impulso.")

	for _frame in 24:
		await physics_frame

	player.position = Vector2(500, 0)
	_assert(player.start_dodge(Vector2.RIGHT), "A esquiva deve voltar após a recarga.")
	for _frame in 14:
		await physics_frame
	_assert(player.position.x < 540.0, "A esquiva não deve atravessar a borda da arena.")

	if failed:
		quit(1)
	else:
		print("PHASE3_DODGE_TEST: PASS")
		quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PHASE3_DODGE_TEST: " + message)
