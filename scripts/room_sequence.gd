extends Node2D

signal sequence_completed

const MELEE := preload("res://scenes/melee_enemy.tscn")
const RANGED := preload("res://scenes/ranged_enemy.tscn")
const BOSS := preload("res://scenes/boss.tscn")
const EXIT_HATCH_SCRIPT := preload("res://scripts/exit_hatch.gd")
const BOSS_ROOM := 3
const ROOM_NAMES := ["ACESSO", "ARQUIVO", "NÚCLEO", "COBRADOR DE MEMÓRIAS"]
const ROOM_COLORS := [Color("101a32"), Color("201731"), Color("102a2c"), Color("291a24")]
const HATCH_ANCHORS := [
	[Vector2(-225, 112), Vector2(-35, -158), Vector2(235, 108), Vector2(285, -82)],
	[Vector2(-250, -92), Vector2(-75, 155), Vector2(170, -135), Vector2(275, 88)],
	[Vector2(-275, 72), Vector2(-95, -150), Vector2(155, 145), Vector2(285, -68)],
]
# Three authored waves per room. Room 0 wave 0 is preplaced in main.tscn.
const ROOM_WAVES := [
	[
		[],
		[[false, Vector2(-40, -150)], [false, Vector2(80, 145)], [true, Vector2(285, 0)]],
		[[false, Vector2(-80, -165)], [false, Vector2(30, 165)], [true, Vector2(225, -95)], [true, Vector2(270, 105)]],
	],
	[
		[[false, Vector2(20, -150)], [false, Vector2(100, 140)], [true, Vector2(300, 0)]],
		[[false, Vector2(-90, -165)], [false, Vector2(30, 165)], [true, Vector2(230, -100)], [true, Vector2(280, 105)]],
		[[false, Vector2(-130, 0)], [false, Vector2(0, -175)], [false, Vector2(30, 175)], [true, Vector2(225, -105)], [true, Vector2(285, 105)]],
	],
	[
		[[false, Vector2(-10, -170)], [false, Vector2(-10, 170)], [true, Vector2(220, -95)], [true, Vector2(220, 95)]],
		[[false, Vector2(-125, 0)], [false, Vector2(5, -175)], [false, Vector2(5, 175)], [true, Vector2(235, -105)], [true, Vector2(275, 105)]],
		[[false, Vector2(-150, -100)], [false, Vector2(-150, 100)], [false, Vector2(15, 0)], [true, Vector2(205, -135)], [true, Vector2(290, 0)], [true, Vector2(205, 135)]],
	],
]
const BOSS_GUARDS := [[false, Vector2(0, -150)], [false, Vector2(0, 150)]]

var room_index := 0
var wave_index := 0
var room_cleared := false
var reward_selected := false
var transitioning := false
var boss: CharacterBody2D
var exit_hatch: Node2D
var hatch_random := RandomNumberGenerator.new()
@onready var arena = get_parent()


func _ready() -> void:
	hatch_random.randomize()
	exit_hatch = EXIT_HATCH_SCRIPT.new()
	exit_hatch.name = "ExitHatch"
	add_child(exit_hatch)
	_place_hatch_for_room()
	_update_labels()
	queue_redraw()


func _process(delta: float) -> void:
	_update_boss_hud()
	if arena.run_state != arena.RunState.PLAYING or transitioning:
		return
	if not room_cleared and _enemies().is_empty():
		_clear_projectiles()
		arena.protocols.clear_room()
		if room_index < BOSS_ROOM and wave_index + 1 < ROOM_WAVES[room_index].size():
			wave_index += 1
			_spawn_encounter(ROOM_WAVES[room_index][wave_index])
		else:
			room_cleared = true
			if room_index == BOSS_ROOM:
				sequence_completed.emit()
			else:
				exit_hatch.begin_unlock()
				arena.upgrades.offer(room_index)
		_update_labels()
		queue_redraw()


