class_name AudioRegistry
extends Resource

@export var sounds: Dictionary = {}

func has_sound(sound_name: StringName) -> bool:
	return sounds.has(sound_name) or sounds.has(String(sound_name))

func get_sound(sound_name: StringName) -> Resource:
	if sounds.has(sound_name):
		return sounds[sound_name] as Resource

	var string_key := String(sound_name)
	if sounds.has(string_key):
		return sounds[string_key] as Resource

	return null
