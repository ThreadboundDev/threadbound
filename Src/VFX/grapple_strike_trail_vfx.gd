class_name GrappleStrikeTrailVFX
extends Node2D

const PALETTE := preload("res://Src/VFX/thread_vfx_palette.gd")
const IVORY := PALETTE.CORE
const GOLD := PALETTE.THREAD

@export_range(0.04, 0.3, 0.01) var fade_out_time := 0.12
@export_range(40.0, 180.0, 1.0) var trail_length := 112.0

var _target: Node2D = null
var _direction := Vector2.RIGHT
var _elapsed := 0.0
var _fade := 1.0
var _stopping := false

func _ready() -> void:
	z_index = 70
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unlit
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
	var end := Vector2(-trail_length+pulse,0)
	var ribbon := PackedVector2Array([Vector2(-12,-5),Vector2(-trail_length*.45,-18),end,
		Vector2(-trail_length*.45,18),Vector2(-12,5)])
	draw_colored_polygon(ribbon,Color(PALETTE.FILL,.38*_fade))
	draw_colored_polygon(PackedVector2Array([Vector2(-12,-3),Vector2(-trail_length*.55,-8),end,Vector2(-trail_length*.55,8),Vector2(-12,3)]),Color(IVORY,.40*_fade))
	for index in range(3):
		var lane := float(index - 1)
		var length_weight := 1.0 - absf(lane) * 0.055
		var start := Vector2(-18.0 + pulse * 0.15, lane * 7.0)
		var finish := Vector2(-trail_length * length_weight + pulse, lane * 12.0)
		var color := IVORY if index == 1 else GOLD
		color.a = _fade * (0.72 - absf(lane) * 0.08)
		draw_line(start, finish, color, 3.2 if index == 3 else 1.8, true)
	for index in range(2):
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
