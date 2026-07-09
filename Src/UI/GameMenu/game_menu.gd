extends CanvasLayer
class_name GameMenu

const TAB_ORDER: Array[StringName] = [&"Inventory", &"Map", &"Lore", &"Controls"]
const BINDING_KIND_BUTTON: StringName = &"button"
const BINDING_KIND_MOVE: StringName = &"move"
const BINDING_KIND_AIM: StringName = &"aim"
const CONTROL_BINDINGS := [
	{"node": "Move", "label": "MOVE", "actions": [&"move_left", &"move_right", &"move_up", &"move_down"], "kind": BINDING_KIND_MOVE, "layout_nodes": {&"ps5": "LeftStick"}},
	{"node": "Aim", "label": "AIM", "actions": [&"aim_left", &"aim_right", &"aim_up", &"aim_down"], "kind": BINDING_KIND_AIM, "layout_nodes": {&"ps5": "RightStick", &"xbox": "Look", &"nintendo": "Look", &"steam": "Look"}},
	{"node": "MoveLeft", "label": "MOVE LEFT", "actions": [&"move_left"], "keyboard_input": "A"},
	{"node": "MoveRight", "label": "MOVE RIGHT", "actions": [&"move_right"], "keyboard_input": "D"},
	{"node": "Interact", "label": "INTERACT", "actions": [&"interact"], "keyboard_input": "E"},
	{"node": "LookUp", "label": "LOOK UP", "actions": [&"move_up"], "keyboard_input": "W HELD"},
	{"node": "LookDown", "label": "LOOK DOWN", "actions": [&"move_down"], "keyboard_input": "S HELD"},
	{"node": "Jump", "label": "JUMP", "actions": [&"Jump"], "layout_nodes": {&"ps5": "CrossButton"}},
	{"node": "Dash", "label": "DASH", "actions": [&"Dash"], "layout_nodes": {&"ps5": "CircleButton"}},
	{"node": "Grapple", "label": "GRAPPLE", "actions": [&"Grapple"], "layout_nodes": {&"ps5": "R2Button"}},
	{"node": "Attack", "label": "ATTACK", "actions": [&"Attack"], "keyboard_input": "LMB", "layout_nodes": {&"ps5": "SquareButton"}},
	{"node": "SpecialAttack", "label": "SPECIAL ATTACK", "actions": [&"SpecialAttack"], "keyboard_input": "RMB", "layout_nodes": {&"ps5": "TriangleButton"}},
	{"node": "Inventory", "label": "INVENTORY", "actions": [&"open_inventory"], "layout_nodes": {&"ps5": "DPadUp"}},
	{"node": "Map", "label": "MAP", "actions": [&"open_map"], "layout_nodes": {&"ps5": "DPadLeft"}},
	{"node": "Lore", "label": "LORE", "actions": [&"open_lore"], "layout_nodes": {&"ps5": "DPadDown"}},
	{"node": "Controls", "label": "CONTROLS", "actions": [&"open_controls"], "layout_nodes": {&"ps5": "DPadRight"}},
	{"node": "Pause", "label": "PAUSE", "actions": [&"ui_cancel"], "layout_nodes": {&"ps5": "OptionsButton"}},
	{"node": "CycleLeft", "label": "CYCLE LEFT", "actions": [&"menu_tab_left"], "layout_nodes": {&"ps5": "L1Button"}},
	{"node": "CycleRight", "label": "CYCLE RIGHT", "actions": [&"menu_tab_right"], "layout_nodes": {&"ps5": "R1Button"}},
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
	"SpecialAttack",
	"Inventory",
	"Map",
	"Lore",
	"Controls",
	"Pause",
	"CycleLeft",
	"CycleRight",
]
const REBINDABLE_CONTROLLER_NODES := [
	"Move",
	"Aim",
	"Interact",
	"Jump",
	"Dash",
	"Grapple",
	"Attack",
	"SpecialAttack",
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
		"equip_slot_idx": 0,
	},
	{
		"id": &"hermit_gloves",
		"category": &"equipment",
		"name": "HERMIT GLOVES",
		"description": "A long pendulum grapple built for swing timing and momentum.",
		"icon_texture": "31_icon_blue_gloves",
		"equip_slot_idx": 3,
	},
	{
		"id": &"monarch_gloves",
		"category": &"equipment",
		"name": "MONARCH GLOVES",
		"description": "A charged chain grapple built for aggressive movement.",
		"icon_texture": "30_icon_red_gloves",
		"equip_slot_idx": 6,
	},
	{
		"id": &"sage_gloves",
		"category": &"equipment",
		"name": "SAGE GLOVES",
		"description": "A short snap grapple built for fast repositioning.",
		"icon_texture": "32_icon_yellow_gloves",
		"equip_slot_idx": 9,
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
		"icon_texture": "26_icon_grapple",
		"equip_slot_idx": 0,
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
@export var inventory_tooltip_mouse_offset := Vector2(28.0, 12.0)
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
@onready var inventory_skill_damage_label: Label = $MenuRoot/Pages/InventoryPage/IdentityStatsPanel/StatsGrid/SkillDamage as Label
@onready var inventory_action_recharge_label: Label = $MenuRoot/Pages/InventoryPage/IdentityStatsPanel/StatsGrid/ActionRecharge as Label
@onready var inventory_momentum_gain_label: Label = $MenuRoot/Pages/InventoryPage/IdentityStatsPanel/StatsGrid/MomentumGain as Label
@onready var inventory_resistance_label: Label = $MenuRoot/Pages/InventoryPage/IdentityStatsPanel/StatsGrid/Resistance as Label
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
@onready var keyboard_binding_panel: Control = $MenuRoot/Pages/ControlsPage/ControlsLayout/CalloutLayouts/KeyboardMouse/BindingPanel as Control
@onready var keyboard_bindings_root: Control = $MenuRoot/Pages/ControlsPage/ControlsLayout/CalloutLayouts/KeyboardMouse/BindingPanel/Bindings as Control
@onready var controls_reset_defaults: Label = $MenuRoot/Pages/ControlsPage/ControlsLayout/ResetDefaults as Label
@onready var rebind_prompt: Control = $MenuRoot/ControlsRebindPrompt as Control
@onready var rebind_prompt_title: Label = $MenuRoot/ControlsRebindPrompt/Panel/Title as Label
@onready var rebind_prompt_body: Label = $MenuRoot/ControlsRebindPrompt/Panel/Body as Label
@onready var rebind_prompt_footer: Label = $MenuRoot/ControlsRebindPrompt/Panel/Footer as Label

var _selected_index := 0
var _closing := false
var _controls_input_family: StringName = &"keyboard_mouse"
var _hovered_tab_index := -1
var _hovered_binding_node := ""
var _selected_controller_binding_node := ""
var _rebinding_node := ""
var _rebinding_action: StringName = &""
var _pending_rebind_event: InputEvent = null
var _pending_conflict_action: StringName = &""
var _pending_rebind_group: Dictionary = {}
var _inventory_category: StringName = &"all"
var _controls_only := false

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
	if EquipManager and not EquipManager.equip_changed.is_connected(_on_equip_changed):
		EquipManager.equip_changed.connect(_on_equip_changed)
	if controls_reset_defaults:
		controls_reset_defaults.mouse_filter = Control.MOUSE_FILTER_STOP
		controls_reset_defaults.gui_input.connect(_on_controls_reset_defaults_gui_input)
		controls_reset_defaults.mouse_entered.connect(_on_controls_reset_defaults_mouse_entered)
		controls_reset_defaults.mouse_exited.connect(_on_controls_reset_defaults_mouse_exited)
	_setup_keyboard_binding_rows()
	_setup_inventory_ui()
	_hide_rebind_prompt()
	_update_equipped_slot_items()
	_update_inventory_threads()
	_update_map_tracker()

func _process(_delta: float) -> void:
	if TAB_ORDER[_selected_index] == &"Map":
		_update_map_tracker()
	if inventory_tooltip and inventory_tooltip.visible:
		_position_inventory_tooltip()

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

func open_controls_only(input_family: StringName = &"keyboard_mouse") -> void:
	_controls_only = true
	get_tree().paused = true
	_set_player_flow_audio_suspended(true)
	_set_controls_input_family(input_family)
	_select_tab(TAB_ORDER.find(&"Controls"), true)
	_update_controls_only_visibility()

func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	if _rebinding_action != &"":
		get_viewport().set_input_as_handled()
		return

	_update_controls_input_family_from_event(event)

	if TAB_ORDER[_selected_index] == &"Controls" and _controls_input_family != &"keyboard_mouse":
		if _handle_controller_controls_navigation(event):
			get_viewport().set_input_as_handled()
			return

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
				_set_children_mouse_filter(slot, Control.MOUSE_FILTER_IGNORE)
				(slot as Control).mouse_entered.connect(_on_inventory_slot_mouse_entered.bind(slot))
				(slot as Control).mouse_exited.connect(_on_inventory_slot_mouse_exited.bind(slot))
				(slot as Control).gui_input.connect(_on_inventory_slot_gui_input.bind(slot))
	if equipment_slots_root:
		for slot in equipment_slots_root.get_children():
			if slot is Control and EQUIPPED_SLOT_ITEMS.has(slot.name):
				(slot as Control).mouse_filter = Control.MOUSE_FILTER_STOP
				_set_children_mouse_filter(slot, Control.MOUSE_FILTER_IGNORE)
				(slot as Control).mouse_entered.connect(_on_inventory_slot_mouse_entered.bind(slot))
				(slot as Control).mouse_exited.connect(_on_inventory_slot_mouse_exited.bind(slot))
				(slot as Control).gui_input.connect(_on_inventory_slot_gui_input.bind(slot))

func _on_inventory_category_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_inventory_category(INVENTORY_CATEGORIES[index])

func _on_inventory_category_mouse_entered(_index: int) -> void:
	AudioManager.play_ui(&"ui_click")

func _on_equip_changed(_slot_type: int, _new_equip_index: int) -> void:
	_update_equipped_slot_items()

func _set_children_mouse_filter(node: Node, filter: Control.MouseFilter) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = filter
		_set_children_mouse_filter(child, filter)

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
			_try_equip_inventory_item(item)

func _show_inventory_tooltip(item: Dictionary) -> void:
	if not inventory_tooltip:
		return
	inventory_tooltip.visible = true
	inventory_tooltip_title.text = String(item.get("name", "ITEM")).to_upper()
	inventory_tooltip_description.text = String(item.get("description", "")).to_upper()
	_position_inventory_tooltip()

func _position_inventory_tooltip() -> void:
	if not inventory_tooltip:
		return
	var target_position := inventory_tooltip.get_global_mouse_position() + inventory_tooltip_mouse_offset
	var viewport_rect := get_viewport().get_visible_rect()
	var tooltip_size := inventory_tooltip.size
	target_position.x = minf(target_position.x, viewport_rect.end.x - tooltip_size.x - 8.0)
	target_position.y = minf(target_position.y, viewport_rect.end.y - tooltip_size.y - 8.0)
	target_position.x = maxf(target_position.x, viewport_rect.position.x + 8.0)
	target_position.y = maxf(target_position.y, viewport_rect.position.y + 8.0)
	inventory_tooltip.global_position = target_position

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
	if _controls_only:
		index = TAB_ORDER.find(&"Controls")
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

func _update_controls_only_visibility() -> void:
	if title_label:
		title_label.text = "CONTROLS"
	for i in tab_labels.size():
		tab_labels[i].visible = i == TAB_ORDER.find(&"Controls")

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
	if keyboard_binding_panel:
		keyboard_binding_panel.visible = _controls_input_family == &"keyboard_mouse"

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
	_setup_controller_binding_callouts(active_layout)
	_update_control_binding_labels()
	_update_controls_reset_defaults_visual(false)

func _on_controls_reset_defaults_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		InputBindingManager.reset_to_defaults()
		_update_control_binding_labels()
		AudioManager.play_ui(&"menu_select")
		get_viewport().set_input_as_handled()

func _on_controls_reset_defaults_mouse_entered() -> void:
	_update_controls_reset_defaults_visual(true)
	AudioManager.play_ui(&"ui_click")

func _on_controls_reset_defaults_mouse_exited() -> void:
	_update_controls_reset_defaults_visual(false)

func _update_controls_reset_defaults_visual(is_hovered: bool) -> void:
	if not controls_reset_defaults:
		return
	controls_reset_defaults.modulate = hover_tab_color if is_hovered else normal_tab_color

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

func _get_control_binding_node_name(binding: Dictionary, input_family: StringName) -> String:
	if binding.has("layout_nodes"):
		var layout_nodes := binding["layout_nodes"] as Dictionary
		if layout_nodes.has(input_family):
			return String(layout_nodes[input_family])
	return String(binding["node"])

func _update_control_binding_labels() -> void:
	var active_layout := controls_callout_layouts.get(_controls_input_family) as Control
	if not active_layout or active_layout.get_child_count() == 0:
		active_layout = controls_callout_layouts.get(controller_callout_fallback_family) as Control
	if not active_layout:
		return

	for binding in CONTROL_BINDINGS:
		var binding_node := active_layout.find_child(_get_control_binding_node_name(binding, _controls_input_family), true, false)
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
	_update_controller_binding_highlights()

func _format_control_binding(binding: Dictionary, input_family: StringName) -> String:
	if input_family != &"keyboard_mouse":
		var directional_label := _format_directional_binding(binding, input_family)
		if not directional_label.is_empty():
			return directional_label

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

func _format_directional_binding(binding: Dictionary, input_family: StringName) -> String:
	var kind := _get_binding_kind(binding)
	if kind != BINDING_KIND_MOVE and kind != BINDING_KIND_AIM:
		return ""

	var groups: Array[StringName] = []
	var actions: Array = binding["actions"]
	for action in actions:
		if not InputMap.has_action(action):
			continue
		for event in InputMap.action_get_events(action):
			var group := _get_controller_directional_group(event, kind == BINDING_KIND_MOVE)
			if group != &"" and not groups.has(group):
				groups.append(group)

	if groups.is_empty():
		return ""
	if groups.size() > 1:
		return _format_control_binding_fallback(binding, input_family)

	match groups[0]:
		&"left_stick":
			return "LEFT STICK"
		&"right_stick":
			return "RIGHT STICK"
		&"dpad":
			return "D PAD"
		_:
			return ""

func _format_control_binding_fallback(binding: Dictionary, input_family: StringName) -> String:
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

func _setup_controller_binding_callouts(active_layout: Control) -> void:
	if _controls_input_family == &"keyboard_mouse":
		return
	if not active_layout or active_layout.get_child_count() == 0:
		active_layout = controls_callout_layouts.get(controller_callout_fallback_family) as Control
	if not active_layout:
		return

	for node_name in REBINDABLE_CONTROLLER_NODES:
		var binding := _get_binding_for_node(node_name)
		if binding.is_empty():
			continue
		var binding_node_name := _get_control_binding_node_name(binding, _controls_input_family)
		var callout := active_layout.find_child(binding_node_name, true, false) as Control
		if not callout:
			continue
		var text_box := callout.get_node_or_null("TextBox") as Control
		if not text_box:
			continue
		text_box.mouse_filter = Control.MOUSE_FILTER_STOP
		var gui_callable := _on_controller_binding_gui_input.bind(node_name)
		if not text_box.gui_input.is_connected(gui_callable):
			text_box.gui_input.connect(gui_callable)
		var entered_callable := _on_controller_binding_mouse_entered.bind(node_name)
		if not text_box.mouse_entered.is_connected(entered_callable):
			text_box.mouse_entered.connect(entered_callable)
		var exited_callable := _on_controller_binding_mouse_exited.bind(node_name)
		if not text_box.mouse_exited.is_connected(exited_callable):
			text_box.mouse_exited.connect(exited_callable)
		_ensure_callout_highlight(text_box)

	if _selected_controller_binding_node.is_empty():
		_selected_controller_binding_node = _get_first_controller_binding_node()

func _ensure_callout_highlight(text_box: Control) -> void:
	var highlight := text_box.get_node_or_null("Highlight") as ColorRect
	if not highlight:
		highlight = ColorRect.new()
		highlight.name = "Highlight"
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight.color = binding_hover_color
		highlight.visible = false
		text_box.add_child(highlight)
		text_box.move_child(highlight, 0)
	highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight.offset_left = -6.0
	highlight.offset_top = -4.0
	highlight.offset_right = 6.0
	highlight.offset_bottom = 4.0

func _on_controller_binding_mouse_entered(node_name: String) -> void:
	_hovered_binding_node = node_name
	_selected_controller_binding_node = node_name
	_update_controller_binding_highlights()

func _on_controller_binding_mouse_exited(node_name: String) -> void:
	if _hovered_binding_node == node_name:
		_hovered_binding_node = ""
	_update_controller_binding_highlights()

func _on_controller_binding_gui_input(event: InputEvent, node_name: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_controller_binding_node = node_name
		var binding := _get_binding_for_node(node_name)
		if binding.is_empty():
			return
		var actions: Array = binding["actions"]
		if actions.is_empty():
			return
		_start_rebind(node_name, actions[0])
		get_viewport().set_input_as_handled()

func _handle_controller_controls_navigation(event: InputEvent) -> bool:
	if not _is_controller_navigation_event(event):
		return false

	if event.is_action_pressed("ui_cancel"):
		return false
	if event.is_action_pressed("interact") or event.is_action_pressed("Jump") or event.is_action_pressed("ui_accept"):
		if _selected_controller_binding_node.is_empty():
			_selected_controller_binding_node = _get_first_controller_binding_node()
		var binding := _get_binding_for_node(_selected_controller_binding_node)
		if binding.is_empty():
			return true
		var actions: Array = binding["actions"]
		if actions.is_empty():
			return true
		_start_rebind(_selected_controller_binding_node, actions[0])
		return true

	var direction := Vector2.ZERO
	if event.is_action_pressed("move_up"):
		direction.y = -1.0
	elif event.is_action_pressed("move_down"):
		direction.y = 1.0
	elif event.is_action_pressed("move_left"):
		direction.x = -1.0
	elif event.is_action_pressed("move_right"):
		direction.x = 1.0

	if direction == Vector2.ZERO:
		return false

	_select_controller_binding_in_direction(direction)
	return true

func _is_controller_navigation_event(event: InputEvent) -> bool:
	if event is InputEventJoypadButton and event.pressed:
		return true
	if event is InputEventJoypadMotion and absf(event.axis_value) > 0.55:
		return true
	return false

func _select_controller_binding_in_direction(direction: Vector2) -> void:
	var entries := _get_controller_binding_entries()
	if entries.is_empty():
		return
	if _selected_controller_binding_node.is_empty():
		_selected_controller_binding_node = String(entries[0]["node"])
		_update_controller_binding_highlights()
		return

	var current := {}
	for entry in entries:
		if String(entry["node"]) == _selected_controller_binding_node:
			current = entry
			break
	if current.is_empty():
		_selected_controller_binding_node = String(entries[0]["node"])
		_update_controller_binding_highlights()
		return

	var best := {}
	var best_score := INF
	var current_y := float(current["y"])
	var current_side := int(current["side"])

	for entry in entries:
		if String(entry["node"]) == _selected_controller_binding_node:
			continue
		var side := int(entry["side"])
		var y := float(entry["y"])
		var score := INF
		if direction.y != 0.0 and side == current_side:
			var dy := y - current_y
			if signf(dy) == signf(direction.y):
				score = absf(dy)
		elif direction.x != 0.0 and side != current_side:
			score = absf(y - current_y)
		if score < best_score:
			best_score = score
			best = entry

	if not best.is_empty():
		_selected_controller_binding_node = String(best["node"])
		_update_controller_binding_highlights()
		AudioManager.play_ui(&"ui_click")

func _get_controller_binding_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var layout := _get_active_controller_layout()
	if not layout:
		return entries

	var viewport_center_x := get_viewport().get_visible_rect().size.x * 0.5
	for node_name in REBINDABLE_CONTROLLER_NODES:
		var binding := _get_binding_for_node(node_name)
		if binding.is_empty():
			continue
		var callout := _get_callout_for_binding(layout, binding)
		if not callout:
			continue
		var text_box := callout.get_node_or_null("TextBox") as Control
		if not text_box:
			continue
		var center := text_box.get_global_rect().get_center()
		entries.append({
			"node": node_name,
			"text_box": text_box,
			"side": -1 if center.x < viewport_center_x else 1,
			"y": center.y,
		})
	return entries

func _get_first_controller_binding_node() -> String:
	var entries := _get_controller_binding_entries()
	if entries.is_empty():
		return ""
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["side"]) == int(b["side"]):
			return float(a["y"]) < float(b["y"])
		return int(a["side"]) < int(b["side"])
	)
	return String(entries[0]["node"])

