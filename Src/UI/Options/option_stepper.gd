extends Control
class_name OptionStepper

signal focused(stepper: OptionStepper)
signal changed(stepper: OptionStepper, direction: int)
signal selected_index(stepper: OptionStepper, index: int)
signal pressed(stepper: OptionStepper)

@export var label_text := "OPTION"
@export var value_text := "VALUE"
@export_enum("dropdown", "toggle", "button") var mode := "dropdown"
@export var dropdown_texture: Texture2D = preload("res://Assets/UI/Main Menu/settings_dropdown_button.png")
@export var plain_button_texture: Texture2D = preload("res://Assets/UI/Main Menu/settings_dropdown_item_button.png")

@onready var label: Label = $Label as Label
@onready var value_backing: TextureRect = $ValueBacking as TextureRect
@onready var value_label: Label = $Value as Label
@onready var check_box: TextureRect = $CheckBox as TextureRect
@onready var check_mark: TextureRect = $CheckBox/CheckMark as TextureRect
@onready var dropdown: Control = $Dropdown as Control
@onready var dropdown_items: VBoxContainer = $Dropdown/Items as VBoxContainer

var _options: Array[String] = []
var _selected_option_index := 0
var _checked := false
var _dropdown_open := false
var _dropdown_blocker: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_text()
	_refresh_mode()
	_rebuild_dropdown()
	_set_dropdown_open(false)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		focused.emit(self)
		if event.button_index == MOUSE_BUTTON_LEFT:
			_activate_primary()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if mode == "dropdown":
				changed.emit(self, -1)
			accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not has_focus():
		return

	if _dropdown_open and event.is_action_pressed("ui_cancel"):
		_set_dropdown_open(false)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		if mode == "dropdown":
			changed.emit(self, -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right") or event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or event.is_action_pressed("Jump"):
		_activate_primary()
		get_viewport().set_input_as_handled()

func set_selected(is_selected: bool) -> void:
	modulate = Color(1.12, 1.06, 0.9, 1.0) if is_selected else Color.WHITE
	if is_selected:
		grab_focus()

func set_value_text(text: String) -> void:
	value_text = text
	_refresh_text()

func configure_dropdown(values: Array, selected: int = 0) -> void:
	mode = "dropdown"
	_options.clear()
	for value in values:
		_options.append(str(value))
	_selected_option_index = clampi(selected, 0, max(_options.size() - 1, 0))
	if not _options.is_empty():
		value_text = _options[_selected_option_index]
	_refresh_text()
	_refresh_mode()
	_rebuild_dropdown()

func configure_toggle(checked: bool) -> void:
	mode = "toggle"
	_checked = checked
	value_text = "ON" if checked else "OFF"
	_refresh_text()
	_refresh_mode()

func configure_button(text: String) -> void:
	mode = "button"
	value_text = text
	_refresh_text()
	_refresh_mode()

func set_selected_index(index: int) -> void:
	if _options.is_empty():
		return
	_selected_option_index = clampi(index, 0, _options.size() - 1)
	value_text = _options[_selected_option_index]
	_refresh_text()
	_refresh_dropdown_highlight()

func set_toggle_checked(checked: bool) -> void:
	_checked = checked
	value_text = "ON" if checked else "OFF"
	_refresh_text()
	_refresh_mode()

func _refresh_text() -> void:
	if label:
		label.text = label_text
	if value_label:
		value_label.text = value_text

func _activate_primary() -> void:
	match mode:
		"dropdown":
			_set_dropdown_open(not _dropdown_open)
		"toggle":
			changed.emit(self, 1)
		"button":
			pressed.emit(self)
			changed.emit(self, 1)

func _refresh_mode() -> void:
	if not is_node_ready():
		return
	var uses_check := mode == "toggle"
	if value_backing:
		value_backing.visible = true
		value_backing.texture = dropdown_texture if mode == "dropdown" else plain_button_texture
	if value_label:
		value_label.visible = true
	if check_box:
		check_box.visible = uses_check
	if check_mark:
		check_mark.visible = uses_check and _checked

func _set_dropdown_open(is_open: bool) -> void:
	_dropdown_open = is_open and mode == "dropdown" and not _options.is_empty()
	z_index = 200 if _dropdown_open else 0
	if dropdown:
		dropdown.top_level = _dropdown_open
		dropdown.z_index = 201 if _dropdown_open else 50
		dropdown.visible = _dropdown_open
		if _dropdown_open:
			_position_dropdown()
	if _dropdown_open:
		_show_dropdown_blocker()
	else:
		_hide_dropdown_blocker()

func _position_dropdown() -> void:
	if dropdown == null or value_backing == null:
		return
	dropdown.global_position = value_backing.global_position + Vector2(0.0, value_backing.size.y * 0.88)
	dropdown.size = Vector2(value_backing.size.x, maxf(56.0 * float(_options.size()), 56.0))

func _show_dropdown_blocker() -> void:
	if _dropdown_blocker != null and is_instance_valid(_dropdown_blocker):
		return
	_dropdown_blocker = Control.new()
	_dropdown_blocker.name = "DropdownClickBlocker"
	_dropdown_blocker.top_level = true
	_dropdown_blocker.z_index = 199
	_dropdown_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_dropdown_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dropdown_blocker.gui_input.connect(_on_dropdown_blocker_gui_input)
	get_tree().root.add_child(_dropdown_blocker)
	_dropdown_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dropdown_blocker.offset_left = 0.0
	_dropdown_blocker.offset_top = 0.0
	_dropdown_blocker.offset_right = 0.0
	_dropdown_blocker.offset_bottom = 0.0

func _hide_dropdown_blocker() -> void:
	if _dropdown_blocker == null or not is_instance_valid(_dropdown_blocker):
		_dropdown_blocker = null
		return
	_dropdown_blocker.queue_free()
	_dropdown_blocker = null

func _on_dropdown_blocker_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _try_select_dropdown_item_at(get_global_mouse_position()):
			accept_event()
			return
		_set_dropdown_open(false)
		accept_event()

func _try_select_dropdown_item_at(global_mouse_position: Vector2) -> bool:
	if dropdown == null or not dropdown.visible or dropdown_items == null:
		return false

	for i in dropdown_items.get_child_count():
		var item := dropdown_items.get_child(i) as Control
		if item and item.get_global_rect().has_point(global_mouse_position):
			selected_index.emit(self, i)
			_set_dropdown_open(false)
			return true

	# Keep the dropdown open if the click lands inside its panel but between item controls.
	return dropdown.get_global_rect().has_point(global_mouse_position)

func _rebuild_dropdown() -> void:
	if not is_node_ready() or dropdown_items == null:
		return
	for child in dropdown_items.get_children():
		child.queue_free()
	for i in _options.size():
		var option := _create_dropdown_item(_options[i], i)
		dropdown_items.add_child(option)
	_refresh_dropdown_highlight()

func _create_dropdown_item(text: String, index: int) -> Control:
	var item := Control.new()
	item.custom_minimum_size = Vector2(462, 56)
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	item.gui_input.connect(_on_dropdown_item_gui_input.bind(index))
	item.mouse_entered.connect(_on_dropdown_item_mouse_entered.bind(item))
	item.mouse_exited.connect(_on_dropdown_item_mouse_exited.bind(item, index))

	var backing := TextureRect.new()
	backing.name = "Backing"
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.texture = plain_button_texture if plain_button_texture else value_backing.texture if value_backing else null
	backing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backing.stretch_mode = TextureRect.STRETCH_SCALE
	item.add_child(backing)

	var item_label := Label.new()
	item_label.name = "Label"
	item_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	item_label.offset_left = 24.0
	item_label.offset_right = -24.0
	item_label.text = text
	item_label.label_settings = value_label.label_settings if value_label else null
	item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.add_child(item_label)
	return item

func _on_dropdown_item_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_index.emit(self, index)
		_set_dropdown_open(false)
		accept_event()

func _on_dropdown_item_mouse_entered(item: Control) -> void:
	item.modulate = Color(1.16, 1.08, 0.82, 1.0)

func _on_dropdown_item_mouse_exited(item: Control, index: int) -> void:
	item.modulate = Color(1.1, 0.94, 0.62, 1.0) if index == _selected_option_index else Color.WHITE

func _refresh_dropdown_highlight() -> void:
	if not is_node_ready() or dropdown_items == null:
		return
	for i in dropdown_items.get_child_count():
		var item := dropdown_items.get_child(i) as Control
		if item:
			item.modulate = Color(1.1, 0.94, 0.62, 1.0) if i == _selected_option_index else Color.WHITE
