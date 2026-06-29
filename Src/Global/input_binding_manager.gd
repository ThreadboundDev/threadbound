extends Node

signal bindings_changed

const SAVE_PATH := "user://controls.cfg"
const SECTION := "keyboard_mouse"

var _defaults: Dictionary = {}

func _ready() -> void:
	_capture_defaults()
	load_bindings()

func get_primary_keyboard_event(action: StringName) -> InputEvent:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey or event is InputEventMouseButton:
			return event
	return null

func get_keyboard_conflict(new_event: InputEvent, ignored_action: StringName = &"") -> StringName:
	for action in InputMap.get_actions():
		if action == ignored_action:
			continue
		for existing_event in InputMap.action_get_events(action):
			if _events_match_keyboard_mouse(existing_event, new_event):
				return StringName(action)
	return &""

func rebind_keyboard_action(action: StringName, new_event: InputEvent, overwrite_conflict := false) -> bool:
	if not InputMap.has_action(action):
		return false
	if not _is_keyboard_mouse_event(new_event):
		return false

	var conflict := get_keyboard_conflict(new_event, action)
	if conflict != &"":
		if not overwrite_conflict:
			return false
		_remove_keyboard_mouse_events(conflict)

	_remove_keyboard_mouse_events(action)
	InputMap.action_add_event(action, _normalized_event(new_event))
	save_bindings()
	bindings_changed.emit()
	return true

func load_bindings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return

	for action in config.get_section_keys(SECTION):
		if not InputMap.has_action(action):
			continue
		var encoded := String(config.get_value(SECTION, action, ""))
		var event := _decode_event(encoded)
		if event:
			_remove_keyboard_mouse_events(StringName(action))
			InputMap.action_add_event(StringName(action), event)

	bindings_changed.emit()

func save_bindings() -> void:
	var config := ConfigFile.new()
	for action in InputMap.get_actions():
		var event := get_primary_keyboard_event(StringName(action))
		if event:
			config.set_value(SECTION, String(action), _encode_event(event))
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("InputBindingManager could not save controls: %s." % error_string(error))

func reset_to_defaults() -> void:
	for action in _defaults:
		_remove_keyboard_mouse_events(action)
		for event in _defaults[action]:
			InputMap.action_add_event(action, event.duplicate())
	save_bindings()
	bindings_changed.emit()

func _capture_defaults() -> void:
	for action in InputMap.get_actions():
		var events: Array[InputEvent] = []
		for event in InputMap.action_get_events(action):
			if _is_keyboard_mouse_event(event):
				events.append(event.duplicate())
		if not events.is_empty():
			_defaults[StringName(action)] = events

func _remove_keyboard_mouse_events(action: StringName) -> void:
	for event in InputMap.action_get_events(action):
		if _is_keyboard_mouse_event(event):
			InputMap.action_erase_event(action, event)

func _normalized_event(event: InputEvent) -> InputEvent:
	var copy := event.duplicate()
	copy.device = -1
	if copy is InputEventKey:
		copy.pressed = false
		copy.echo = false
	elif copy is InputEventMouseButton:
		copy.pressed = false
	return copy

func _is_keyboard_mouse_event(event: InputEvent) -> bool:
	return event is InputEventKey or event is InputEventMouseButton

func _events_match_keyboard_mouse(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var a_code: int = a.physical_keycode if a.physical_keycode != 0 else a.keycode
		var b_code: int = b.physical_keycode if b.physical_keycode != 0 else b.keycode
		return a_code == b_code
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	return false

func _encode_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		return "key:%d" % code
	if event is InputEventMouseButton:
		return "mouse:%d" % event.button_index
	return ""

func _decode_event(encoded: String) -> InputEvent:
	var parts := encoded.split(":", false, 1)
	if parts.size() != 2:
		return null

	match parts[0]:
		"key":
			var event := InputEventKey.new()
			event.physical_keycode = int(parts[1])
			return event
		"mouse":
			var event := InputEventMouseButton.new()
			event.button_index = int(parts[1])
			return event
		_:
			return null
