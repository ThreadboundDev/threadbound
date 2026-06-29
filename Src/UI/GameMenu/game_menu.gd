extends CanvasLayer
class_name GameMenu

const TAB_ORDER: Array[StringName] = [&"Inventory", &"Map", &"Lore", &"Controls"]
const CONTROL_BINDINGS := [
	{"node": "Move", "label": "MOVE", "actions": [&"move_left", &"move_right"]},
	{"node": "Look", "label": "LOOK", "actions": [&"move_up", &"move_down"]},
	{"node": "MoveLeft", "label": "MOVE LEFT", "actions": [&"move_left"], "keyboard_input": "A"},
	{"node": "MoveRight", "label": "MOVE RIGHT", "actions": [&"move_right"], "keyboard_input": "D"},
	{"node": "Interact", "label": "INTERACT", "actions": [&"interact"], "keyboard_input": "E"},
	{"node": "LookUp", "label": "LOOK UP", "actions": [&"move_up"], "keyboard_input": "W HELD"},
	{"node": "LookDown", "label": "LOOK DOWN", "actions": [&"move_down"], "keyboard_input": "S HELD"},
	{"node": "Jump", "label": "JUMP", "actions": [&"Jump"]},
	{"node": "Dash", "label": "DASH", "actions": [&"Dash"]},
	{"node": "Grapple", "label": "GRAPPLE", "actions": [&"Grapple"]},
	{"node": "Attack", "label": "ATTACK", "actions": [&"Attack"], "keyboard_input": "LMB"},
	{"node": "Inventory", "label": "INVENTORY", "actions": [&"open_inventory"]},
	{"node": "Map", "label": "MAP", "actions": [&"open_map"]},
	{"node": "Lore", "label": "LORE", "actions": [&"open_lore"]},
	{"node": "Controls", "label": "CONTROLS", "actions": [&"open_controls"]},
	{"node": "Pause", "label": "PAUSE", "actions": [&"ui_cancel"]},
	{"node": "CycleLeft", "label": "CYCLE LEFT", "actions": [&"menu_tab_left"]},
	{"node": "CycleRight", "label": "CYCLE RIGHT", "actions": [&"menu_tab_right"]},
]
const REBINDABLE_KEYBOARD_NODES := [
	"MoveLeft",
	"MoveRight",
	"Interact",
	"LookUp",
	"LookDown",
	"Jump",
	"Dash",
	"Grapple",
	"Attack",
	"Inventory",
	"Map",
	"Lore",
	"Controls",
	"Pause",
	"CycleLeft",
	"CycleRight",
]
const INVENTORY_CATEGORIES: Array[StringName] = [&"all", &"key_items", &"equipment", &"materials"]
const INVENTORY_ITEMS := [
	{
		"id": &"power",
		"category": &"key_items",
		"name": "THREAD OF POWER",
		"description": "Claimed from the red wing.",
		"icon_texture": "7_thread_power",
		"thread_id": &"power",
	},
	{
		"id": &"balance",
		"category": &"key_items",
		"name": "THREAD OF BALANCE",
		"description": "Claimed from the blue wing.",
		"icon_texture": "8_thread_balance",
		"thread_id": &"balance",
	},
	{
		"id": &"essence",
		"category": &"key_items",
		"name": "THREAD OF ESSENCE",
		"description": "Claimed from the yellow wing.",
		"icon_texture": "9_thread_essence",
		"thread_id": &"essence",
	},
	{
		"id": &"base_gloves",
		"category": &"equipment",
		"name": "BASE GLOVES",
		"description": "Thread wraps and grapple needle. Current demo equipment.",
		"icon_texture": "26_icon_grapple",
	},
	{
		"id": &"weavers_shuttle",
		"category": &"equipment",
		"name": "WEAVER'S SHUTTLE",
		"description": "A simple shuttle weapon for close-range attacks.",
		"icon_texture": "28_icon_shuttle",
	},
	{
		"id": &"base_chest",
		"category": &"equipment",
		"name": "BASE CHEST",
		"description": "The current Threadborne chest wrapping and cloth kit.",
		"icon_texture": "29_icon_chest",
	},
	{
		"id": &"base_boots",
		"category": &"equipment",
		"name": "BASE BOOTS",
		"description": "Standard Threadborne footwork. Current demo equipment.",
		"icon_texture": "27_icon_boots",
	},
]
const EQUIPPED_SLOT_ITEMS := {
	"WeaponSlot": {
		"name": "WEAVER'S SHUTTLE",
		"description": "A simple shuttle weapon for close-range attacks.",
	},
	"GlovesSlot": {
		"name": "BASE GLOVES",
		"description": "Thread wraps and grapple needle. Current demo equipment.",
	},
	"ChestSlot": {
		"name": "BASE CHEST",
		"description": "The current Threadborne chest wrapping and cloth kit.",
	},
	"BootsSlot": {
		"name": "BASE BOOTS",
		"description": "Standard Threadborne footwork. Current demo equipment.",
	},
}

