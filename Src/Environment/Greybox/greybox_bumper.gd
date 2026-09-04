@tool
class_name GreyboxBumper2D
extends Node2D

signal hit_count_changed(hits_remaining: int)
signal broken
signal regenerated

@export var size := Vector2(128.0, 128.0):
	set(value):
		size = Vector2(maxf(value.x, 8.0), maxf(value.y, 8.0))
		_refresh()
@export_range(1, 99, 1) var hits_to_break := 1:
	set(value):
		hits_to_break = maxi(value, 1)
		if not _is_broken:
			_hits_remaining = hits_to_break
		queue_redraw()
@export_range(0.1, 8.0, 0.05, "or_greater") var launch_jump_heights := 2.0
@export_range(0.0, 1200.0, 10.0, "or_greater") var ground_scoot_speed := 320.0
@export_range(0.0, 1200.0, 10.0, "or_greater") var contact_bonk_speed := 240.0
@export_range(0.0, 128.0, 1.0, "or_greater") var contact_clearance := 40.0
@export_range(0.0, 3000.0, 10.0, "or_greater") var required_break_speed := 700.0
@export_range(1.0, 3.0, 0.05, "or_greater") var momentum_multiplier := 1.2
@export_range(0.0, 1200.0, 10.0, "or_greater") var minimum_exit_speed := 820.0
@export_range(0.0, 1.0, 0.05) var failure_speed_retention := 0.65
@export_range(0.0, 30.0, 0.1, "or_greater") var regeneration_delay := 3.0
@export_group("Prototype Appearance")
@export var bumper_color := Color(0.94, 0.96, 1.0, 0.96):
	set(value):
		bumper_color = value
		queue_redraw()
@export var outline_color := Color(0.33, 0.78, 1.0, 1.0):
	set(value):
		outline_color = value
		queue_redraw()

@onready var hit_receiver_collision: CollisionShape2D = $HitReceiver/CollisionShape2D
@onready var contact_receiver_collision: CollisionShape2D = $ContactReceiver/CollisionShape2D
@onready var grapple_receiver_collision: CollisionShape2D = $GrappleTarget/CollisionShape2D

var _hits_remaining := 1
var _is_broken := false


func _ready() -> void:
	_hits_remaining = hits_to_break
	_refresh()
	if not Engine.is_editor_hint():
		$HitReceiver.hit_received.connect(_on_hit_received)
		$ContactReceiver.body_entered.connect(_on_body_entered)
		call_deferred("_resolve_existing_overlaps")


func _refresh() -> void:
	queue_redraw()
	if not is_node_ready():
		return
	_set_rectangle_size(hit_receiver_collision, size)
	_set_rectangle_size(contact_receiver_collision, size)
	_set_rectangle_size(grapple_receiver_collision, size)


func _set_rectangle_size(collision_shape: CollisionShape2D, rectangle_size: Vector2) -> void:
	var rectangle := collision_shape.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		collision_shape.shape = rectangle
	rectangle.size = rectangle_size


func _draw() -> void:
	if _is_broken:
		return
	var rect := Rect2(-size * 0.5, size)
	var health_ratio := float(_hits_remaining) / float(maxi(hits_to_break, 1))
	var display_color := bumper_color.darkened((1.0 - health_ratio) * 0.28)
	draw_rect(rect, display_color, true)
	draw_rect(rect, outline_color, false, 4.0)
	var mode_label := "BULB  %d" % roundi(required_break_speed)
	var label_size := ThemeDB.fallback_font.get_string_size(mode_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	draw_string(ThemeDB.fallback_font, Vector2(-label_size.x * 0.5, 6.0), mode_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.03, 0.08, 0.13, 0.92))
	if hits_to_break > 1:
		var pip_spacing := 14.0
		var pip_width := float(hits_to_break - 1) * pip_spacing
		for index in hits_to_break:
			var pip_position := Vector2(-pip_width * 0.5 + float(index) * pip_spacing, 24.0)
			draw_circle(pip_position, 4.0, outline_color if index < _hits_remaining else outline_color.darkened(0.65))


func _on_hit_received(damage: DamageData) -> void:
	# Momentum gates are traversal checks. Weapon damage cannot bypass them.
	pass


func _on_body_entered(body: Node2D) -> void:
	if _is_broken or not body.is_in_group("player"):
		return
	var moving_body := body as CharacterBody2D
	var impact_speed: float = moving_body.velocity.length() if moving_body else 0.0
	if impact_speed >= required_break_speed:
		_break_from_momentum(body)
		return
	_rebound_body(body)


