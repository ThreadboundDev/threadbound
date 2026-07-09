extends CanvasLayer

signal closed

const ITEMS := [
	{
		"id": &"small_heal",
		"name": "MENDED PETAL",
		"type": "CONSUMABLE",
		"cost": 2,
		"icon_path": "res://Assets/UI/Merchant/merchant_icon_heal.png",
		"description": "Restore a small amount of health."
	},
	{
		"id": &"ap_refresh",
		"name": "QUICKENED THREAD",
		"type": "CONSUMABLE",
		"cost": 3,
		"icon_path": "res://Assets/UI/Merchant/merchant_icon_ap.png",
		"description": "Restore two action points."
	},
	{
		"id": &"momentum_boost",
		"name": "GILDED MOTION",
		"type": "CONSUMABLE",
		"cost": 3,
		"icon_path": "res://Assets/UI/Merchant/merchant_icon_momentum.png",
		"description": "Gain a burst of momentum."
	},
	{
		"id": &"vitality_thread",
		"name": "VITAL THREAD",
		"type": "ONE TIME",
		"cost": 8,
		"icon_path": "res://Assets/UI/Merchant/merchant_icon_stat_boost.png",
		"description": "Permanently strengthens health once."
	},
]

@export var selected_color := Color(1.0, 0.86, 0.52, 1.0)
@export var normal_color := Color(0.76, 0.67, 0.50, 1.0)
@export var disabled_color := Color(0.38, 0.34, 0.28, 0.78)
@export var selected_scale := Vector2(1.03, 1.03)
@export var normal_scale := Vector2.ONE

@onready var rows_root: VBoxContainer = %Rows as VBoxContainer
@onready var title_label: Label = %TitleLabel as Label
@onready var thread_knot_label: Label = %ThreadKnotLabel as Label
@onready var description_label: Label = %DescriptionLabel as Label
@onready var status_label: Label = %StatusLabel as Label

var _merchant: Node
var _player: Node
var _selected_index := 0
var _rows: Array[Control] = []
var _closing := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 108
	get_tree().paused = true
	_set_player_flow_audio_suspended(true)
	_build_rows()
	_select_index(0, true)
	_refresh_currency()

func set_context(merchant: Node, player: Node) -> void:
	_merchant = merchant
	_player = player
	_refresh_currency()
	_refresh_all_rows()

func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return

	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_select_index(_selected_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_select_index(_selected_index + 1)
		get_viewport().set_input_as_handled()
	elif _is_confirm_event(event):
		_purchase_selected()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("open_menu"):
		close()
		get_viewport().set_input_as_handled()

func close() -> void:
	if _closing:
		return

	_closing = true
	_set_player_flow_audio_suspended(false)
	get_tree().paused = false
	closed.emit()
	queue_free()

func _build_rows() -> void:
	_rows.clear()
	for child in rows_root.get_children():
		child.queue_free()

	for i in ITEMS.size():
		var row := _create_item_row(ITEMS[i])
		rows_root.add_child(row)
		_rows.append(row)
		row.mouse_entered.connect(_select_index.bind(i))
		row.gui_input.connect(_on_row_gui_input.bind(i))

func _create_item_row(item: Dictionary) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(760.0, 108.0)
	row.mouse_filter = Control.MOUSE_FILTER_STOP

	var background := ColorRect.new()
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.05, 0.045, 0.035, 0.82)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(background)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.position = Vector2(18.0, 17.0)
	icon.size = Vector2(74.0, 74.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = load(String(item["icon_path"]))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.position = Vector2(112.0, 12.0)
	name_label.size = Vector2(390.0, 42.0)
	name_label.text = String(item["name"])
	name_label.label_settings = _make_label_settings(28, normal_color, true)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_label)

	var type_label := Label.new()
	type_label.name = "Type"
	type_label.position = Vector2(112.0, 56.0)
	type_label.size = Vector2(260.0, 30.0)
	type_label.text = String(item["type"])
	type_label.label_settings = _make_label_settings(18, Color(0.58, 0.50, 0.36, 1.0), false)
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(type_label)

	var cost_label := Label.new()
	cost_label.name = "Cost"
	cost_label.position = Vector2(560.0, 24.0)
	cost_label.size = Vector2(160.0, 52.0)
	cost_label.text = "%d KNOTS" % int(item["cost"])
	cost_label.label_settings = _make_label_settings(24, normal_color, true)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(cost_label)

	return row

