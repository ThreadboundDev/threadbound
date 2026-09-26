@tool
class_name PlayerLive3DVisual
extends Node2D

const MODEL := preload("res://Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_combat_swings.glb")
const AUTHORED_ATTACKS := preload("res://Assets/Threadborne/Player/Equipped3DTest/threadborne_authored_attacks.glb")
const SWORD_SWEEP := preload("res://Src/VFX/sword_sweep_vfx.gd")
const OUTLINE_SHADER := preload("res://Src/Characters/Player/player_live_3d_outline.gdshader")

const LOOPING_ACTIONS := {
	&"idle_4": true,
	&"run_1": true,
	&"run_2": true,
	&"walk_1": true,
	&"walk_2": true,
	&"block_idle_1": true,
	&"crouch_idle_1": true,
	&"crouch_block_idle_1": true,
	&"grapple_swinging_1": true,
	&"water_idle_1": true,
	&"swimming_1": true,
	&"hanging_idle_1": true,
}

const LOWER_BODY_BONES: Array[StringName] = [
	&"pelvis",
	&"thigh.L", &"shin.L", &"foot.L", &"toe.L",
	&"thigh.R", &"shin.R", &"foot.R", &"toe.R",
]

@export var enabled := true
@export var viewport_size := Vector2i(800, 600)
@export var display_scale := Vector2(0.5, 0.5)
@export var camera_size := 2.8
@export var idle_variation_delay := 6.0
@export var base_playback_speed := 1.25
@export var grapple_throw_duration := 0.30
@export var roll_duration := 0.30
@export_range(1.0, 4.0, 0.1) var water_dash_animation_speed := 2.0
@export var wall_cling_entry_duration := 0.18
@export var neutral_special_duration := 1.20

@export_group("Sword Smear")
@export var sword_smear_enabled := true

var _player: CharacterBody2D
var _viewport: SubViewport
var _model_root: Node3D
var _animation_player: AnimationPlayer
var _skeleton: Skeleton3D
var _pelvis_index := -1
var _left_upper_arm_index := -1
var _left_hand_index := -1
var _pelvis_rest_y := 0.0
var _display: Sprite2D
var _display_rest_position := Vector2.ZERO
var _camera: Camera3D
var _sword_mesh: MeshInstance3D
var _sword_sweep: SwordSweepVFX
var _clips: Dictionary = {}
var _logical_animation: StringName = &""
var _current_action: StringName = &""
var _queued_action: StringName = &""
var _idle_elapsed := 0.0
var _idle_variant_index := 0
var _lower_sampler_root: Node3D
var _lower_sampler_player: AnimationPlayer
var _lower_sampler_skeleton: Skeleton3D
var _lower_sampler_action: StringName = &""
var _upper_body_overlay_active := false
var _air_slash_active := false
var _water_attack_blend := 0.0
var _action_sequence: Array[StringName] = []
var _action_sequence_name: StringName = &""


func _ready() -> void:
	process_priority = 100
	_player = get_parent() as CharacterBody2D
	if not enabled or not _player:
		return
	_build_viewport()
	if Engine.is_editor_hint():
		_hide_legacy_visuals()
		if _animation_player and _clips.has(&"idle_4"):
			_animation_player.play(_clips[&"idle_4"], 0.0)
			_animation_player.seek(0.0, true)
			_animation_player.pause()
		_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		return
	_sword_sweep = SWORD_SWEEP.new()
	_sword_sweep.name = "SwordSweep"
	_sword_sweep.z_index = 15
	add_child(_sword_sweep)
	_sword_sweep.set_as_top_level(true)
	_hide_legacy_visuals()
	play_gameplay_animation(&"Idle")


func _process(delta: float) -> void:
	if not enabled or not _display:
		return
	_hide_legacy_visuals()
	if Engine.is_editor_hint():
		return
	var facing := int(_player.get("last_direction"))
	if _logical_animation in [&"Dash", &"Water_Dash"]:
		var wet: bool = _player.is_in_prototype_water()
		if wet != (_logical_animation == &"Water_Dash"):
			play_gameplay_animation(&"Dash")
	_display.flip_h = facing < 0
	if _air_slash_active and (not _player.is_attacking or not _player.current_attack_uses_air_double):
		_air_slash_active = false
		_lower_sampler_action = &""
		_skeleton.clear_bones_global_pose_override()
	_update_swim_direction(delta, facing)
	_update_idle_variation(delta)
	if _upper_body_overlay_active:
		_sync_lower_body_sampler()
		_apply_lower_body_overrides()
	elif _skeleton:
		_skeleton.clear_bones_global_pose_override()
	if _air_slash_active and _player.is_in_prototype_water():
		_apply_water_attack_blend(delta)
	_apply_grapple_aim_override()
	_apply_swim_idle_sword_pose()
	_apply_idle_sword_clearance()
	_update_sword_smears(delta)
	if _skeleton and _pelvis_index >= 0:
		var lift := maxf(
			0.0,
			_skeleton.get_bone_global_pose(_pelvis_index).origin.y - _pelvis_rest_y
		)
		_model_root.position.y = -lift


func _exit_tree() -> void:
	# The generated composite is a sibling, not a serialized scene node.
	if Engine.is_editor_hint() and is_instance_valid(_display):
		_display.queue_free()