@export var selected_tab_color := Color(1.0, 0.91, 0.72, 1.0)
@export var normal_tab_color := Color(0.70, 0.64, 0.53, 1.0)
@export var hover_tab_color := Color(0.98, 0.82, 0.46, 1.0)
@export var selected_tab_scale := Vector2(1.04, 1.04)
@export var normal_tab_scale := Vector2.ONE
@export var binding_hover_color := Color(0.52, 0.36, 0.12, 0.36)
@export var binding_edit_color := Color(0.82, 0.54, 0.16, 0.54)
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
@onready var inventory_category_tabs: Array[Label] = [
	$MenuRoot/Pages/InventoryPage/InventoryPanel/CategoryTabs/All,
	$MenuRoot/Pages/InventoryPage/InventoryPanel/CategoryTabs/KeyItems,
	$MenuRoot/Pages/InventoryPage/InventoryPanel/CategoryTabs/Equipment,
	$MenuRoot/Pages/InventoryPage/InventoryPanel/CategoryTabs/Materials,
]
@onready var equipment_slots_root: Control = $MenuRoot/Pages/InventoryPage/EquipmentSlots as Control
@onready var inventory_slots_root: Control = $MenuRoot/Pages/InventoryPage/InventorySlots as Control
@onready var inventory_tooltip: Control = $MenuRoot/Pages/InventoryPage/ItemTooltip as Control
@onready var inventory_tooltip_title: Label = $MenuRoot/Pages/InventoryPage/ItemTooltip/Title as Label
@onready var inventory_tooltip_description: Label = $MenuRoot/Pages/InventoryPage/ItemTooltip/Description as Label
@onready var inventory_thread_knot_count: Label = $MenuRoot/Pages/InventoryPage/CurrenciesPanel/ThreadKnots/Count as Label
@onready var inventory_health_label: Label = $MenuRoot/Pages/InventoryPage/IdentityStatsPanel/StatsGrid/Health as Label
@onready var inventory_attack_label: Label = $MenuRoot/Pages/InventoryPage/IdentityStatsPanel/StatsGrid/Attack as Label
@onready var inventory_speed_label: Label = $MenuRoot/Pages/InventoryPage/IdentityStatsPanel/StatsGrid/Speed as Label
@onready var inventory_action_points_label: Label = $MenuRoot/Pages/InventoryPage/IdentityStatsPanel/StatsGrid/ActionPoints as Label
@onready var inventory_action_recharge_label: Label = $MenuRoot/Pages/InventoryPage/IdentityStatsPanel/StatsGrid/ActionRecharge as Label
@onready var inventory_flow_speed_label: Label = $MenuRoot/Pages/InventoryPage/IdentityStatsPanel/StatsGrid/FlowSpeed as Label
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
@onready var keyboard_bindings_root: Control = $MenuRoot/Pages/ControlsPage/ControlsLayout/CalloutLayouts/KeyboardMouse/BindingPanel/Bindings as Control
@onready var rebind_prompt: Control = $MenuRoot/ControlsRebindPrompt as Control
@onready var rebind_prompt_title: Label = $MenuRoot/ControlsRebindPrompt/Panel/Title as Label
@onready var rebind_prompt_body: Label = $MenuRoot/ControlsRebindPrompt/Panel/Body as Label
@onready var rebind_prompt_footer: Label = $MenuRoot/ControlsRebindPrompt/Panel/Footer as Label