func on_upgrade_chosen(completed_room: int) -> void:
	if completed_room != room_index or not room_cleared or reward_selected:
		return
	reward_selected = true
	exit_hatch.open()
	_update_labels()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_E and event.pressed and not event.echo:
		if try_advance():
			get_viewport().set_input_as_handled()


func _enemies() -> Array[Node]:
	var result: Array[Node] = []
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if arena.is_ancestor_of(enemy) and not enemy.is_queued_for_deletion():
			result.append(enemy)
	return result


func _clear_projectiles() -> void:
	for projectile in get_tree().get_nodes_in_group("enemy_projectile"):
		if arena.is_ancestor_of(projectile):
			projectile.set_physics_process(false)
			projectile.set_deferred("monitoring", false)
			projectile.queue_free()


func try_advance() -> bool:
	if transitioning or not room_cleared or not reward_selected or not _enemies().is_empty() or arena.run_state != arena.RunState.PLAYING:
		return false
	if room_index >= BOSS_ROOM or not is_instance_valid(exit_hatch) or not exit_hatch.is_ready():
		return false
	if arena.player.global_position.distance_to(exit_hatch.global_position) > 82.0:
		return false
	transitioning = true
	_begin_hatch_transition.call_deferred()
	return true


func _begin_hatch_transition() -> void:
	if arena.run_state != arena.RunState.PLAYING or arena.player.is_dead or not exit_hatch.is_ready():
		transitioning = false
		return
	arena._finish_hit_stop()
	if not arena.player.begin_hatch_entry(exit_hatch.global_position):
		transitioning = false
		return
	exit_hatch.begin_entry()
	await arena.player.hatch_entry_finished
	if arena.run_state != arena.RunState.PLAYING or arena.player.is_dead:
		transitioning = false
		return
	_transition()


func _transition() -> void:
	if arena.run_state != arena.RunState.PLAYING or arena.player.is_dead:
		transitioning = false
		return
	arena._finish_hit_stop()
	arena.protocols.clear_room()
	_clear_projectiles()
	for child in arena.get_children():
		if child.scene_file_path in ["res://scenes/hit_spark.tscn", "res://scenes/training_target.tscn"]:
			child.queue_free()
	arena.player.reset_combat_pose()
	arena.player.controls_enabled = true
	arena.player.position = Vector2(-320, 0)
	arena.player.facing_direction = Vector2.RIGHT
	arena.player.visual_horizontal_direction = 1
	arena.player._update_character_visual()
	arena.shake_left = 0.0
	arena.shake_strength = 0.0
	arena.camera.offset = Vector2.ZERO
	arena.camera.reset_smoothing()
	room_index += 1
	wave_index = 0
	room_cleared = false
	reward_selected = false
	_place_hatch_for_room()
	if room_index == BOSS_ROOM:
		_spawn_encounter(BOSS_GUARDS)
	else:
		_spawn_encounter(ROOM_WAVES[room_index][wave_index])
	if room_index == BOSS_ROOM:
		boss = BOSS.instantiate()
		boss.position = Vector2(180, 0)
		boss.defeated.connect(_clear_projectiles)
		boss.reinforcement_requested.connect(_spawn_boss_reinforcements)
		arena.add_child(boss)
	_update_labels()
	arena.queue_redraw()
	queue_redraw()
	transitioning = false


func start_boss_test() -> void:
	# Ferramenta temporaria: preserva o encontro real, pulando apenas as salas anteriores.
	_clear_projectiles()
	for enemy in _enemies():
		enemy.queue_free()
	arena.protocols.clear_room()
	arena.player.reset_combat_pose()
	arena.player.position = Vector2(-320, 0)
	arena.player.facing_direction = Vector2.RIGHT
	arena.player.visual_horizontal_direction = 1
	arena.player._update_character_visual()
	room_index = BOSS_ROOM
	wave_index = 0
	room_cleared = false
	reward_selected = false
	transitioning = false
	exit_hatch.visible = false
	exit_hatch.set_process(false)
	_spawn_encounter(BOSS_GUARDS)
	boss = BOSS.instantiate()
	boss.position = Vector2(180, 0)
	boss.defeated.connect(_clear_projectiles)
	boss.reinforcement_requested.connect(_spawn_boss_reinforcements)
	arena.add_child(boss)
	_update_labels()
	arena.queue_redraw()
	queue_redraw()


