extends CanvasLayer
class_name GameMenu

const TAB_ORDER: Array[StringName] = [&"Inventory", &"Map", &"Lore", &"Controls"]
const CONTROL_BINDINGS := [
	{"node": "Move", "label": "Move", "actions": [&"move_left", &"move_right"]},
	{"node": "Look", "label": "Look", "actions": [&"move_up", &"move_down"]},
	{"node": "Jump", "label": "Jump", "actions": [&"Jump"]},
	{"node": "Dash", "label": "Dash", "actions": [&"Dash"]},
	{"node": "Grapple", "label": "Grapple", "actions": [&"Grapple"]},
	{"node": "Attack", "label": "Attack", "actions": [&"Attack"]},
	{"node": "Inventory", "label": "Inventory", "actions": [&"open_inventory"]},
	{"node": "Map", "label": "Map", "actions": [&"open_map"]},
	{"node": "Lore", "label": "Lore", "actions": [&"open_lore"]},
	{"node": "Controls", "label": "Controls", "actions": [&"open_controls"]},
	{"node": "Pause", "label": "Pause", "actions": [&"ui_cancel"]},
	{"node": "CycleLeft", "label": "Cycle Left", "actions": [&"menu_tab_left"]},
	{"node": "CycleRight", "label": "Cycle Right", "actions": [&"menu_tab_right"]},
]
const INVENTORY_THREADS := [
	{
		"id": &"power",
		"name": "THREAD OF POWER",
		"description": "Claimed from the red wing.",
		"icon": "MenuRoot/Pages/InventoryPage/ThreadSlots/PowerSlot/Icon",
		"label": "MenuRoot/Pages/InventoryPage/ThreadSlots/PowerSlot/Name",
		"description_label": "MenuRoot/Pages/InventoryPage/ThreadSlots/PowerSlot/Description",
	},
	{
		"id": &"balance",
		"name": "THREAD OF BALANCE",
		"description": "Claimed from the blue wing.",
		"icon": "MenuRoot/Pages/InventoryPage/ThreadSlots/BalanceSlot/Icon",
		"label": "MenuRoot/Pages/InventoryPage/ThreadSlots/BalanceSlot/Name",
		"description_label": "MenuRoot/Pages/InventoryPage/ThreadSlots/BalanceSlot/Description",
	},
	{
		"id": &"essence",
		"name": "THREAD OF ESSENCE",
		"description": "Claimed from the yellow wing.",
		"icon": "MenuRoot/Pages/InventoryPage/ThreadSlots/EssenceSlot/Icon",
		"label": "MenuRoot/Pages/InventoryPage/ThreadSlots/EssenceSlot/Name",
		"description_label": "MenuRoot/Pages/InventoryPage/ThreadSlots/EssenceSlot/Description",
	},
]

@export var selected_tab_color := Color(1.0, 0.91, 0.72, 1.0)
@export var normal_tab_color := Color(0.70, 0.64, 0.53, 1.0)
@export var selected_tab_scale := Vector2(1.04, 1.04)
@export var normal_tab_scale := Vector2.ONE
@export_group("Map Tracker")
@export var map_world_bounds := Rect2(-9500.0, -4500.0, 17700.0, 9400.0)
@export var map_tracker_clamp_to_map := true
@export_group("Controls Page")
@export var controller_callout_fallback_family: StringName = &"xbox"