func activate_from_grapple(_source: Node = null) -> bool:
	return false


func _break_from_momentum(body: Node2D) -> void:
	_is_broken = true
	_hits_remaining = 0
	hit_count_changed.emit(_hits_remaining)
	_set_receivers_disabled(true)
	queue_redraw()
	broken.emit()
	var moving_body := body as CharacterBody2D
	var direction: Vector2 = moving_body.velocity.normalized() if moving_body else Vector2.ZERO
	if direction == Vector2.ZERO:
		direction = (body.global_position - global_position).normalized()
	if body.has_method("apply_water_bulb_boost"):
		body.call_deferred("apply_water_bulb_boost", direction, momentum_multiplier, minimum_exit_speed)
	if regeneration_delay > 0.0:
		get_tree().create_timer(regeneration_delay).timeout.connect(_regenerate)


func _rebound_body(body: Node2D) -> void:
	var moving_body := body as CharacterBody2D
	var incoming: Vector2 = moving_body.velocity if moving_body else Vector2.ZERO
	var direction: Vector2 = -incoming.normalized()
	if direction == Vector2.ZERO:
		direction = (body.global_position - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.UP
	_bonk_body_out(body)
	if moving_body:
		moving_body.velocity = direction * maxf(contact_bonk_speed, incoming.length() * failure_speed_retention)


func _accept_activation(damage: DamageData, force_full_launch: bool, recoil: bool) -> void:
	_hits_remaining = maxi(_hits_remaining - 1, 0)
	hit_count_changed.emit(_hits_remaining)
	queue_redraw()
	if _hits_remaining <= 0:
		_break(damage, force_full_launch, recoil)


func _break(damage: DamageData, force_full_launch := false, recoil := true) -> void:
	_is_broken = true
	_set_receivers_disabled(true)
	queue_redraw()
	broken.emit()
	if damage:
		_launch_attacker(damage, force_full_launch, recoil)
	if regeneration_delay > 0.0:
		get_tree().create_timer(regeneration_delay).timeout.connect(_regenerate)


func _launch_attacker(damage: DamageData, force_full_launch: bool, recoil: bool) -> void:
	if damage == null or not is_instance_valid(damage.source):
		return
	var source := damage.source
	if not source.is_in_group("player") or not source.has_method("apply_traversal_launch"):
		return
	var incoming_direction := damage.knockback.normalized()
	if incoming_direction == Vector2.ZERO and source is Node2D:
		incoming_direction = (global_position - (source as Node2D).global_position).normalized()
	if incoming_direction == Vector2.ZERO:
		incoming_direction = Vector2.DOWN
	var launch_direction := -incoming_direction if recoil else incoming_direction
	var was_grounded: bool = source.is_on_floor() and not force_full_launch
	source.call_deferred("apply_traversal_launch", launch_direction, launch_jump_heights, was_grounded, ground_scoot_speed)


func _bonk_body_out(body: Node2D) -> void:
	var local_body := to_local(body.global_position)
	var half_size := size * 0.5
	var distances := [absf(local_body.x + half_size.x), absf(half_size.x - local_body.x), absf(local_body.y + half_size.y), absf(half_size.y - local_body.y)]
	var nearest_edge := 0
	for index in range(1, distances.size()):
		if distances[index] < distances[nearest_edge]:
			nearest_edge = index
	var outward: Vector2 = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN][nearest_edge]
	var resolved_local := local_body
	if outward.x != 0.0:
		resolved_local.x = outward.x * (half_size.x + contact_clearance)
	else:
		resolved_local.y = outward.y * (half_size.y + contact_clearance)
	body.global_position = to_global(resolved_local)
	if "velocity" in body:
		body.velocity = outward * contact_bonk_speed


func _resolve_existing_overlaps() -> void:
	if _is_broken:
		return
	for body in $ContactReceiver.get_overlapping_bodies():
		if body is Node2D:
			_on_body_entered(body as Node2D)


func _set_receivers_disabled(disabled: bool) -> void:
	hit_receiver_collision.set_deferred("disabled", disabled)
	contact_receiver_collision.set_deferred("disabled", disabled)
	grapple_receiver_collision.set_deferred("disabled", disabled)


func _regenerate() -> void:
	if not is_inside_tree():
		return
	_is_broken = false
	_hits_remaining = hits_to_break
	_set_receivers_disabled(false)
	queue_redraw()
	regenerated.emit()
	call_deferred("_resolve_existing_overlaps")


func get_hits_remaining() -> int:
	return _hits_remaining


func is_broken() -> bool:
	return _is_broken
