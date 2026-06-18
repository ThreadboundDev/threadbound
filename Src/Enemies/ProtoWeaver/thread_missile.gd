class_name ThreadMissile
extends Area2D

@export var damage_amount := 1
@export var knockback_strength := 190.0
@export var arc_gravity := 980.0
@export var flight_fps := 10.0
@export var impact_duration := 0.12
@export var max_lifetime := 3.0

@onready var sprite: Sprite2D = $Sprite2D as Sprite2D

var source: Node = null
var velocity := Vector2.ZERO
var _animation_timer := 0.0
var _lifetime := 0.0
var _is_impacting := false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	if sprite:
		sprite.hframes = 4
		sprite.vframes = 1
		sprite.frame = 0

func launch(initial_velocity: Vector2, hit_source: Node) -> void:
	velocity = initial_velocity
	source = hit_source
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	if _is_impacting:
		return

	_lifetime += delta
	if _lifetime >= max_lifetime:
		_start_impact()
		return

	velocity.y += arc_gravity * delta
	global_position += velocity * delta
	if velocity.length() > 0.01:
		rotation = velocity.angle()

	_update_flight_animation(delta)

func _update_flight_animation(delta: float) -> void:
	if not sprite or flight_fps <= 0.0:
		return

	_animation_timer += delta
	sprite.frame = int(floor(_animation_timer * flight_fps)) % 3

func _on_area_entered(area: Area2D) -> void:
	if _is_impacting:
		return

	var hurtbox := area as HurtboxComponent
	if not hurtbox:
		return

	var damage := DamageData.new()
	damage.amount = damage_amount
	damage.source = source
	damage.hit_position = global_position
	var knockback_direction := velocity.normalized()
	if knockback_direction.length() <= 0.01:
		knockback_direction = Vector2.RIGHT
	damage.knockback = knockback_direction * knockback_strength

	hurtbox.receive_hit(damage)
	_start_impact()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
	_start_impact()

func _start_impact() -> void:
	if _is_impacting:
		return

	_is_impacting = true
	monitoring = false
	velocity = Vector2.ZERO
	if sprite:
		sprite.frame = 3
	await get_tree().create_timer(impact_duration).timeout
	queue_free()