func _get_active_controller_layout() -> Control:
	var active_layout := controls_callout_layouts.get(_controls_input_family) as Control
	if active_layout and active_layout.get_child_count() > 0:
		return active_layout
	return controls_callout_layouts.get(controller_callout_fallback_family) as Control

func _get_callout_for_binding(layout: Control, binding: Dictionary) -> Control:
	if not layout:
		return null
	var binding_node_name := _get_control_binding_node_name(binding, _controls_input_family)
	var callout := layout.find_child(binding_node_name, true, false) as Control
	if callout:
		return callout
	return layout.find_child(String(binding["node"]), true, false) as Control

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
	_pending_rebind_group = {}
	_show_rebind_prompt("PRESS NEW INPUT", _get_rebind_prompt_body(node_name), _get_rebind_prompt_footer(node_name))
	_update_keyboard_binding_highlights()
	_update_controller_binding_highlights()
	AudioManager.play_ui(&"menu_select")

func _handle_rebind_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_rebind()
		return
	if _pending_rebind_event and _is_rebind_confirm_event(event):
		_apply_pending_rebind(true)
		_finish_rebind()
		return

	if not _is_rebind_event(event):
		return

	if _controls_input_family != &"keyboard_mouse":
		_handle_controller_rebind_input(event)
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
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventJoypadMotion:
		return absf(event.axis_value) > 0.55
	return false

