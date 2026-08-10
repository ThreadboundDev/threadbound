class_name CombatFeedback
extends Node

const HIT_PAUSE_DURATION_MULTIPLIER := 1.65
const HIT_PAUSE_MIN_VISIBLE_DURATION := 0.05
const HIT_PAUSE_MAX_DURATION := 0.12

static var _pause_end_usec := 0
static var _pause_running := false
static var _pause_restore_time_scale := 1.0
static var _pause_tree_id := 0
static var _shake_states: Dictionary = {}

static func hit_pause(source_node: Node, duration: float, time_scale: float = 0.08) -> void:
	if duration <= 0.0 or not source_node or not source_node.is_inside_tree():
		return

	var effective_duration := get_effective_hit_pause_duration(duration)
	var tree := source_node.get_tree()
	var tree_id := tree.get_instance_id()
	var now_usec := Time.get_ticks_usec()
	var requested_end_usec := now_usec + int(effective_duration * 1000000.0)

	if _pause_running and _pause_tree_id != tree_id:
		Engine.time_scale = _pause_restore_time_scale
		_pause_running = false
		_pause_end_usec = 0

	_pause_end_usec = maxi(_pause_end_usec, requested_end_usec)
	if _pause_running:
		Engine.time_scale = minf(Engine.time_scale, time_scale)
		return

	_pause_running = true
	_pause_tree_id = tree_id
	_pause_restore_time_scale = Engine.time_scale
	Engine.time_scale = time_scale
	_run_hit_pause(tree, tree_id)

static func get_effective_hit_pause_duration(duration: float) -> float:
	if duration <= 0.0:
		return 0.0
	return clampf(
		duration * HIT_PAUSE_DURATION_MULTIPLIER,
		HIT_PAUSE_MIN_VISIBLE_DURATION,
		HIT_PAUSE_MAX_DURATION
	)

static func _run_hit_pause(tree: SceneTree, tree_id: int) -> void:
	while _pause_running and _pause_tree_id == tree_id:
		var remaining_seconds := float(_pause_end_usec - Time.get_ticks_usec()) / 1000000.0
		if remaining_seconds <= 0.0:
			break
		await tree.create_timer(remaining_seconds, true, false, true).timeout

	if not _pause_running or _pause_tree_id != tree_id:
		return

	Engine.time_scale = _pause_restore_time_scale
	_pause_running = false
	_pause_end_usec = 0
	_pause_tree_id = 0

static func screen_shake(source_node: Node, strength: float = 6.0, duration: float = 0.08) -> void:
	if strength <= 0.0 or duration <= 0.0 or not source_node or not source_node.is_inside_tree():
		return

	var camera := source_node.get_viewport().get_camera_2d()
	if not camera:
		return

	var camera_id := camera.get_instance_id()
	var base_offset := camera.offset
	var merged_strength := strength
	var merged_duration := duration
	if _shake_states.has(camera_id):
		var previous_state: Dictionary = _shake_states[camera_id]
		base_offset = previous_state.get("base_offset", base_offset)
		merged_strength = maxf(strength, float(previous_state.get("strength", 0.0)))
		merged_duration = maxf(duration, float(previous_state.get("duration", 0.0)))
		var previous_tween := previous_state.get("tween") as Tween
		if previous_tween and previous_tween.is_valid():
			previous_tween.kill()

	var tween := camera.create_tween()
	_shake_states[camera_id] = {
		"base_offset": base_offset,
		"strength": merged_strength,
		"duration": merged_duration,
		"tween": tween,
	}

	var steps := 5
	for _step in range(steps):
		var shake := Vector2(
			randf_range(-merged_strength, merged_strength),
			randf_range(-merged_strength, merged_strength)
		)
		tween.tween_property(
			camera,
			"offset",
			base_offset + shake,
			merged_duration / float(steps + 1)
		)
	tween.tween_property(
		camera,
		"offset",
		base_offset,
		merged_duration / float(steps + 1)
	)
	tween.tween_callback(_finish_screen_shake.bind(camera_id, camera, tween, base_offset))

static func _finish_screen_shake(
	camera_id: int,
	camera: Camera2D,
	completed_tween: Tween,
	base_offset: Vector2
) -> void:
	if not _shake_states.has(camera_id):
		return
	var state: Dictionary = _shake_states[camera_id]
	if state.get("tween") != completed_tween:
		return
	if is_instance_valid(camera):
		camera.offset = base_offset
	_shake_states.erase(camera_id)
