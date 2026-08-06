class_name ProtoWeaverSmashVFX
extends Node2D

@export var lifetime := 0.48
@export var radius := 190.0

var _elapsed := 0.0

func _ready() -> void:
	z_index = 3
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var ratio := clampf(_elapsed / lifetime, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - ratio, 3.0)
	var alpha := pow(1.0 - ratio, 1.35)
	var current_radius := radius * eased

	draw_arc(Vector2.ZERO, current_radius, PI, TAU, 32, Color(0.98, 0.77, 0.43, alpha * 0.72), 8.0, true)
	draw_arc(Vector2.ZERO, current_radius * 0.72, PI, TAU, 28, Color(1.0, 0.97, 0.82, alpha), 3.0, true)
	for strand in range(9):
		var spread := lerpf(-1.0, 1.0, float(strand) / 8.0)
		var base := Vector2(spread * 54.0, 0.0)
		var tip := Vector2(spread * current_radius, -sin(float(strand + 1) * 0.77) * 34.0 - 18.0)
		var control := Vector2((base.x + tip.x) * 0.5, -current_radius * (0.2 + absf(spread) * 0.12))
		draw_polyline(PackedVector2Array([base, control, tip]), Color(0.88, 0.64, 0.3, alpha * 0.7), 5.0, true)
		draw_polyline(PackedVector2Array([base, control, tip]), Color(1.0, 0.92, 0.72, alpha), 2.0, true)
