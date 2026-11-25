@tool
extends "res://Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_model_2d.gd"
## Standalone furniture marker, scaled to the existing player's height.
@export var asset_scale := 0.78
@export var model_depth := -0.4

func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(render_model):
		render_model.scale *= asset_scale
		render_model.position.z = model_depth
