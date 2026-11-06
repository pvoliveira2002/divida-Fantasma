extends Node2D

signal sequence_completed

const MELEE := preload("res://scenes/melee_enemy.tscn")
const RANGED := preload("res://scenes/ranged_enemy.tscn")
const BOSS := preload("res://scenes/boss.tscn")
const BOSS_ROOM := 3
const EXIT_POSITION := Vector2(400, 0)
const ROOM_NAMES := ["ACESSO", "ARQUIVO", "NÚCLEO", "COBRADOR DE MEMÓRIAS"]
const ROOM_COLORS := [Color("101a32"), Color("201731"), Color("102a2c"), Color("291a24")]
# Authored encounters; the first room keeps the approved demo arrangement.
const ENCOUNTERS := [
	[],
	[[false, Vector2(20, -150)], [false, Vector2(100, 140)], [true, Vector2(300, 0)]],
	[[false, Vector2(-10, -170)], [false, Vector2(-10, 170)], [true, Vector2(220, -95)], [true, Vector2(220, 95)]],
	[[false, Vector2(0, -150)], [false, Vector2(0, 150)]],
]

var room_index := 0
var room_cleared := false
var reward_selected := false
var transitioning := false
var gate_collision: CollisionShape2D
var boss: CharacterBody2D
@onready var arena = get_parent()


func _ready() -> void:
	var gate := StaticBody2D.new()
	gate.position = EXIT_POSITION
	gate.collision_layer = 1
	gate.collision_mask = 0
	add_child(gate)
	gate_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(18, 90)
	gate_collision.shape = shape
	gate.add_child(gate_collision)
	_update_labels()
	queue_redraw()


func _process(_delta: float) -> void:
	_update_boss_hud()
	if arena.run_state != arena.RunState.PLAYING or transitioning:
		return
	if not room_cleared and _enemies().is_empty():
		room_cleared = true
		_clear_projectiles()
		arena.protocols.clear_room()
		if room_index == BOSS_ROOM:
			sequence_completed.emit()
		else:
			arena.upgrades.offer(room_index)
		_update_labels()
		queue_redraw()


func on_upgrade_chosen(completed_room: int) -> void:
	if completed_room != room_index or not room_cleared or reward_selected:
		return
	reward_selected = true
	gate_collision.set_deferred("disabled", true)
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
	if room_index >= ROOM_NAMES.size() - 1 or arena.player.position.distance_to(EXIT_POSITION) > 85.0:
		return false
	transitioning = true
	_transition.call_deferred()
	return true


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
	arena.player.position = Vector2(-320, 0)
	arena.player.facing_direction = Vector2.RIGHT
	arena.player.visual_horizontal_direction = 1
	arena.player._update_character_visual()
	arena.shake_left = 0.0
	arena.shake_strength = 0.0
	arena.camera.offset = Vector2.ZERO
	arena.camera.reset_smoothing()
	room_index += 1
	room_cleared = false
	reward_selected = false
	gate_collision.disabled = false
	for spawn in ENCOUNTERS[room_index]:
		var enemy = (RANGED if spawn[0] else MELEE).instantiate()
		enemy.position = spawn[1]
		arena.add_child(enemy)
	if room_index == BOSS_ROOM:
		boss = BOSS.instantiate()
		boss.position = Vector2(180, 0)
		boss.defeated.connect(_clear_projectiles)
		arena.add_child(boss)
	_update_labels()
	arena.queue_redraw()
	queue_redraw()
	transitioning = false


func _update_labels() -> void:
	arena.get_node("Interface/Phase").text = "SALA %d/3 — %s" % [room_index + 1, ROOM_NAMES[room_index]]
	if room_index == BOSS_ROOM:
		arena.get_node("Interface/Phase").text = "CONFRONTO FINAL"
	var hint := "Elimine os inimigos para liberar a porta à direita."
	if room_cleared:
		hint = "Instale um protocolo para continuar."
		if reward_selected:
			hint = "Porta liberada à direita — aproxime-se e pressione E."
		if reward_selected and room_index == BOSS_ROOM - 1:
			hint = "Chefe à frente — aproxime-se da porta e pressione E."
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
	draw_rect(Rect2(EXIT_POSITION - Vector2(14, 50), Vector2(28, 100)), Color("080d19"))
	draw_rect(Rect2(EXIT_POSITION - Vector2(14, 50), Vector2(28, 100)), color, false, 3.0)
	if not reward_selected:
		for y in [-30, -10, 10, 30]:
			draw_line(EXIT_POSITION + Vector2(-12, y), EXIT_POSITION + Vector2(12, y), color, 3.0)
	else:
		draw_polyline(PackedVector2Array([EXIT_POSITION + Vector2(-8, -14), EXIT_POSITION + Vector2(8, 0), EXIT_POSITION + Vector2(-8, 14)]), color, 3.0)
	# Distinct floor markings identify each authored room without blocking AI paths.
	for index in range(room_index + 1):
		var center := Vector2(-80 + index * 80, -210)
		draw_polyline(PackedVector2Array([center + Vector2(-24, 0), center + Vector2(0, -13), center + Vector2(24, 0), center + Vector2(0, 13), center + Vector2(-24, 0)]), color, 2.0)
