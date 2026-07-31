extends Node2D
class_name FlowStateVFX

const FLOW_TINT_SHADER: Shader = preload("res://Src/VFX/flow_state_tint.gdshader")
const FLOW_SILHOUETTE_SHADER: Shader = preload(
	"res://Src/VFX/flow_state_silhouette.gdshader"
)

const IVORY := Color(1.0, 0.965, 0.82, 1.0)
const ANTIQUE_GOLD := Color(0.96, 0.67, 0.24, 1.0)
const POWER_RED := Color(0.94, 0.2, 0.17, 1.0)
const BALANCE_BLUE := Color(0.25, 0.56, 1.0, 1.0)
const ESSENCE_YELLOW := Color(1.0, 0.79, 0.2, 1.0)

@export var active := false

@export_group("Buildup")
@export_range(0.0, 100.0, 1.0) var buildup_start_momentum := 45.0
@export var buildup_slow_interval := 0.62
@export var buildup_fast_interval := 0.17

@export_group("Aura")
@export var aura_fade_in_speed := 6.5
@export var aura_fade_out_speed := 4.8
@export var aura_pulse_speed := 3.0
@export_range(1.0, 24.0, 0.5) var silhouette_distance_px := 16.0
@export_range(1.0, 12.0, 0.5) var silhouette_feather_px := 10.0
@export_range(0.0, 32.0, 0.5) var silhouette_flame_height_px := 18.0
@export_range(0.1, 0.9, 0.01) var meditation_aura_target := 0.48
@export_range(0.1, 1.0, 0.01) var meditation_visual_strength := 0.68
@export var run_trail_min_speed := 180.0
@export var run_trail_max_speed := 780.0
@export var run_trail_interval := 0.14
@export var ambient_wisp_interval := 0.09

@export_group("Events")
@export var maximum_ephemeral_sprites := 32
@export var minimum_landing_effect_speed := 160.0

@onready var silhouette_shell: Sprite2D = $AuraBack/SilhouetteShell
@onready var flow_light: PointLight2D = $AuraBack/FlowLight
@onready var transition_core: AnimatedSprite2D = $TransitionLayer/TransitionCore
@onready var transition_accents: Array[AnimatedSprite2D] = [
	$TransitionLayer/TransitionAccent1 as AnimatedSprite2D,
	$TransitionLayer/TransitionAccent2 as AnimatedSprite2D,
	$TransitionLayer/TransitionAccent3 as AnimatedSprite2D,
]
@onready var event_layer: Node2D = $EventLayer
@onready var attack_template: AnimatedSprite2D = $Templates/AttackTemplate
@onready var movement_templates: Array[Sprite2D] = [
	$Templates/MovementTemplates/Dash as Sprite2D,
	$Templates/MovementTemplates/Jump as Sprite2D,
	$Templates/MovementTemplates/Land as Sprite2D,
	$Templates/MovementTemplates/AirJump as Sprite2D,
]
@onready var mote_templates: Array[Sprite2D] = [
	$Templates/MoteTemplates/Filament as Sprite2D,
	$Templates/MoteTemplates/Knot as Sprite2D,
	$Templates/MoteTemplates/Spark as Sprite2D,
	$Templates/MoteTemplates/Fragment as Sprite2D,
]

var _momentum_amount := 0.0
var _aura_visibility := 0.0
var _aura_target := 0.0
var _time := 0.0
var _buildup_timer := 0.0
var _run_trail_timer := 0.0
var _ambient_wisp_timer := 0.0
var _ambient_wisp_side := -1.0
var _activation_burst := 0.0
var _activation_tween: Tween
var _channel_cursor := 0
var _identity_channels: Array[Color] = []
var _identity_override_active := false
var _ephemeral_sprites: Array[CanvasItem] = []
var _meditation_active := false
var _player_visual: AnimatedSprite2D
var _silhouette_material: ShaderMaterial

