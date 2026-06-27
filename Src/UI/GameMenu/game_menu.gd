extends CanvasLayer
class_name GameMenu

const TAB_ORDER: Array[StringName] = [&"Inventory", &"Map", &"Lore", &"Controls"]
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
@onready var controls_device_label: Label = $MenuRoot/Pages/ControlsPage/ControlsLayout/DeviceLabel as Label
@onready var controls_device_art: Dictionary = {
	&"keyboard_mouse": $MenuRoot/Pages/ControlsPage/ControlsLayout/DeviceArt/MouseKeyboard,
	&"xbox": $MenuRoot/Pages/ControlsPage/ControlsLayout/DeviceArt/Xbox,
	&"ps5": $MenuRoot/Pages/ControlsPage/ControlsLayout/DeviceArt/PS5,
	&"nintendo": $MenuRoot/Pages/ControlsPage/ControlsLayout/DeviceArt/Nintendo,
	&"steam": $MenuRoot/Pages/ControlsPage/ControlsLayout/DeviceArt/Steam,
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

	if controls_device_label:
		controls_device_label.text = _get_controls_device_display_name(_controls_input_family)

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
