extends Area2D

@export var speed := 280.0
@export var lifetime := 3.0
var direction := Vector2.RIGHT


func _ready() -> void:
	add_to_group("enemy_projectile")
	body_entered.connect(_on_body_entered)


func setup(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("receive_enemy_hit"):
		body.receive_enemy_hit(1)
	queue_free()

