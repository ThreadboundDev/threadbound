extends CanvasLayer
class_name GameMenu

const TAB_ORDER: Array[StringName] = [&"Inventory", &"Map", &"Lore", &"Controls"]

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

var _selected_index := 0
var _closing := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 108
	add_to_group("game_menu")

	for i in tab_labels.size():
		var tab := tab_labels[i]
		tab.mouse_filter = Control.MOUSE_FILTER_STOP
		tab.pivot_offset = tab.size * 0.5
		tab.gui_input.connect(_on_tab_gui_input.bind(i))

func open(initial_tab: StringName = &"Inventory") -> void:
	get_tree().paused = true
	_select_tab(TAB_ORDER.find(initial_tab) if TAB_ORDER.has(initial_tab) else 0, true)

func _unhandled_input(event: InputEvent) -> void:
	if _closing:
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

func _select_named_tab(tab_name: StringName) -> void:
	var index := TAB_ORDER.find(tab_name)
	if index >= 0:
		_select_tab(index)

func _select_tab(index: int, instant := false) -> void:
	_selected_index = wrapi(index, 0, TAB_ORDER.size())
	title_label.text = String(TAB_ORDER[_selected_index]).to_upper()

	for i in pages.size():
		pages[i].visible = i == _selected_index

	for i in tab_labels.size():
		var is_selected := i == _selected_index
		tab_labels[i].modulate = selected_tab_color if is_selected else normal_tab_color
		tab_labels[i].scale = selected_tab_scale if is_selected else normal_tab_scale

	if not instant:
		AudioManager.play_ui(&"ui_click")

func _close() -> void:
	if _closing:
		return

	_closing = true
	AudioManager.play_ui(&"menu_select")
	get_tree().paused = false
	queue_free()
