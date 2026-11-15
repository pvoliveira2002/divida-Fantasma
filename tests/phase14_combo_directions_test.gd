extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var arena = scene.instantiate()
	root.add_child(arena)
	await physics_frame
	await physics_frame
	var player = arena.player
	var target = arena.get_node("TrainingTarget")
	var visual := player.get_node("CharacterVisual") as Sprite2D
	for enemy in get_nodes_in_group("enemy"):
		enemy.set_physics_process(false)

	var directions := [
		Vector2(1.0, 1.0).normalized(), Vector2(1.0, -1.0).normalized(),
		Vector2(-1.0, 1.0).normalized(), Vector2(-1.0, -1.0).normalized(),
	]
	var expected_textures := [
		player.combo_texture, player.combo_back_right_texture,
		player.combo_front_left_texture, player.combo_back_left_texture,
	]
	var previous_texture_paths := [
		"res://assets/characters/protagonist_01/combo_front_right_16f_v1.png",
		"res://assets/characters/protagonist_01/combo_back_right_16f_v1.png",
		"res://assets/characters/protagonist_01/combo_front_left_16f_v1.png",
		"res://assets/characters/protagonist_01/combo_back_left_16f_v1.png",
	]
	for direction_index in directions.size():
		var current_image: Image = expected_textures[direction_index].get_image()
		var previous_image: Image = load(previous_texture_paths[direction_index]).get_image()
		_assert(expected_textures[direction_index].resource_path.ends_with("_v2.png"), "O jogador deve usar as folhas v2 que incluem o chute.")
		_assert(current_image.get_size() == Vector2i(1536, 1536), "Cada folha v2 deve manter a grade exata de 1536 x 1536.")
		_assert(hash(current_image.get_region(Rect2i(0, 0, 1536, 768)).get_data()) == hash(previous_image.get_region(Rect2i(0, 0, 1536, 768)).get_data()), "Os dois primeiros golpes devem permanecer identicos ao v1.")
		_assert(hash(current_image.get_region(Rect2i(0, 768, 1536, 384)).get_data()) != hash(previous_image.get_region(Rect2i(0, 768, 1536, 384)).get_data()), "O terceiro golpe deve possuir a nova sequencia de chute.")
		_assert(hash(current_image.get_region(Rect2i(0, 1152, 1536, 384)).get_data()) == hash(previous_image.get_region(Rect2i(0, 1152, 1536, 384)).get_data()), "O finalizador deve permanecer identico ao v1.")
		player.reset_combat_pose()
		player.position = Vector2.ZERO
		target.position = directions[direction_index] * 70.0
		target.max_health = 10
		target.current_health = 10
		target.hit_count = 0
		target.is_resetting = false
		target.visible = true
		target.monitorable = true
		await physics_frame
		_assert(player.start_attack(directions[direction_index]), "Cada direcao deve iniciar o primeiro golpe do combo.")
		player._update_character_visual()
		_assert(visual.texture == expected_textures[direction_index], "Cada direcao deve selecionar sua folha propria sem espelhamento.")
		_assert(not visual.flip_h, "Nenhuma direcao pode espelhar ou trocar o braco cibernetico.")
		for expected_step in 4:
			_assert(player.combo_step == expected_step, "O combo deve percorrer os quatro golpes em todas as direcoes.")
			if expected_step < 3:
				for _frame in 20:
					if player.attack_state == player.AttackState.ACTIVE:
						break
					await physics_frame
				_assert(player.start_attack(directions[direction_index]), "A entrada seguinte deve ser aceita durante o impacto.")
				for _frame in 40:
					if player.combo_step == expected_step + 1:
						break
					await physics_frame
		for _frame in 50:
			if player.attack_state == player.AttackState.READY:
				break
			await physics_frame
		_assert(target.hit_count == 4 and target.current_health == 5, "Cada direcao deve aplicar quatro impactos e dano total cinco.")

	arena.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	if not failed:
		print("PHASE14_COMBO_DIRECTIONS_TEST: PASS")
	quit(1 if failed else 0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("PHASE14_COMBO_DIRECTIONS_TEST: " + message)
