class_name GrappleStrikeTrailVFX
extends Node2D

const IVORY := Color(1.0, 0.97, 0.84)
const GOLD := Color(1.0, 0.72, 0.24)

@export_range(0.04, 0.3, 0.01) var fade_out_time := 0.12
@export_range(40.0, 180.0, 1.0) var trail_length := 112.0

var _target: Node2D = null
var _direction := Vector2.RIGHT
var _elapsed := 0.0
var _fade := 1.0
var _stopping := false

func _ready() -> void:
	z_index = 70
	queue_redraw()

func play(target: Node2D, direction: Vector2) -> void:
	_target = target
	update_direction(direction)
	_elapsed = 0.0
	_fade = 1.0
	_stopping = false
	visible = true

func update_direction(direction: Vector2) -> void:
	if direction.length_squared() > 0.001:
		_direction = direction.normalized()
	rotation = _direction.angle()

func stop() -> void:
	_stopping = true

func _process(delta: float) -> void:
	_elapsed += delta
	if is_instance_valid(_target):
		global_position = _target.global_position
	elif not _stopping:
		_stopping = true
	if _stopping:
		_fade = maxf(0.0, _fade - delta / maxf(fade_out_time, 0.01))
		if _fade <= 0.0:
			queue_free()
			return
	queue_redraw()

func _draw() -> void:
	var pulse := sin(_elapsed * 34.0) * 3.0
	for index in range(7):
		var lane := float(index - 3)
		var length_weight := 1.0 - absf(lane) * 0.055
		var start := Vector2(-18.0 + pulse * 0.15, lane * 7.0)
		var finish := Vector2(-trail_length * length_weight + pulse, lane * 12.0)
		var color := IVORY if index % 2 == 0 else GOLD
		color.a = _fade * (0.72 - absf(lane) * 0.08)
		draw_line(start, finish, color, 3.2 if index == 3 else 1.8, true)
	for index in range(4):
		var offset := float(index - 2) * 15.0
		var spark := IVORY
		spark.a = _fade * 0.55
		draw_line(
			Vector2(-42.0 - float(index) * 18.0, offset),
			Vector2(-70.0 - float(index) * 24.0, offset * 1.15),
			spark,
			1.2,
			true
		)