func _ready() -> void:
	_configure_static_materials()
	_resolve_player_visual()
	_connect_transition_signals()
	if not DemoProgress.threads_changed.is_connected(_refresh_demo_identity_channels):
		DemoProgress.threads_changed.connect(_refresh_demo_identity_channels)
	_refresh_demo_identity_channels()

	_aura_visibility = 1.0 if active else 0.0
	_aura_target = _aura_visibility
	visible = active or _momentum_amount >= buildup_start_momentum
	set_process(visible)
	_update_aura_visuals()

func _exit_tree() -> void:
	if DemoProgress.threads_changed.is_connected(_refresh_demo_identity_channels):
		DemoProgress.threads_changed.disconnect(_refresh_demo_identity_channels)

func set_flow_active(is_active: bool) -> void:
	if active == is_active:
		return

	active = is_active
	_aura_target = (
		1.0
		if active
		else (meditation_aura_target if _meditation_active else 0.0)
	)
	visible = true
	set_process(true)
	_buildup_timer = 0.0
	_play_transition(&"ignite" if active else &"unravel")

func set_meditation_active(is_active: bool) -> void:
	if _meditation_active == is_active:
		return
	_meditation_active = is_active
	_aura_target = (
		1.0
		if active
		else (meditation_aura_target if _meditation_active else 0.0)
	)
	if active or _meditation_active or _aura_visibility > 0.005:
		visible = true
		set_process(true)
	else:
		_refresh_processing_state()
	if _meditation_active and not active:
		_play_meditation_bloom()

func set_momentum_amount(value: float) -> void:
	_momentum_amount = clampf(value, 0.0, 100.0)
	if active or _momentum_amount >= buildup_start_momentum:
		visible = true
		set_process(true)
	else:
		_refresh_processing_state()

func set_identity_channels(channels: Array[Color]) -> void:
	_identity_override_active = false
	_set_identity_channels_internal(channels)

func set_identity_mix(
	power_weight: float,
	balance_weight: float,
	essence_weight: float
) -> void:
	_identity_override_active = true
	var channels: Array[Color] = []
	var weights := [
		clampf(power_weight, 0.0, 1.0),
		clampf(balance_weight, 0.0, 1.0),
		clampf(essence_weight, 0.0, 1.0),
	]
	var colors: Array[Color] = [POWER_RED, BALANCE_BLUE, ESSENCE_YELLOW]
	for index in colors.size():
		if weights[index] <= 0.0:
			continue
		var weighted_color := colors[index]
		weighted_color.a = weights[index]
		channels.append(weighted_color)
	_set_identity_channels_internal(channels)

func clear_identity_override() -> void:
	_identity_override_active = false
	_refresh_demo_identity_channels()

func _set_identity_channels_internal(channels: Array[Color]) -> void:
	_identity_channels.clear()
	for channel in channels:
		if channel.a > 0.0:
			_identity_channels.append(channel)
	_apply_identity_channels()

func play_attack_swing(
	direction: Vector2,
	arc_degrees: float = 130.0,
	strike_index: int = 0
) -> void:
	if not active or not is_inside_tree():
		return

	var swing_direction := direction.normalized()
	if swing_direction.length() <= 0.001:
		swing_direction = Vector2.RIGHT
	var arc_scale := clampf(arc_degrees / 130.0, 0.72, 1.24)
	var colors := _get_action_colors()
	var color_center := (float(colors.size()) - 1.0) * 0.5

	for index in colors.size():
		var sprite := attack_template.duplicate() as AnimatedSprite2D
		event_layer.add_child(sprite)
		sprite.visible = true
		sprite.position = (
			Vector2(0.0, -38.0)
			+ swing_direction * (35.0 + index * 1.25)
		)
		sprite.rotation = (
			swing_direction.angle()
			+ (float(index) - color_center) * 0.035
		)
		sprite.scale = Vector2.ONE * (0.58 * arc_scale * (1.0 - index * 0.025))
		# The authored crescent faces opposite the weapon travel direction.
		# Mirror it horizontally while retaining the alternating vertical cut.
		sprite.flip_h = not attack_template.flip_h
		sprite.flip_v = strike_index % 2 == 1
		sprite.material = _make_tint_material(
			colors[index],
			0.18 if index == 0 else 0.9,
			1.28 if index == 0 else 1.04
		)
		sprite.modulate.a = 0.32 if index == 0 else 0.18
		_register_ephemeral(sprite)
		sprite.animation_finished.connect(_release_ephemeral.bind(sprite), CONNECT_ONE_SHOT)
		sprite.play(&"swing")