var _selected_index := 0
var _closing := false
var _controls_input_family: StringName = &"keyboard_mouse"
var _hovered_tab_index := -1
var _hovered_binding_node := ""
var _rebinding_node := ""
var _rebinding_action: StringName = &""
var _pending_rebind_event: InputEvent = null
var _pending_conflict_action: StringName = &""
var _inventory_category: StringName = &"all"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 108
	add_to_group("game_menu")

	for i in tab_labels.size():
		var tab := tab_labels[i]
		tab.mouse_filter = Control.MOUSE_FILTER_STOP
		tab.pivot_offset = tab.size * 0.5
		tab.gui_input.connect(_on_tab_gui_input.bind(i))
		tab.mouse_entered.connect(_on_tab_mouse_entered.bind(i))
		tab.mouse_exited.connect(_on_tab_mouse_exited.bind(i))
	if not DemoProgress.threads_changed.is_connected(_update_inventory_threads):
		DemoProgress.threads_changed.connect(_update_inventory_threads)
	if not InputBindingManager.bindings_changed.is_connected(_update_control_binding_labels):
		InputBindingManager.bindings_changed.connect(_update_control_binding_labels)
	_setup_keyboard_binding_rows()
	_setup_inventory_ui()
	_hide_rebind_prompt()
	_update_inventory_threads()
	_update_map_tracker()

func _process(_delta: float) -> void:
	if TAB_ORDER[_selected_index] == &"Map":
		_update_map_tracker()

func _input(event: InputEvent) -> void:
	if _rebinding_action == &"":
		return
	_handle_rebind_input(event)
	get_viewport().set_input_as_handled()

func open(initial_tab: StringName = &"Inventory", input_family: StringName = &"keyboard_mouse") -> void:
	get_tree().paused = true
	_set_player_flow_audio_suspended(true)
	_set_controls_input_family(input_family)
	_select_tab(TAB_ORDER.find(initial_tab) if TAB_ORDER.has(initial_tab) else 0, true)

func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	if _rebinding_action != &"":
		get_viewport().set_input_as_handled()
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

func _setup_inventory_ui() -> void:
	for i in inventory_category_tabs.size():
		var tab := inventory_category_tabs[i]
		tab.mouse_filter = Control.MOUSE_FILTER_STOP
		tab.gui_input.connect(_on_inventory_category_gui_input.bind(i))
		tab.mouse_entered.connect(_on_inventory_category_mouse_entered.bind(i))
	if inventory_tooltip:
		inventory_tooltip.visible = false
	if inventory_slots_root:
		for slot in inventory_slots_root.get_children():
			if slot is Control:
				(slot as Control).mouse_filter = Control.MOUSE_FILTER_STOP
				(slot as Control).mouse_entered.connect(_on_inventory_slot_mouse_entered.bind(slot))
				(slot as Control).mouse_exited.connect(_on_inventory_slot_mouse_exited.bind(slot))
				(slot as Control).gui_input.connect(_on_inventory_slot_gui_input.bind(slot))
	if equipment_slots_root:
		for slot in equipment_slots_root.get_children():
			if slot is Control and EQUIPPED_SLOT_ITEMS.has(slot.name):
				slot.set_meta("inventory_item", EQUIPPED_SLOT_ITEMS[slot.name])
				(slot as Control).mouse_filter = Control.MOUSE_FILTER_STOP
				(slot as Control).mouse_entered.connect(_on_inventory_slot_mouse_entered.bind(slot))
				(slot as Control).mouse_exited.connect(_on_inventory_slot_mouse_exited.bind(slot))
				(slot as Control).gui_input.connect(_on_inventory_slot_gui_input.bind(slot))

func _on_inventory_category_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_inventory_category(INVENTORY_CATEGORIES[index])

func _on_inventory_category_mouse_entered(_index: int) -> void:
	AudioManager.play_ui(&"ui_click")

func _select_inventory_category(category: StringName) -> void:
	if not INVENTORY_CATEGORIES.has(category):
		category = &"all"
	_inventory_category = category
	_update_inventory_threads()
	AudioManager.play_ui(&"menu_select")

func _update_inventory_category_tabs() -> void:
	for i in inventory_category_tabs.size():
		var is_selected := INVENTORY_CATEGORIES[i] == _inventory_category
		inventory_category_tabs[i].modulate = selected_tab_color if is_selected else normal_tab_color
		inventory_category_tabs[i].scale = selected_tab_scale if is_selected else normal_tab_scale

func _on_inventory_slot_mouse_entered(slot: Node) -> void:
	var item: Dictionary = slot.get_meta("inventory_item", {})
	if item.is_empty():
		return
	_show_inventory_tooltip(item)

func _on_inventory_slot_mouse_exited(_slot: Node) -> void:
	_hide_inventory_tooltip()

