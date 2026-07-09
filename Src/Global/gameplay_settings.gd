extends Node

signal gameplay_settings_changed

const SAVE_PATH := "user://gameplay.cfg"
const SECTION := "gameplay"
const DIFFICULTIES: Array[String] = ["EASY", "NORMAL", "HARD"]

var difficulty_index := 1
var auto_save := true
var tutorial_hints := true
var vibration := true
var damage_numbers := true

func _ready() -> void:
	load_settings()

func get_difficulty_label() -> String:
	return DIFFICULTIES[clampi(difficulty_index, 0, DIFFICULTIES.size() - 1)]

func set_difficulty_index(index: int) -> void:
	difficulty_index = clampi(index, 0, DIFFICULTIES.size() - 1)
	save_settings()
	gameplay_settings_changed.emit()

func cycle_difficulty(step: int) -> void:
	set_difficulty_index(wrapi(difficulty_index + step, 0, DIFFICULTIES.size()))

func set_toggle(setting_name: StringName, enabled: bool) -> void:
	match setting_name:
		&"auto_save":
			auto_save = enabled
		&"tutorial_hints":
			tutorial_hints = enabled
		&"vibration":
			vibration = enabled
		&"damage_numbers":
			damage_numbers = enabled
	save_settings()
	gameplay_settings_changed.emit()

func get_toggle_label(setting_name: StringName) -> String:
	return "ON" if _get_toggle(setting_name) else "OFF"

func cycle_toggle(setting_name: StringName) -> void:
	set_toggle(setting_name, not _get_toggle(setting_name))

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	difficulty_index = int(config.get_value(SECTION, "difficulty_index", difficulty_index))
	difficulty_index = clampi(difficulty_index, 0, DIFFICULTIES.size() - 1)
	auto_save = bool(config.get_value(SECTION, "auto_save", auto_save))
	tutorial_hints = bool(config.get_value(SECTION, "tutorial_hints", tutorial_hints))
	vibration = bool(config.get_value(SECTION, "vibration", vibration))
	damage_numbers = bool(config.get_value(SECTION, "damage_numbers", damage_numbers))

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, "difficulty_index", difficulty_index)
	config.set_value(SECTION, "auto_save", auto_save)
	config.set_value(SECTION, "tutorial_hints", tutorial_hints)
	config.set_value(SECTION, "vibration", vibration)
	config.set_value(SECTION, "damage_numbers", damage_numbers)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("GameplaySettings could not save settings: %s." % error_string(error))

func _get_toggle(setting_name: StringName) -> bool:
	match setting_name:
		&"auto_save":
			return auto_save
		&"tutorial_hints":
			return tutorial_hints
		&"vibration":
			return vibration
		&"damage_numbers":
			return damage_numbers
		_:
			return false
