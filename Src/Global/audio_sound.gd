class_name AudioSound
extends Resource

@export var stream: AudioStream
@export var bus: StringName = &"SFX"
@export_range(-80.0, 24.0, 0.1) var volume_db: float = 0.0
@export_range(0.25, 4.0, 0.01) var pitch_scale: float = 1.0
@export_range(0.0, 0.5, 0.001) var pitch_variation: float = 0.0

func get_pitch_scale(pitch_variation_override: float = -1.0) -> float:
	var variation := pitch_variation
	if pitch_variation_override >= 0.0:
		variation = pitch_variation_override
	if variation <= 0.0:
		return pitch_scale

	return pitch_scale * randf_range(1.0 - variation, 1.0 + variation)