func _update_swim_direction(delta: float, facing: int) -> void:
	var swimming: bool = _player.is_in_prototype_water() and (_logical_animation in [&"Swim", &"Water_Dash"] or _air_slash_active) and not _upper_body_overlay_active
	if not swimming:
		_display.rotation = 0.0
		_display.position = _display_rest_position
		return
	if _player.velocity.length() > 20.0:
		var direction := _player.velocity.normalized()
		# The mirrored clip points left; rotate from that axis rather than right.
		var target := direction.angle() - (PI if facing < 0 else 0.0)
		_display.rotation = lerp_angle(_display.rotation, target, 1.0-exp(-14.0*delta))
	else:
		_display.rotation = lerp_angle(_display.rotation, 0.0, 1.0-exp(-14.0*delta))
	# Rotate around the collision center rather than swinging around the feet.
	var center := (_player.get_node("CollisionShape2D") as CollisionShape2D).position
	_display.position = center + (_display_rest_position-center).rotated(_display.rotation)


func play_gameplay_animation(logical_name: StringName) -> void:
	if not _animation_player:
		return
	if _player.current_attack_uses_air_double and logical_name in [&"Air_Double_Attack", &"Pogo_Attack"]:
		# The attack entry point owns the clip; keep the preceding swim phase
		# available for its lower-body sampler rather than flashing a placeholder.
		return
	if logical_name == &"Dash" and _player.is_in_prototype_water():
		logical_name = &"Water_Dash"
	if _upper_body_overlay_active:
		# Locomotion changes continue feeding the hidden lower-body sampler while
		# casting_2 owns the torso and arms.
		_logical_animation = logical_name
		return
	if _logical_animation == logical_name:
		return
	var was_water_dash := _logical_animation == &"Water_Dash"
	_logical_animation = logical_name
	_idle_elapsed = 0.0
	var selection := _select_action(logical_name)
	if logical_name == &"Water_Dash":
		_play_action(&"swimming_1", &"", 0.0, true, water_dash_animation_speed)
		return
	if was_water_dash and logical_name == &"Swim":
		# Same clip, different rate: explicitly restore ordinary swimming speed.
		_play_action(&"swimming_1", &"", 0.0, true, 1.0)
		return
	if logical_name == &"Dash":
		var roll_speed := get_action_duration(&"roll_1") / maxf(roll_duration, 0.01)
		_play_action(&"roll_1", &"idle_4", 0.0, true, roll_speed / base_playback_speed)
		return
	if logical_name == &"Wall_Cling":
		var entry_speed := (
			get_action_duration(&"jump_into_wall_hang_1")
			/ maxf(wall_cling_entry_duration, 0.01)
		)
		_play_action(
			&"jump_into_wall_hang_1",
			&"hanging_idle_1",
			0.0,
			true,
			entry_speed / base_playback_speed
		)
		return
	if logical_name == &"Neutral_Special_Attack":
		var power_speed := (
			get_action_duration(&"power_up_1")
			/ maxf(neutral_special_duration, 0.01)
		)
		_play_action(&"power_up_1", &"", 0.0, true, power_speed / base_playback_speed)
		return
	if logical_name == &"Sit":
		_start_action_sequence(&"save_point_sit", [&"turn_1", &"stand_to_sit_1"])
		return
	_play_action(selection.action, selection.get("fallback", &""), selection.get("start", 0.0), false, selection.get("speed", 1.0))


func play_grapple_throw() -> void:
	if not _animation_player or _upper_body_overlay_active:
		return
	_begin_upper_body_grapple_throw()


func play_water_entry() -> void:
	_cancel_upper_body_overlay()
	_action_sequence.clear()
	_action_sequence_name = &"water_entry"
	_current_action = &""
	_play_action(&"jumping_into_water_1", &"swimming_1", 0.0, true, 1.45)


func finish_water_entry() -> void:
	_action_sequence.clear()
	_action_sequence_name = &""
	_logical_animation = &""
	_current_action = &""
	_play_action(&"swimming_1" if _player.is_in_prototype_water() else &"jump_1", &"", 0.0, true)


func play_save_point_stand() -> void:
	_start_action_sequence(&"save_point_stand", [&"sit_to_stand_1", &"turn_2"])


func is_action_sequence_playing(sequence_name: StringName = &"") -> bool:
	return (
		_action_sequence_name != &""
		and (sequence_name == &"" or _action_sequence_name == sequence_name)
	)


func set_ledge_climb_progress(progress: float) -> void:
	if not _animation_player:
		return
	var clip := _clips.get(&"get_up_from_hang_1", &"") as StringName
	if clip == &"":
		return
	if _current_action != &"get_up_from_hang_1":
		_logical_animation = &"Ledge_Climb"
		_current_action = &"get_up_from_hang_1"
		_queued_action = &""
		_animation_player.play(clip, 0.05)
	var animation := _animation_player.get_animation(clip)
	_animation_player.seek(clampf(progress, 0.0, 0.999) * animation.length, true)
	_animation_player.pause()


func play_block_impact(crouched: bool) -> void:
	_cancel_upper_body_overlay()
	_logical_animation = &"Crouch_Block" if crouched else &"Block"
	_play_action(
		&"crouch_block_2" if crouched else &"impact_1",
		&"crouch_block_idle_1" if crouched else &"block_idle_1"
	)


