class_name InputGlyphFormatter
extends RefCounted

const GLYPH_ROOT := "res://Assets/UI/controller/Controller Glyphs and Images/Xelu_Free_Controller&Key_Prompts"
const KEYBOARD_DARK_ROOT := GLYPH_ROOT + "/Keyboard & Mouse/Dark"
const PS5_ROOT := GLYPH_ROOT + "/PS5"
const XBOX_ROOT := GLYPH_ROOT + "/Xbox Series"
const SWITCH_ROOT := GLYPH_ROOT + "/Switch"
const STEAM_ROOT := GLYPH_ROOT + "/Steam Deck"

const KEYBOARD_GLYPHS := {
	"0": "0_Key_Dark.png",
	"1": "1_Key_Dark.png",
	"2": "2_Key_Dark.png",
	"3": "3_Key_Dark.png",
	"4": "4_Key_Dark.png",
	"5": "5_Key_Dark.png",
	"6": "6_Key_Dark.png",
	"7": "7_Key_Dark.png",
	"8": "8_Key_Dark.png",
	"9": "9_Key_Dark.png",
	"A": "A_Key_Dark.png",
	"B": "B_Key_Dark.png",
	"C": "C_Key_Dark.png",
	"D": "D_Key_Dark.png",
	"E": "E_Key_Dark.png",
	"F": "F_Key_Dark.png",
	"G": "G_Key_Dark.png",
	"H": "H_Key_Dark.png",
	"I": "I_Key_Dark.png",
	"J": "J_Key_Dark.png",
	"K": "K_Key_Dark.png",
	"L": "L_Key_Dark.png",
	"M": "M_Key_Dark.png",
	"N": "N_Key_Dark.png",
	"O": "O_Key_Dark.png",
	"P": "P_Key_Dark.png",
	"Q": "Q_Key_Dark.png",
	"R": "R_Key_Dark.png",
	"S": "S_Key_Dark.png",
	"T": "T_Key_Dark.png",
	"U": "U_Key_Dark.png",
	"V": "V_Key_Dark.png",
	"W": "W_Key_Dark.png",
	"X": "X_Key_Dark.png",
	"Y": "Y_Key_Dark.png",
	"Z": "Z_Key_Dark.png",
	"SPACE": "Space_Key_Dark.png",
	"SPACEBAR": "Space_Key_Dark.png",
	"ESC": "Esc_Key_Dark.png",
	"SHIFT": "Shift_Key_Dark.png",
	"TAB": "Tab_Key_Dark.png",
	"ENTER": "Enter_Key_Dark.png",
	"CTRL": "Ctrl_Key_Dark.png",
	"ALT": "Alt_Key_Dark.png",
	"LEFT ARROW": "Arrow_Left_Key_Dark.png",
	"RIGHT ARROW": "Arrow_Right_Key_Dark.png",
	"UP ARROW": "Arrow_Up_Key_Dark.png",
	"DOWN ARROW": "Arrow_Down_Key_Dark.png",
	"LMB": "Mouse_Left_Key_Dark.png",
	"RMB": "Mouse_Right_Key_Dark.png",
	"MMB": "Mouse_Middle_Key_Dark.png",
}

const PS5_BUTTON_GLYPHS := {
	0: "PS5_Cross.png",
	1: "PS5_Circle.png",
	2: "PS5_Square.png",
	3: "PS5_Triangle.png",
	4: "PS5_Share.png",
	6: "PS5_Options.png",
	9: "PS5_L1.png",
	10: "PS5_R1.png",
	11: "PS5_Dpad_Up.png",
	12: "PS5_Dpad_Down.png",
	13: "PS5_Dpad_Left.png",
	14: "PS5_Dpad_Right.png",
}

