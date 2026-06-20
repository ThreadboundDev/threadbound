extends Area2D
class_name ThreadKnotPickup

@export var value := 1
@export var drift_gravity := 520.0
@export var settle_time := 0.55
@export var bob_height := 4.0
@export var bob_speed := 3.2
@export var spin_speed := 1.2

@onready var sprite: Sprite2D = $Sprite2D as Sprite2D

var velocity := Vector2.ZERO
var _age := 0.0
var _base_y := 0.0
var _settled := false

func _ready() -> void:
	add_to_group("thread_knot_pickups")
	_base_y = position.y

func launch(initial_velocity: Vector2) -> void:
	velocity = initial_velocity
	_settled = false
	_age = 0.0
	_base_y = position.y

func _physics_process(delta: float) -> void:
	_age += delta
	if not _settled:
		velocity.y += drift_gravity * delta
		position += velocity * delta
		if _age >= settle_time:
			_settled = true
			_base_y = position.y
			velocity = Vector2.ZERO
	else:
		position.y = _base_y + sin(_age * bob_speed) * bob_height

	if sprite:
		sprite.rotation += spin_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if not body or not body.has_method("collect_thread_knots"):
		return

	body.collect_thread_knots(value)
	queue_free()