func play_dash(direction: Vector2) -> void:
	if not active or not is_inside_tree():
		return

	var dash_direction := direction.normalized()
	if dash_direction.length() <= 0.001:
		dash_direction = Vector2.RIGHT
	_spawn_movement_layers(
		movement_templates[0],
		Vector2(0.0, -34.0) - dash_direction * 36.0,
		dash_direction.angle(),
		Vector2(0.62, 0.5),
		0.24,
		dash_direction * -22.0,
		0.82
	)

func play_jump(direction: Vector2) -> void:
	if not active or not is_inside_tree():
		return

	var player_body := get_parent() as CharacterBody2D
	var is_air_jump := player_body != null and not player_body.is_on_floor()
	var template := movement_templates[3] if is_air_jump else movement_templates[1]
	var horizontal_tilt := clampf(direction.x, -1.0, 1.0) * 0.14
	_spawn_movement_layers(
		template,
		Vector2(0.0, 2.0 if is_air_jump else 30.0),
		horizontal_tilt,
		Vector2(0.3, 0.32) if is_air_jump else Vector2(0.32, 0.35),
		0.64 if is_air_jump else 0.7,
		Vector2(-direction.x * 4.0, 12.0 if is_air_jump else 20.0),
		0.48
	)

func play_land(impact_speed: float) -> void:
	if (
		not active
		or not is_inside_tree()
		or impact_speed < minimum_landing_effect_speed
	):
		return

	var strength := clampf(
		inverse_lerp(minimum_landing_effect_speed, 1100.0, impact_speed),
		0.0,
		1.0
	)
	var landing_scale := Vector2(
		lerpf(0.33, 0.52, strength),
		lerpf(0.24, 0.38, strength)
	)
	_spawn_landing_layers(
		landing_scale,
		lerpf(0.92, 1.18, strength),
		lerpf(0.46, 0.62, strength)
	)

func _process(delta: float) -> void:
	_time += delta
	_sync_silhouette_source()
	var fade_speed := aura_fade_in_speed if active else aura_fade_out_speed
	_aura_visibility = move_toward(
		_aura_visibility,
		_aura_target,
		fade_speed * delta
	)

	if active:
		_update_run_trails(delta)
		_update_ambient_wisps(delta)
	elif not _meditation_active:
		_update_buildup(delta)

	_update_aura_visuals()
	_refresh_processing_state()

func _configure_static_materials() -> void:
	_silhouette_material = ShaderMaterial.new()
	_silhouette_material.shader = FLOW_SILHOUETTE_SHADER
	silhouette_shell.material = _silhouette_material
	transition_core.material = _make_tint_material(IVORY, 0.08, 1.35)
	_update_silhouette_identity_material()

func _resolve_player_visual() -> void:
	var player := get_parent()
	if player:
		_player_visual = player.get_node_or_null("Player Animation") as AnimatedSprite2D