func _is_rebind_confirm_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return true
	if _controls_input_family != &"keyboard_mouse":
		return event.is_action_pressed("interact") or event.is_action_pressed("Jump") or event.is_action_pressed("ui_accept")
	return false

func _handle_controller_rebind_input(event: InputEvent) -> void:
	var binding := _get_binding_for_node(_rebinding_node)
	if binding.is_empty():
		return

	var kind := _get_binding_kind(binding)
	if kind == BINDING_KIND_MOVE or kind == BINDING_KIND_AIM:
		var allow_dpad := kind == BINDING_KIND_MOVE
		var group := _get_controller_directional_group(event, allow_dpad)
		if group == &"":
			_show_rebind_prompt("INPUT NOT ALLOWED", _get_rebind_rule_text(kind), "TRY ANOTHER INPUT OR ESC CANCELS")
			AudioManager.play_ui(&"ui_click")
			return
		var action_events := _build_controller_directional_events(kind, group)
		var conflict := _get_controller_group_conflict(action_events)
		if conflict != &"":
			_pending_rebind_event = event.duplicate()
			_pending_rebind_group = action_events
			_pending_conflict_action = conflict
			_show_rebind_prompt(
				"INPUT ALREADY USED",
				"%s IS ASSIGNED TO %s" % [_format_controller_group_name(group), _format_action_name(conflict)],
				"PRESS INTERACT TO OVERWRITE OR ESC TO CANCEL"
			)
			AudioManager.play_ui(&"ui_click")
			return
		InputBindingManager.rebind_controller_action_group(action_events, false)
		_finish_rebind()
		return

	var clean_event := _clean_controller_button_event(event)
	if not clean_event:
		_show_rebind_prompt("INPUT NOT ALLOWED", "CHOOSE A CONTROLLER BUTTON FOR %s" % _get_binding_label(_rebinding_node), "TRY ANOTHER INPUT OR ESC CANCELS")
		AudioManager.play_ui(&"ui_click")
		return

	var conflict := InputBindingManager.get_controller_conflict(clean_event, [_rebinding_action])
	if conflict != &"":
		_pending_rebind_event = clean_event
		_pending_rebind_group = {}
		_pending_conflict_action = conflict
		_show_rebind_prompt(
			"INPUT ALREADY USED",
			"%s IS ASSIGNED TO %s" % [_format_input_event(clean_event, _controls_input_family), _format_action_name(conflict)],
			"PRESS INTERACT TO OVERWRITE OR ESC TO CANCEL"
		)
		AudioManager.play_ui(&"ui_click")
		return

	InputBindingManager.rebind_controller_action(_rebinding_action, clean_event, false)
	_finish_rebind()