func _on_inventory_slot_gui_input(event: InputEvent, slot: Node) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var item: Dictionary = slot.get_meta("inventory_item", {})
		if not item.is_empty():
			_show_inventory_tooltip(item)

func _show_inventory_tooltip(item: Dictionary) -> void:
	if not inventory_tooltip:
		return
	inventory_tooltip.visible = true
	inventory_tooltip_title.text = String(item.get("name", "ITEM")).to_upper()
	inventory_tooltip_description.text = String(item.get("description", "")).to_upper()

func _hide_inventory_tooltip() -> void:
	if inventory_tooltip:
		inventory_tooltip.visible = false

func _on_tab_mouse_entered(index: int) -> void:
	_hovered_tab_index = index
	_update_tab_visuals()

func _on_tab_mouse_exited(index: int) -> void:
	if _hovered_tab_index == index:
		_hovered_tab_index = -1
	_update_tab_visuals()

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

	_update_tab_visuals()

	if not instant:
		AudioManager.play_ui(&"ui_click")

func _update_tab_visuals() -> void:
	for i in tab_labels.size():
		var is_selected := i == _selected_index
		var is_hovered := i == _hovered_tab_index
		tab_labels[i].modulate = selected_tab_color if is_selected else hover_tab_color if is_hovered else normal_tab_color
		tab_labels[i].scale = selected_tab_scale if is_selected else normal_tab_scale

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
			return "MOUSE AND KEYBOARD"
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

		var action_text := String(binding["label"]).to_upper()
		var input_text := _format_control_binding(binding, _controls_input_family)
		if binding_node.has_method("set"):
			binding_node.set("action_text", action_text)
			binding_node.set("input_text", input_text)

		var action_label := binding_node.find_child("ActionLabel", true, false) as Label
		if action_label:
			action_label.text = action_text
		var input_label := binding_node.find_child("InputLabel", true, false) as Label
		if input_label:
			input_label.text = input_text
	_update_keyboard_binding_highlights()

func _format_control_binding(binding: Dictionary, input_family: StringName) -> String:
	var labels: Array[String] = []
	var actions: Array = binding["actions"]
	for action in actions:
		if not InputMap.has_action(action):
			continue
		for event in InputMap.action_get_events(action):
			var label := _format_input_event(event, input_family)
			if label != "" and not labels.has(label):
				labels.append(label)
	if labels.is_empty():
		return "UNBOUND"
	return " OR ".join(labels).to_upper()

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
			return "SPACEBAR"
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
			var text := OS.get_keycode_string(keycode)
			return text.to_upper() if text != "" else event.as_text().to_upper()

func _format_mouse_button(event: InputEventMouseButton) -> String:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			return "LMB"
		MOUSE_BUTTON_RIGHT:
			return "RMB"
		MOUSE_BUTTON_MIDDLE:
			return "MMB"
		_:
			return "MOUSE %d" % event.button_index

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

func _setup_keyboard_binding_rows() -> void:
	if not keyboard_bindings_root:
		return

	for node_name in REBINDABLE_KEYBOARD_NODES:
		var row := keyboard_bindings_root.get_node_or_null(node_name) as Control
		if not row:
			continue
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		if not row.gui_input.is_connected(_on_keyboard_binding_gui_input):
			row.gui_input.connect(_on_keyboard_binding_gui_input.bind(node_name))
		if not row.mouse_entered.is_connected(_on_keyboard_binding_mouse_entered):
			row.mouse_entered.connect(_on_keyboard_binding_mouse_entered.bind(node_name))
		if not row.mouse_exited.is_connected(_on_keyboard_binding_mouse_exited):
			row.mouse_exited.connect(_on_keyboard_binding_mouse_exited.bind(node_name))

		var highlight := row.get_node_or_null("Highlight") as ColorRect
		if not highlight:
			highlight = ColorRect.new()
			highlight.name = "Highlight"
			highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
			highlight.color = binding_hover_color
			highlight.visible = false
			row.add_child(highlight)
			row.move_child(highlight, 0)
		highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
		highlight.offset_left = -8.0
		highlight.offset_top = -2.0
		highlight.offset_right = 8.0
		highlight.offset_bottom = 2.0

func _on_keyboard_binding_mouse_entered(node_name: String) -> void:
	_hovered_binding_node = node_name
	_update_keyboard_binding_highlights()

func _on_keyboard_binding_mouse_exited(node_name: String) -> void:
	if _hovered_binding_node == node_name:
		_hovered_binding_node = ""
	_update_keyboard_binding_highlights()