func _place_hatch_for_room() -> void:
	if not is_instance_valid(exit_hatch):
		return
	if room_index >= BOSS_ROOM:
		exit_hatch.visible = false
		exit_hatch.set_process(false)
		return
	var anchors: Array = HATCH_ANCHORS[room_index]
	var anchor: Vector2 = anchors[hatch_random.randi_range(0, anchors.size() - 1)]
	var accent: Color = arena.ROOM_VISUAL_ACCENTS[room_index]
	exit_hatch.set_process(true)
	exit_hatch.configure(anchor, accent)


func _spawn_encounter(encounter: Array) -> void:
	for spawn in encounter:
		var enemy = (RANGED if spawn[0] else MELEE).instantiate()
		enemy.position = spawn[1]
		arena.add_child(enemy)


func _spawn_boss_reinforcements(stage: int) -> void:
	if room_index != BOSS_ROOM or room_cleared or arena.run_state != arena.RunState.PLAYING:
		return
	var y_sign := -1.0 if stage == 1 else 1.0
	_spawn_encounter([
		[false, Vector2(-120, 155 * y_sign)],
		[true, Vector2(285, -120 * y_sign)],
	])
	arena.get_node("Interface/RoomHint").text = "REFORÇOS DETECTADOS — elimine a escolta e mantenha distância dos avisos."


func _update_labels() -> void:
	var total_waves: int = ROOM_WAVES[room_index].size() if room_index < BOSS_ROOM else 1
	arena.get_node("Interface/Phase").text = "SALA %d/3 — %s · ONDA %d/%d" % [room_index + 1, ROOM_NAMES[room_index], wave_index + 1, total_waves]
	if room_index == BOSS_ROOM:
		arena.get_node("Interface/Phase").text = "CONFRONTO FINAL"
	var hint := "Elimine a onda atual. Novos sinais hostis podem entrar na sala."
	if room_cleared:
		hint = "Escotilha localizada. Instale um protocolo para concluir o desbloqueio."
		if reward_selected:
			hint = "Escotilha aberta — siga o sinal holográfico e pressione E."
		if reward_selected and room_index == BOSS_ROOM - 1:
			hint = "Rota para o confronto final aberta — entre na escotilha."
	if room_index == BOSS_ROOM:
		hint = "Derrote o Cobrador e seus dois guardas. Anel ciano: janela de contra-ataque."
	arena.get_node("Interface/RoomHint").text = hint


func _update_boss_hud() -> void:
	var hud := arena.get_node("Interface/BossHUD")
	hud.visible = room_index == BOSS_ROOM
	if not hud.visible:
		return
	var bar := hud.get_node("Health") as ProgressBar
	if is_instance_valid(boss):
		bar.max_value = boss.max_health
		bar.value = boss.health
		hud.get_node("Name").text = "COBRADOR DE MEMÓRIAS · RITMO ACELERADO" if boss.enraged else "COBRADOR DE MEMÓRIAS"
	else:
		bar.value = 0
		hud.get_node("Name").text = "COBRADOR DERROTADO · ELIMINE OS GUARDAS RESTANTES"


func _draw() -> void:
	var color := Color("2fffd5") if reward_selected else Color("ff496c")
	# Distinct floor markings identify each authored room without blocking AI paths.
	for index in range(room_index + 1):
		var center := Vector2(-80 + index * 80, -210)
		draw_polyline(PackedVector2Array([center + Vector2(-24, 0), center + Vector2(0, -13), center + Vector2(24, 0), center + Vector2(0, 13), center + Vector2(-24, 0)]), color, 2.0)
