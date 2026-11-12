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
	var melee_visual := melee.get_node_or_null("CharacterVisual") as Sprite2D
	_assert(melee_visual != null and melee_visual.texture != null, "O Executor deve carregar seu visual direcional.")
	var ranged_visual := ranged.get_node_or_null("CharacterVisual") as Sprite2D
	_assert(ranged_visual != null and ranged_visual.texture != null, "A Auditora deve carregar seu visual direcional.")
	var expected_frames := [0, 4, 8, 12]
	var directions := [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	for index in directions.size():
		melee.facing_direction = directions[index]
		melee._update_character_visual()
		_assert(melee_visual.frame == expected_frames[index], "O Executor deve selecionar a vista correta para cada direção.")
	var position_before_animation: Vector2 = melee.position
	melee._update_character_visual(0.5)
	_assert(melee.position == position_before_animation, "A animação do Executor não deve mover seu corpo físico.")
	var ranged_expected_frames := [0, 4, 8, 12]
	for index in directions.size():
		ranged.facing_direction = directions[index]
		ranged.visual_animation_frame = 0
		ranged._update_character_visual()
		_assert(ranged_visual.frame == ranged_expected_frames[index], "A Auditora deve selecionar a vista correta para cada direção.")
	var ranged_position_before_animation: Vector2 = ranged.position
	ranged.state = ranged.State.POSITIONING
	ranged.visual_movement = ranged.VisualMovement.ADVANCE
	ranged._update_character_visual(0.25)
	_assert(ranged_visual.texture == ranged.advance_texture, "A Auditora deve usar avanço quando se aproxima do jogador.")
	ranged.visual_movement = ranged.VisualMovement.RETREAT
	ranged._update_character_visual(0.25)
	_assert(ranged_visual.texture == ranged.backpedal_texture, "A Auditora deve usar passos para trás quando recua do jogador.")
	_assert(ranged.position == ranged_position_before_animation, "As animações da Auditora não devem mover seu corpo físico.")

	player.position = Vector2.ZERO
	melee.position = Vector2(65, 0)
	melee.state = 0
	melee.start_windup()
	_assert(melee.is_telegraphing(), "O ataque corpo a corpo deve começar com sinalização.")
	melee._update_character_visual()
	_assert(melee_visual.texture == melee.attack_texture and melee_visual.frame % 4 <= 1, "O aviso do Executor deve usar os quadros de preparação do ataque.")
	var hits_before: int = player.debug_hits_received
	for _frame in 38:
		await physics_frame
	_assert(player.debug_hits_received == hits_before + 1, "O ataque corpo a corpo sinalizado deve causar um impacto.")
	_assert(melee_visual.texture == melee.attack_texture and melee_visual.frame % 4 >= 2, "O impacto deve avançar para os quadros finais do ataque.")
	_assert(melee.attack_impact_left > 0.0, "O golpe do Executor deve ativar seu reforço visual de impacto.")
	var impact_spark_found := false
	for child in main.get_children():
		if child.scene_file_path == "res://scenes/hit_spark.tscn":
			impact_spark_found = true
	_assert(impact_spark_found, "O golpe do Executor deve criar faíscas no ponto de impacto.")

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
	ranged._update_character_visual()
	_assert(ranged_visual.texture == ranged.shoot_texture and ranged_visual.frame % 4 == 0, "A Auditora deve iniciar o disparo com a arma baixa.")
	ranged.state_time = ranged.windup_duration * 0.45
	ranged._update_character_visual()
	_assert(ranged_visual.frame % 4 == 1, "A Auditora deve levantar o rifle durante a preparacao.")
	ranged.state_time = ranged.windup_duration * 0.1
	ranged._update_character_visual()
	_assert(ranged_visual.frame % 4 == 2, "A Auditora deve mirar antes de disparar.")
	_assert(ranged.is_telegraphing(), "O tiro deve começar com uma linha de mira sinalizada.")
	ranged.state_time = 0.001
	await physics_frame
	_assert(ranged_visual.texture == ranged.shoot_texture and ranged_visual.frame % 4 == 3, "O projetil deve coincidir com o quadro de disparo e recuo.")
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

	var ranged_visual_base_position: Vector2 = ranged_visual.position
	_assert(ranged.take_damage(1, Vector2.RIGHT), "A Auditora deve reagir ao dano sem morrer.")
	ranged._update_character_visual()
	_assert(ranged_visual.position != ranged_visual_base_position, "O dano deve deslocar e oscilar apenas o visual da Auditora.")
	var ranged_death_reference: WeakRef = weakref(ranged)
	_assert(ranged.take_damage(999, Vector2.RIGHT), "O golpe fatal deve iniciar a destruicao da Auditora.")
	_assert(ranged.state == ranged.State.DEAD and ranged.is_in_group("enemy"), "A Auditora deve permanecer disponivel durante o sinal do golpe fatal.")
	_assert(not ranged.is_queued_for_deletion(), "A destruicao da Auditora deve permanecer visivel antes da remocao.")
	await process_frame
	_assert(not ranged.is_in_group("enemy"), "A Auditora derrotada deve sair do combate apos processar o golpe fatal.")
	for _frame in 10:
		await physics_frame
	_assert(is_instance_valid(ranged) and absf(ranged_visual.rotation) > 0.01, "A destruicao deve inclinar o corpo da Auditora.")
	for _frame in 24:
		await physics_frame
	_assert(ranged_death_reference.get_ref() == null, "A Auditora deve ser removida ao terminar a destruicao.")

	melee.set_physics_process(true)
	var death_reference: WeakRef = weakref(melee)
	_assert(melee.take_damage(999, Vector2.RIGHT), "O golpe fatal deve iniciar a destruição do Executor.")
	_assert(melee.state == melee.State.DEAD and melee.is_in_group("enemy"), "O Executor deve permanecer disponível durante o sinal do golpe fatal.")
	_assert(not melee.is_queued_for_deletion(), "A destruição deve permanecer visível antes da remoção.")
	await process_frame
	_assert(not melee.is_in_group("enemy"), "O Executor derrotado deve sair do combate após processar o golpe fatal.")
	for _frame in 8:
		await physics_frame
	_assert(is_instance_valid(melee) and absf(melee.get_node("CharacterVisual").rotation) > 0.01, "A destruição deve inclinar o corpo do Executor.")
	for _frame in 24:
		await physics_frame
	_assert(death_reference.get_ref() == null, "O Executor deve ser removido ao terminar a destruição.")

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
