@tool
extends Node3D
## Scene-local art direction. No project renderer or global settings are changed.
@export_enum("Soft daylight", "Blue dusk") var lighting_preset := 0:
	set(value):
		lighting_preset = value
		if is_node_ready():
			apply_preset()
@export_range(0.0, 2.0, 0.01) var sun_multiplier := 1.0:
	set(value):
		sun_multiplier = value
		if is_node_ready():
			apply_preset()
@export var contact_shading := true:
	set(value):
		contact_shading = value
		if is_node_ready():
			apply_preset()

func _ready() -> void:
	# Each stage owns its Environment; inspector edits cannot mutate another room.
	$WorldEnvironment.environment = $WorldEnvironment.environment.duplicate()
	apply_preset()

func apply_preset() -> void:
	var dusk := lighting_preset == 1
	var env := $WorldEnvironment.environment as Environment
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.ambient_light_color = Color(0.40, 0.55, 0.78) if dusk else Color(0.64, 0.74, 0.84)
	env.ambient_light_energy = 0.24 if dusk else 0.36
	env.ssao_enabled = contact_shading
	$Sun.light_color = Color(0.61, 0.74, 1.0) if dusk else Color(1.0, 0.88, 0.72)
	$Sun.light_energy = (0.38 if dusk else 1.05) * sun_multiplier
	$Sun.rotation_degrees = Vector3(-32, -28, 0)
	$SkyFill.light_energy = 0.12 if dusk else 0.20
