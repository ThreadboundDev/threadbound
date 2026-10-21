@tool
extends Node3D
## Rigged art only. Movement, collision and attack windows belong to its future controller.

const LOOPING: Array[StringName] = [&"idle", &"run", &"wall_perch"]
@export var preview_clip: StringName = &"idle"
var animator: AnimationPlayer

func _ready() -> void:
	for candidate: Node in find_children("*", "AnimationPlayer", true, false):
		animator = candidate as AnimationPlayer
		break
	if animator:
		for key: StringName in animator.get_animation_list():
			animator.get_animation(key).loop_mode = Animation.LOOP_LINEAR if key in LOOPING else Animation.LOOP_NONE
		play_clip(preview_clip)
		if Engine.is_editor_hint():
			animator.seek(0.0, true)
			animator.pause()

func play_clip(clip: StringName, duration := 0.0, blend := 0.06) -> bool:
	if animator == null or not animator.has_animation(clip):
		return false
	var speed := animator.get_animation(clip).length / duration if duration > 0 else 1.0
	animator.play(clip, blend, speed)
	return true
