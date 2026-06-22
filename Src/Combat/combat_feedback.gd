class_name CombatFeedback
extends Node

static func hit_pause(source_node: Node, duration: float, time_scale: float = 0.08) -> void:
	if duration <= 0.0 or not source_node or not source_node.is_inside_tree():
		return

	Engine.time_scale = time_scale
	await source_node.get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

static func screen_shake(source_node: Node, strength: float = 6.0, duration: float = 0.08) -> void:
	if strength <= 0.0 or duration <= 0.0 or not source_node or not source_node.is_inside_tree():
		return

	var camera := source_node.get_viewport().get_camera_2d()
	if not camera:
		return

	var original_offset := camera.offset
	var tween := source_node.create_tween()
	var steps := 4
	for i in range(steps):
		var shake := Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		tween.tween_property(camera, "offset", shake, duration / float(steps))
	tween.tween_property(camera, "offset", original_offset, duration / float(steps))