func _sync_silhouette_source() -> void:
	if not is_instance_valid(_player_visual):
		_resolve_player_visual()
	if not is_instance_valid(_player_visual) or _player_visual.sprite_frames == null:
		silhouette_shell.visible = false
		return

	var frame_texture := _player_visual.sprite_frames.get_frame_texture(
		_player_visual.animation,
		_player_visual.frame
	)
	if frame_texture == null:
		silhouette_shell.visible = false
		return

	silhouette_shell.texture = frame_texture
	silhouette_shell.position = _player_visual.position
	silhouette_shell.rotation = _player_visual.rotation
	silhouette_shell.scale = _player_visual.scale
	silhouette_shell.flip_h = _player_visual.flip_h
	silhouette_shell.flip_v = _player_visual.flip_v
	silhouette_shell.offset = _player_visual.offset
	silhouette_shell.centered = _player_visual.centered

	if _silhouette_material:
		var sampled_texture: Texture2D = frame_texture
		var sampled_size := Vector2(frame_texture.get_size())
		var source_uv_rect := Rect2(0.0, 0.0, 1.0, 1.0)
		if frame_texture is AtlasTexture:
			var atlas_frame := frame_texture as AtlasTexture
			if atlas_frame.atlas:
				sampled_texture = atlas_frame.atlas
				var atlas_size := Vector2(sampled_texture.get_size())
				sampled_size = atlas_frame.region.size
				source_uv_rect = Rect2(
					(Vector2(atlas_frame.region.position) + Vector2(0.5, 0.5))
					/ atlas_size,
					(Vector2(atlas_frame.region.size) - Vector2.ONE)
					/ atlas_size
				)
		_silhouette_material.set_shader_parameter(
			&"silhouette_texture",
			sampled_texture
		)
		_silhouette_material.set_shader_parameter(
			&"source_texture_size",
			sampled_size
		)
		_silhouette_material.set_shader_parameter(
			&"source_uv_rect",
			Color(
				source_uv_rect.position.x,
				source_uv_rect.position.y,
				source_uv_rect.size.x,
				source_uv_rect.size.y
			)
		)

func _connect_transition_signals() -> void:
	var transition_sprites: Array[AnimatedSprite2D] = [transition_core]
	transition_sprites.append_array(transition_accents)
	for sprite in transition_sprites:
		if not sprite.animation_finished.is_connected(
			_on_transition_animation_finished.bind(sprite)
		):
			sprite.animation_finished.connect(
				_on_transition_animation_finished.bind(sprite)
			)

func _refresh_demo_identity_channels() -> void:
	if _identity_override_active:
		return
	var channels: Array[Color] = []
	if DemoProgress.has_thread(&"power"):
		channels.append(POWER_RED)
	if DemoProgress.has_thread(&"balance"):
		channels.append(BALANCE_BLUE)
	if DemoProgress.has_thread(&"essence"):
		channels.append(ESSENCE_YELLOW)
	_set_identity_channels_internal(channels)

func _apply_identity_channels() -> void:
	var effective_channels := _get_effective_identity_channels()
	for index in transition_accents.size():
		var color := (
			effective_channels[index]
			if index < effective_channels.size()
			else ANTIQUE_GOLD
		)
		transition_accents[index].material = _make_tint_material(color, 0.94, 1.08)

	flow_light.color = _get_identity_glow_color(effective_channels)
	_update_silhouette_identity_material()
	_update_aura_visuals()

func _get_identity_glow_color(channels: Array[Color]) -> Color:
	if channels.is_empty():
		return ANTIQUE_GOLD.lerp(IVORY, 0.18)

	var weighted_rgb := Vector3.ZERO
	var total_weight := 0.0
	for channel in channels:
		var weight := clampf(channel.a, 0.0, 1.0)
		weighted_rgb += Vector3(channel.r, channel.g, channel.b) * weight
		total_weight += weight
	if total_weight <= 0.0001:
		return ANTIQUE_GOLD.lerp(IVORY, 0.18)

	weighted_rgb /= total_weight
	var identity_color := Color(
		weighted_rgb.x,
		weighted_rgb.y,
		weighted_rgb.z,
		1.0
	)
	return identity_color.lerp(IVORY, 0.18)

