class_name CombatFeedback
extends Node

static func hit_pause(owner: Node, duration: float, time_scale: float = 0.08) -> void:
	if duration <= 0.0 or not owner or not owner.is_inside_tree():
		return

	Engine.time_scale = time_scale
	await owner.get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

static func screen_shake(owner: Node, strength: float = 6.0, duration: float = 0.08) -> void:
	if strength <= 0.0 or duration <= 0.0 or not owner or not owner.is_inside_tree():
		return

	var camera := owner.get_viewport().get_camera_2d()
	if not camera:
		return

	var original_offset := camera.offset
	var tween := owner.create_tween()
	var steps := 4
	for i in range(steps):
		var shake := Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		tween.tween_property(camera, "offset", shake, duration / float(steps))
	tween.tween_property(camera, "offset", original_offset, duration / float(steps))
