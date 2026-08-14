class_name InteractionPromptFormatter
extends RefCounted

const INTERACT_ACTION := &"interact"
const GLYPH_LABEL_NAME := "InputGlyphContent"

static func format_interact_prompt(action_text: String) -> String:
	return "%s - %s" % [get_action_display(INTERACT_ACTION, "E"), action_text]

static func apply_interact_prompt(label: Label, action_text: String, icon_size := 38) -> void:
	var glyph := InputGlyphFormatter.get_action_display_bbcode(
		INTERACT_ACTION,
		"E",
		get_active_input_family(),
		icon_size
	)
	_apply_glyph_bbcode(label, "[center]%s  %s[/center]" % [glyph, action_text.to_upper()])

static func apply_action_glyph(label: Label, action: StringName, fallback: String, icon_size := 38) -> void:
	var glyph := InputGlyphFormatter.get_action_display_bbcode(
		action,
		fallback,
		get_active_input_family(),
		icon_size
	)
	_apply_glyph_bbcode(label, "[center]%s[/center]" % glyph)

static func apply_action_glyphs(label: Label, actions: Array[StringName], fallback: String, icon_size := 34) -> void:
	var glyphs: Array[String] = []
	for action in actions:
		var glyph := InputGlyphFormatter.get_action_display_bbcode(
			action,
			fallback,
			get_active_input_family(),
			icon_size
		)
		if not glyphs.has(glyph):
			glyphs.append(glyph)
	_apply_glyph_bbcode(label, "[center]%s[/center]" % "  /  ".join(glyphs))

static func get_active_input_family() -> StringName:
	if not _is_controller_active():
		return &"keyboard_mouse"
	return _controller_family()

static func _apply_glyph_bbcode(label: Label, bbcode: String) -> void:
	if not label:
		return
	var content := label.get_node_or_null(GLYPH_LABEL_NAME) as RichTextLabel
	if not content:
		content = RichTextLabel.new()
		content.name = GLYPH_LABEL_NAME
		content.bbcode_enabled = true
		content.fit_content = false
		content.scroll_active = false
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if label.label_settings:
			var settings := label.label_settings
			if settings.font:
				content.add_theme_font_override("normal_font", settings.font)
			content.add_theme_font_size_override("normal_font_size", settings.font_size)
			content.add_theme_color_override("default_color", settings.font_color)
			content.add_theme_constant_override("outline_size", settings.outline_size)
			content.add_theme_color_override("font_outline_color", settings.outline_color)
		label.add_child(content)
	label.text = ""
	content.text = bbcode

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
	var controller_active := _is_controller_active()
	if manager:
		var event = (
			manager.get_primary_controller_event(action)
			if controller_active and manager.has_method("get_primary_controller_event")
			else manager.get_primary_keyboard_event(action)
		)
		var formatted := _format_input_event(event)
		if not formatted.is_empty():
			return formatted

	for event in InputMap.action_get_events(action):
		if controller_active != (event is InputEventJoypadButton or event is InputEventJoypadMotion):
			continue
		var formatted := _format_input_event(event)
		if not formatted.is_empty():
			return formatted
	return fallback

static func _get_input_binding_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root:
		return null
	return tree.root.get_node_or_null("InputBindingManager")

static func _is_controller_active() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root:
		return false
	var tracker := tree.root.get_node_or_null("CustomCursor")
	return tracker != null and tracker.has_method("is_controller_active") and bool(tracker.call("is_controller_active"))

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
	if event is InputEventJoypadButton:
		match event.button_index:
			JOY_BUTTON_A:
				return "X" if _controller_family() == &"ps5" else "A"
			JOY_BUTTON_B:
				return "O" if _controller_family() == &"ps5" else "B"
			JOY_BUTTON_X:
				return "SQUARE" if _controller_family() == &"ps5" else "X"
			JOY_BUTTON_Y:
				return "TRIANGLE" if _controller_family() == &"ps5" else "Y"
			JOY_BUTTON_BACK:
				return "CREATE" if _controller_family() == &"ps5" else "VIEW"
			JOY_BUTTON_START:
				return "OPTIONS" if _controller_family() == &"ps5" else "MENU"
			JOY_BUTTON_LEFT_SHOULDER:
				return "L1" if _controller_family() == &"ps5" else "LB"
			JOY_BUTTON_RIGHT_SHOULDER:
				return "R1" if _controller_family() == &"ps5" else "RB"
	return ""

static func _controller_family() -> StringName:
	for device_id in Input.get_connected_joypads():
		var joy_name := Input.get_joy_name(device_id).to_lower()
		if joy_name.contains("playstation") or joy_name.contains("dualshock") or joy_name.contains("dualsense") or joy_name.contains("ps5"):
			return &"ps5"
	return &"xbox"
