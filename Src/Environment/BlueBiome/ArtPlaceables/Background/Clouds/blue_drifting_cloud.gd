class_name BlueDriftingCloud2D
extends Sprite2D

@export var drift_speed := 3.5
@export var wrap_min_x := -4600.0
@export var wrap_max_x := 4600.0
@export_range(0.0, 8.0, 0.1) var billow_amount := 2.0
@export_range(0.0, 2.0, 0.01) var billow_speed := 0.32
@export_range(0.0, 6.283, 0.01) var motion_phase := 0.0
@export_range(0.0, 12.0, 0.1) var vertical_float_amount := 3.0
@export_range(0.0, 1.0, 0.01) var vertical_float_speed := 0.18

var _rest_y := 0.0
var _elapsed := 0.0


func _ready() -> void:
	_rest_y = position.y
	if material is ShaderMaterial:
		material = material.duplicate()
		(material as ShaderMaterial).set_shader_parameter("billow_amount", billow_amount)
		(material as ShaderMaterial).set_shader_parameter("billow_speed", billow_speed)
		(material as ShaderMaterial).set_shader_parameter("billow_phase", motion_phase)


func _process(delta: float) -> void:
	_elapsed += delta
	position.x += drift_speed * delta
	position.y = _rest_y + sin(_elapsed * vertical_float_speed + motion_phase) * vertical_float_amount
	var span := wrap_max_x - wrap_min_x
	if span <= 0.0:
		return
	if position.x > wrap_max_x:
		position.x = wrap_min_x + fmod(position.x - wrap_max_x, span)
	elif position.x < wrap_min_x:
		position.x = wrap_max_x - fmod(wrap_min_x - position.x, span)
