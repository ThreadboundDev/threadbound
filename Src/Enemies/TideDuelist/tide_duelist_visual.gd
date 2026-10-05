@tool
extends Node2D
## A live 3D fish in the 2D world, including a static editor preview.

const MODEL = preload("res://Assets/BlueBiome/Enemies/Models/TideDuelist_Rigged_v2.glb")
const OUTLINE_SHADER = preload("res://Src/Enemies/TideDuelist/tide_duelist_outline.gdshader")
@export_group("Living Motion")
@export var living_motion_enabled := true
@export_range(2.0, 8.0, 0.1) var idle_cycle_seconds := 4.8
@export_range(0.0, 6.0, 0.25) var hover_pixels := 3.0
@export_range(0.0, 3.0, 0.1) var hover_pitch_degrees := 1.4
@export_range(0.0, 16.0, 0.5) var tail_motion_degrees := 9.0
var animator: AnimationPlayer
var eye_materials: Array[StandardMaterial3D] = []
var tell_intensity := 0.0
var _skeleton: Skeleton3D
var _fish: Node2D
var _rest_position := Vector2.ZERO
var _life_clock := 0.0
var _phase_offset := 0.0
var _hover_weight := 0.0
var _recovery_rotation := 0.0

func _ready() -> void:
	_rest_position = position
	_fish = get_parent().get_parent() as Node2D if get_parent() else null
	# Duplicated fish should not all breathe/tail-beat in perfect synchrony.
	_phase_offset = fmod(float(get_instance_id() % 97) * 0.173, TAU)
	var viewport := SubViewport.new()
	viewport.name = "FishRender"
	viewport.size = Vector2i(512, 320)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	var model := MODEL.instantiate()
	viewport.add_child(model)
	animator = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	animator.get_animation(&"still").loop_mode = Animation.LOOP_LINEAR
	_install_living_clips()
	animator.animation_finished.connect(_on_clip_finished)
	for node in model.find_children("EyeTell*", "MeshInstance3D", true, false):
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		node.material_override = material
		eye_materials.append(material)
	set_attack_tell(0.0)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.3
	camera.position = Vector3(0, -0.2, 8)
	viewport.add_child(camera)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.TRANSPARENT
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.65, 0.8, 1.0)
	environment.environment.ambient_light_energy = 0.65
	viewport.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	light.light_energy = 1.25
	viewport.add_child(light)
	var sprite := Sprite2D.new()
	sprite.name = "FishImage"
	sprite.texture = viewport.get_texture()
	sprite.scale = Vector2.ONE * 0.60
	var outline_material := ShaderMaterial.new()
	outline_material.shader = OUTLINE_SHADER
	sprite.material = outline_material
	add_child(sprite)
	play_clip(&"still")
	if Engine.is_editor_hint():
		animator.seek(0.0, true)
		animator.pause()

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not animator:
		return
	if is_instance_valid(_fish) and _fish.get("is_dead") == true:
		_hover_weight = 0.0
		_recovery_rotation = 0.0
		_apply_hover_pose()
		animator.pause()
		return
	_life_clock += delta
	var hovering := living_motion_enabled and animator.current_animation == &"life/hover"
	_hover_weight = move_toward(_hover_weight, 1.0 if hovering else 0.0, delta * 8.0)
	_apply_hover_pose()

func _on_clip_finished(clip: StringName) -> void:
	# Keep the authored blade-unfurl intact. Once released, use a separate
	# streamlined tail-beat loop; never loop back through the curled windup.
	if clip == &"dash" and living_motion_enabled and not Engine.is_editor_hint():
		if not is_instance_valid(_fish) or _fish.get("is_dead") != true:
			animator.play(&"life/dash_glide", 0.08)

func _apply_hover_pose() -> void:
	var phase := _life_clock * TAU / idle_cycle_seconds + _phase_offset
	position = _rest_position + Vector2(sin(phase * 2.0) * 0.8, sin(phase) * hover_pixels) * _hover_weight
	rotation = _recovery_rotation + deg_to_rad(hover_pitch_degrees) * sin(phase + 0.6) * _hover_weight

func _install_living_clips() -> void:
	# Add runtime animation variants, leaving the approved GLB/Blender work intact.
	var library := AnimationLibrary.new()
	library.add_animation(&"hover", _make_living_clip(animator.get_animation(&"still"), idle_cycle_seconds, 1.0))
	var dash := animator.get_animation(&"dash")
	library.add_animation(&"dash_glide", _make_living_clip(dash, 0.72, 0.55, dash.length))
	animator.add_animation_library(&"life", library)

