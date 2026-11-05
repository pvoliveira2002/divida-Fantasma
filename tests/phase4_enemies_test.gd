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

	var player = main.get_node("Player")
	var melee = main.get_node("MeleeEnemy")
	var ranged = main.get_node("RangedEnemy")
	_assert(player != null and melee != null and ranged != null, "Os dois inimigos e o jogador devem existir.")

	player.position = Vector2.ZERO
	melee.position = Vector2(65, 0)
	melee.state = 0
	melee.start_windup()
	_assert(melee.is_telegraphing(), "O ataque corpo a corpo deve começar com sinalização.")
	var hits_before: int = player.debug_hits_received
	for _frame in 38:
		await physics_frame
	_assert(player.debug_hits_received == hits_before + 1, "O ataque corpo a corpo sinalizado deve causar um impacto.")

	melee.set_physics_process(false)
	melee.position = Vector2(70, 0)
	var melee_health_before: int = melee.health
	player.start_attack(Vector2.RIGHT)
	for _frame in 20:
		await physics_frame
	_assert(melee.health == melee_health_before - 1, "O ataque do jogador deve ferir o inimigo físico uma vez.")

	ranged.position = Vector2(300, 0)
	ranged.state = 0
	ranged.start_windup()
	_assert(ranged.is_telegraphing(), "O tiro deve começar com uma linha de mira sinalizada.")
	for _frame in 48:
		await physics_frame
	_assert(get_nodes_in_group("enemy_projectile").size() >= 1, "O atirador deve criar um projétil após a sinalização.")

	# Integração real entre projétil e invulnerabilidade da esquiva.
	var projectile_scene := load("res://scenes/enemy_projectile.tscn") as PackedScene
	var test_projectile = projectile_scene.instantiate()
	var hits_before_dodge: int = player.debug_hits_received
	var original_dodge_speed: float = player.dodge_speed
	player.dodge_speed = 0.0
	player.dodge_cooldown_left = 0.0
	player.attack_state = 0
	_assert(player.start_dodge(Vector2.UP), "A esquiva de teste deve iniciar.")
	main.add_child(test_projectile)
	test_projectile.global_position = player.global_position
	test_projectile.setup(Vector2.RIGHT)
	for _frame in 3:
		await physics_frame
	_assert(player.debug_hits_received == hits_before_dodge, "Um projétil não deve causar impacto durante a invulnerabilidade da esquiva.")
	player.dodge_speed = original_dodge_speed

	if failed:
		quit(1)
	else:
		print("PHASE4_ENEMIES_TEST: PASS")
		quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PHASE4_ENEMIES_TEST: " + message)