const XBOX_BUTTON_GLYPHS := {
	0: "XboxSeriesX_A.png",
	1: "XboxSeriesX_B.png",
	2: "XboxSeriesX_X.png",
	3: "XboxSeriesX_Y.png",
	4: "XboxSeriesX_View.png",
	6: "XboxSeriesX_Menu.png",
	9: "XboxSeriesX_LB.png",
	10: "XboxSeriesX_RB.png",
	11: "XboxSeriesX_Dpad_Up.png",
	12: "XboxSeriesX_Dpad_Down.png",
	13: "XboxSeriesX_Dpad_Left.png",
	14: "XboxSeriesX_Dpad_Right.png",
}

const SWITCH_BUTTON_GLYPHS := {
	0: "Switch_B.png",
	1: "Switch_A.png",
	2: "Switch_Y.png",
	3: "Switch_X.png",
	4: "Switch_Minus.png",
	6: "Switch_Plus.png",
	9: "Switch_LB.png",
	10: "Switch_RB.png",
	11: "Switch_Dpad_Up.png",
	12: "Switch_Dpad_Down.png",
	13: "Switch_Dpad_Left.png",
	14: "Switch_Dpad_Right.png",
}

const STEAM_BUTTON_GLYPHS := {
	0: "SteamDeck_A.png",
	1: "SteamDeck_B.png",
	2: "SteamDeck_X.png",
	3: "SteamDeck_Y.png",
	4: "SteamDeck_Minus.png",
	6: "SteamDeck_Menu.png",
	9: "SteamDeck_L1.png",
	10: "SteamDeck_R1.png",
	11: "SteamDeck_Dpad_Up.png",
	12: "SteamDeck_Dpad_Down.png",
	13: "SteamDeck_Dpad_Left.png",
	14: "SteamDeck_Dpad_Right.png",
}

static func get_action_display_bbcode(action: StringName, fallback: String, input_family := &"keyboard_mouse", icon_size := 38) -> String:
	var event := _get_action_event(action, input_family)
	var glyph_path := _get_event_glyph_path(event, input_family)
	if not glyph_path.is_empty():
		return "[img=%dx%d]%s[/img]" % [icon_size, icon_size, glyph_path]

	var text_label := InteractionPromptFormatter.get_action_display(action, fallback)
	return "[%s]" % text_label

static func detect_input_family(event: InputEvent) -> StringName:
	if event is InputEventKey or event is InputEventMouseButton:
		return &"keyboard_mouse"
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return _get_controller_family(event.device)
	return &""

static func _get_action_event(action: StringName, input_family: StringName) -> InputEvent:
	var manager := _get_input_binding_manager()
	if manager:
		if input_family == &"keyboard_mouse" and manager.has_method("get_primary_keyboard_event"):
			var keyboard_event = manager.get_primary_keyboard_event(action)
			if keyboard_event:
				return keyboard_event
		if input_family != &"keyboard_mouse" and manager.has_method("get_primary_controller_event"):
			var controller_event = manager.get_primary_controller_event(action)
			if controller_event:
				return controller_event

	for event in InputMap.action_get_events(action):
		if input_family == &"keyboard_mouse" and (event is InputEventKey or event is InputEventMouseButton):
			return event
		if input_family != &"keyboard_mouse" and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
			return event
	return null

static func _get_input_binding_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root:
		return null
	return tree.root.get_node_or_null("InputBindingManager")

static func _get_event_glyph_path(event: InputEvent, input_family: StringName) -> String:
	if not event:
		return ""
	if event is InputEventKey:
		return _get_keyboard_glyph_path(_format_key_event(event))
	if event is InputEventMouseButton:
		return _get_keyboard_glyph_path(_format_mouse_button(event))
	if event is InputEventJoypadButton:
		return _get_controller_button_glyph_path(event.button_index, input_family)
	if event is InputEventJoypadMotion:
		return _get_controller_axis_glyph_path(event.axis, event.axis_value, input_family)
	return ""

static func _get_keyboard_glyph_path(label: String) -> String:
	var file_name := str(KEYBOARD_GLYPHS.get(label.to_upper(), ""))
	if file_name.is_empty():
		return ""
	var path := "%s/%s" % [KEYBOARD_DARK_ROOT, file_name]
	return path if ResourceLoader.exists(path) else ""