func play_hurt(heavy: bool, crouched: bool) -> void:
	_cancel_upper_body_overlay()
	_logical_animation = &"Hurt"
	if crouched:
		_play_action(&"crouching_3")
	else:
		_play_action(&"impact_3" if heavy else &"impact_2")


func play_death(forward: bool) -> void:
	_cancel_upper_body_overlay()
	_logical_animation = &"Death"
	_play_action(&"death_2" if forward else &"death_1")


func play_ground_combo_strike(strike_index: int, crouched: bool, playback_speed: float) -> void:
	_cancel_upper_body_overlay()
	_logical_animation = StringName("Ground_Strike_%d" % strike_index)
	_idle_elapsed = 0.0
	if crouched:
		_play_action(&"slash_5", &"", 0.0, true, playback_speed)
		return
	var starts := [0.0, 1.15, 2.33]
	_play_action(
		&"slash_2",
		&"",
		starts[clampi(strike_index, 0, starts.size() - 1)],
		true,
		playback_speed
	)


func play_air_attack(playback_speed: float) -> float:
	_cancel_upper_body_overlay()
	_air_slash_active = true
	_logical_animation = &"Air_Double_Attack"
	_idle_elapsed = 0.0
	_skeleton.clear_bones_global_pose_override()
	var action: StringName = &"air_attack_forward"
	if _player.is_in_prototype_water():
		action = &"water_attack_idle"
		_water_attack_blend = clampf(_player.velocity.length() / 120.0, 0.0, 1.0)
	elif _player.attack_direction.y > 0.55:
		action = &"air_attack_down"
	elif _player.attack_direction.y < -0.55:
		action = &"air_attack_up"
	# Authored clips are already timed at 30fps; don't apply locomotion speed.
	_play_action(action, &"", 0.0, true, playback_speed / base_playback_speed, 0.01 if action in [&"air_attack_up", &"air_attack_down"] else 0.04)
	return get_action_duration(action) / maxf(playback_speed, 0.01)


func _apply_water_attack_blend(delta: float) -> void:
	var clip := _clips.get(&"water_attack_move", &"") as StringName
	if clip == &"" or not _lower_sampler_player:
		return
	_lower_sampler_action = &"water_attack_move"
	_lower_sampler_player.play(clip, 0.0)
	_lower_sampler_player.seek(get_current_action_position(), true)
	_lower_sampler_player.pause()
	var target := clampf(_player.velocity.length() / 120.0, 0.0, 1.0)
	_water_attack_blend = move_toward(_water_attack_blend, target, delta * 8.0)
	var globals: Array[Transform3D] = []
	for index in _skeleton.get_bone_count():
		var source := _lower_sampler_skeleton.find_bone(_skeleton.get_bone_name(index))
		var pose := _skeleton.get_bone_pose(index)
		if source >= 0:
			pose = pose.interpolate_with(_lower_sampler_skeleton.get_bone_pose(source), _water_attack_blend)
		var parent := _skeleton.get_bone_parent(index)
		var global_pose := globals[parent] * pose if parent >= 0 else pose
		globals.append(global_pose)
		_skeleton.set_bone_global_pose_override(index, global_pose, 1.0, true)


func play_spin_special(duration: float) -> void:
	_cancel_upper_body_overlay()
	_air_slash_active = false
	_skeleton.clear_bones_global_pose_override()
	_logical_animation = &"Spin_Special"
	_play_action(&"attack_2", &"", 0.0, true, get_action_duration(&"attack_2") / maxf(duration * base_playback_speed, 0.01))


func get_grapple_origin_player_offset() -> Vector2:
	if not _skeleton or _left_hand_index < 0 or not _camera or not _display:
		return Vector2.ZERO
	var hand_pose := _skeleton.get_bone_global_pose(_left_hand_index)
	var hand_world := _skeleton.to_global(hand_pose.origin)
	var viewport_point := _camera.unproject_position(hand_world)
	var sprite_point := (
		viewport_point
		- Vector2(_viewport.size) * 0.5
		+ _display.offset
	)
	if _display.flip_h:
		sprite_point.x = -sprite_point.x
	if _display.flip_v:
		sprite_point.y = -sprite_point.y
	return _display.transform * sprite_point


func get_ground_combo_segment_duration(strike_index: int, crouched: bool) -> float:
	if crouched:
		return get_action_duration(&"slash_5")
	var boundaries := [0.0, 1.15, 2.33, get_action_duration(&"slash_2")]
	var index := clampi(strike_index, 0, 2)
	return maxf(0.0, boundaries[index + 1] - boundaries[index])


func get_action_duration(action_name: StringName) -> float:
	var clip := _clips.get(action_name, &"") as StringName
	if clip == &"":
		return 0.0
	return _animation_player.get_animation(clip).length


func get_current_action_position() -> float:
	return _animation_player.current_animation_position if _animation_player else 0.0


func get_current_action_frame_30fps() -> int:
	return floori(get_current_action_position() * 30.0)


func get_current_action_remaining_duration() -> float:
	if not _animation_player or _animation_player.current_animation == &"":
		return 0.0
	var animation := _animation_player.get_animation(_animation_player.current_animation)
	return maxf(0.0, animation.length - _animation_player.current_animation_position)


