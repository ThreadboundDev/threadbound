class_name ThreadMissile
extends Area2D

@export var damage_amount := 24
@export var knockback_strength := 190.0
@export var arc_gravity := 1650.0
@export var flight_fps := 10.0
@export var impact_duration := 0.12
@export var max_lifetime := 2.6
@export var arming_time := 0.14
@export var velocity_rotation_offset := -PI / 2.0
@export var world_collision_descent_ratio := 0.42

@onready var sprite: Sprite2D = $Sprite2D as Sprite2D

var source: Node = null
var velocity := Vector2.ZERO
var _animation_timer := 0.0
var _lifetime := 0.0
var _is_impacting := false
var _planned_flight_time := 1.0
var _landing_marker: ThreadMissileLaserMarker
var _marker_released := false


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	monitoring = false
	if sprite:
		sprite.hframes = 4
		sprite.vframes = 1
		sprite.frame = 0


func _exit_tree() -> void:
	if is_instance_valid(_landing_marker) and not _marker_released:
		_landing_marker.cancel()


func launch(initial_velocity: Vector2, hit_source: Node) -> void:
	velocity = initial_velocity
	source = hit_source
	_update_velocity_rotation()
	_arm_after_delay()


func launch_to_landing(landing_position: Vector2, flight_time: float, hit_source: Node) -> void:
	var safe_time := maxf(0.35, flight_time)
	_planned_flight_time = safe_time
	var displacement := landing_position - global_position
	velocity = Vector2(
		displacement.x / safe_time,
		(displacement.y - 0.5 * arc_gravity * safe_time * safe_time) / safe_time
	)
	source = hit_source
	max_lifetime = maxf(max_lifetime, safe_time + 0.35)
	_create_landing_marker(landing_position)
	_update_velocity_rotation()
	_arm_after_delay()


func _create_landing_marker(landing_position: Vector2) -> void:
	var parent := get_parent()
	if not parent:
		return
	_landing_marker = ThreadMissileLaserMarker.new()
	parent.add_child(_landing_marker)
	_landing_marker.configure(landing_position)


func _physics_process(delta: float) -> void:
	if _is_impacting:
		return

	_lifetime += delta
	if _lifetime >= max_lifetime:
		queue_free()
		return

	velocity.y += arc_gravity * delta
	global_position += velocity * delta
	if velocity.length() > 0.01:
		_update_velocity_rotation()
	if is_instance_valid(_landing_marker):
		_landing_marker.update_flight(
			global_position,
			_lifetime / maxf(_planned_flight_time, 0.01),
			velocity.y >= 0.0
		)

	_update_flight_animation(delta)


func _update_flight_animation(delta: float) -> void:
	if not sprite or flight_fps <= 0.0:
		return
	_animation_timer += delta
	sprite.frame = int(floor(_animation_timer * flight_fps)) % 3


func _update_velocity_rotation() -> void:
	rotation = velocity.angle() + velocity_rotation_offset


func _on_area_entered(area: Area2D) -> void:
	if _is_impacting or not monitoring:
		return

	var hurtbox := area as HurtboxComponent
	if not hurtbox:
		return

	var damage := DamageData.new()
	damage.amount = EnemyScaling.scale_damage(damage_amount)
	damage.source = source
	damage.hit_position = global_position
	var knockback_direction := velocity.normalized()
	if knockback_direction.length() <= 0.01:
		knockback_direction = Vector2.RIGHT
	damage.knockback = knockback_direction * knockback_strength

	if hurtbox.receive_hit(damage):
		_start_impact()


func _on_body_entered(body: Node2D) -> void:
	if _is_impacting or not monitoring or body.is_in_group("player"):
		return
	if velocity.y < 0.0 or _lifetime < _planned_flight_time * world_collision_descent_ratio:
		return
	_start_impact()


func _arm_after_delay() -> void:
	await get_tree().create_timer(arming_time).timeout
	if not _is_impacting:
		set_deferred("monitoring", true)


func _start_impact() -> void:
	if _is_impacting:
		return

	_is_impacting = true
	set_deferred("monitoring", false)
	velocity = Vector2.ZERO
	if sprite:
		sprite.visible = false
	if is_instance_valid(_landing_marker):
		_landing_marker.trigger_impact()
		_marker_released = true
	await get_tree().create_timer(impact_duration).timeout
	queue_free()
