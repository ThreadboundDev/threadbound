@tool
class_name GreyboxHazard2D
extends Area2D

@export var size := Vector2(192.0, 64.0):
	set(value):
		size = Vector2(maxf(value.x, 8.0), maxf(value.y, 8.0))
		_refresh()
@export_range(1, 999, 1) var damage := 20
@export var knockback := Vector2(320.0, -360.0)
@export_range(0.05, 5.0, 0.05) var retrigger_delay := 0.7
@export_group("Prototype Appearance")
@export var hazard_color := Color(0.78, 0.035, 0.055, 0.88)
@export var spike_edge_color := Color(1.0, 0.3, 0.25, 1.0)
@export_range(12.0, 128.0, 1.0) var preferred_spike_width := 42.0:
	set(value):
		preferred_spike_width = maxf(value, 12.0)
		queue_redraw()
@export var debug_draw_enabled := true:
	set(value):
		debug_draw_enabled = value
		queue_redraw()
@onready var collision: CollisionShape2D = $CollisionShape2D
var _cooldowns: Dictionary = {}


func _ready() -> void:
	_refresh()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for body in _cooldowns.keys():
		_cooldowns[body] = maxf(float(_cooldowns[body]) - delta, 0.0)
		if float(_cooldowns[body]) <= 0.0 and overlaps_body(body):
			_damage_body(body)


func _refresh() -> void:
	queue_redraw()
	if not is_node_ready():
		return
	var rectangle := collision.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		collision.shape = rectangle
	rectangle.size = size


func _draw() -> void:
	if not debug_draw_enabled:
		return
	var half_size := size * 0.5
	var spike_count := maxi(1, int(round(size.x / preferred_spike_width)))
	var spike_width := size.x / float(spike_count)
	var base_y := half_size.y
	var tip_y := -half_size.y
	for index in spike_count:
		var left_x := -half_size.x + float(index) * spike_width
		var right_x := left_x + spike_width
		var tip_x := (left_x + right_x) * 0.5
		var triangle := PackedVector2Array([
			Vector2(left_x, base_y),
			Vector2(tip_x, tip_y),
			Vector2(right_x, base_y),
		])
		draw_colored_polygon(triangle, hazard_color)
		draw_polyline(PackedVector2Array([
			triangle[0], triangle[1], triangle[2], triangle[0]
		]), spike_edge_color, 3.0, true)
	draw_line(
		Vector2(-half_size.x, base_y),
		Vector2(half_size.x, base_y),
		spike_edge_color,
		4.0,
		true
	)


func _on_body_entered(body: Node2D) -> void:
	_damage_body(body)


func _on_body_exited(body: Node2D) -> void:
	_cooldowns.erase(body)


func _damage_body(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var hurtbox := body.get_node_or_null("Hurtbox") as HurtboxComponent
	if hurtbox == null:
		return
	var hit := DamageData.new()
	hit.amount = damage
	hit.knockback = Vector2(signf(body.global_position.x - global_position.x) * absf(knockback.x), knockback.y)
	hit.hitstun = 0.18
	hit.source = self
	hit.hit_position = body.global_position
	hurtbox.receive_hit(hit)
	_cooldowns[body] = retrigger_delay