func is_playing_transition() -> bool:
	return _queued_action != &"" and _animation_player and _animation_player.is_playing()


func _select_action(logical_name: StringName) -> Dictionary:
	match logical_name:
		&"Idle":
			return {"action": &"idle_4"}
		&"Run":
			return {"action": &"run_1"}
		&"Jump_Ascent", &"Jump_Apex", &"Jump_Descent", &"Jump_Land":
			return {"action": &"jump_1"}
		&"Double_Jump":
			return {"action": &"jump_2"}
		&"Crouch_Enter":
			return {"action": &"crouch_1", "fallback": &"crouch_idle_1"}
		&"Crouch_Idle":
			return {"action": &"crouch_idle_1"}
		&"Crouch_Exit":
			return {"action": &"crouching_1", "fallback": &"idle_4"}
		&"Block_Enter":
			return {"action": &"block_1", "fallback": &"block_idle_1"}
		&"Block_Idle":
			return {"action": &"block_idle_1"}
		&"Block_Backpedal":
			return {"action": &"run_2"}
		&"Block_Forward":
			return {"action": &"run_2", "speed": -1.0}
		&"Crouch_Block_Enter":
			return {"action": &"crouch_block_1", "fallback": &"crouch_block_idle_1"}
		&"Crouch_Block_Idle":
			return {"action": &"crouch_block_idle_1"}
		&"Crouch_Block_Exit":
			return {"action": &"crouching_2", "fallback": &"crouch_idle_1"}
		&"Ground_Attack_Combo_1":
			return {"action": &"slash_5" if bool(_player.get("is_crouching")) else &"slash_1"}
		&"Ground_Attack_Combo_2":
			# Skip the duplicated first swing in the authored three-hit clip.
			return {"action": &"slash_2", "start": 1.15}
		&"Crouch_Attack":
			return {"action": &"slash_5"}
		&"Neutral_Special_Attack":
			return {"action": &"power_up_1"}
		&"Air_Double_Attack":
			return {"action": &"slash_2"}
		&"Pogo_Attack":
			return {"action": &"slash_2"}
		&"Hurt":
			return {"action": &"impact_2"}
		&"Dash":
			return {"action": &"roll_1"}
		&"Swim":
			return {"action": &"swimming_1"}
		&"Swim_Idle":
			return {"action": &"water_idle_1"}
		&"Grapple_Swing":
			return {"action": &"grapple_swinging_1"}
		&"Wall_Cling":
			return {"action": &"jump_into_wall_hang_1", "fallback": &"hanging_idle_1"}
		&"Water_Ledge_Grab":
			return {"action": &"grab_ledge_from_water_1", "fallback": &"hanging_idle_1"}
		&"Ledge_Climb":
			return {"action": &"get_up_from_hang_1"}
		_:
			return {"action": &"idle_4"}


func _play_action(
	action_name: StringName,
	fallback: StringName = &"",
	start := 0.0,
	force_restart := false,
	playback_speed := 1.0,
	blend_time := -1.0
) -> void:
	var clip := _clips.get(action_name, &"") as StringName
	if clip == &"" or not force_restart and _current_action == action_name and _animation_player.is_playing() and signf(_animation_player.speed_scale) == signf(playback_speed):
		return
	_current_action = action_name
	_queued_action = fallback
	var animation := _animation_player.get_animation(clip)
	animation.loop_mode = (
		Animation.LOOP_LINEAR if LOOPING_ACTIONS.has(action_name) else Animation.LOOP_NONE
	)
	_animation_player.play(clip, blend_time if blend_time >= 0.0 else (0.0 if force_restart else 0.10))
	_animation_player.speed_scale = playback_speed * base_playback_speed
	if playback_speed < 0.0:
		_animation_player.seek(maxf(0.0, animation.length - 0.001), true)
	if start > 0.0 or force_restart:
		_animation_player.seek(minf(start, animation.length), true)


func _on_animation_finished(animation_name: StringName) -> void:
	if _action_sequence_name != &"":
		if not _action_sequence.is_empty():
			var next_sequence_action: StringName = _action_sequence.pop_front()
			_current_action = &""
			_play_action(next_sequence_action, &"", 0.0, true)
			return
		_action_sequence_name = &""
	if _upper_body_overlay_active and animation_name == _clips.get(&"casting_2", &""):
		_finish_upper_body_overlay()
		return
	if _queued_action == &"":
		return
	var next := _queued_action
	_queued_action = &""
	_current_action = &""
	_play_action(next)


func _update_idle_variation(delta: float) -> void:
	if _logical_animation != &"Idle" or _current_action != &"idle_4":
		return
	_idle_elapsed += delta
	if _idle_elapsed < idle_variation_delay:
		return
	_idle_elapsed = 0.0
	var variants: Array[StringName] = [&"idle_1", &"idle_2", &"idle_3"]
	var variant := variants[_idle_variant_index % variants.size()]
	_idle_variant_index += 1
	_play_action(variant, &"idle_4")


