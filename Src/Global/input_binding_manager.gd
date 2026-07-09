extends Node

signal bindings_changed

const SAVE_PATH := "user://controls.cfg"
const KEYBOARD_SECTION := "keyboard_mouse"
const CONTROLLER_SECTION := "controller"

var _keyboard_defaults: Dictionary = {}
var _controller_defaults: Dictionary = {}

func _ready() -> void:
	_capture_defaults()
	load_bindings()

func get_primary_keyboard_event(action: StringName) -> InputEvent:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey or event is InputEventMouseButton:
			return event
	return null

func get_primary_controller_event(action: StringName) -> InputEvent:
	for event in InputMap.action_get_events(action):
		if _is_controller_event(event):
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

func get_controller_conflict(new_event: InputEvent, ignored_actions: Array[StringName] = []) -> StringName:
	for action in InputMap.get_actions():
		var action_name := StringName(action)
		if ignored_actions.has(action_name):
			continue
		for existing_event in InputMap.action_get_events(action_name):
			if _events_match_controller(existing_event, new_event):
				return action_name
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

func rebind_controller_action(action: StringName, new_event: InputEvent, overwrite_conflict := false) -> bool:
	if not InputMap.has_action(action):
		return false
	if not _is_controller_event(new_event):
		return false

	var conflict := get_controller_conflict(new_event, [action])
	if conflict != &"":
		if not overwrite_conflict:
			return false
		_remove_controller_events(conflict)

	_remove_controller_events(action)
	InputMap.action_add_event(action, _normalized_event(new_event))
	save_bindings()
	bindings_changed.emit()
	return true

func rebind_controller_action_group(action_events: Dictionary, overwrite_conflict := false) -> bool:
	var target_actions: Array[StringName] = []
	for action in action_events:
		var action_name := StringName(action)
		if not InputMap.has_action(action_name):
			return false
		var event := action_events[action] as InputEvent
		if not event or not _is_controller_event(event):
			return false
		target_actions.append(action_name)

	var conflicts: Array[StringName] = []
	for action in action_events:
		var event := action_events[action] as InputEvent
		var conflict := get_controller_conflict(event, target_actions)
		if conflict != &"" and not conflicts.has(conflict):
			conflicts.append(conflict)
	if not conflicts.is_empty():
		if not overwrite_conflict:
			return false
		for conflict in conflicts:
			_remove_controller_events(conflict)

	for action in target_actions:
		_remove_controller_events(action)
	for action in action_events:
		InputMap.action_add_event(StringName(action), _normalized_event(action_events[action]))
	save_bindings()
	bindings_changed.emit()
	return true

func load_bindings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return

	if config.has_section(KEYBOARD_SECTION):
		for action in config.get_section_keys(KEYBOARD_SECTION):
			if not InputMap.has_action(action):
				continue
			var encoded := String(config.get_value(KEYBOARD_SECTION, action, ""))
			var event := _decode_event(encoded)
			if event:
				_remove_keyboard_mouse_events(StringName(action))
				InputMap.action_add_event(StringName(action), event)

	if config.has_section(CONTROLLER_SECTION):
		for action in config.get_section_keys(CONTROLLER_SECTION):
			if not InputMap.has_action(action):
				continue
			var encoded := String(config.get_value(CONTROLLER_SECTION, action, ""))
			var event := _decode_event(encoded)
			if event:
				_remove_controller_events(StringName(action))
				InputMap.action_add_event(StringName(action), event)

	bindings_changed.emit()

func save_bindings() -> void:
	var config := ConfigFile.new()
	for action in InputMap.get_actions():
		var event := get_primary_keyboard_event(StringName(action))
		if event:
			config.set_value(KEYBOARD_SECTION, String(action), _encode_event(event))
		var controller_event := get_primary_controller_event(StringName(action))
		if controller_event:
			config.set_value(CONTROLLER_SECTION, String(action), _encode_event(controller_event))
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("InputBindingManager could not save controls: %s." % error_string(error))

func reset_to_defaults() -> void:
	for action in _keyboard_defaults:
		_remove_keyboard_mouse_events(action)
		for event in _keyboard_defaults[action]:
			InputMap.action_add_event(action, event.duplicate())
	for action in _controller_defaults:
		_remove_controller_events(action)
		for event in _controller_defaults[action]:
			InputMap.action_add_event(action, event.duplicate())
	save_bindings()
	bindings_changed.emit()

func _capture_defaults() -> void:
	for action in InputMap.get_actions():
		var keyboard_events: Array[InputEvent] = []
		var controller_events: Array[InputEvent] = []
		for event in InputMap.action_get_events(action):
			if _is_keyboard_mouse_event(event):
				keyboard_events.append(event.duplicate())
			elif _is_controller_event(event):
				controller_events.append(event.duplicate())
		if not keyboard_events.is_empty():
			_keyboard_defaults[StringName(action)] = keyboard_events
		if not controller_events.is_empty():
			_controller_defaults[StringName(action)] = controller_events

func _remove_keyboard_mouse_events(action: StringName) -> void:
	for event in InputMap.action_get_events(action):
		if _is_keyboard_mouse_event(event):
			InputMap.action_erase_event(action, event)

func _remove_controller_events(action: StringName) -> void:
	for event in InputMap.action_get_events(action):
		if _is_controller_event(event):
			InputMap.action_erase_event(action, event)

func _normalized_event(event: InputEvent) -> InputEvent:
	var copy := event.duplicate()
	copy.device = -1
	if copy is InputEventKey:
		copy.pressed = false
		copy.echo = false
	elif copy is InputEventMouseButton:
		copy.pressed = false
	elif copy is InputEventJoypadButton:
		copy.pressed = true
		copy.pressure = 0.0
	return copy

func _is_keyboard_mouse_event(event: InputEvent) -> bool:
	return event is InputEventKey or event is InputEventMouseButton

func _is_controller_event(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion

func _events_match_keyboard_mouse(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var a_code: int = a.physical_keycode if a.physical_keycode != 0 else a.keycode
		var b_code: int = b.physical_keycode if b.physical_keycode != 0 else b.keycode
		return a_code == b_code
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	return false

func _events_match_controller(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and signf(a.axis_value) == signf(b.axis_value)
	return false

func _encode_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		return "key:%d" % code
	if event is InputEventMouseButton:
		return "mouse:%d" % event.button_index
	if event is InputEventJoypadButton:
		return "joy_button:%d" % event.button_index
	if event is InputEventJoypadMotion:
		return "joy_motion:%d:%f" % [event.axis, event.axis_value]
	return ""

func _decode_event(encoded: String) -> InputEvent:
	var parts := encoded.split(":", false)
	if parts.size() < 2:
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
		"joy_button":
			var event := InputEventJoypadButton.new()
			event.button_index = int(parts[1])
			event.pressed = true
			return event
		"joy_motion":
			if parts.size() < 3:
				return null
			var event := InputEventJoypadMotion.new()
			event.axis = int(parts[1])
			event.axis_value = float(parts[2])
			return event
		_:
			return null
