extends Node2D

const BALANCE_BEAM_TEXTURE := preload("res://Assets/VFX/thread_of_balance_beam.png")
const ESSENCE_BEAM_TEXTURE := preload("res://Assets/VFX/thread_of_essence_beam.png")
const POWER_BEAM_TEXTURE := preload("res://Assets/VFX/thread_of_power_beam.png")
const THREAD_LIGHT_TEXTURE := preload("res://Src/Environment/World/lighting/thread_light.png")
const LIGHTS_PER_BEAM := 15
const SEGMENTS := 44

@export var thread_width := 9.0
@export var glow_width := 52.0
@export var motion_speed := 1.15
@export var wiggle_strength := 28.0
@export var loom_origin := Vector2(0, 500)
@export var conduit_top := Vector2(0, -1560)
@export var beam_width := 92.0
@export var beam_light_energy := 0.54
@export var beam_light_scale := 7.25

var _time := 0.0
var _beam_lines: Array[Line2D] = []
var _glow_lines: Array[Line2D] = []
var _outer_glow_lines: Array[Line2D] = []
var _beam_lights: Array[Array] = []

func _ready() -> void:
	_build_beams()

func _process(delta: float) -> void:
	_time += delta * motion_speed
	_update_beams()

func _build_beams() -> void:
	for spec: Dictionary in _thread_specs():
		var outer_glow := Line2D.new()
		outer_glow.name = "%sOuterGlow" % spec["name"]
		outer_glow.z_index = -3
		outer_glow.width = beam_width * 1.45
		outer_glow.default_color = _with_alpha(spec["glow_color"] as Color, 0.055)
		outer_glow.antialiased = true
		add_child(outer_glow)
		_outer_glow_lines.append(outer_glow)

		var glow := Line2D.new()
		glow.name = "%sGlow" % spec["name"]
		glow.z_index = -2
		glow.width = beam_width * 1.12
		glow.default_color = _with_alpha(spec["glow_color"] as Color, 0.16)
		glow.antialiased = true
		add_child(glow)
		_glow_lines.append(glow)

		var beam := Line2D.new()
		beam.name = "%sBeam" % spec["name"]
		beam.z_index = -1
		beam.width = beam_width
		beam.texture = spec["texture"] as Texture2D
		beam.texture_mode = 2
		beam.default_color = Color(1.18, 1.12, 1.0, 1.0)
		beam.antialiased = true
		add_child(beam)
		_beam_lines.append(beam)

		var lights: Array[PointLight2D] = []
		for i in range(LIGHTS_PER_BEAM):
			var light := PointLight2D.new()
			light.name = "%sLight%02d" % [spec["name"], i + 1]
			light.z_index = -1
			light.texture = THREAD_LIGHT_TEXTURE
			light.texture_scale = beam_light_scale
			light.color = spec["light_color"] as Color
			light.energy = beam_light_energy
			light.range_z_min = -4096
			light.range_z_max = 4096
			add_child(light)
			lights.append(light)
		_beam_lights.append(lights)

	_update_beams()

func _update_beams() -> void:
	var specs: Array = _thread_specs()
	for index in range(specs.size()):
		var spec: Dictionary = specs[index]
		var points := _thread_points(float(spec["offset"]), float(spec["phase"]))
		_outer_glow_lines[index].points = points
		_glow_lines[index].points = points
		_beam_lines[index].points = points

		var lights: Array = _beam_lights[index]
		for light_index in range(lights.size()):
			var t := float(light_index) / float(max(lights.size() - 1, 1))
			var light := lights[light_index] as PointLight2D
			light.position = _sample_point(points, t)
			light.energy = beam_light_energy * lerp(0.92, 1.24, 1.0 - abs(t - 0.5) * 2.0)

func _thread_specs() -> Array:
	return [
		{
			"name": "PowerThread",
			"texture": POWER_BEAM_TEXTURE,
			"glow_color": Color(1.0, 0.18, 0.14, 1.0),
			"light_color": Color(1.0, 0.48, 0.4, 1.0),
			"offset": -56.0,
			"phase": 0.0,
		},
		{
			"name": "BalanceThread",
			"texture": BALANCE_BEAM_TEXTURE,
			"glow_color": Color(1.0, 0.78, 0.22, 1.0),
			"light_color": Color(1.0, 0.84, 0.46, 1.0),
			"offset": 0.0,
			"phase": 2.1,
		},
		{
			"name": "EssenceThread",
			"texture": ESSENCE_BEAM_TEXTURE,
			"glow_color": Color(0.22, 0.62, 1.0, 1.0),
			"light_color": Color(0.48, 0.72, 1.0, 1.0),
			"offset": 56.0,
			"phase": 4.2,
		},
	]

func _thread_points(offset: float, phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(SEGMENTS + 1):
		var t := float(i) / float(SEGMENTS)
		var y: float = lerp(loom_origin.y, conduit_top.y, t)
		var base_x: float = lerp(loom_origin.x + offset * 0.18, conduit_top.x + offset, t)
		var twist: float = sin(t * TAU * 3.0 + _time + phase) * wiggle_strength * (0.25 + t * 0.75)
		var counter: float = sin(t * TAU * 7.0 - _time * 1.6 + phase) * wiggle_strength * 0.18
		points.append(Vector2(base_x + twist + counter, y))
	return points

func _sample_point(points: PackedVector2Array, t: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var index := clampi(roundi(t * float(points.size() - 1)), 0, points.size() - 1)
	return points[index]

func _with_alpha(color: Color, alpha: float) -> Color:
	color.a = alpha
	return color