func _build_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "LiveCharacterViewport"
	_viewport.size = viewport_size
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	add_child(_viewport)

	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.65, 0.76, 0.90)
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	_viewport.add_child(environment_node)

	_model_root = MODEL.instantiate() as Node3D
	_model_root.name = "ThreadborneLive3D"
	_viewport.add_child(_model_root)
	_apply_toon_materials(_model_root)
	_animation_player = _find_first_type(_model_root, "AnimationPlayer") as AnimationPlayer
	_skeleton = _find_first_type(_model_root, "Skeleton3D") as Skeleton3D
	_sword_mesh = _model_root.find_child("Threadborne_Sword", true, false) as MeshInstance3D
	if _skeleton:
		_pelvis_index = _skeleton.find_bone("pelvis")
		_left_upper_arm_index = _skeleton.find_bone("upper_arm.L")
		_left_hand_index = _skeleton.find_bone("hand.L")
		if _pelvis_index >= 0:
			_pelvis_rest_y = _skeleton.get_bone_global_rest(_pelvis_index).origin.y
	_install_authored_attacks(_animation_player, _skeleton)
	_index_clips()
	if not Engine.is_editor_hint():
		_build_lower_body_sampler()
	if _animation_player:
		_animation_player.animation_finished.connect(_on_animation_finished)

	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = camera_size
	_camera.position = Vector3(-7.0, 1.15, 0)
	_viewport.add_child(_camera)
	_camera.look_at(Vector3(0, 1.15, 0), Vector3.UP)
	_camera.current = true
	# Add vertical render room without changing the character's pixel scale.
	var probe := Vector3(0, 1.15, 0)
	var pixels_before := _camera.unproject_position(probe).distance_to(_camera.unproject_position(probe + Vector3.UP))
	_viewport.size.y = ceili(viewport_size.y * 1.5)
	var pixels_after := _camera.unproject_position(probe).distance_to(_camera.unproject_position(probe + Vector3.UP))
	_camera.size *= pixels_after / maxf(pixels_before, 0.001)

	var key_light := DirectionalLight3D.new()
	key_light.light_color = Color(1.0, 0.94, 0.84)
	key_light.light_energy = 1.45
	key_light.shadow_enabled = true
	_viewport.add_child(key_light)
	key_light.look_at_from_position(Vector3(-4.0, 3.2, -2.8), Vector3(0, 1.0, 0), Vector3.UP)
	var rim_light := DirectionalLight3D.new()
	rim_light.light_color = Color(0.31, 0.47, 0.76)
	rim_light.light_energy = 0.65
	_viewport.add_child(rim_light)
	rim_light.look_at_from_position(Vector3(3.0, 2.4, 2.2), Vector3(0, 1.0, 0), Vector3.UP)
	var fill_light := DirectionalLight3D.new()
	fill_light.name = "SoftSkyFill"
	fill_light.light_color = Color(0.72, 0.84, 1.0)
	fill_light.light_energy = 0.65
	_viewport.add_child(fill_light)
	fill_light.look_at_from_position(Vector3(-5.0, 1.7, 3.0), Vector3(0, 1.0, 0), Vector3.UP)

	_display = Sprite2D.new()
	_display.name = "Live3DComposite"
	# World lights include lighting layer 2; the player's layer-1 soul glow
	# should illuminate nearby scenery without washing out its own model.
	_display.light_mask = 2
	_display.texture = _viewport.get_texture()
	_display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_display.scale = display_scale
	_display.offset = Vector2(0, -255)
	var collider := _player.get_node("CollisionShape2D") as CollisionShape2D
	var shape := collider.shape as RectangleShape2D
	_display.position = Vector2(0, collider.position.y + shape.size.y * 0.5)
	_display_rest_position = _display.position
	var outline_material := ShaderMaterial.new()
	outline_material.shader = OUTLINE_SHADER
	_display.material = outline_material
	_player.add_child.call_deferred(_display)


func _index_clips() -> void:
	if not _animation_player:
		return
	for animation_name in _animation_player.get_animation_list():
		var lower := String(animation_name).to_lower()
		for desired in [
			"idle_1", "idle_2", "idle_3", "idle_4", "run_1", "run_2",
			"walk_1", "walk_2", "jump_1", "jump_2", "crouch_1",
			"crouch_idle_1", "crouching_1", "crouching_2", "crouching_3",
			"block_1", "block_idle_1", "crouch_block_1", "crouch_block_2",
			"crouch_block_idle_1", "impact_1", "impact_2", "impact_3",
			"death_1", "death_2", "attack_1", "attack_2", "attack_3", "air_light_1", "slash_1", "slash_2", "slash_5",
			"casting_1", "casting_2", "power_up_1", "turn_1", "turn_2",
			"stand_to_sit_1", "sit_to_stand_1", "jumping_into_water_1",
			"grapple_swinging_1", "water_idle_1", "swimming_1",
			"grab_ledge_from_water_1", "get_up_from_hang_1", "hanging_idle_1",
			"jump_into_wall_hang_1", "roll_1",
			"air_attack_forward", "air_attack_up", "air_attack_down",
			"water_attack_idle", "water_attack_move"
		]:
			if lower.ends_with(desired) and not _clips.has(StringName(desired)):
				_clips[StringName(desired)] = animation_name