func _make_living_clip(source: Animation, period: float, energy: float, source_time := 0.0) -> Animation:
	var clip := source.duplicate(true) as Animation
	clip.length = period
	clip.loop_mode = Animation.LOOP_LINEAR
	# A dolphin-like vertical wave travels from the body towards the tail tip.
	# Counter-motion in the head keeps the long bill composed, not noodly.
	var motion := {&"body": Vector2(0.08, 0.0), &"head": Vector2(-0.12, 0.25),
		&"tail": Vector2(0.45, -0.30), &"tail_mid": Vector2(0.72, -0.85), &"tail_tip": Vector2(1.0, -1.40)}
	for track in clip.get_track_count():
		var path := clip.track_get_path(track)
		if path.get_subname_count() != 1:
			continue
		var bone := StringName(path.get_subname(0))
		var type := clip.track_get_type(track)
		if type not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
			continue
		var index := _skeleton.find_bone(bone)
		if index < 0:
			continue
		var base: Variant
		match type:
			Animation.TYPE_POSITION_3D: base = source.position_track_interpolate(track, source_time)
			Animation.TYPE_ROTATION_3D: base = source.rotation_track_interpolate(track, source_time)
			Animation.TYPE_SCALE_3D: base = source.scale_track_interpolate(track, source_time)
		while clip.track_get_key_count(track) > 0:
			clip.track_remove_key(track, 0)
		if type != Animation.TYPE_ROTATION_3D or not motion.has(bone):
			clip.track_insert_key(track, 0.0, base)
			continue
		var wave: Vector2 = motion[bone]
		var axis := (_skeleton.get_bone_global_rest(index).basis.inverse() * Vector3.RIGHT).normalized()
		var samples := ceili(period * 30.0)
		for sample in range(samples + 1):
			var time := minf(float(sample) / 30.0, period)
			var phase := time / period * TAU
			var modulation := 0.86 + 0.14 * sin(phase)
			var angle := deg_to_rad(tail_motion_degrees) * wave.x * energy * sin(phase + wave.y) * modulation
			clip.track_insert_key(track, time, (base as Quaternion) * Quaternion(axis, angle))
	return clip

func play_clip(clip: StringName, duration := 0.0) -> void:
	if clip == &"still" and living_motion_enabled and not Engine.is_editor_hint():
		clip = &"life/hover"
	if not animator or not animator.has_animation(clip):
		return
	if clip == &"life/hover" and animator.current_animation == clip and animator.is_playing():
		return
	var speed := animator.get_animation(clip).length / duration if duration > 0.0 else 1.0
	animator.play(clip, 0.16 if clip == &"life/hover" else 0.04, speed)
	if clip == &"life/hover":
		animator.seek(fposmod(_life_clock + _phase_offset / TAU * idle_cycle_seconds, idle_cycle_seconds), true)
	elif clip == &"hurt":
		_hover_weight = 0.0
		_recovery_rotation = 0.0
		_apply_hover_pose()

func reset_living_motion() -> void:
	_life_clock = 0.0
	_hover_weight = 0.0
	_recovery_rotation = 0.0
	_apply_hover_pose()
	play_clip(&"still")

func set_recovery_shake(progress: float) -> void:
	progress = clampf(progress, 0.0, 1.0)
	if is_zero_approx(progress) or is_equal_approx(progress, 1.0):
		_recovery_rotation = 0.0
		_apply_hover_pose()
		return
	# A short, damped side-to-side shake reads as the fish clearing its head
	# without requiring a separate authored animation clip.
	var envelope := sin(progress * PI)
	_recovery_rotation = deg_to_rad(11.0) * sin(progress * TAU * 3.5) * envelope
	_apply_hover_pose()

func set_attack_tell(intensity: float) -> void:
	tell_intensity = clampf(intensity, 0.0, 1.0)
	# Amber awareness becomes an ivory-hot flash for the final held draw pose.
	var color := Color(0.28, 0.23, 0.15).lerp(Color(1.0, 0.35, 0.04), minf(tell_intensity * 2.0, 1.0))
	if tell_intensity > 0.8:
		color = color.lerp(Color(1.0, 0.94, 0.68), (tell_intensity - 0.8) / 0.2)
	for material in eye_materials:
		material.albedo_color = color
		material.emission = color
		material.emission_energy_multiplier = 0.1 + tell_intensity * 3.0