static func _get_controller_button_glyph_path(button_index: int, input_family: StringName) -> String:
	var root := XBOX_ROOT
	var glyphs := XBOX_BUTTON_GLYPHS
	match input_family:
		&"ps5":
			root = PS5_ROOT
			glyphs = PS5_BUTTON_GLYPHS
		&"nintendo":
			root = SWITCH_ROOT
			glyphs = SWITCH_BUTTON_GLYPHS
		&"steam":
			root = STEAM_ROOT
			glyphs = STEAM_BUTTON_GLYPHS
		_:
			root = XBOX_ROOT
			glyphs = XBOX_BUTTON_GLYPHS
	var file_name := str(glyphs.get(button_index, ""))
	if file_name.is_empty():
		return ""
	var path := "%s/%s" % [root, file_name]
	return path if ResourceLoader.exists(path) else ""

static func _get_controller_axis_glyph_path(axis: int, _axis_value: float, input_family: StringName) -> String:
	var root := XBOX_ROOT
	var file_name := "XboxSeriesX_Left_Stick.png"
	match input_family:
		&"ps5":
			root = PS5_ROOT
			file_name = _get_axis_glyph_name(axis, "PS5_Left_Stick.png", "PS5_Right_Stick.png", "PS5_L2.png", "PS5_R2.png")
		&"nintendo":
			root = SWITCH_ROOT
			file_name = _get_axis_glyph_name(axis, "Switch_Left_Stick.png", "Switch_Right_Stick.png", "Switch_LT.png", "Switch_RT.png")
		&"steam":
			root = STEAM_ROOT
			file_name = _get_axis_glyph_name(axis, "SteamDeck_Left_Stick.png", "SteamDeck_Right_Stick.png", "SteamDeck_L2.png", "SteamDeck_R2.png")
		_:
			root = XBOX_ROOT
			file_name = _get_axis_glyph_name(axis, "XboxSeriesX_Left_Stick.png", "XboxSeriesX_Right_Stick.png", "XboxSeriesX_LT.png", "XboxSeriesX_RT.png")
	var path := "%s/%s" % [root, file_name]
	return path if ResourceLoader.exists(path) else ""

static func _get_axis_glyph_name(axis: int, left_stick: String, right_stick: String, left_trigger: String, right_trigger: String) -> String:
	match axis:
		JOY_AXIS_TRIGGER_LEFT:
			return left_trigger
		JOY_AXIS_TRIGGER_RIGHT:
			return right_trigger
		_:
			return left_stick if axis < JOY_AXIS_RIGHT_X else right_stick

static func _format_key_event(event: InputEventKey) -> String:
	var keycode: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	match keycode:
		KEY_SPACE:
			return "SPACE"
		KEY_ESCAPE:
			return "ESC"
		KEY_SHIFT:
			return "SHIFT"
		KEY_LEFT:
			return "LEFT ARROW"
		KEY_RIGHT:
			return "RIGHT ARROW"
		KEY_UP:
			return "UP ARROW"
		KEY_DOWN:
			return "DOWN ARROW"
		_:
			return OS.get_keycode_string(keycode).to_upper()

static func _format_mouse_button(event: InputEventMouseButton) -> String:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			return "LMB"
		MOUSE_BUTTON_RIGHT:
			return "RMB"
		MOUSE_BUTTON_MIDDLE:
			return "MMB"
		_:
			return ""

static func _get_controller_family(device_id: int) -> StringName:
	var joy_name := Input.get_joy_name(device_id).to_lower()
	if joy_name.contains("playstation") or joy_name.contains("dualshock") or joy_name.contains("dualsense") or joy_name.contains("ps5"):
		return &"ps5"
	if joy_name.contains("nintendo") or joy_name.contains("switch"):
		return &"nintendo"
	if joy_name.contains("steam"):
		return &"steam"
	return &"xbox"
