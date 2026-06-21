extends CharacterBody2D
class_name ThreadKnotPickup

@export_range(1, 99, 1) var value := 1
@export var gravity := 1250.0
@export var max_fall_speed := 900.0
@export var floor_friction := 760.0
@export var floor_bounce_damping := 0.22
@export var min_bounce_speed := 220.0
@export var vacuum_delay := 0.28
@export var vacuum_radius := 145.0
@export var vacuum_acceleration := 2450.0
@export var vacuum_max_speed := 760.0
@export var collect_distance := 18.0
@export var collect_fade_time := 0.12
@export var bob_height := 2.5
@export var bob_speed := 4.2
@export var spin_speed := 5.0

@onready var sprite: Sprite2D = $Sprite2D as Sprite2D

var _age := 0.0
var _floor_age := 0.0
var _is_vacuuming := false
var _is_collected := false
var _base_scale := Vector2.ONE

func _ready() -> void:
	add_to_group("thread_knot_pickups")
	if sprite:
		_base_scale = sprite.scale

func launch(initial_velocity: Vector2) -> void:
	velocity = initial_velocity
	_age = 0.0
	_floor_age = randf_range(0.0, TAU)
	_is_vacuuming = false
	_is_collected = false

func _physics_process(delta: float) -> void:
	if _is_collected:
		return

	_age += delta
	var player := _find_player()
	if player and _age >= vacuum_delay and global_position.distance_to(player.global_position) <= vacuum_radius:
		_is_vacuuming = true

	if _is_vacuuming and player:
		_process_vacuum(delta, player)
	else:
		_process_world_motion(delta)

	if sprite:
		sprite.rotation += spin_speed * delta * signf(maxf(absf(velocity.x), 1.0)) * 0.2

func _process_world_motion(delta: float) -> void:
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	var was_falling_fast := velocity.y > min_bounce_speed
	move_and_slide()

	if is_on_floor():
		if was_falling_fast:
			velocity.y = -velocity.y * floor_bounce_damping
		else:
			velocity.y = 0.0
		velocity.x = move_toward(velocity.x, 0.0, floor_friction * delta)
		_floor_age += delta
		if sprite and absf(velocity.x) < 8.0:
			sprite.position.y = sin(_floor_age * bob_speed) * bob_height
	else:
		if sprite:
			sprite.position.y = 0.0

func _process_vacuum(delta: float, player: Node2D) -> void:
	var to_player := player.global_position - global_position
	if to_player.length() <= collect_distance:
		_collect(player)
		return

	var desired_velocity := to_player.normalized() * vacuum_max_speed
	velocity = velocity.move_toward(desired_velocity, vacuum_acceleration * delta)
	global_position += velocity * delta
	if sprite:
		sprite.position.y = 0.0

func _collect(player: Node) -> void:
	if _is_collected:
		return

	_is_collected = true
	if player.has_method("collect_thread_knots"):
		player.collect_thread_knots(value)

	if not sprite:
		queue_free()
		return

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, collect_fade_time)
	tween.tween_property(sprite, "scale", _base_scale * 0.35, collect_fade_time)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

func _find_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D
