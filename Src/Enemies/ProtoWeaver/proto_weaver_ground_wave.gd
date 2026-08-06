class_name ProtoWeaverGroundWave
extends Area2D

@export var travel_speed := 820.0
@export var lifetime := 1.7
@export var damage_amount := 30
@export var knockback_strength := 230.0
@export var visual_height := 132.0

var source: Node
var _direction := 1.0
var _elapsed := 0.0
var _hit_player := false
var _impacting := false
var _impact_elapsed := 0.0
var _impact_duration := 0.16

func _ready() -> void:
	collision_layer = 0
	collision_mask = 3
	z_index = 2
	area_entered.connect(_on_area_entered)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(138.0, 104.0)
	var collision := CollisionShape2D.new()
	collision.position = Vector2(6.0, -52.0)
	collision.shape = shape
	add_child(collision)
	queue_redraw()

func launch(direction: int, hit_source: Node) -> void:
	_direction = float(sign(direction)) if direction != 0 else 1.0
	source = hit_source
	scale.x = _direction

func _physics_process(delta: float) -> void:
	if _impacting:
		_impact_elapsed += delta
		if _impact_elapsed >= _impact_duration:
			queue_free()
			return
		queue_redraw()
		return
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
		return
	global_position.x += _direction * travel_speed * delta
	queue_redraw()

func _draw() -> void:
	var pulse := 0.5 + sin(_elapsed * 22.0) * 0.5
	var impact_alpha := 1.0
	var impact_scale := 1.0
	if _impacting:
		var impact_ratio := clampf(_impact_elapsed / _impact_duration, 0.0, 1.0)
		impact_alpha = 1.0 - impact_ratio
		impact_scale = lerpf(1.0, 1.38, impact_ratio)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * impact_scale)

	# A low, forward-cutting energy fang with two fading echoes behind it.
	for echo in range(2, -1, -1):
		var echo_offset := Vector2(-float(echo) * 28.0, float(echo) * 3.0)
		var echo_scale := 1.0 - float(echo) * 0.13
		var echo_alpha := impact_alpha * (0.24 + float(2 - echo) * 0.34)
		_draw_fang(echo_offset, echo_scale, echo_alpha, pulse)

	# Ground seam and small debris/thread sparks make the projectile feel planted.
	draw_line(Vector2(-82.0, -1.0), Vector2(78.0, -1.0), Color(0.18, 0.075, 0.025, impact_alpha * 0.9), 13.0, true)
	draw_line(Vector2(-74.0, -4.0), Vector2(72.0, -4.0), Color(1.0, 0.48, 0.08, impact_alpha * 0.72), 3.0, true)
	for spark in range(8):
		var phase := fmod(_elapsed * (2.1 + float(spark) * 0.07) + float(spark) * 0.17, 1.0)
		var spark_position := Vector2(lerpf(-94.0, 44.0, phase), -sin(phase * PI) * (16.0 + float(spark % 3) * 7.0))
		var spark_tip := spark_position + Vector2(-14.0, 9.0)
		draw_line(spark_position, spark_tip, Color(1.0, 0.78, 0.3, impact_alpha * (1.0 - phase)), 2.0, true)

func _draw_fang(offset: Vector2, scale_factor: float, alpha: float, pulse: float) -> void:
	var outer := PackedVector2Array([
		offset + Vector2(-62.0, -5.0) * scale_factor,
		offset + Vector2(-38.0, -20.0) * scale_factor,
		offset + Vector2(-8.0, -54.0) * scale_factor,
		offset + Vector2(24.0, -96.0) * scale_factor,
		offset + Vector2(70.0, -visual_height) * scale_factor,
		offset + Vector2(57.0, -80.0) * scale_factor,
		offset + Vector2(64.0, -24.0) * scale_factor,
		offset + Vector2(78.0, -7.0) * scale_factor,
		offset + Vector2(22.0, -15.0) * scale_factor,
	])
	draw_colored_polygon(outer, Color(0.94, 0.38, 0.07, minf(1.0, alpha * 0.58)))
	draw_polyline(outer, Color(1.0, 0.68, 0.2, minf(1.0, alpha * 0.95)), lerpf(8.0, 11.0, pulse), true)
	var core := PackedVector2Array([
		offset + Vector2(-46.0, -8.0) * scale_factor,
		offset + Vector2(-7.0, -48.0) * scale_factor,
		offset + Vector2(60.0, -visual_height + 18.0) * scale_factor,
		offset + Vector2(43.0, -62.0) * scale_factor,
		offset + Vector2(57.0, -14.0) * scale_factor,
	])
	draw_polyline(core, Color(1.0, 0.98, 0.84, minf(1.0, alpha * 1.2)), lerpf(4.0, 6.0, pulse), true)

func _on_area_entered(area: Area2D) -> void:
	if _hit_player:
		return
	var hurtbox := area as HurtboxComponent
	if not hurtbox or not hurtbox.hurtbox_owner or not hurtbox.hurtbox_owner.is_in_group("player"):
		return

	var damage := DamageData.new()
	damage.amount = EnemyScaling.scale_damage(damage_amount)
	damage.source = source
	damage.hit_position = global_position
	damage.knockback = Vector2(_direction * knockback_strength, -120.0)
	damage.hitstun = 0.22
	damage.hit_pause = 0.045
	if hurtbox.receive_hit(damage):
		_hit_player = true
		set_deferred("monitoring", false)
		_start_impact()

func _start_impact() -> void:
	_impacting = true
	_impact_elapsed = 0.0
