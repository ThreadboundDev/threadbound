class_name InteractionPromptFormatter
extends RefCounted

const INTERACT_ACTION := &"interact"

static func format_interact_prompt(action_text: String) -> String:
	return "%s - %s" % [get_action_display(INTERACT_ACTION, "E"), action_text]

static func prompt_action_from_text(prompt_text: String, fallback: String) -> String:
	var text := prompt_text.strip_edges()
	var separator_index := text.find(" - ")
	if separator_index >= 0:
		var action_text := text.substr(separator_index + 3).strip_edges()
		if not action_text.is_empty():
			return action_text
	if text.to_lower() in ["w", "up", "e", "interact"]:
		return fallback
	return text if not text.is_empty() else fallback

static func get_action_display(action: StringName, fallback: String) -> String:
	var manager := _get_input_binding_manager()
	if manager and manager.has_method("get_primary_keyboard_event"):
		var event = manager.get_primary_keyboard_event(action)
		var formatted := _format_input_event(event)
		if not formatted.is_empty():
			return formatted

	for event in InputMap.action_get_events(action):
		var formatted := _format_input_event(event)
		if not formatted.is_empty():
			return formatted
	return fallback

static func _get_input_binding_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root:
		return null
	return tree.root.get_node_or_null("InputBindingManager")

static func _format_input_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var code: int = key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
		if code == KEY_ESCAPE:
			return "ESC"
		if code == KEY_SPACE:
			return "SPACE"
		return OS.get_keycode_string(code).to_upper()
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		match mouse_event.button_index:
			MOUSE_BUTTON_LEFT:
				return "LMB"
			MOUSE_BUTTON_RIGHT:
				return "RMB"
			MOUSE_BUTTON_MIDDLE:
				return "MMB"
	return ""