func _update_silhouette_identity_material() -> void:
	if not _silhouette_material:
		return

	var effective_channels := _get_effective_identity_channels()
	var colors: Array[Color] = [ANTIQUE_GOLD, ANTIQUE_GOLD, ANTIQUE_GOLD]
	var weights := Vector3.ZERO
	for index in mini(effective_channels.size(), 3):
		var color := effective_channels[index]
		var weight := clampf(color.a, 0.0, 1.0)
		color.a = 1.0
		colors[index] = color
		match index:
			0:
				weights.x = weight
			1:
				weights.y = weight
			2:
				weights.z = weight
	if weights.length_squared() <= 0.0001:
		weights.x = 1.0

	_silhouette_material.set_shader_parameter(&"channel_1", colors[0])
	_silhouette_material.set_shader_parameter(&"channel_2", colors[1])
	_silhouette_material.set_shader_parameter(&"channel_3", colors[2])
	_silhouette_material.set_shader_parameter(&"channel_weights", weights)

func _get_effective_identity_channels() -> Array[Color]:
	if not _identity_channels.is_empty():
		return _identity_channels
	var baseline: Array[Color] = [ANTIQUE_GOLD]
	return baseline

func _get_action_colors() -> Array[Color]:
	var colors: Array[Color] = [IVORY]
	if _identity_channels.is_empty():
		colors.append(ANTIQUE_GOLD)
	else:
		colors.append_array(_identity_channels)
	return colors

func _update_aura_visuals() -> void:
	if not is_node_ready():
		return

	var show_aura := _aura_visibility > 0.005
	var pulse := 0.5 + sin(_time * aura_pulse_speed) * 0.5
	var meditation_only := _meditation_active and not active
	var persistent_strength := (
		meditation_visual_strength
		if meditation_only
		else 1.0
	)
	var display_strength := clampf(
		_aura_visibility * persistent_strength,
		0.0,
		1.0
	)

	silhouette_shell.visible = show_aura and silhouette_shell.texture != null

	if _silhouette_material:
		_silhouette_material.set_shader_parameter(&"time_seconds", _time)
		_silhouette_material.set_shader_parameter(
			&"aura_visibility",
			display_strength
		)
		_silhouette_material.set_shader_parameter(
			&"outline_distance_px",
			silhouette_distance_px + _activation_burst * 8.0
		)
		_silhouette_material.set_shader_parameter(
			&"outline_feather_px",
			silhouette_feather_px
		)
		_silhouette_material.set_shader_parameter(
			&"flame_height_px",
			(silhouette_flame_height_px * 0.55)
			if meditation_only
			else silhouette_flame_height_px + _activation_burst * 6.0
		)
		_silhouette_material.set_shader_parameter(
			&"energy",
			1.28 + pulse * 0.42 + _activation_burst * 0.82
		)

	flow_light.energy = (
		display_strength
		* (0.48 + pulse * 0.22 + _activation_burst * 0.42)
	)
	flow_light.texture_scale = (
		1.08
		+ pulse * 0.16
		+ _activation_burst * 0.22
	)