func _hide_legacy_visuals() -> void:
	if Engine.is_editor_hint():
		# Hide only their canvas RIDs: do not serialize editor-only visibility
		# changes into the player or the user's level instances.
		for path in ["Player Animation", "GlowSprite", "EquipmentMount/BackSheathedWeaverShuttle"]:
			var legacy := _player.get_node_or_null(path) as CanvasItem
			if legacy:
				RenderingServer.canvas_item_set_visible(legacy.get_canvas_item(), false)
		return
	for path in ["Player Animation", "GlowSprite"]:
		var item := _player.get_node_or_null(path) as CanvasItem
		if item:
			item.hide()
	var equipment_mount := _player.get_node_or_null("EquipmentMount") as CanvasItem
	if equipment_mount:
		# Gameplay hitboxes and the active grapple live below this mount, so the
		# parent must stay visible even though its retired weapon art is hidden.
		equipment_mount.show()
	var sheathed_weapon := _player.get_node_or_null(
		"EquipmentMount/BackSheathedWeaverShuttle"
	) as CanvasItem
	if sheathed_weapon:
		sheathed_weapon.hide()
	var gloves = _player.get("current_gloves")
	if gloves is CanvasItem:
		# Keep the established top-level rope simulation and needle visible. Only
		# the old stowed wrist sprite is replaced by the live 3D grapple coil.
		gloves.show()
		var equipment := gloves.get_node_or_null("Equipment") as CanvasItem
		if equipment:
			equipment.show()
		var wrist_art := gloves.get_node_or_null("Equipment/RightHandAnchor") as CanvasItem
		if wrist_art:
			wrist_art.hide()
		var active_grapple := gloves.get_node_or_null("Equipment/ActiveGrappleRoot") as CanvasItem
		if active_grapple:
			# The live 3D composite is added after equipment at runtime. An absolute
			# foreground Z keeps the launched rope and needle readable above it.
			active_grapple.z_as_relative = false
			active_grapple.z_index = 20
	var pattern = _player.get("_pattern_visual")
	if pattern is CanvasItem:
		pattern.hide()


func _apply_toon_materials(root: Node) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if not mesh_instance.mesh:
			continue
		for surface in mesh_instance.mesh.get_surface_count():
			var source := mesh_instance.get_active_material(surface)
			if source is StandardMaterial3D:
				var stylized := source.duplicate() as StandardMaterial3D
				stylized.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
				stylized.specular_mode = BaseMaterial3D.SPECULAR_TOON
				stylized.roughness = maxf(stylized.roughness, 0.62)
				if mesh_instance.name == &"Threadborne_Sword":
					# The cloth toon pass flattened the sword's specular highlights.
					stylized.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
					stylized.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
					stylized.roughness = 0.25
					stylized.metallic = 0.35
					stylized.metallic_specular = 0.9
					stylized.albedo_color = Color(1.65, 1.72, 1.8, 1.0)
				mesh_instance.set_surface_override_material(surface, stylized)


func _apply_grapple_aim_override() -> void:
	if not _skeleton or _left_upper_arm_index < 0:
		return
	if _current_action != &"casting_2":
		return
	var gloves = _player.get("current_gloves")
	if not gloves or not gloves.has_method("get_active_grapple_direction"):
		return
	var direction: Vector2 = gloves.call("get_active_grapple_direction")
	if direction.length_squared() <= 0.001:
		return
	var facing := float(_player.get("last_direction"))
	var local_direction := Vector2(direction.x * facing, direction.y).normalized()
	var aim_angle := clampf(local_direction.angle(), deg_to_rad(-75.0), deg_to_rad(75.0))
	var pose := _skeleton.get_bone_global_pose_no_override(_left_upper_arm_index)
	# The orthographic camera looks down model X, so rotating about X aims the
	# shield/grapple arm within the 2D gameplay plane while preserving the cast.
	pose.basis = Basis(Vector3.RIGHT, aim_angle) * pose.basis
	_skeleton.set_bone_global_pose_override(_left_upper_arm_index, pose, 0.82, true)


func _update_sword_smears(_delta: float) -> void:
	if not _sword_sweep:
		return
	var data: Dictionary = _player.get_sword_sweep_state()
	if not sword_smear_enabled or data.is_empty():
		_sword_sweep.clear()
		return
	var channels: Array[Color] = []
	var aura = _player.get("flow_state_aura")
	if aura and aura.has_method("get_attack_identity_channels"):
		channels = aura.get_attack_identity_channels()
	_sword_sweep.set_sweep(data.phase, data.radius, data.arc,
		data.pose, channels, data.reverse,
		_get_blade_world_points(), data.style)
	if data.style == 2 and _player.is_on_floor():
		var collider := _player.get_node("CollisionShape2D") as CollisionShape2D
		var feet := collider.to_global(Vector2(0, collider.shape.get_rect().end.y))
		_sword_sweep.align_ground(feet.y)