@onready var title_label: Label = $MenuRoot/Title as Label
@onready var tab_labels: Array[Label] = [
	$MenuRoot/Tabs/InventoryTab,
	$MenuRoot/Tabs/MapTab,
	$MenuRoot/Tabs/LoreTab,
	$MenuRoot/Tabs/ControlsTab,
]
@onready var pages: Array[Control] = [
	$MenuRoot/Pages/InventoryPage,
	$MenuRoot/Pages/MapPage,
	$MenuRoot/Pages/LorePage,
	$MenuRoot/Pages/ControlsPage,
]
@onready var inventory_empty_label: Label = $MenuRoot/Pages/InventoryPage/EmptyLabel as Label
@onready var rough_map: TextureRect = $MenuRoot/Pages/MapPage/RoughMap as TextureRect
@onready var map_player_marker: Control = $MenuRoot/Pages/MapPage/RoughMap/PlayerMarker as Control
@onready var controls_device_label: Label = $MenuRoot/Pages/ControlsPage/ControlsLayout/DeviceLabel as Label
@onready var controls_device_art: Dictionary = {
	&"keyboard_mouse": $MenuRoot/Pages/ControlsPage/ControlsLayout/DeviceArt/MouseKeyboard,
	&"xbox": $MenuRoot/Pages/ControlsPage/ControlsLayout/DeviceArt/Xbox,
	&"ps5": $MenuRoot/Pages/ControlsPage/ControlsLayout/DeviceArt/PS5,
	&"nintendo": $MenuRoot/Pages/ControlsPage/ControlsLayout/DeviceArt/Nintendo,
	&"steam": $MenuRoot/Pages/ControlsPage/ControlsLayout/DeviceArt/Steam,
}
@onready var controls_callout_layouts: Dictionary = {
	&"keyboard_mouse": $MenuRoot/Pages/ControlsPage/ControlsLayout/CalloutLayouts/KeyboardMouse,
	&"xbox": $MenuRoot/Pages/ControlsPage/ControlsLayout/CalloutLayouts/Xbox,
	&"ps5": $MenuRoot/Pages/ControlsPage/ControlsLayout/CalloutLayouts/PS5,
	&"nintendo": $MenuRoot/Pages/ControlsPage/ControlsLayout/CalloutLayouts/Nintendo,
	&"steam": $MenuRoot/Pages/ControlsPage/ControlsLayout/CalloutLayouts/Steam,
}

var _selected_index := 0
var _closing := false
var _controls_input_family: StringName = &"keyboard_mouse"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 108
	add_to_group("game_menu")

	for i in tab_labels.size():
		var tab := tab_labels[i]
		tab.mouse_filter = Control.MOUSE_FILTER_STOP
		tab.pivot_offset = tab.size * 0.5
		tab.gui_input.connect(_on_tab_gui_input.bind(i))
	if not DemoProgress.threads_changed.is_connected(_update_inventory_threads):
		DemoProgress.threads_changed.connect(_update_inventory_threads)
	_update_inventory_threads()
	_update_map_tracker()

func _process(_delta: float) -> void:
	if TAB_ORDER[_selected_index] == &"Map":
		_update_map_tracker()

func open(initial_tab: StringName = &"Inventory", input_family: StringName = &"keyboard_mouse") -> void:
	get_tree().paused = true
	_set_player_flow_audio_suspended(true)
	_set_controls_input_family(input_family)
	_select_tab(TAB_ORDER.find(initial_tab) if TAB_ORDER.has(initial_tab) else 0, true)