func _make_label_settings(font_size: int, color: Color, use_sc_font: bool) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font = load("res://Assets/UI/Fonts/Almendra_SC/AlmendraSC-Regular.ttf") if use_sc_font else load("res://Assets/UI/Fonts/Almendra/Almendra-Regular.ttf")
	settings.font_size = font_size
	settings.font_color = color
	settings.outline_size = 3
	settings.outline_color = Color(0.02, 0.015, 0.01, 1.0)
	return settings

func _on_row_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_index(index)
		_purchase_selected()

func _select_index(index: int, instant := false) -> void:
	if _rows.is_empty():
		return

	if not instant:
		AudioManager.play_ui(&"ui_click")

	_selected_index = wrapi(index, 0, _rows.size())
	for i in _rows.size():
		_set_row_selected(i, i == _selected_index)
	_refresh_description()

func _set_row_selected(index: int, selected: bool) -> void:
	var row := _rows[index]
	var item: Dictionary = ITEMS[index]
	var sold_out := _is_sold_out(StringName(item["id"]))
	var target_color := selected_color if selected else normal_color
	if sold_out:
		target_color = disabled_color

	var background := row.get_node("Background") as ColorRect
	var name_label := row.get_node("Name") as Label
	var cost_label := row.get_node("Cost") as Label
	row.scale = selected_scale if selected else normal_scale
	background.color = Color(0.12, 0.095, 0.055, 0.90) if selected else Color(0.05, 0.045, 0.035, 0.82)
	name_label.modulate = target_color
	cost_label.modulate = target_color

func _refresh_all_rows() -> void:
	for i in _rows.size():
		_set_row_selected(i, i == _selected_index)
	_refresh_description()

func _refresh_description() -> void:
	if _rows.is_empty() or not description_label:
		return

	var item: Dictionary = ITEMS[_selected_index]
	var id := StringName(item["id"])
	var description := String(item["description"])
	if _is_sold_out(id):
		description += "\nAlready purchased."
	description_label.text = description

func _purchase_selected() -> void:
	if not _merchant or not _player or _rows.is_empty():
		return

	var item: Dictionary = ITEMS[_selected_index]
	var item_id := StringName(item["id"])
	var cost := int(item["cost"])
	var one_time := String(item["type"]) == "ONE TIME"

	if _is_sold_out(item_id):
		_set_status("This thread has already been claimed.")
		return
	if not _can_afford(cost):
		_set_status("Not enough Thread Knots.")
		AudioManager.play_ui(&"ui_click")
		return

	var purchased := false
	if _merchant.has_method("try_purchase"):
		purchased = _merchant.try_purchase(item_id, _player, cost, one_time)

	if purchased:
		AudioManager.play_ui(&"menu_select")
		_set_status("Purchased %s." % String(item["name"]).to_lower())
	else:
		_set_status("The Follower cannot offer this yet.")
	_refresh_currency()
	_refresh_all_rows()

func _can_afford(cost: int) -> bool:
	if not _player:
		return false
	if _player.has_method("can_weave_stat_upgrade"):
		return _player.can_weave_stat_upgrade(cost)
	return int(_player.get("thread_knot_count")) >= cost

func _is_sold_out(item_id: StringName) -> bool:
	return _merchant and _merchant.has_method("has_purchased") and _merchant.has_purchased(item_id)

func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text

func _refresh_currency() -> void:
	if not thread_knot_label:
		return

	var knots := 0
	if _player:
		knots = int(_player.get("thread_knot_count"))
	thread_knot_label.text = str(knots)

func _set_player_flow_audio_suspended(is_suspended: bool) -> void:
	var player := _player if _player else get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_flow_state_audio_suspended"):
		player.set_flow_state_audio_suspended(is_suspended)

func _is_confirm_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_A
	return event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or event.is_action_pressed("Attack")
