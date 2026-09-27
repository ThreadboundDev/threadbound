@tool
extends CanvasLayer
class_name ScreenGlowGrade

@export_group("Glow")
@export_range(0.0, 2.0, 0.01) var glow_strength := 0.16
@export_range(0.0, 2.0, 0.01) var glow_threshold := 1.08
@export_range(0.01, 1.0, 0.01) var glow_soft_knee := 0.14
@export_range(1.0, 6.0, 0.1) var glow_spread := 2.6

@export_group("Grade")
@export_range(-1.0, 1.0, 0.01) var exposure := 0.0
@export_range(0.5, 1.5, 0.01) var contrast := 1.0
@export_range(0.0, 1.5, 0.01) var saturation := 1.0
@export var color_balance := Vector3.ONE

@export_group("Vignette")
@export_range(0.0, 1.0, 0.01) var vignette_strength := 0.03
@export_range(0.1, 1.5, 0.01) var vignette_radius := 1.05

@export var enabled := true:
	set(value):
		enabled = value
		_refresh_visibility()

@onready var composite: ColorRect = $Composite

func _ready() -> void:
	_refresh_visibility()
	_apply_parameters()
	if not Engine.is_editor_hint():
		call_deferred(&"_enable_blue_flow_prototype")

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_apply_parameters()

func _refresh_visibility() -> void:
	if is_instance_valid(composite):
		composite.visible = enabled

func _enable_blue_flow_prototype() -> void:
	for flow_vfx in get_tree().get_nodes_in_group(&"flow_state_vfx"):
		if flow_vfx.has_method(&"enable_multimesh_soul_trail"):
			flow_vfx.call(&"enable_multimesh_soul_trail", true)

func _apply_parameters() -> void:
	if not is_instance_valid(composite):
		return
	var shader_material := composite.material as ShaderMaterial
	if not shader_material:
		return
	shader_material.set_shader_parameter(&"glow_strength", glow_strength)
	shader_material.set_shader_parameter(&"glow_threshold", glow_threshold)
	shader_material.set_shader_parameter(&"glow_soft_knee", glow_soft_knee)
	shader_material.set_shader_parameter(&"glow_spread", glow_spread)
	shader_material.set_shader_parameter(&"exposure", exposure)
	shader_material.set_shader_parameter(&"contrast", contrast)
	shader_material.set_shader_parameter(&"saturation", saturation)
	shader_material.set_shader_parameter(&"color_balance", color_balance)
	shader_material.set_shader_parameter(&"vignette_strength", vignette_strength)
	shader_material.set_shader_parameter(&"vignette_radius", vignette_radius)
