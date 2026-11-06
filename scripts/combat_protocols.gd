extends Node2D

const CYAN := Color("49f4ff")
const MAGENTA := Color("ff48c4")
const GOLD := Color("ffd36c")
@export var circuit_range := 220.0
@export var ghost_delay := 0.35
@export var ghost_radius := 100.0
@export var overload_range := 145.0
@export var combo_timeout := 2.5

var ranks: Array[int] = [0, 0, 0]
var circuit_hits: Dictionary = {}
var overload_charge := 0
var combo_left := 0.0
var last_swing := -1
var effects: Array[Dictionary] = []
@onready var arena = get_parent()


func _ready() -> void:
	z_index = 12
	arena.player.protocol_hit.connect(_on_hit)
	arena.player.dodge_started.connect(_on_dodge)


func install(index: int) -> void:
	ranks[index] += 1
	_update_arm()


func _physics_process(delta: float) -> void:
	if arena.run_state != arena.RunState.PLAYING or arena.player.is_dead:
		clear_room()
		return
	for id in circuit_hits.keys():
		if not is_instance_id_valid(id):
			circuit_hits.erase(id)
	if overload_charge < 3 and combo_left > 0.0:
		combo_left = maxf(0.0, combo_left - delta)
		if combo_left == 0.0:
			overload_charge = 0
	_update_arm()
	# Iterate over a copy: an expiring ghost can append an explosion safely.
	for effect in effects.duplicate():
		effect.time -= delta
		if effect.kind == "ghost" and is_instance_valid(effect.sprite):
			effect.sprite.modulate.a = 0.35 + 0.25 * (0.5 + 0.5 * sin(effect.time * 35.0))
		if effect.time <= 0.0:
			effects.erase(effect)
			if effect.kind == "ghost":
				effect.sprite.queue_free()
				_burst(effect.origin, ghost_radius, int(effect.damage))
	queue_redraw()


func _enemies() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if arena.is_ancestor_of(enemy) and not enemy.is_queued_for_deletion():
			result.append(enemy)
	return result


func _on_hit(target: Node2D, impact: Vector2, swing: int) -> void:
	if arena.player.is_dead or arena.run_state != arena.RunState.PLAYING or not target.is_in_group("enemy"):
		return
	if ranks[0] > 0:
		var id := target.get_instance_id()
		var count := int(circuit_hits.get(id, 0)) + 1
		circuit_hits[id] = count % 3
		if count >= 3:
			var nearest: Node2D
			var distance := circuit_range
			for enemy in _enemies():
				var candidate_distance := impact.distance_to(enemy.global_position)
				if enemy != target and candidate_distance <= distance:
					nearest = enemy
					distance = candidate_distance
			if is_instance_valid(nearest):
				var destination := nearest.global_position
				_secondary_damage(nearest, ranks[0], impact)
				_add_effect("arc", impact, 0.22, {"end": destination})
			else:
				_add_effect("spark", impact, 0.18)
	if ranks[2] > 0 and swing != last_swing:
		last_swing = swing
		if overload_charge == 3:
			overload_charge = 0
			combo_left = 0.0
			var origin: Vector2 = arena.player.global_position
			var direction: Vector2 = arena.player.facing_direction
			for enemy in _enemies():
				var offset := enemy.global_position - origin
				if offset.length() <= overload_range and (offset.is_zero_approx() or offset.normalized().dot(direction) >= 0.35):
					_secondary_damage(enemy, 1 + ranks[2], origin)
			_add_effect("wave", origin, 0.25, {"direction": direction})
		else:
			overload_charge += 1
			combo_left = combo_timeout
	_update_arm()
	queue_redraw()


func _on_dodge() -> void:
	if ranks[1] <= 0 or arena.player.is_dead:
		return
	var source: Sprite2D = arena.player.character_visual
	var ghost := Sprite2D.new()
	ghost.texture = source.texture
	ghost.hframes = source.hframes
	ghost.vframes = source.vframes
	ghost.frame = source.frame
	ghost.scale = source.global_scale
	ghost.rotation = source.global_rotation
	ghost.modulate = MAGENTA
	ghost.modulate.a = 0.6
	add_child(ghost)
	ghost.global_position = source.global_position
	_add_effect("ghost", arena.player.global_position, ghost_delay, {"sprite": ghost, "damage": ranks[1]})