func _apply_pending_rebind(overwrite_conflict: bool) -> void:
	if not _pending_rebind_group.is_empty():
		InputBindingManager.rebind_controller_action_group(_pending_rebind_group, overwrite_conflict)
	elif _controls_input_family == &"keyboard_mouse":
		InputBindingManager.rebind_keyboard_action(_rebinding_action, _pending_rebind_event, overwrite_conflict)
	else:
		InputBindingManager.rebind_controller_action(_rebinding_action, _pending_rebind_event, overwrite_conflict)

func _get_rebind_prompt_body(node_name: String) -> String:
	var binding := _get_binding_for_node(node_name)
	var label := _get_binding_label(node_name)
	if _controls_input_family == &"keyboard_mouse":
		return "CHOOSE A KEY OR MOUSE BUTTON FOR %s" % label
	var kind := _get_binding_kind(binding)
	if kind == BINDING_KIND_MOVE or kind == BINDING_KIND_AIM:
		return _get_rebind_rule_text(kind)
	return "CHOOSE A CONTROLLER BUTTON FOR %s" % label

func _get_rebind_prompt_footer(node_name: String) -> String:
	var binding := _get_binding_for_node(node_name)
	var kind := _get_binding_kind(binding)
	if _controls_input_family != &"keyboard_mouse" and (kind == BINDING_KIND_MOVE or kind == BINDING_KIND_AIM):
		return "MOVE SELECTS A SIDE OR DIRECTION SET  ESC CANCELS"
	return "ESC CANCELS"

