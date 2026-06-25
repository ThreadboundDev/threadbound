class_name AudioSound
extends Resource

@export var stream: AudioStream
@export var stream_variants: Array[AudioStream] = []
@export var bus: StringName = &"SFX"
@export_range(-80.0, 24.0, 0.1) var volume_db: float = 0.0
@export_range(0.25, 4.0, 0.01) var pitch_scale: float = 1.0
@export_range(0.0, 0.5, 0.001) var pitch_variation: float = 0.0

func get_stream() -> AudioStream:
	var available_streams: Array[AudioStream] = []
	if stream:
		available_streams.append(stream)
	for variant in stream_variants:
		if variant:
			available_streams.append(variant)

	if available_streams.is_empty():
		return null
	if available_streams.size() == 1:
		return available_streams[0]
	return available_streams.pick_random()

func get_pitch_scale(pitch_variation_override: float = -1.0) -> float:
	var variation := pitch_variation
	if pitch_variation_override >= 0.0:
		variation = pitch_variation_override
	if variation <= 0.0:
		return pitch_scale

	return pitch_scale * randf_range(1.0 - variation, 1.0 + variation)