func _on_keyboard_binding_gui_input(event: InputEvent, node_name: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var binding := _get_binding_for_node(node_name)
		if binding.is_empty():
			return
		var actions: Array = binding["actions"]
		if actions.is_empty():
			return
		_start_rebind(node_name, actions[0])
		get_viewport().set_input_as_handled()

func _start_rebind(node_name: String, action: StringName) -> void:
	_rebinding_node = node_name
	_rebinding_action = action
	_pending_rebind_event = null
	_pending_conflict_action = &""
	_show_rebind_prompt("PRESS NEW INPUT", "CHOOSE A KEY OR MOUSE BUTTON FOR %s" % _get_binding_label(node_name), "ESC CANCELS")
	_update_keyboard_binding_highlights()
	AudioManager.play_ui(&"menu_select")

func _handle_rebind_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_rebind()
		return
	if _pending_rebind_event and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		InputBindingManager.rebind_keyboard_action(_rebinding_action, _pending_rebind_event, true)
		_finish_rebind()
		return

	if not _is_rebind_event(event):
		return

	var clean_event := event.duplicate()
	var conflict := InputBindingManager.get_keyboard_conflict(clean_event, _rebinding_action)
	if conflict != &"":
		_pending_rebind_event = clean_event
		_pending_conflict_action = conflict
		_show_rebind_prompt(
			"INPUT ALREADY USED",
			"%s IS ASSIGNED TO %s" % [_format_input_event(clean_event, &"keyboard_mouse"), _format_action_name(conflict)],
			"LEFT CLICK TO OVERWRITE OR ESC TO CANCEL"
		)
		AudioManager.play_ui(&"ui_click")
		return

	InputBindingManager.rebind_keyboard_action(_rebinding_action, clean_event, false)
	_finish_rebind()

func _is_rebind_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed
	return false

func _cancel_rebind() -> void:
	_rebinding_node = ""
	_rebinding_action = &""
	_pending_rebind_event = null
	_pending_conflict_action = &""
	_hide_rebind_prompt()
	_update_keyboard_binding_highlights()
	AudioManager.play_ui(&"ui_click")

func _finish_rebind() -> void:
	_rebinding_node = ""
	_rebinding_action = &""
	_pending_rebind_event = null
	_pending_conflict_action = &""
	_hide_rebind_prompt()
	_update_control_binding_labels()
	AudioManager.play_ui(&"menu_select")

func _show_rebind_prompt(title: String, body: String, footer: String) -> void:
	if not rebind_prompt:
		return
	rebind_prompt.visible = true
	rebind_prompt_title.text = title.to_upper()
	rebind_prompt_body.text = body.to_upper()
	rebind_prompt_footer.text = footer.to_upper()

func _hide_rebind_prompt() -> void:
	if rebind_prompt:
		rebind_prompt.visible = false

func _update_keyboard_binding_highlights() -> void:
	if not keyboard_bindings_root:
		return
	for node_name in REBINDABLE_KEYBOARD_NODES:
		var row := keyboard_bindings_root.get_node_or_null(node_name) as Control
		if not row:
			continue
		var highlight := row.get_node_or_null("Highlight") as ColorRect
		if not highlight:
			continue
		var is_active: bool = node_name == _rebinding_node
		var is_hovered: bool = node_name == _hovered_binding_node
		highlight.visible = is_active or is_hovered
		highlight.color = binding_edit_color if is_active else binding_hover_color

func _get_binding_for_node(node_name: String) -> Dictionary:
	for binding in CONTROL_BINDINGS:
		if String(binding["node"]) == node_name:
			return binding
	return {}

func _get_binding_label(node_name: String) -> String:
	var binding := _get_binding_for_node(node_name)
	if binding.is_empty():
		return node_name.to_upper()
	return String(binding["label"]).to_upper()

func _format_action_name(action: StringName) -> String:
	for binding in CONTROL_BINDINGS:
		var actions: Array = binding["actions"]
		if actions.has(action):
			return String(binding["label"]).to_upper()
	return String(action).replace("_", " ").to_upper()

func _update_inventory_threads() -> void:
	_update_inventory_category_tabs()
	_hide_inventory_tooltip()
	if not inventory_slots_root:
		return

	var slot_nodes := inventory_slots_root.get_children()
	for slot in slot_nodes:
		if not slot is Control:
			continue
		slot.remove_meta("inventory_item")
		var frame := slot.get_node_or_null("InventoryFrame") as TextureRect
		if frame:
			frame.modulate = Color(0.45, 0.4, 0.32, 0.44)
		var icon := slot.get_node_or_null("Icon") as TextureRect
		if icon:
			icon.visible = false
		var name_label := slot.get_node_or_null("Name") as Label
		if name_label:
			name_label.visible = false
		var description_label := slot.get_node_or_null("Description") as Label
		if description_label:
			description_label.visible = false

	var visible_items := _get_visible_inventory_items()
	var item_index := 0
	for slot in slot_nodes:
		if item_index >= visible_items.size():
			break
		if not slot is Control:
			continue
		_set_inventory_slot_item(slot as Control, visible_items[item_index])
		item_index += 1
	_update_inventory_stats()

func _get_visible_inventory_items() -> Array[Dictionary]:
	var visible_items: Array[Dictionary] = []
	for item in INVENTORY_ITEMS:
		var category: StringName = item["category"]
		if _inventory_category != &"all" and category != _inventory_category:
			continue
		if item.has("thread_id") and not DemoProgress.has_thread(item["thread_id"]):
			continue
		visible_items.append(item)
	return visible_items

func _set_inventory_slot_item(slot: Control, item: Dictionary) -> void:
	slot.set_meta("inventory_item", item)
	var frame := slot.get_node_or_null("InventoryFrame") as TextureRect
	if frame:
		frame.z_index = 0
		frame.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var icon := slot.get_node_or_null("Icon") as TextureRect
	if not icon:
		icon = TextureRect.new()
		icon.name = "Icon"
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.anchor_right = 1.0
		icon.anchor_bottom = 1.0
		icon.offset_left = 22.0
		icon.offset_top = 20.0
		icon.offset_right = -22.0
		icon.offset_bottom = -20.0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.add_child(icon)
	icon.z_index = 1
	icon.visible = true
	var texture_id := String(item.get("icon_texture", ""))
	if not texture_id.is_empty():
		icon.texture = _get_inventory_icon_texture(texture_id)
	icon.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _get_inventory_icon_texture(texture_id: String) -> Texture2D:
	match texture_id:
		"7_thread_power":
			return preload("res://Assets/chamber_of_first_weave/Threads/thread_of_power.png")
		"8_thread_balance":
			return preload("res://Assets/chamber_of_first_weave/Threads/thread_of_balance.png")
		"9_thread_essence":
			return preload("res://Assets/chamber_of_first_weave/Threads/thread_of_essence.png")
		"26_icon_grapple":
			return preload("res://Assets/UI/Inventory/base_grapple_icon.png")
		"27_icon_boots":
			return preload("res://Assets/UI/Inventory/base_boots_icon.png")
		"28_icon_shuttle":
			return preload("res://Assets/UI/Inventory/weaver_shuttle_icon.png")
		"29_icon_chest":
			return preload("res://Assets/UI/Inventory/base_chest_icon.png")
		_:
			return null

func _update_inventory_stats() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if inventory_thread_knot_count:
		var knot_count := 0
		if player:
			knot_count = int(player.get("thread_knot_count"))
		inventory_thread_knot_count.text = str(knot_count)

	var stats: PlayerStats = null
	if player:
		stats = player.get("player_stats") as PlayerStats
	if inventory_health_label:
		var health: int = 0
		if stats:
			health = stats.max_health
		elif player:
			health = int(player.get("max_health"))
		inventory_health_label.text = "HP %d" % health
	if inventory_attack_label:
		var attack: int = stats.attack_damage if stats else 0
		inventory_attack_label.text = "ATTACK %d" % attack
	if inventory_speed_label:
		var move_speed: int = int(round(float(player.get("speed")))) if player else 0
		inventory_speed_label.text = "SPEED %d" % move_speed
	if inventory_action_points_label:
		var action_points: int = int(player.get("max_action_points")) if player else 0
		inventory_action_points_label.text = "ACTION POINTS %d" % action_points
	if inventory_action_recharge_label:
		var recharge_time: float = float(player.get("action_point_recharge_time")) if player else 0.0
		inventory_action_recharge_label.text = "AP RECHARGE %.1f SEC" % recharge_time
	if inventory_flow_speed_label:
		var flow_speed: float = float(player.get("momentum_move_speed_flow")) if player else 1.0
		inventory_flow_speed_label.text = "FLOW SPEED %d%%" % int(round(flow_speed * 100.0))

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
