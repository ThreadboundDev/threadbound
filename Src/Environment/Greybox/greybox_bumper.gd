@tool
class_name GreyboxBumper2D
extends StaticBody2D

enum LaunchMode {
	RECOIL,
	THROUGH,
}

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
@export var launch_mode := LaunchMode.RECOIL:
	set(value):
		launch_mode = value
		queue_redraw()
@export_range(0.1, 8.0, 0.05, "or_greater") var launch_jump_heights := 2.0
@export_range(0.0, 1200.0, 10.0, "or_greater") var ground_scoot_speed := 320.0
@export_range(0.0, 30.0, 0.1, "or_greater") var regeneration_delay := 3.0
@export_group("Prototype Appearance")
@export var bumper_color := Color(0.92, 0.18, 0.22, 0.96):
	set(value):
		bumper_color = value
		queue_redraw()
@export var outline_color := Color(0.55, 0.72, 1.0, 1.0):
	set(value):
		outline_color = value
		queue_redraw()

@onready var solid_collision: CollisionShape2D = $CollisionShape2D
@onready var hit_receiver_collision: CollisionShape2D = $HitReceiver/CollisionShape2D
@onready var dash_receiver_collision: CollisionShape2D = $DashReceiver/CollisionShape2D

var _hits_remaining := 1
var _is_broken := false


func _ready() -> void:
	_hits_remaining = hits_to_break
	_refresh()
	if not Engine.is_editor_hint():
		$HitReceiver.hit_received.connect(_on_hit_received)
		$DashReceiver.body_entered.connect(_on_dash_body_entered)


func _refresh() -> void:
	queue_redraw()
	if not is_node_ready():
		return
	_set_rectangle_size(solid_collision, size)
	_set_rectangle_size(hit_receiver_collision, size)
	_set_rectangle_size(dash_receiver_collision, size + Vector2(32.0, 32.0))


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
	var mode_color := bumper_color
	if launch_mode == LaunchMode.THROUGH:
		mode_color = Color(0.94, 0.96, 1.0, bumper_color.a)
	var display_color := mode_color.darkened((1.0 - health_ratio) * 0.28)
	draw_rect(rect, display_color, true)
	draw_rect(rect, outline_color, false, 4.0)
	var mode_label := "RECOIL" if launch_mode == LaunchMode.RECOIL else "THROUGH"
	var label_size := ThemeDB.fallback_font.get_string_size(mode_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-label_size.x * 0.5, 6.0),
		mode_label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color(1.0, 1.0, 1.0, 0.96) if launch_mode == LaunchMode.RECOIL else Color(0.03, 0.08, 0.13, 0.92)
	)
	if hits_to_break > 1:
		var pip_spacing := 14.0
		var pip_width := float(hits_to_break - 1) * pip_spacing
		for index in hits_to_break:
			var pip_position := Vector2(
				-pip_width * 0.5 + float(index) * pip_spacing,
				0.0
			)
			draw_circle(pip_position, 4.0, outline_color if index < _hits_remaining else outline_color.darkened(0.65))


func _on_hit_received(damage: DamageData) -> void:
	if _is_broken or launch_mode == LaunchMode.THROUGH:
		return
	_accept_activation(damage, false)


func _on_dash_body_entered(body: Node2D) -> void:
	if (
		_is_broken
		or not body.is_in_group("player")
		or not body.has_method("is_dash_active")
		or not bool(body.call("is_dash_active"))
	):
		return
	var dash_hit := DamageData.new()
	dash_hit.source = body
	dash_hit.knockback = body.velocity
	_accept_activation(dash_hit, true)


func _accept_activation(damage: DamageData, force_full_launch: bool) -> void:
	_hits_remaining = maxi(_hits_remaining - 1, 0)
	hit_count_changed.emit(_hits_remaining)
	queue_redraw()
	if _hits_remaining > 0:
		return
	_break(damage, force_full_launch)


func _break(damage: DamageData, force_full_launch := false) -> void:
	_is_broken = true
	solid_collision.set_deferred("disabled", true)
	hit_receiver_collision.set_deferred("disabled", true)
	dash_receiver_collision.set_deferred("disabled", true)
	queue_redraw()
	broken.emit()
	_launch_attacker(damage, force_full_launch)
	if regeneration_delay > 0.0:
		get_tree().create_timer(regeneration_delay).timeout.connect(_regenerate)


func _launch_attacker(damage: DamageData, force_full_launch := false) -> void:
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
	var was_grounded: bool = source.is_on_floor() and not force_full_launch
	var launch_direction := get_launch_direction_for_attack(incoming_direction)
	# Wait until the hitbox has emitted hit_landed so an ordinary pogo callback
	# cannot overwrite this stronger, direction-aware traversal launch.
	source.call_deferred(
		"apply_traversal_launch",
		launch_direction,
		launch_jump_heights,
		was_grounded,
		ground_scoot_speed
	)


func get_launch_direction_for_attack(attack_direction: Vector2) -> Vector2:
	var normalized_direction := attack_direction.normalized()
	if normalized_direction == Vector2.ZERO:
		normalized_direction = Vector2.DOWN
	if launch_mode == LaunchMode.THROUGH:
		return normalized_direction
	return -normalized_direction


func _regenerate() -> void:
	if not is_inside_tree():
		return
	_is_broken = false
	_hits_remaining = hits_to_break
	solid_collision.set_deferred("disabled", false)
	hit_receiver_collision.set_deferred("disabled", false)
	dash_receiver_collision.set_deferred("disabled", false)
	queue_redraw()
	regenerated.emit()


func get_hits_remaining() -> int:
	return _hits_remaining


func is_broken() -> bool:
	return _is_broken
