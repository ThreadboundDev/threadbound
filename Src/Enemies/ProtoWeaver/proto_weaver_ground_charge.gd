class_name ProtoWeaverGroundCharge
extends Node2D

var _duration := 1.0
var _elapsed := 0.0
var _direction := 1.0

func configure(direction: int, duration: float) -> void:
	_direction = float(sign(direction)) if direction != 0 else 1.0
	_duration = maxf(0.2, duration)
	position = Vector2(_direction * 154.0, -42.0)

func _ready() -> void:
	z_index = 3
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var ratio := clampf(_elapsed / _duration, 0.0, 1.0)
	var pulse := 0.5 + sin(_elapsed * 20.0) * 0.5
	var radius := lerpf(18.0, 58.0, smoothstep(0.0, 0.78, ratio))
	var alpha := smoothstep(0.0, 0.18, ratio) * (1.0 - smoothstep(0.82, 1.0, ratio))

	draw_arc(Vector2.ZERO, radius, PI * 0.12, PI * 0.88, 20, Color(1.0, 0.74, 0.26, alpha * 0.36), 10.0, true)
	draw_arc(Vector2.ZERO, radius * 0.72, PI * 0.08, PI * 0.92, 18, Color(1.0, 0.97, 0.82, alpha), lerpf(2.0, 4.0, pulse), true)
	draw_line(Vector2(-radius, 1.0), Vector2(radius, 1.0), Color(0.96, 0.52, 0.12, alpha * 0.62), 5.0, true)
	for spark in range(5):
		var spark_ratio := fmod(ratio * 2.4 + float(spark) * 0.21, 1.0)
		var spark_x := lerpf(-radius, radius, spark_ratio)
		var spark_y := -sin(spark_ratio * PI) * radius * 0.72
		draw_circle(Vector2(spark_x, spark_y), lerpf(1.5, 4.0, pulse), Color(1.0, 0.86, 0.52, alpha))
