@tool
extends Node2D
const MODEL := preload("res://Assets/BlueBiome/Enemies/Models/Bellstriker_Boxing_v4.glb")
const OUTLINE := preload("res://Src/Enemies/Bellstriker/bellstriker_outline.gdshader")
var animator: AnimationPlayer
var image: Sprite2D
var _tell := 0.0
var _clock := 0.0
var _effect := 0.0
var _splash := false
var _clip: StringName
var bell: AudioStreamPlayer2D
var swimming := false
var boxing := false
var _aim := Vector2.RIGHT

func _ready() -> void:
	var viewport := SubViewport.new()
	# More vertical room for the raised thorax and heavy finisher. Keep the same
	# pixels-per-world-unit so changing stance does not change apparent scale.
	viewport.size = Vector2i(720, 720)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	var model := MODEL.instantiate() as Node3D
	viewport.add_child(model)
	animator = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for clip in [&"idle", &"walk", &"swim", &"swim_idle", &"box_idle"]:
		if animator.has_animation(clip):
			animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.4
	viewport.add_child(camera)
	camera.position = Vector3(1.6, 1.45, 8)
	camera.look_at(Vector3(0, 0.82, 0))
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.65, 0.76, 0.9)
	environment.environment.ambient_light_energy = 0.8
	viewport.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -35, 0)
	light.light_energy = 1.3
	viewport.add_child(light)
	image = Sprite2D.new()
	image.texture = viewport.get_texture()
	image.scale = Vector2.ONE * 0.78
	image.position.y = -101
	var material := ShaderMaterial.new()
	material.shader = OUTLINE
	image.material = material
	add_child(image)
	play_clip(&"idle")
	if Engine.is_editor_hint():
		animator.pause()
	else:
		bell = AudioStreamPlayer2D.new()
		bell.stream = _make_bell()
		bell.volume_db = -12
		bell.max_distance = 1500
		add_child(bell)

func _process(delta: float) -> void:
	_clock += delta
	_effect = maxf(0.0, _effect - delta)
	if image:
		# The authored boxing spine is fully upright. Travel pitch belongs only
		# to horizontal swimming, not to the committed upright combat stance.
		var angle := clampf(_aim.angle(), -0.65, 0.65) if swimming and not boxing and _aim.length() > 0.01 else 0.0
		image.rotation = lerp_angle(image.rotation, angle, 1.0 - exp(-10.0 * delta))
		image.position = Vector2(0, -54) + Vector2(0, -47).rotated(image.rotation)
	queue_redraw()

func set_water_motion(wet: bool, fighting: bool, direction: Vector2, facing: int) -> void:
	swimming = wet
	boxing = fighting
	_aim = Vector2(direction.x * float(facing), direction.y)

func play_clip(clip: StringName, duration := 0.0) -> void:
	if not animator or not animator.has_animation(clip):
		return
	if clip == _clip and clip in [&"idle", &"walk", &"swim", &"swim_idle", &"box_idle"]:
		return
	var blend := 0.10 if clip == &"box_idle" else 0.045
	if clip == &"water_charge_1" and _clip in [&"swim", &"swim_idle"]:
		blend = 0.12
	_clip = clip
	var speed := animator.get_animation(clip).length / duration if duration > 0 else 1.0
	animator.play(clip, blend, speed)

func set_tell(value: float) -> void:
	_tell = clampf(value, 0, 1)

func ring_bell(pitch := 1.0) -> void:
	if bell:
		bell.pitch_scale = pitch
		bell.play()

func splash() -> void:
	_effect = 0.35
	_splash = true

func impact() -> void:
	_effect = 0.22
	_splash = false

func _draw() -> void:
	if _tell > 0:
		var color := Color(1.0, 0.78, 0.3, 0.4 + _tell * 0.6)
		draw_arc(Vector2(94, -78), 18 + _tell * 12, 0, TAU, 32, color, 3)
		if _tell > 0.72:
			draw_line(Vector2(94, -143), Vector2(94, -126), color, 4)
			draw_circle(Vector2(94, -118), 3, color)
	if _effect > 0:
		var duration := 0.35 if _splash else 0.22
		var progress := 1.0 - _effect / duration
		var color := Color(0.45, 0.83, 1.0, 1 - progress) if _splash else Color(1, 0.8, 0.4, 1 - progress)
		draw_arc(Vector2(0, -12) if _splash else Vector2(148, -54), lerpf(20, 85, progress), PI, TAU, 32, color, 3)

func _make_bell() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(22050)
	for i in range(11025):
		var t := float(i) / 22050.0
		var value := (sin(TAU * 720 * t) + 0.45 * sin(TAU * 1337 * t) + 0.25 * sin(TAU * 2011 * t)) * exp(-10 * t) * 0.38
		data.encode_s16(i * 2, int(clampf(value, -1, 1) * 32767))
	stream.data = data
	return stream