func _apply_swim_idle_sword_pose() -> void:
	if _logical_animation != &"Swim_Idle" or not _skeleton or not _sword_mesh:
		return
	if _upper_body_overlay_active or bool(_player.get("is_attacking")):
		return
	var upper := _skeleton.find_bone("upper_arm.R")
	var fore := _skeleton.find_bone("forearm.R")
	var hand := _skeleton.find_bone("hand.R")
	if upper < 0 or fore < 0 or hand < 0:
		return
	var upper_rest := _skeleton.get_bone_global_rest(upper)
	var fore_rest := _skeleton.get_bone_global_rest(fore)
	var hand_rest := _skeleton.get_bone_global_rest(hand)
	var shoulder := _skeleton.get_bone_global_pose_no_override(upper).origin
	# Hold the arm ahead of the torso; let the original tread-water animation
	# continue on the body, legs and shield arm without sweeping the sword back.
	var elbow := shoulder + Vector3(0, -0.7, 0.7).normalized() * upper_rest.origin.distance_to(fore_rest.origin)
	var grip := elbow + Vector3(0, 0.65, 0.76).normalized() * fore_rest.origin.distance_to(hand_rest.origin)
	var upper_pose := upper_rest
	upper_pose.origin = shoulder
	upper_pose.basis = Basis(Quaternion((fore_rest.origin-upper_rest.origin).normalized(), (elbow-shoulder).normalized())) * upper_rest.basis
	_skeleton.set_bone_global_pose_override(upper, upper_pose, 1.0, true)
	var fore_pose := fore_rest
	fore_pose.origin = elbow
	fore_pose.basis = Basis(Quaternion((hand_rest.origin-fore_rest.origin).normalized(), (grip-elbow).normalized())) * fore_rest.basis
	_skeleton.set_bone_global_pose_override(fore, fore_pose, 1.0, true)
	var hand_pose := hand_rest
	hand_pose.origin = grip
	_skeleton.set_bone_global_pose_override(hand, hand_pose, 1.0, true)
	var blade := _get_blade_model_points()
	if blade.size() == 2:
		var axis := (_skeleton.global_basis.inverse() * (blade[1]-blade[0])).normalized()
		hand_pose.basis = Basis(Quaternion(axis, Vector3(0,1,0.15).normalized())) * hand_pose.basis
		_skeleton.set_bone_global_pose_override(hand, hand_pose, 1.0, true)


func _get_blade_world_points() -> PackedVector2Array:
	if not _sword_mesh or not _skeleton:
		return PackedVector2Array()
	var points := PackedVector2Array()
	for point in _get_blade_model_points():
		var pixel := _camera.unproject_position(point) - Vector2(_viewport.size) * 0.5 + _display.offset
		if _display.flip_h:
			pixel.x = -pixel.x
		points.append(_display.to_global(pixel))
	return points


func _get_blade_model_points() -> PackedVector3Array:
	# BoneAttachment updates after animation. Reconstruct its transform from the
	# current skeleton pose so aiming and smears never consume last frame's sword.
	var node: Node = _sword_mesh
	var relative := Transform3D.IDENTITY
	while node is Node3D and not node is BoneAttachment3D:
		relative = (node as Node3D).transform * relative
		node = node.get_parent()
	if not node is BoneAttachment3D:
		return PackedVector3Array()
	var attachment := node as BoneAttachment3D
	var bone_pose := _skeleton.global_transform * _skeleton.get_bone_global_pose(attachment.bone_idx)
	var sword_pose := bone_pose * relative
	# Mesh-local blade centerline measured from the actual sword vertices.
	# A bounding-box corner sits off the blade and made stab silhouettes drift.
	var blade_base := Vector3(0.0004, 0.20, 0.3145)
	var blade_tip := Vector3(0.0003, -0.49, 0.3144)
	return PackedVector3Array([sword_pose * blade_base, sword_pose * blade_tip])


func _build_lower_body_sampler() -> void:
	_lower_sampler_root = MODEL.instantiate() as Node3D
	_lower_sampler_root.name = "LowerBodyAnimationSampler"
	_lower_sampler_root.visible = false
	_viewport.add_child(_lower_sampler_root)
	# Imported meshes and skins share their resources with the visible model.
	# Hiding the sampler prevents any second draw while retaining valid skin
	# bindings for the animation-only skeleton.
	_lower_sampler_player = _find_first_type(_lower_sampler_root, "AnimationPlayer") as AnimationPlayer
	_lower_sampler_skeleton = _find_first_type(_lower_sampler_root, "Skeleton3D") as Skeleton3D
	_install_authored_attacks(_lower_sampler_player, _lower_sampler_skeleton)


func _start_action_sequence(sequence_name: StringName, actions: Array[StringName]) -> void:
	_cancel_upper_body_overlay()
	_action_sequence = actions.duplicate()
	_action_sequence_name = sequence_name
	if _action_sequence.is_empty():
		_action_sequence_name = &""
		return
	var first_action: StringName = _action_sequence.pop_front()
	_current_action = &""
	_queued_action = &""
	_play_action(first_action, &"", 0.0, true)


func _begin_upper_body_grapple_throw() -> void:
	_upper_body_overlay_active = true
	_logical_animation = &"Neutral_Special_Attack"
	_idle_elapsed = 0.0
	_sync_lower_body_sampler(true)
	var throw_speed := get_action_duration(&"casting_2") / maxf(grapple_throw_duration, 0.01)
	_play_action(&"casting_2", &"", 0.0, true, throw_speed / base_playback_speed)


func _finish_upper_body_overlay() -> void:
	var resume_action := _select_lower_body_action()
	var resume_position := 0.0
	if _lower_sampler_player and _lower_sampler_player.current_animation != &"":
		resume_position = _lower_sampler_player.current_animation_position
	_cancel_upper_body_overlay()
	_logical_animation = &""
	_current_action = &""
	_play_action(resume_action, &"", resume_position, true)


