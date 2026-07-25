class_name DamageNumber
extends Label

const RISE_DISTANCE := 54.0
const DRIFT_DISTANCE := 12.0
const POP_DURATION := 0.10
const HOLD_DURATION := 0.22
const FADE_DURATION := 0.38


func show_damage(amount: int, world_position: Vector2) -> void:
	text = str(amount)
	global_position = world_position - size * 0.5

	var drift_direction := -1.0 if randi() % 2 == 0 else 1.0
	var destination := position + Vector2(DRIFT_DISTANCE * drift_direction, -RISE_DISTANCE)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, POP_DURATION).from(Vector2(0.65, 0.65)) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", destination, POP_DURATION + HOLD_DURATION + FADE_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION).set_delay(POP_DURATION + HOLD_DURATION)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
