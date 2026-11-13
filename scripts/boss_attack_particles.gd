extends Node2D

enum Effect { DASH, SLAM, VOLLEY, SHOULDER, BREAKDOWN }

var particles: Array[Dictionary] = []
var effect := Effect.DASH
var direction := Vector2.RIGHT
var random := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("boss_attack_effect")
	random.randomize()


func setup(kind: int, attack_direction: Vector2) -> void:
	effect = kind as Effect
	direction = attack_direction.normalized() if not attack_direction.is_zero_approx() else Vector2.RIGHT
	match effect:
		Effect.DASH:
			_emit_dash_dust()
		Effect.SLAM:
			_emit_slam_debris()
		Effect.VOLLEY:
			_emit_volley_energy()
		Effect.SHOULDER:
			_emit_shoulder_sparks()
		Effect.BREAKDOWN:
			_emit_breakdown()
	queue_redraw()


func _process(delta: float) -> void:
	for particle in particles:
		particle.position += particle.velocity * delta
		particle.velocity += particle.gravity * delta
		particle.life -= delta
	particles = particles.filter(func(particle: Dictionary) -> bool: return particle.life > 0.0)
	if particles.is_empty():
		queue_free()
		return
	queue_redraw()


func _emit_dash_dust() -> void:
	for index in 12:
		var spread := random.randf_range(-1.05, 1.05)
		var velocity := -direction.rotated(spread) * random.randf_range(55.0, 145.0)
		velocity += Vector2(0.0, random.randf_range(-35.0, 15.0))
		_add_particle(velocity, random.randf_range(0.22, 0.42), random.randf_range(3.0, 7.0), Color("a77752"), Vector2(0.0, 95.0))
	for index in 5:
		var spark_velocity := -direction.rotated(random.randf_range(-0.7, 0.7)) * random.randf_range(120.0, 220.0)
		_add_particle(spark_velocity, random.randf_range(0.12, 0.24), 2.5, Color("ffb13b"), Vector2.ZERO)


func _emit_slam_debris() -> void:
	# Nuvem baixa e larga para vender o peso antes dos fragmentos mais rapidos.
	for index in 30:
		var dust_direction := Vector2.RIGHT.rotated(TAU * float(index) / 30.0 + random.randf_range(-0.18, 0.18))
		var dust_velocity := dust_direction * random.randf_range(45.0, 145.0) + Vector2(0.0, random.randf_range(-28.0, 8.0))
		var dust_color := Color("8f715d") if index % 2 == 0 else Color("5f5660")
		_add_particle(dust_velocity, random.randf_range(0.42, 0.72), random.randf_range(6.0, 12.0), dust_color, Vector2(0.0, 55.0))
	for index in 22:
		var radial := Vector2.RIGHT.rotated(TAU * float(index) / 22.0 + random.randf_range(-0.12, 0.12))
		var velocity := radial * random.randf_range(90.0, 245.0) + Vector2(0.0, random.randf_range(-85.0, -20.0))
		var color := Color("5defff") if index % 3 == 0 else Color("b67a4b")
		_add_particle(velocity, random.randf_range(0.28, 0.52), random.randf_range(2.5, 6.0), color, Vector2(0.0, 210.0))


func _emit_volley_energy() -> void:
	for index in 14:
		var velocity := direction.rotated(random.randf_range(-0.8, 0.8)) * random.randf_range(70.0, 190.0)
		var color := Color("b8e1ff") if index % 2 == 0 else Color("3388ff")
		_add_particle(velocity, random.randf_range(0.14, 0.30), random.randf_range(2.0, 5.0), color, Vector2.ZERO)


func _emit_shoulder_sparks() -> void:
	for index in 26:
		var spark_direction := -direction.rotated(random.randf_range(-0.72, 0.72))
		var velocity := spark_direction * random.randf_range(150.0, 330.0)
		velocity += direction.orthogonal() * random.randf_range(-65.0, 65.0)
		var color := Color("fff0a6") if index % 3 == 0 else Color("ff8a28")
		_add_particle(velocity, random.randf_range(0.16, 0.34), random.randf_range(2.0, 3.8), color, Vector2(0.0, 65.0))


func _emit_breakdown() -> void:
	# Estouro misto: energia do nucleo, faiscas da armadura e fragmentos pesados.
	for index in 34:
		var radial := Vector2.RIGHT.rotated(TAU * float(index) / 34.0 + random.randf_range(-0.16, 0.16))
		var velocity := radial * random.randf_range(105.0, 310.0) + Vector2(0.0, random.randf_range(-95.0, 10.0))
		var color := Color("b9efff") if index % 3 == 0 else Color("3388ff")
		_add_particle(velocity, random.randf_range(0.30, 0.62), random.randf_range(2.0, 4.5), color, Vector2(0.0, 150.0))
	for index in 18:
		var fragment_direction := Vector2.RIGHT.rotated(TAU * float(index) / 18.0 + random.randf_range(-0.22, 0.22))
		var fragment_velocity := fragment_direction * random.randf_range(65.0, 205.0) + Vector2(0.0, random.randf_range(-120.0, -25.0))
		var fragment_color := Color("ff9d32") if index % 2 == 0 else Color("5f5660")
		_add_particle(fragment_velocity, random.randf_range(0.42, 0.78), random.randf_range(3.0, 7.0), fragment_color, Vector2(0.0, 230.0))


func _add_particle(velocity: Vector2, life: float, radius: float, color: Color, gravity: Vector2) -> void:
	particles.append({
		"position": Vector2.ZERO,
		"velocity": velocity,
		"life": life,
		"max_life": life,
		"radius": radius,
		"color": color,
		"gravity": gravity,
	})


func _draw() -> void:
	for particle in particles:
		var alpha: float = clampf(particle.life / particle.max_life, 0.0, 1.0)
		var color: Color = particle.color
		color.a = alpha
		if effect in [Effect.DASH, Effect.SHOULDER, Effect.BREAKDOWN] and particle.radius <= 4.5:
			var tail: Vector2 = particle.velocity.normalized() * particle.radius * 4.0
			draw_line(particle.position, particle.position - tail, color, particle.radius, true)
		else:
			draw_circle(particle.position, particle.radius * (0.45 + alpha * 0.55), color)