func _get_rebind_rule_text(kind: StringName) -> String:
	match kind:
		BINDING_KIND_AIM:
			return "AIM MUST USE A CONTROLLER STICK"
		BINDING_KIND_MOVE:
			return "MOVE CAN USE A STICK OR D PAD"
		_:
			return "CHOOSE A VALID INPUT"

func _get_binding_kind(binding: Dictionary) -> StringName:
	if binding.has("kind"):
		return binding["kind"]
	return BINDING_KIND_BUTTON

func _get_controller_directional_group(event: InputEvent, allow_dpad: bool) -> StringName:
	if event is InputEventJoypadMotion and absf(event.axis_value) > 0.55:
		match event.axis:
			0, 1:
				return &"left_stick"
			2, 3:
				return &"right_stick"
	if allow_dpad and event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			11, 12, 13, 14:
				return &"dpad"
	return &""

func _build_controller_directional_events(kind: StringName, group: StringName) -> Dictionary:
	var action_prefix := "move" if kind == BINDING_KIND_MOVE else "aim"
	var action_events := {}
	match group:
		&"left_stick":
			action_events[StringName("%s_left" % action_prefix)] = _make_joy_motion(0, -1.0)
			action_events[StringName("%s_right" % action_prefix)] = _make_joy_motion(0, 1.0)
			action_events[StringName("%s_up" % action_prefix)] = _make_joy_motion(1, -1.0)
			action_events[StringName("%s_down" % action_prefix)] = _make_joy_motion(1, 1.0)
		&"right_stick":
			action_events[StringName("%s_left" % action_prefix)] = _make_joy_motion(2, -1.0)
			action_events[StringName("%s_right" % action_prefix)] = _make_joy_motion(2, 1.0)
			action_events[StringName("%s_up" % action_prefix)] = _make_joy_motion(3, -1.0)
			action_events[StringName("%s_down" % action_prefix)] = _make_joy_motion(3, 1.0)
		&"dpad":
			if kind == BINDING_KIND_MOVE:
				action_events[&"move_up"] = _make_joy_button(11)
				action_events[&"move_down"] = _make_joy_button(12)
				action_events[&"move_left"] = _make_joy_button(13)
				action_events[&"move_right"] = _make_joy_button(14)
	return action_events