func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	_update_controls_input_family_from_event(event)

	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_tab_left"):
		_select_tab(_selected_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_tab_right"):
		_select_tab(_selected_index + 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_inventory"):
		_select_named_tab(&"Inventory")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_map"):
		_select_named_tab(&"Map")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_lore"):
		_select_named_tab(&"Lore")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_controls"):
		_select_named_tab(&"Controls")
		get_viewport().set_input_as_handled()

func _on_tab_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_tab(index)

func _select_named_tab(tab_name: StringName) -> void:
	var index := TAB_ORDER.find(tab_name)
	if index >= 0:
		_select_tab(index)

func _select_tab(index: int, instant := false) -> void:
	_selected_index = wrapi(index, 0, TAB_ORDER.size())
	title_label.text = String(TAB_ORDER[_selected_index]).to_upper()
	if TAB_ORDER[_selected_index] == &"Inventory":
		_update_inventory_threads()
	elif TAB_ORDER[_selected_index] == &"Map":
		_update_map_tracker()
	elif TAB_ORDER[_selected_index] == &"Controls":
		_refresh_controls_page()

	for i in pages.size():
		pages[i].visible = i == _selected_index

	for i in tab_labels.size():
		var is_selected := i == _selected_index
		tab_labels[i].modulate = selected_tab_color if is_selected else normal_tab_color
		tab_labels[i].scale = selected_tab_scale if is_selected else normal_tab_scale

	if not instant:
		AudioManager.play_ui(&"ui_click")

func _update_controls_input_family_from_event(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		_set_controls_input_family(&"keyboard_mouse")
	elif event is InputEventJoypadButton and event.pressed:
		_set_controls_input_family(_get_controller_family(event.device))
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.45:
		_set_controls_input_family(_get_controller_family(event.device))

func _set_controls_input_family(input_family: StringName) -> void:
	if not controls_device_art.has(input_family):
		input_family = &"keyboard_mouse"
	_controls_input_family = input_family
	_refresh_controls_page()

func _refresh_controls_page() -> void:
	for family in controls_device_art:
		var art := controls_device_art[family] as CanvasItem
		if art:
			art.visible = family == _controls_input_family

	var active_layout := controls_callout_layouts.get(_controls_input_family) as Control
	var use_fallback_layout := (
		active_layout != null
		and active_layout.get_child_count() == 0
		and _controls_input_family != controller_callout_fallback_family
	)
	for family in controls_callout_layouts:
		var layout := controls_callout_layouts[family] as CanvasItem
		if layout:
			layout.visible = family == _controls_input_family or (use_fallback_layout and family == controller_callout_fallback_family)

	if controls_device_label:
		controls_device_label.text = _get_controls_device_display_name(_controls_input_family)
	_update_control_binding_labels()

func _get_controller_family(device_id: int) -> StringName:
	var joy_name := Input.get_joy_name(device_id).to_lower()
	if joy_name.contains("playstation") or joy_name.contains("ps5") or joy_name.contains("dualsense") or joy_name.contains("dualshock"):
		return &"ps5"
	if joy_name.contains("nintendo") or joy_name.contains("switch") or joy_name.contains("joy-con") or joy_name.contains("pro controller"):
		return &"nintendo"
	if joy_name.contains("steam"):
		return &"steam"
	return &"xbox"

func _get_controls_device_display_name(input_family: StringName) -> String:
	match input_family:
		&"keyboard_mouse":
			return "MOUSE & KEYBOARD"
		&"ps5":
			return "PLAYSTATION"
		&"nintendo":
			return "NINTENDO"
		&"steam":
			return "STEAM"
		_:
	return "XBOX"

func _update_control_binding_labels() -> void:
	var active_layout := controls_callout_layouts.get(_controls_input_family) as Control
	if not active_layout or active_layout.get_child_count() == 0:
		active_layout = controls_callout_layouts.get(controller_callout_fallback_family) as Control
	if not active_layout:
		return

	for binding in CONTROL_BINDINGS:
		var binding_node := active_layout.find_child(String(binding["node"]), true, false)
		if not binding_node:
			continue

		var action_text := String(binding["label"])
		var input_text := _format_control_binding(binding["actions"], _controls_input_family)
		if binding_node.has_method("set"):
			binding_node.set("action_text", action_text)
			binding_node.set("input_text", input_text)

		var action_label := binding_node.find_child("ActionLabel", true, false) as Label
		if action_label:
			action_label.text = action_text
		var input_label := binding_node.find_child("InputLabel", true, false) as Label
		if input_label:
			input_label.text = input_text

func _format_control_binding(actions: Array, input_family: StringName) -> String:
	var labels: Array[String] = []
	for action in actions:
		if not InputMap.has_action(action):
			continue
		for event in InputMap.action_get_events(action):
			var label := _format_input_event(event, input_family)
			if label != "" and not labels.has(label):
				labels.append(label)
	if labels.is_empty():
		return "UNBOUND"
	return " / ".join(labels)

func _format_input_event(event: InputEvent, input_family: StringName) -> String:
	if input_family == &"keyboard_mouse":
		if event is InputEventKey:
			return _format_key_event(event)
		if event is InputEventMouseButton:
			return _format_mouse_button(event)
		return ""

	if event is InputEventJoypadButton:
		return _format_joypad_button(event.button_index, input_family)
	if event is InputEventJoypadMotion:
		return _format_joypad_motion(event.axis, event.axis_value)
	return ""

func _format_key_event(event: InputEventKey) -> String:
	var keycode := event.physical_keycode if event.physical_keycode != 0 else event.keycode
	match keycode:
		KEY_SPACE:
			return "Spacebar"
		KEY_ESCAPE:
			return "Esc"
		KEY_SHIFT:
			return "Shift"
		KEY_LEFT:
			return "Left Arrow"
		KEY_RIGHT:
			return "Right Arrow"
		KEY_UP:
			return "Up Arrow"
		KEY_DOWN:
			return "Down Arrow"
		_:
			var text := OS.get_keycode_string(keycode)
			return text if text != "" else event.as_text()

func _format_mouse_button(event: InputEventMouseButton) -> String:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			return "LMB"
		MOUSE_BUTTON_RIGHT:
			return "RMB"
		MOUSE_BUTTON_MIDDLE:
			return "MMB"
		_:
			return "Mouse %d" % event.button_index

func _format_joypad_button(button_index: int, input_family: StringName) -> String:
	match input_family:
		&"ps5":
			match button_index:
				0: return "Cross"
				1: return "Circle"
				2: return "Square"
				3: return "Triangle"
				9: return "L1"
				10: return "R1"
				11: return "D-Pad Up"
				12: return "D-Pad Down"
				13: return "D-Pad Left"
				14: return "D-Pad Right"
				_: return "Button %d" % button_index
		&"nintendo":
			match button_index:
				0: return "B"
				1: return "A"
				2: return "Y"
				3: return "X"
				9: return "L"
				10: return "R"
				11: return "D-Pad Up"
				12: return "D-Pad Down"
				13: return "D-Pad Left"
				14: return "D-Pad Right"
				_: return "Button %d" % button_index
		_:
			match button_index:
				0: return "A"
				1: return "B"
				2: return "X"
				3: return "Y"
				9: return "LB"
				10: return "RB"
				11: return "D-Pad Up"
				12: return "D-Pad Down"
				13: return "D-Pad Left"
				14: return "D-Pad Right"
				_: return "Button %d" % button_index

func _format_joypad_motion(axis: int, axis_value: float) -> String:
	match axis:
		0:
			return "Left Stick Left" if axis_value < 0.0 else "Left Stick Right"
		1:
			return "Left Stick Up" if axis_value < 0.0 else "Left Stick Down"
		2:
			return "Right Stick Left" if axis_value < 0.0 else "Right Stick Right"
		3:
			return "Right Stick Up" if axis_value < 0.0 else "Right Stick Down"
		_:
			return "Axis %d" % axis

func _update_inventory_threads() -> void:
	var claimed_count := 0
	for thread_data in INVENTORY_THREADS:
		var thread_id: StringName = thread_data["id"]
		var claimed := DemoProgress.has_thread(thread_id)
		if claimed:
			claimed_count += 1

		var icon := get_node_or_null(String(thread_data["icon"])) as TextureRect
		if icon:
			icon.modulate = Color(1.0, 1.0, 1.0, 1.0) if claimed else Color(0.18, 0.18, 0.18, 0.45)

		var label := get_node_or_null(String(thread_data["label"])) as Label
		if label:
			label.text = String(thread_data["name"]) if claimed else "UNKNOWN THREAD"
			label.modulate = Color(1.0, 0.93, 0.72, 1.0) if claimed else Color(0.48, 0.43, 0.34, 0.72)

		var description_label := get_node_or_null(String(thread_data["description_label"])) as Label
		if description_label:
			description_label.text = String(thread_data["description"]) if claimed else "Not yet claimed."
			description_label.modulate = Color(0.86, 0.78, 0.60, 1.0) if claimed else Color(0.44, 0.40, 0.34, 0.68)

	if inventory_empty_label:
		inventory_empty_label.visible = claimed_count == 0

func _update_map_tracker() -> void:
	if not rough_map or not map_player_marker or map_world_bounds.size == Vector2.ZERO:
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		map_player_marker.visible = false
		return

	map_player_marker.visible = true
	var normalized := Vector2(
		(player.global_position.x - map_world_bounds.position.x) / map_world_bounds.size.x,
		(player.global_position.y - map_world_bounds.position.y) / map_world_bounds.size.y
	)
	if map_tracker_clamp_to_map:
		normalized = normalized.clamp(Vector2.ZERO, Vector2.ONE)

	map_player_marker.position = normalized * rough_map.size - map_player_marker.size * 0.5

func _close() -> void:
	if _closing:
		return

	_closing = true
	AudioManager.play_ui(&"menu_select")
	_set_player_flow_audio_suspended(false)
	get_tree().paused = false
	queue_free()

func _set_player_flow_audio_suspended(is_suspended: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_flow_state_audio_suspended"):
		player.set_flow_state_audio_suspended(is_suspended)
