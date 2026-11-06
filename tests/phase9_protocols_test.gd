extends SceneTree

var failed := false
var arena
var player
var protocols

func _initialize() -> void:
	call_deferred("_run")

func _enemy(point: Vector2):
	var enemy = load("res://scenes/melee_enemy.tscn").instantiate()
	enemy.max_health = 100
	enemy.position = point
	arena.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy

func _hit(target) -> void:
	player.reset_combat_pose()
	player.start_attack(Vector2.RIGHT)
	player.attack_state = player.AttackState.ACTIVE
	player._try_damage_target(target)
	player._try_damage_target(target)
	arena._finish_hit_stop()

func _run() -> void:
	arena = load("res://scenes/main.tscn").instantiate()
	root.add_child(arena)
	await physics_frame
	player = arena.player
	protocols = arena.protocols
	arena.rooms.set_process(false)
	for enemy in get_nodes_in_group("enemy"):
		enemy.queue_free()
	await process_frame
	player.set_physics_process(false)
	player.position = Vector2.ZERO
	var first = _enemy(Vector2(50, 0))
	var near = _enemy(Vector2(110, 0))
	var far = _enemy(Vector2(350, 0))
	protocols.install(0)
	_hit(first)
	_hit(near)
	_hit(first)
	_assert(near.health == 99, "Golpes em alvos diferentes não podem completar o contador do primeiro.")
	_hit(first)
	_assert(first.health == 97 and near.health == 98, "Terceiro golpe deve descarregar uma única vez no vizinho.")
	_assert(far.health == 100, "Descarga deve respeitar alcance.")
	_assert(protocols.circuit_hits[near.get_instance_id()] == 1, "Descargas não podem carregar outras descargas.")
	protocols.install(0)
	for index in 3:
		_hit(first)
	_assert(near.health == 96, "Evoluir Curto-Circuito deve elevar o dano da descarga.")
	# The third hit can kill its source and still discharge to a living neighbor.
	first.health = 3
	for index in 3:
		_hit(first)
	_assert(near.health == 94, "Golpe fatal também deve disparar a descarga.")
	await process_frame
	protocols.clear_room()
	protocols.ranks.assign([0, 1, 0])
	player.reset_combat_pose()
	player.dodge_cooldown_left = 0
	near.position = Vector2(40, 0)
	var before: int = near.health
	_assert(player.start_dodge(Vector2.RIGHT), "Esquiva deve iniciar com Rastro instalado.")
	_assert(protocols.effects.size() == 1 and protocols.effects[0].kind == "ghost", "Esquiva deve deixar uma silhueta.")
	_assert(near.health == before, "Rastro não deve explodir imediatamente.")
	player.position = Vector2(-250, 0)
	protocols._physics_process(0.36)
	_assert(near.health == before - 1, "Explosão deve atingir a posição deixada, não seguir o jogador.")
	protocols._physics_process(0.5)
	_assert(near.health == before - 1, "Uma silhueta não pode explodir duas vezes.")
	_assert(far.health == 100, "Explosão deve respeitar seu raio.")
	player.position = Vector2.ZERO
	protocols.clear_room()
	protocols.ranks.assign([0, 0, 1])
	first = _enemy(Vector2(50, 0))
	near.position = Vector2(110, 0)
	var behind = _enemy(Vector2(-80, 0))
	for index in 3:
		_hit(first)
	_assert(protocols.overload_charge == 3, "Três golpes distintos devem carregar o braço.")
	before = near.health
	_hit(first)
	_assert(first.health == 94, "Quarto golpe aplica dano básico e uma única onda de 2 de dano.")
	_assert(near.health == before - 2 and behind.health == 100 and far.health == 100, "Onda deve atingir somente o cone frontal curto.")
	_assert(protocols.overload_charge == 0, "Onda não pode recarregar a si mesma.")
	_hit(first)
	protocols._physics_process(2.6)
	_assert(protocols.overload_charge == 0, "Carga parcial deve expirar sem golpes consecutivos.")
	_hit(first)
	player._try_damage_target(near)
	_assert(protocols.overload_charge == 1, "Um golpe em vários alvos carrega Sobrecarga apenas uma vez.")
	# All three coexist; secondary damage must not create additional counters.
	protocols.clear_room()
	protocols.ranks.assign([1, 1, 1])
	for index in 3:
		_hit(first)
	_assert(protocols.overload_charge == 3, "Descarga combinada não deve consumir a Sobrecarga pronta.")
	player.reset_combat_pose()
	player.dodge_cooldown_left = 0
	player.start_dodge(Vector2.RIGHT)
	protocols.clear_room()
	before = near.health
	protocols._physics_process(1.0)
	_assert(near.health == before and protocols.effects.is_empty(), "Transição deve cancelar explosões pendentes.")
	_assert(protocols.ranks == [1, 1, 1] and protocols.circuit_hits.is_empty(), "Limpar sala preserva protocolos e remove cargas/referências.")
	player.reset_combat_pose()
	player.dodge_cooldown_left = 0
	player.start_dodge(Vector2.RIGHT)
	player.dodge_grants_invulnerability = false
	player.receive_enemy_hit(99)
	protocols._physics_process(1.0)
	_assert(protocols.effects.is_empty() and near.health == before, "Morte deve cancelar efeitos pendentes sem dano posterior.")
	arena.queue_free()
	await process_frame
	# Allow the audio server to release the burst of test-only playback instances.
	await create_timer(0.3).timeout
	if not failed:
		print("PHASE9_PROTOCOLS_TEST: PASS")
	quit(1 if failed else 0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("PHASE9_PROTOCOLS_TEST: " + message)