func _get_controller_group_conflict(action_events: Dictionary) -> StringName:
	var ignored_actions: Array[StringName] = []
	for action in action_events:
		ignored_actions.append(StringName(action))
	for action in action_events:
		var event := action_events[action] as InputEvent
		var conflict := InputBindingManager.get_controller_conflict(event, ignored_actions)
		if conflict != &"":
			return conflict
	return &""

func _clean_controller_button_event(event: InputEvent) -> InputEvent:
	if event is InputEventJoypadButton and event.pressed:
		return _make_joy_button(event.button_index)
	if event is InputEventJoypadMotion and absf(event.axis_value) > 0.55:
		var axis_event := InputEventJoypadMotion.new()
		axis_event.axis = event.axis
		axis_event.axis_value = signf(event.axis_value)
		return axis_event
	return null

func _make_joy_button(button_index: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	event.pressed = true
	return event

func _make_joy_motion(axis: int, axis_value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	return event

func _format_controller_group_name(group: StringName) -> String:
	match group:
		&"left_stick":
			return "LEFT STICK"
		&"right_stick":
			return "RIGHT STICK"
		&"dpad":
			return "D PAD"
		_:
			return "INPUT"

func _cancel_rebind() -> void:
	_rebinding_node = ""
	_rebinding_action = &""
	_pending_rebind_event = null
	_pending_conflict_action = &""
	_pending_rebind_group = {}
	_hide_rebind_prompt()
	_update_keyboard_binding_highlights()
	_update_controller_binding_highlights()
	AudioManager.play_ui(&"ui_click")

func _finish_rebind() -> void:
	_rebinding_node = ""
	_rebinding_action = &""
	_pending_rebind_event = null
	_pending_conflict_action = &""
	_pending_rebind_group = {}
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

func _update_controller_binding_highlights() -> void:
	var layout := _get_active_controller_layout()
	if not layout:
		return

	for node_name in REBINDABLE_CONTROLLER_NODES:
		var binding := _get_binding_for_node(node_name)
		if binding.is_empty():
			continue
		var callout := _get_callout_for_binding(layout, binding)
		if not callout:
			continue
		var text_box := callout.get_node_or_null("TextBox") as Control
		if not text_box:
			continue
		var highlight := text_box.get_node_or_null("Highlight") as ColorRect
		if not highlight:
			continue
		var is_active: bool = node_name == _rebinding_node or node_name == _selected_controller_binding_node
		var is_hovered: bool = node_name == _hovered_binding_node
		highlight.visible = is_active or is_hovered
		highlight.color = binding_edit_color if node_name == _rebinding_node else binding_hover_color

func _get_binding_for_node(node_name: String) -> Dictionary:
	for binding in CONTROL_BINDINGS:
		if String(binding["node"]) == node_name:
			return binding
		if binding.has("layout_nodes"):
			var layout_nodes := binding["layout_nodes"] as Dictionary
			for layout_family in layout_nodes:
				if String(layout_nodes[layout_family]) == node_name:
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
		"30_icon_red_gloves":
			return preload("res://Assets/Threadborne/Equipment/Red Gear/red_glove_icon.png")
		"31_icon_blue_gloves":
			return preload("res://Assets/Threadborne/Equipment/Blue Gear/blue_glove_icon.png")
		"32_icon_yellow_gloves":
			return preload("res://Assets/Threadborne/Equipment/Yellow Gear/yellow_glove_icon.png")
		_:
			return null

func _try_equip_inventory_item(item: Dictionary) -> void:
	if not item.has("equip_slot_idx"):
		return
	var slot_idx := int(item["equip_slot_idx"])
	if not [0, 3, 6, 9].has(slot_idx):
		return
	if EquipManager:
		AudioManager.play_ui(&"menu_select")
		EquipManager.equip_item(slot_idx)
		_update_equipped_slot_items()

func _update_equipped_slot_items() -> void:
	if not equipment_slots_root or not EquipManager:
		return

	_apply_equipped_slot_item("GlovesSlot", _get_equipped_gloves_item())
	_apply_equipped_slot_item("BootsSlot", _get_equipped_static_item("BASE BOOTS", "Standard Threadborne footwork. Current demo equipment.", "27_icon_boots", -1))
	_apply_equipped_slot_item("ChestSlot", _get_equipped_static_item("BASE CHEST", "The current Threadborne chest wrapping and cloth kit.", "29_icon_chest", -1))
	_apply_equipped_slot_item("WeaponSlot", _get_equipped_static_item("WEAVER'S SHUTTLE", "A simple shuttle weapon for close-range attacks.", "28_icon_shuttle", -1))

func _apply_equipped_slot_item(slot_name: String, item: Dictionary) -> void:
	var slot := equipment_slots_root.get_node_or_null(slot_name) as Control
	if not slot:
		return

	slot.set_meta("inventory_item", item)
	var icon := slot.get_node_or_null("Icon") as TextureRect
	if icon:
		icon.texture = _get_inventory_icon_texture(String(item.get("icon_texture", "")))
	var value_label := slot.get_node_or_null("Value") as Label
	if value_label:
		value_label.text = String(item.get("name", ""))

func _get_equipped_gloves_item() -> Dictionary:
	var glove_idx := int(EquipManager.current_equip[0])
	if glove_idx == 3:
		return {
			"name": "HERMIT GLOVES",
			"description": "A long pendulum grapple built for swing timing and momentum.",
			"icon_texture": "31_icon_blue_gloves",
			"equip_slot_idx": 3,
		}
	if glove_idx == 6:
		return {
			"name": "MONARCH GLOVES",
			"description": "A charged chain grapple built for aggressive movement.",
			"icon_texture": "30_icon_red_gloves",
			"equip_slot_idx": 6,
		}
	if glove_idx == 9:
		return {
			"name": "SAGE GLOVES",
			"description": "A short snap grapple built for fast repositioning.",
			"icon_texture": "32_icon_yellow_gloves",
			"equip_slot_idx": 9,
		}
	return {
		"name": "BASE GLOVES",
		"description": "Thread wraps and grapple needle. Current demo equipment.",
		"icon_texture": "26_icon_grapple",
		"equip_slot_idx": 0,
	}

func _get_equipped_static_item(item_name: String, description: String, icon_texture: String, equip_slot_idx: int) -> Dictionary:
	var item := {
		"name": item_name,
		"description": description,
		"icon_texture": icon_texture,
	}
	if equip_slot_idx >= 0:
		item["equip_slot_idx"] = equip_slot_idx
	return item

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
		inventory_attack_label.text = "ATTACK DAMAGE - %d" % attack
	if inventory_skill_damage_label:
		var skill_damage_percent := roundi((stats.skill_damage_multiplier if stats else 1.0) * 100.0)
		inventory_skill_damage_label.text = "SKILL DAMAGE - %d%%" % skill_damage_percent
	if inventory_action_recharge_label:
		var recharge_multiplier := stats.action_point_recharge_multiplier if stats else 1.0
		var recharge_percent := roundi(recharge_multiplier * 100.0)
		inventory_action_recharge_label.text = "AP RECHARGE - %d%%" % recharge_percent
	if inventory_momentum_gain_label:
		var momentum_gain_percent := roundi((stats.momentum_generation_multiplier if stats else 1.0) * 100.0)
		inventory_momentum_gain_label.text = "MOMENTUM GAIN - %d%%" % momentum_gain_percent
	if inventory_resistance_label:
		var resistance_percent := roundi(stats.get_resistance_mitigation() * 100.0) if stats else 0
		inventory_resistance_label.text = "RESISTANCE - %d%%" % resistance_percent

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
