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

	for frame in 20:
		await physics_frame

	_assert(target.current_health == initial_health - 1, "Um golpe deve causar exatamente um ponto de dano.")
	_assert(target.hit_count == 1, "O mesmo golpe não pode acertar o alvo mais de uma vez.")

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
