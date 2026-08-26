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
@export var hazard_color := Color(0.95, 0.08, 0.12, 0.68)
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
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect, hazard_color, true)
	draw_rect(rect, Color(1.0, 0.5, 0.45, 1.0), false, 4.0)
	var left := -size.x * 0.5
	while left < size.x * 0.5:
		draw_line(Vector2(left, size.y * 0.5), Vector2(left + minf(size.y, 48.0) * 0.5, -size.y * 0.5), Color(1.0, 0.75, 0.7, 0.8), 3.0)
		left += minf(size.y, 48.0)


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