func _cancel_upper_body_overlay() -> void:
	if not _upper_body_overlay_active:
		return
	_upper_body_overlay_active = false
	_lower_sampler_action = &""
	if _lower_sampler_player:
		_lower_sampler_player.stop()
	if _skeleton:
		_skeleton.clear_bones_global_pose_override()


func _select_lower_body_action() -> StringName:
	if _player.has_method("is_in_prototype_water") and _player.call("is_in_prototype_water"):
		return &"swimming_1" if _player.velocity.length() > 20.0 else &"water_idle_1"
	if not _player.is_on_floor():
		var gloves = _player.get("current_gloves")
		if gloves and gloves.has_method("is_grapple_attached") and gloves.call("is_grapple_attached"):
			return &"grapple_swinging_1"
		return &"jump_1"
	if bool(_player.get("is_crouching")):
		return &"crouch_idle_1"
	if absf(_player.velocity.x) > 20.0:
		return &"run_1"
	return &"idle_4"


func _sync_lower_body_sampler(force_restart := false) -> void:
	if not _lower_sampler_player:
		return
	var action := _select_lower_body_action()
	var clip := _clips.get(action, &"") as StringName
	if clip == &"" or not force_restart and action == _lower_sampler_action:
		return
	_lower_sampler_action = action
	var animation := _lower_sampler_player.get_animation(clip)
	animation.loop_mode = Animation.LOOP_LINEAR if LOOPING_ACTIONS.has(action) else Animation.LOOP_NONE
	_lower_sampler_player.play(clip, 0.08)
	_lower_sampler_player.speed_scale = base_playback_speed


func _apply_lower_body_overrides() -> void:
	if not _skeleton or not _lower_sampler_skeleton:
		return
	for bone_name in LOWER_BODY_BONES:
		var target_index := _skeleton.find_bone(bone_name)
		var source_index := _lower_sampler_skeleton.find_bone(bone_name)
		if target_index < 0 or source_index < 0:
			continue
		var pose := _lower_sampler_skeleton.get_bone_global_pose(source_index)
		_skeleton.set_bone_global_pose_override(target_index, pose, 1.0, true)


func _find_first_type(root: Node, type_name: String) -> Node:
	if root.is_class(type_name):
		return root
	for child in root.get_children():
		var found := _find_first_type(child, type_name)
		if found:
			return found
	return null


func _install_authored_attacks(target: AnimationPlayer, skeleton: Skeleton3D) -> void:
	var donor := AUTHORED_ATTACKS.instantiate()
	var animations := _find_first_type(donor, "AnimationPlayer") as AnimationPlayer
	var library := AnimationLibrary.new()
	var skeleton_path := target.get_node(target.root_node).get_path_to(skeleton)
	for clip in animations.get_animation_list():
		if clip == &"RESET":
			continue
		var animation := animations.get_animation(clip).duplicate(true) as Animation
		for track in range(animation.get_track_count()-1, -1, -1):
			var path := animation.track_get_path(track)
			if path.get_subname_count() != 1 or skeleton.find_bone(path.get_subname(0)) < 0:
				animation.remove_track(track)
				continue
			animation.track_set_path(track, NodePath(String(skeleton_path)+":"+String(path.get_subname(0))))
		if String(clip) in ["air_attack_up", "air_attack_down"]:
			# Map the baked poses to quick extension, held contact, quick withdrawal.
			var old_times := [0.0, 4.0/30.0, 7.0/30.0, 9.0/30.0, 11.0/30.0, 17.0/30.0, 0.8]
			var new_times := [0.0, 0.017, 1.0/30.0, 0.17, 0.19, 0.27, 0.32]
			for track in animation.get_track_count():
				for key in animation.track_get_key_count(track):
					var time := animation.track_get_key_time(track, key)
					for segment in range(old_times.size()-1):
						if time <= old_times[segment+1] + 0.00001:
							var weight := inverse_lerp(old_times[segment], old_times[segment+1], time)
							animation.track_set_key_time(track, key, lerpf(new_times[segment], new_times[segment+1], weight))
							break
			animation.length = 0.32
		if String(clip) == "air_attack_forward":
			# Preserve windup/contact; compress only the recovery after frame 12.
			var recovery_start := 11.0/30.0
			for track in animation.get_track_count():
				for key in animation.track_get_key_count(track):
					var time := animation.track_get_key_time(track, key)
					if time > recovery_start:
						animation.track_set_key_time(track, key, recovery_start + (time-recovery_start)*0.35)
			animation.length = recovery_start + (animation.length-recovery_start)*0.35
		library.add_animation(clip, animation)
	target.add_animation_library(&"authored", library)
	donor.free()


func _apply_idle_sword_clearance() -> void:
	if _current_action != &"idle_4" or _air_slash_active or not _skeleton:
		return
	var hand := _skeleton.find_bone("hand.R")
	if hand < 0:
		return
	# Separate the blade tip from the face in the gameplay camera projection.
	# The composite outline cannot distinguish two opaque overlapping surfaces.
	var pose := _skeleton.get_bone_global_pose(hand)
	pose.basis = Basis(Vector3.RIGHT, deg_to_rad(14.0)) * pose.basis
	_skeleton.set_bone_global_pose_override(hand, pose, 1.0, true)