func _secondary_damage(enemy: Node2D, amount: int, origin: Vector2) -> void:
	# Secondary damage never emits protocol_hit, so effects cannot recurse.
	if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
		enemy.take_damage(amount, (enemy.global_position - origin).normalized())


func _burst(origin: Vector2, radius: float, damage: int) -> void:
	if arena.player.is_dead or not arena.player.controls_enabled:
		return
	for enemy in _enemies():
		if enemy.global_position.distance_to(origin) <= radius:
			_secondary_damage(enemy, damage, origin)
	_add_effect("burst", origin, 0.24)


func _add_effect(kind: String, origin: Vector2, duration: float, extra: Dictionary = {}) -> void:
	var effect := {"kind": kind, "origin": origin, "time": duration, "duration": duration}
	effect.merge(extra)
	effects.append(effect)
	queue_redraw()


func clear_room() -> void:
	for effect in effects:
		if effect.kind == "ghost" and is_instance_valid(effect.sprite):
			effect.sprite.queue_free()
	effects.clear()
	circuit_hits.clear()
	overload_charge = 0
	combo_left = 0.0
	last_swing = -1
	_update_arm()
	queue_redraw()


func _update_arm() -> void:
	var circuit_charge := 0
	for count in circuit_hits.values():
		circuit_charge = maxi(circuit_charge, int(count))
	arena.player.circuit_visual_charge = circuit_charge
	arena.player.overload_visual_charge = overload_charge
	arena.player.queue_redraw()


func _draw() -> void:
	# Draw above the character sprite so the circuitry remains visible.
	if not arena.player.is_dead:
		var side: int = arena.player.visual_horizontal_direction
		var arm: Vector2 = to_local(arena.player.global_position) + Vector2(side * 13.0, -23.0)
		for segment in arena.player.circuit_visual_charge:
			draw_line(arm + Vector2(0, -segment * 5), arm + Vector2(side * 6, -segment * 5), CYAN, 2.5, true)
		for segment in overload_charge:
			draw_circle(arm + Vector2(-side * segment * 3, -8 - segment * 6), 2.6, GOLD)
		if overload_charge == 3:
			draw_arc(arm, 10.0, 0, TAU, 20, GOLD, 2.0, true)
	for effect in effects:
		var t: float = clampf(effect.time / effect.duration, 0.0, 1.0)
		var origin: Vector2 = to_local(effect.origin)
		match effect.kind:
			"arc":
				var end: Vector2 = to_local(effect.end)
				var mid := origin.lerp(end, 0.5)
				var points := PackedVector2Array([origin, origin.lerp(end, 0.25) + Vector2(0, -12), mid + Vector2(0, 10), origin.lerp(end, 0.75) + Vector2(0, -8), end])
				draw_polyline(points, Color(CYAN, t), 4.0, true)
				draw_circle(end, 12.0 * t, Color(CYAN, t * 0.4))
			"ghost":
				draw_arc(origin, ghost_radius * (1.0 - t), 0, TAU, 40, Color(MAGENTA, 0.35), 2.0, true)
				for line in 3:
					var y := -15.0 - line * 14.0
					draw_line(origin + Vector2(-15 + sin(t * 30 + line) * 6, y), origin + Vector2(15, y), Color(MAGENTA, t), 2.0)
			"burst":
				draw_arc(origin, ghost_radius * (1.0 - t * 0.6), 0, TAU, 48, Color(MAGENTA, t), 5.0 * t, true)
				draw_circle(origin, ghost_radius * (1.0 - t), Color(MAGENTA, t * 0.14))
			"wave":
				var angle: float = effect.direction.angle()
				draw_arc(origin, overload_range * (1.0 - t * 0.85), angle - 1.2, angle + 1.2, 32, Color(GOLD, t), 7.0 * t, true)
			"spark":
				draw_arc(origin, 24.0 * (1.0 - t), 0, TAU, 20, Color(CYAN, t), 3.0, true)
	# Per-target charge pips make the three-hit requirement readable.
	for id in circuit_hits:
		if is_instance_id_valid(id):
			var target = instance_from_id(id)
			if is_instance_valid(target) and not target.is_queued_for_deletion():
				var point: Vector2 = to_local(target.global_position) + Vector2(-8, -40)
				for pip in int(circuit_hits[id]):
					draw_rect(Rect2(point + Vector2(pip * 10, 0), Vector2(6, 4)), CYAN)