func _play_transition(animation_name: StringName) -> void:
	transition_core.stop()
	transition_core.visible = false
	for sprite in transition_accents:
		sprite.stop()
		sprite.visible = false

	if _activation_tween and _activation_tween.is_valid():
		_activation_tween.kill()
	_activation_tween = create_tween()
	if animation_name == &"ignite":
		transition_core.visible = true
		transition_core.modulate.a = 0.86
		transition_core.scale = Vector2.ONE * 0.62
		transition_core.play(&"ignite")
		for index in transition_accents.size():
			var accent := transition_accents[index]
			accent.visible = true
			accent.modulate.a = 0.38 - index * 0.055
			accent.scale = Vector2.ONE * (0.58 - index * 0.035)
			if index == 1:
				accent.scale.x *= -1.0
			accent.play(&"ignite")
		_activation_burst = 0.0
		_activation_tween.tween_property(
			self,
			"_activation_burst",
			1.0,
			0.1
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		_activation_tween.tween_property(
			self,
			"_activation_burst",
			0.0,
			0.4
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		transition_core.visible = true
		transition_core.modulate.a = 0.34
		transition_core.scale = Vector2.ONE * 0.54
		transition_core.play(&"unravel")
		_activation_burst = minf(maxf(_activation_burst, 0.24), 0.4)
		_activation_tween.tween_property(
			self,
			"_activation_burst",
			0.0,
			0.32
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _play_meditation_bloom() -> void:
	if _activation_tween and _activation_tween.is_valid():
		_activation_tween.kill()
	_activation_burst = 0.34
	_activation_tween = create_tween()
	_activation_tween.tween_property(
		self,
		"_activation_burst",
		0.0,
		0.62
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_transition_animation_finished(sprite: AnimatedSprite2D) -> void:
	sprite.visible = false
	_refresh_processing_state()

func _update_buildup(delta: float) -> void:
	if _momentum_amount < buildup_start_momentum:
		return

	var strength := clampf(
		inverse_lerp(buildup_start_momentum, 100.0, _momentum_amount),
		0.0,
		1.0
	)
	_buildup_timer -= delta
	if _buildup_timer > 0.0:
		return

	_buildup_timer = lerpf(
		buildup_slow_interval,
		buildup_fast_interval,
		strength
	)
	_spawn_buildup_mote(strength)

func _spawn_buildup_mote(strength: float) -> void:
	var template := mote_templates[_channel_cursor % mote_templates.size()]
	var color := _get_next_identity_color()
	var sprite := template.duplicate() as Sprite2D
	event_layer.add_child(sprite)
	sprite.visible = true
	sprite.position = Vector2(
		randf_range(-39.0, 39.0),
		randf_range(-4.0, 28.0)
	)
	sprite.rotation = randf_range(-0.55, 0.55)
	var start_scale := lerpf(0.065, 0.11, strength) * randf_range(0.84, 1.18)
	sprite.scale = Vector2.ONE * start_scale
	sprite.material = _make_tint_material(color, 0.88, 0.86 + strength * 0.22)
	sprite.modulate.a = 0.0
	_register_ephemeral(sprite)

	var lifetime := lerpf(0.58, 0.9, strength)
	var drift := Vector2(randf_range(-13.0, 13.0), -randf_range(42.0, 78.0))
	var movement_tween := create_tween()
	movement_tween.set_parallel(true)
	movement_tween.tween_property(sprite, "position", sprite.position + drift, lifetime)
	movement_tween.tween_property(
		sprite,
		"rotation",
		sprite.rotation + randf_range(-0.45, 0.45),
		lifetime
	)
	movement_tween.tween_property(
		sprite,
		"scale",
		sprite.scale * randf_range(0.72, 0.92),
		lifetime
	)

	var fade_tween := create_tween()
	fade_tween.tween_property(
		sprite,
		"modulate:a",
		lerpf(0.16, 0.4, strength),
		lifetime * 0.22
	)
	fade_tween.tween_property(sprite, "modulate:a", 0.0, lifetime * 0.78)
	fade_tween.finished.connect(_release_ephemeral.bind(sprite), CONNECT_ONE_SHOT)

func _update_run_trails(delta: float) -> void:
	var player_body := get_parent() as CharacterBody2D
	if not player_body:
		return

	var horizontal_speed := absf(player_body.velocity.x)
	if (
		not player_body.is_on_floor()
		or horizontal_speed < run_trail_min_speed
		or horizontal_speed > run_trail_max_speed
	):
		_run_trail_timer = 0.0
		return

	_run_trail_timer -= delta
	if _run_trail_timer > 0.0:
		return
	_run_trail_timer = run_trail_interval

	var direction := Vector2(signf(player_body.velocity.x), 0.0)
	var color := _get_next_identity_color()
	var template := movement_templates[0]
	var sprite := template.duplicate() as Sprite2D
	event_layer.add_child(sprite)
	sprite.visible = true
	sprite.position = Vector2(0.0, -29.0) - direction * 12.0
	sprite.rotation = direction.angle()
	sprite.scale = Vector2(0.18, 0.13)
	sprite.material = _make_tint_material(color, 0.9, 0.82)
	sprite.modulate.a = 0.23
	_register_ephemeral(sprite)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "position", sprite.position - direction * 17.0, 0.2)
	tween.tween_property(sprite, "scale", Vector2(0.23, 0.1), 0.2)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.finished.connect(_release_ephemeral.bind(sprite), CONNECT_ONE_SHOT)

func _update_ambient_wisps(delta: float) -> void:
	if _aura_visibility < 0.35:
		return

	_ambient_wisp_timer -= delta
	if _ambient_wisp_timer > 0.0:
		return
	_ambient_wisp_timer = ambient_wisp_interval * randf_range(0.78, 1.22)
	_ambient_wisp_side *= -1.0

	var sprite := movement_templates[1].duplicate() as Sprite2D
	event_layer.add_child(sprite)
	sprite.visible = true
	sprite.position = Vector2(
		_ambient_wisp_side * randf_range(20.0, 40.0),
		randf_range(-4.0, 31.0)
	)
	sprite.rotation = randf_range(-0.22, 0.22)
	sprite.scale = Vector2(
		randf_range(0.105, 0.16),
		randf_range(0.15, 0.23)
	)
	sprite.material = _make_tint_material(
		_get_next_identity_color(),
		0.9,
		randf_range(1.0, 1.22)
	)
	sprite.modulate.a = 0.0
	_register_ephemeral(sprite)

	var lifetime := randf_range(0.7, 0.95)
	var drift := Vector2(
		_ambient_wisp_side * randf_range(8.0, 18.0),
		-randf_range(92.0, 142.0)
	)
	var motion_tween := create_tween()
	motion_tween.set_parallel(true)
	motion_tween.tween_property(
		sprite,
		"position",
		sprite.position + drift,
		lifetime
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	motion_tween.tween_property(
		sprite,
		"scale",
		sprite.scale * Vector2(0.72, 1.2),
		lifetime
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var fade_tween := create_tween()
	fade_tween.tween_property(
		sprite,
		"modulate:a",
		randf_range(0.36, 0.54),
		lifetime * 0.18
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_tween.tween_interval(lifetime * 0.18)
	fade_tween.tween_property(
		sprite,
		"modulate:a",
		0.0,
		lifetime * 0.64
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_tween.finished.connect(_release_ephemeral.bind(sprite), CONNECT_ONE_SHOT)

func _spawn_movement_layers(
	template: Sprite2D,
	position: Vector2,
	rotation: float,
	start_scale: Vector2,
	lifetime: float,
	drift: Vector2,
	base_alpha: float
) -> void:
	var colors := _get_action_colors()
	var color_center := (float(colors.size()) - 1.0) * 0.5
	for index in colors.size():
		var sprite := template.duplicate() as Sprite2D
		event_layer.add_child(sprite)
		sprite.visible = true
		var color_offset := float(index) - color_center
		sprite.position = position + Vector2(color_offset * 3.0, -color_offset)
		sprite.rotation = rotation + color_offset * 0.026
		sprite.scale = start_scale * (1.0 - float(index) * 0.025)
		sprite.material = _make_tint_material(
			colors[index],
			0.16 if index == 0 else 0.91,
			1.2 if index == 0 else 0.98
		)
		var peak_alpha := (
			base_alpha * 0.72
			if index == 0
			else base_alpha * 0.48
		)
		sprite.modulate.a = 0.0
		_register_ephemeral(sprite)

		var movement_tween := create_tween()
		movement_tween.set_parallel(true)
		movement_tween.tween_property(
			sprite,
			"position",
			sprite.position + drift,
			lifetime
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		movement_tween.tween_property(
			sprite,
			"scale",
			sprite.scale * Vector2(1.2, 1.12),
			lifetime
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		var fade_in_duration := minf(0.09, lifetime * 0.24)
		var hold_duration := lifetime * 0.16 if lifetime > 0.35 else 0.0
		var fade_tween := create_tween()
		fade_tween.tween_property(
			sprite,
			"modulate:a",
			peak_alpha,
			fade_in_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if hold_duration > 0.0:
			fade_tween.tween_interval(hold_duration)
		fade_tween.tween_property(
			sprite,
			"modulate:a",
			0.0,
			maxf(0.01, lifetime - fade_in_duration - hold_duration)
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fade_tween.finished.connect(
			_release_ephemeral.bind(sprite),
			CONNECT_ONE_SHOT
		)

func _spawn_landing_layers(
	target_scale: Vector2,
	lifetime: float,
	base_alpha: float
) -> void:
	var colors := _get_action_colors()
	var color_center := (float(colors.size()) - 1.0) * 0.5
	for index in colors.size():
		var sprite := movement_templates[2].duplicate() as Sprite2D
		event_layer.add_child(sprite)
		sprite.visible = true
		var color_offset := float(index) - color_center
		sprite.position = Vector2(color_offset * 2.5, 65.0)
		sprite.rotation = color_offset * 0.018
		sprite.scale = target_scale * Vector2(0.48, 0.34)
		sprite.material = _make_tint_material(
			colors[index],
			0.12 if index == 0 else 0.9,
			1.18 if index == 0 else 0.98
		)
		var peak_alpha := (
			base_alpha * 0.68
			if index == 0
			else base_alpha * 0.46
		)
		sprite.modulate.a = 0.0
		_register_ephemeral(sprite)

		var motion_tween := create_tween()
		motion_tween.set_parallel(true)
		motion_tween.tween_property(
			sprite,
			"position",
			Vector2(color_offset * 5.0, 54.0),
			lifetime
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		motion_tween.tween_property(
			sprite,
			"scale",
			target_scale * Vector2(1.25, 0.78),
			lifetime
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

		var bloom_duration := minf(0.17, lifetime * 0.2)
		var hold_duration := lifetime * 0.24
		var fade_tween := create_tween()
		fade_tween.tween_property(
			sprite,
			"modulate:a",
			peak_alpha,
			bloom_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		fade_tween.tween_interval(hold_duration)
		fade_tween.tween_property(
			sprite,
			"modulate:a",
			0.0,
			maxf(0.01, lifetime - bloom_duration - hold_duration)
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
		fade_tween.finished.connect(
			_release_ephemeral.bind(sprite),
			CONNECT_ONE_SHOT
		)

func _get_next_identity_color() -> Color:
	var effective_channels := _get_effective_identity_channels()
	var color := effective_channels[_channel_cursor % effective_channels.size()]
	_channel_cursor = (_channel_cursor + 1) % maxi(effective_channels.size(), 1)
	return color

func _make_tint_material(
	color: Color,
	tint_strength: float,
	energy: float
) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = FLOW_TINT_SHADER
	material.set_shader_parameter(&"tint_color", color)
	material.set_shader_parameter(&"tint_strength", tint_strength)
	material.set_shader_parameter(&"energy", energy)
	return material

func _register_ephemeral(sprite: CanvasItem) -> void:
	_ephemeral_sprites.append(sprite)
	while _ephemeral_sprites.size() > maximum_ephemeral_sprites:
		var oldest: CanvasItem = _ephemeral_sprites.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	visible = true
	set_process(true)

func _release_ephemeral(sprite: CanvasItem) -> void:
	_ephemeral_sprites.erase(sprite)
	if is_instance_valid(sprite):
		sprite.queue_free()
	_refresh_processing_state()

func _refresh_processing_state() -> void:
	if not is_node_ready():
		return

	for index in range(_ephemeral_sprites.size() - 1, -1, -1):
		if not is_instance_valid(_ephemeral_sprites[index]):
			_ephemeral_sprites.remove_at(index)

	var transition_visible := transition_core.visible
	for sprite in transition_accents:
		transition_visible = transition_visible or sprite.visible

	var needs_processing := (
		active
		or _meditation_active
		or _aura_visibility > 0.005
		or _momentum_amount >= buildup_start_momentum
		or transition_visible
		or not _ephemeral_sprites.is_empty()
	)
	visible = needs_processing
	set_process(needs_processing)
