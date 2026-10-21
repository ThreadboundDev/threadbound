@tool
extends "res://Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_model_2d.gd"
## One placement lights both the real 3D world and the existing 2D actors.
@export_range(0.0, 8.0, 0.05) var light_energy_3d := 2.2
@export_range(0.5, 12.0, 0.1) var light_radius_units := 4.0
@export_range(0.0, 1.0, 0.01) var actor_light_energy := 0.28
@export var casts_shadows := true
@export var depth_units := 2.4

func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(render_model):
		render_model.position.z = depth_units
		var light := render_model.get_node("WarmLight") as OmniLight3D
		light.light_energy = light_energy_3d
		light.omni_range = light_radius_units
		light.shadow_enabled = casts_shadows
	if has_node("ActorWarmth"):
		$ActorWarmth.energy = actor_light_energy
		$ActorWarmth.texture_scale = light_radius_units * 256.0 / 512.0
