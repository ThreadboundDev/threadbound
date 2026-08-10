class_name ProtoWeaverSpacingVFX
extends Area2D

@export var damage_amount := 12
@export var radius := 190.0
@export var knockback_strength := 520.0
@export var active_time := 0.13
@export var lifetime := 0.46

var source: Node
var _elapsed := 0.0
var _hit_player := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = 4
	area_entered.connect(_on_area_entered)

	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	queue_redraw()


func configure(hit_source: Node, hit_damage: int, effect_radius: float) -> void:
	source = hit_source
	damage_amount = hit_damage
	radius = effect_radius


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= active_time:
		monitoring = false
	if _elapsed >= lifetime:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var ratio := clampf(_elapsed / maxf(lifetime, 0.001), 0.0, 1.0)
	var burst := 1.0 - pow(1.0 - minf(ratio * 1.8, 1.0), 3.0)
	var alpha := pow(1.0 - ratio, 1.5)
	var current_radius := radius * burst

	draw_circle(Vector2.ZERO, current_radius, Color(0.02, 0.18, 0.95, alpha * 0.08))
	draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 48, Color(0.04, 0.34, 1.0, alpha * 0.9), 9.0, true)
	draw_arc(Vector2.ZERO, current_radius * 0.82, 0.0, TAU, 48, Color(0.9, 0.97, 1.0, alpha), 3.0, true)
	for strand in range(12):
		var angle := float(strand) * TAU / 12.0 + sin(_elapsed * 8.0 + float(strand)) * 0.09
		var direction := Vector2.from_angle(angle)
		var tangent := Vector2(-direction.y, direction.x)
		var start := direction * current_radius * 0.2
		var middle := direction * current_radius * 0.58 + tangent * sin(float(strand) * 1.7) * 18.0
		var end := direction * current_radius
		draw_polyline(
			PackedVector2Array([start, middle, end]),
			Color(0.04, 0.3, 1.0, alpha * 0.8),
			4.0,
			true
		)


func _on_area_entered(area: Area2D) -> void:
	if _hit_player or _elapsed > active_time:
		return
	var hurtbox := area as HurtboxComponent
	if not hurtbox or not hurtbox.hurtbox_owner or not hurtbox.hurtbox_owner.is_in_group("player"):
		return

	var direction := signf(hurtbox.global_position.x - global_position.x)
	if direction == 0.0:
		direction = 1.0
	var damage := DamageData.new()
	damage.amount = EnemyScaling.scale_damage(damage_amount)
	damage.source = source
	damage.hit_position = hurtbox.global_position
	damage.knockback = Vector2(direction * knockback_strength, -145.0)
	damage.hitstun = 0.24
	damage.hit_pause = 0.045
	if hurtbox.receive_hit(damage):
		_hit_player = true
		monitoring = false
