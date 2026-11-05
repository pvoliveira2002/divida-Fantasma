extends SceneTree


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

	var player := main.get_node_or_null("Player") as CharacterBody2D
	_assert(player != null, "O personagem deve existir na cena principal.")
	if player == null:
		quit(1)
		return

	_assert(player.get_node_or_null("Camera2D") != null, "O personagem deve possuir uma câmera.")
	_assert(player.get_node_or_null("CollisionShape2D") != null, "O personagem deve possuir colisão.")

	Input.action_press("move_right")
	Input.action_press("move_up")
	var diagonal := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	Input.action_release("move_right")
	Input.action_release("move_up")
	_assert(is_equal_approx(diagonal.length(), 1.0), "O movimento diagonal deve ser normalizado.")

	player.position = Vector2.ZERO
	var collision := player.move_and_collide(Vector2(700, 0))
	_assert(collision != null, "A borda direita da arena deve bloquear o personagem.")
	_assert(player.position.x < 540.0, "O personagem não deve atravessar o limite direito.")

	if Engine.get_meta("phase1_test_failed", false):
		quit(1)
	else:
		print("PHASE1_SMOKE_TEST: PASS")
		quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	Engine.set_meta("phase1_test_failed", true)
	push_error("PHASE1_SMOKE_TEST: " + message)
