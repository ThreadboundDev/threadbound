extends CanvasLayer

signal closed

enum Screen {
	HUB,
	TALK,
	SHOP,
	FAREWELL,
}

const PAUSE_OPEN_BLOCK_UNTIL_META := &"pause_open_block_until_msec"
const PAUSE_OPEN_BLOCK_MSEC := 180
const HUB_CHOICES := ["TALK", "BUY", "LEAVE"]
const ITEMS := [
	{
		"id": &"small_heal",
		"name": "MENDED PETAL",
		"type": "MENDING SERVICE",
		"cost": 2,
		"icon_path": "res://Assets/UI/Merchant/merchant_icon_heal.png",
		"description": "Restore up to 35 health immediately."
	},
	{
		"id": &"vitality_thread",
		"name": "VITAL THREAD",
		"type": "ONE TIME",
		"cost": 8,
		"icon_path": "res://Assets/UI/Merchant/merchant_icon_stat_boost.png",
		"description": "Permanently strengthens health once."
	},
	{
		"id": &"merchant_knot_pattern",
		"name": "FOLLOWER'S KNOT",
		"type": "PATTERN",
		"cost": 12,
		"icon_path": "res://Assets/UI/Hud/V2/pattern_demo_overlay_v2.png",
		"description": "A balanced woven Pattern: +10% AP recharge and +10% momentum generation."
	},
	{
		"id": &"lore_eryndor",
		"name": "THE UNFINISHED REALM",
		"type": "LORE",
		"cost": 2,
		"icon_path": "",
		"description": "A Follower's account of Eryndor. Adds a permanent entry to Lore."
	},
	{
		"id": &"lore_threadling",
		"name": "FIELD NOTE: THREADLING",
		"type": "LORE",
		"cost": 3,
		"icon_path": "",
		"description": "The Follower's observations on Threadlings. Adds a permanent entry to Lore."
	},
	{
		"id": &"lore_tensioner",
		"name": "FIELD NOTE: TENSIONER",
		"type": "LORE",
		"cost": 4,
		"icon_path": "",
		"description": "The Follower's observations on Tensioners. Adds a permanent entry to Lore."
	},
	{
		"id": &"lore_loomkin",
		"name": "FIELD NOTE: LOOMKIN",
		"type": "LORE",
		"cost": 4,
		"icon_path": "",
		"description": "The Follower's observations on Loomkin. Adds a permanent entry to Lore."
	},
]

@export var selected_color := Color(1.0, 0.86, 0.52, 1.0)
@export var normal_color := Color(0.76, 0.67, 0.50, 1.0)
@export var disabled_color := Color(0.38, 0.34, 0.28, 0.78)

@onready var dim: ColorRect = $Dim as ColorRect
@onready var background: TextureRect = $Root/Background as TextureRect
@onready var title_label: Label = %TitleLabel as Label
@onready var currency_panel: Control = %CurrencyPanel as Control
@onready var thread_knot_label: Label = %ThreadKnotLabel as Label
@onready var dialogue_panel: Control = %DialoguePanel as Control
@onready var dialogue_label: Label = %DialogueLabel as Label
@onready var choices_root: VBoxContainer = %Choices as VBoxContainer
@onready var shop_panel: Control = %ShopPanel as Control
@onready var rows_root: VBoxContainer = %Rows as VBoxContainer
@onready var description_label: Label = %DescriptionLabel as Label
@onready var status_label: Label = %StatusLabel as Label
@onready var footer_label: RichTextLabel = %FooterLabel as RichTextLabel

var _merchant: Node
var _player: Node
var _screen := Screen.HUB
var _hub_index := 0
var _shop_index := 0
var _choice_rows: Array[Control] = []
var _shop_rows: Array[Control] = []
var _closing := false
var _input_family: StringName = &"keyboard_mouse"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 108
	add_to_group("merchant_menu")
	get_tree().paused = true
	_set_player_flow_audio_suspended(true)
	_build_hub_choices()
	_build_shop_rows()
	_connect_binding_updates()
	_show_hub()

func set_context(merchant: Node, player: Node) -> void:
	_merchant = merchant
	_player = player
	_refresh_currency()
	_refresh_shop_rows()
	_show_hub()

func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return

	var detected_family := InputGlyphFormatter.detect_input_family(event)
	if not String(detected_family).is_empty() and detected_family != _input_family:
		_input_family = detected_family
		_refresh_footer()

	match _screen:
		Screen.HUB:
			_handle_hub_input(event)
		Screen.TALK:
			_handle_talk_input(event)
		Screen.SHOP:
			_handle_shop_input(event)
		Screen.FAREWELL:
			if _is_confirm_event(event) or _is_cancel_event(event):
				close()
				get_viewport().set_input_as_handled()

func close() -> void:
	if _closing:
		return
	_closing = true
	_set_player_flow_audio_suspended(false)
	get_tree().set_meta(PAUSE_OPEN_BLOCK_UNTIL_META, Time.get_ticks_msec() + PAUSE_OPEN_BLOCK_MSEC)
	get_tree().paused = false
	closed.emit()
	queue_free()

func _handle_hub_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_select_hub(_hub_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_select_hub(_hub_index + 1)
		get_viewport().set_input_as_handled()
	elif _is_confirm_event(event):
		_activate_hub_choice(_hub_index)
		get_viewport().set_input_as_handled()
	elif _is_cancel_event(event):
		_show_farewell()
		get_viewport().set_input_as_handled()

func _handle_talk_input(event: InputEvent) -> void:
	if _is_confirm_event(event) or _is_cancel_event(event):
		_show_hub()
		get_viewport().set_input_as_handled()

func _handle_shop_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_select_shop(_shop_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_select_shop(_shop_index + 1)
		get_viewport().set_input_as_handled()
	elif _is_confirm_event(event):
		_purchase_selected()
		get_viewport().set_input_as_handled()
	elif _is_cancel_event(event):
		_show_hub()
		get_viewport().set_input_as_handled()

func _show_hub() -> void:
	_screen = Screen.HUB
	_set_full_screen_presentation(false, true)
	title_label.text = "THE FOLLOWER"
	dialogue_panel.visible = true
	choices_root.visible = true
	shop_panel.visible = false
	currency_panel.visible = false
	status_label.text = ""
	dialogue_label.text = _merchant.get_opening_line() if _merchant and _merchant.has_method("get_opening_line") else "A curious place to meet."
	_select_hub(_hub_index, true)
	_refresh_footer()

func _show_talk() -> void:
	_screen = Screen.TALK
	_set_full_screen_presentation(false)
	title_label.text = "THE FOLLOWER"
	dialogue_panel.visible = true
	choices_root.visible = false
	shop_panel.visible = false
	currency_panel.visible = false
	status_label.text = ""
	dialogue_label.text = _merchant.get_next_dialogue_line() if _merchant and _merchant.has_method("get_next_dialogue_line") else "..."
	_refresh_footer()

func _show_shop() -> void:
	_screen = Screen.SHOP
	_set_full_screen_presentation(true)
	title_label.text = "FOLLOWER'S WARES"
	dialogue_panel.visible = false
	choices_root.visible = false
	shop_panel.visible = true
	currency_panel.visible = true
	status_label.text = ""
	_refresh_currency()
	_select_shop(_shop_index, true)
	_refresh_footer()

func _show_farewell() -> void:
	_screen = Screen.FAREWELL
	_set_full_screen_presentation(false)
	title_label.text = "THE FOLLOWER"
	dialogue_panel.visible = true
	choices_root.visible = false
	shop_panel.visible = false
	currency_panel.visible = false
	status_label.text = ""
	dialogue_label.text = _merchant.get_farewell_line() if _merchant and _merchant.has_method("get_farewell_line") else "Until next time."
	_refresh_footer()

func _set_full_screen_presentation(is_full_screen: bool, show_choices := false) -> void:
	dim.color = Color(0, 0, 0, 0.62) if is_full_screen else Color(0, 0, 0, 0.18)
	background.visible = is_full_screen
	title_label.visible = is_full_screen
	status_label.visible = is_full_screen

	if is_full_screen:
		dialogue_panel.position = Vector2.ZERO
		dialogue_panel.set_anchors_preset(Control.PRESET_CENTER)
		dialogue_panel.offset_left = -420.0
		dialogue_panel.offset_top = -222.0
		dialogue_panel.offset_right = 420.0
		dialogue_panel.offset_bottom = 62.0
		footer_label.offset_top = 326.0
		footer_label.offset_bottom = 384.0
		return

	# Conversation remains grounded in the room: a restrained lower-third keeps
	# both characters visible while leaving enough space for the opening choices.
	dialogue_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_panel.offset_left = -700.0
	dialogue_panel.offset_top = -330.0
	dialogue_panel.offset_right = 700.0 if not show_choices else 140.0
	dialogue_panel.offset_bottom = -42.0
	choices_root.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	choices_root.offset_left = 160.0
	choices_root.offset_top = -290.0
	choices_root.offset_right = 680.0
	choices_root.offset_bottom = -70.0
	footer_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	footer_label.offset_left = -410.0
	footer_label.offset_top = -58.0
	footer_label.offset_right = 410.0
	footer_label.offset_bottom = -10.0

func _build_hub_choices() -> void:
	_choice_rows.clear()
	for child in choices_root.get_children():
		child.queue_free()
	for index in HUB_CHOICES.size():
		var row := _create_choice_row(HUB_CHOICES[index])
		choices_root.add_child(row)
		_choice_rows.append(row)
		row.mouse_entered.connect(_select_hub.bind(index))
		row.gui_input.connect(_on_choice_gui_input.bind(index))

func _create_choice_row(text: String) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(520.0, 62.0)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	var background := ColorRect.new()
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.05, 0.045, 0.035, 0.82)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(background)
	var label := Label.new()
	label.name = "Label"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	label.text = text
	label.label_settings = _make_label_settings(26, normal_color, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return row

func _select_hub(index: int, instant := false) -> void:
	if _choice_rows.is_empty():
		return
	if not instant:
		AudioManager.play_ui(&"ui_click")
	_hub_index = wrapi(index, 0, _choice_rows.size())
	for i in _choice_rows.size():
		var selected := i == _hub_index
		var row := _choice_rows[i]
		(row.get_node("Background") as ColorRect).color = Color(0.12, 0.095, 0.055, 0.92) if selected else Color(0.05, 0.045, 0.035, 0.82)
		(row.get_node("Label") as Label).modulate = selected_color if selected else normal_color

func _activate_hub_choice(index: int) -> void:
	AudioManager.play_ui(&"menu_select")
	match index:
		0:
			_show_talk()
		1:
			_show_shop()
		_:
			_show_farewell()

func _on_choice_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_hub(index, true)
		_activate_hub_choice(index)

func _build_shop_rows() -> void:
	_shop_rows.clear()
	for child in rows_root.get_children():
		child.queue_free()
	for index in ITEMS.size():
		var row := _create_item_row(ITEMS[index])
		rows_root.add_child(row)
		_shop_rows.append(row)
		row.mouse_entered.connect(_select_shop.bind(index))
		row.gui_input.connect(_on_shop_row_gui_input.bind(index))

func _create_item_row(item: Dictionary) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(820.0, 62.0)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	var background := ColorRect.new()
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.05, 0.045, 0.035, 0.82)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(background)
	var icon_path := String(item["icon_path"])
	if icon_path.is_empty():
		var page_icon := Label.new()
		page_icon.name = "Icon"
		page_icon.position = Vector2(16.0, 5.0)
		page_icon.size = Vector2(52.0, 52.0)
		page_icon.text = "▤"
		page_icon.label_settings = _make_label_settings(34, normal_color, true)
		page_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		page_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		page_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(page_icon)
	else:
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.position = Vector2(16.0, 5.0)
		icon.size = Vector2(52.0, 52.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = load(icon_path)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
	var name_label := Label.new()
	name_label.name = "Name"
	name_label.position = Vector2(84.0, 2.0)
	name_label.size = Vector2(480.0, 32.0)
	name_label.text = String(item["name"])
	name_label.label_settings = _make_label_settings(22, normal_color, true)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_label)
	var type_label := Label.new()
	type_label.name = "Type"
	type_label.position = Vector2(84.0, 34.0)
	type_label.size = Vector2(400.0, 24.0)
	type_label.text = String(item["type"])
	type_label.label_settings = _make_label_settings(14, Color(0.58, 0.50, 0.36, 1.0), false)
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(type_label)
	var cost_label := Label.new()
	cost_label.name = "Cost"
	cost_label.position = Vector2(610.0, 6.0)
	cost_label.size = Vector2(174.0, 50.0)
	cost_label.text = "%d KNOTS" % int(item["cost"])
	cost_label.label_settings = _make_label_settings(22, normal_color, true)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(cost_label)
	return row

func _select_shop(index: int, instant := false) -> void:
	if _shop_rows.is_empty():
		return
	if not instant:
		AudioManager.play_ui(&"ui_click")
	_shop_index = wrapi(index, 0, _shop_rows.size())
	_refresh_shop_rows()

func _refresh_shop_rows() -> void:
	for i in _shop_rows.size():
		var row := _shop_rows[i]
		var item: Dictionary = ITEMS[i]
		var unavailable := _is_sold_out(StringName(item["id"])) or not _merchant_allows_item(StringName(item["id"]))
		var selected := i == _shop_index
		var color := disabled_color if unavailable else (selected_color if selected else normal_color)
		(row.get_node("Background") as ColorRect).color = Color(0.12, 0.095, 0.055, 0.92) if selected else Color(0.05, 0.045, 0.035, 0.82)
		(row.get_node("Name") as Label).modulate = color
		(row.get_node("Cost") as Label).modulate = color
	_refresh_description()

func _refresh_description() -> void:
	if _shop_rows.is_empty():
		return
	var item: Dictionary = ITEMS[_shop_index]
	var item_id := StringName(item["id"])
	var description := String(item["description"])
	if _is_sold_out(item_id):
		description += "\nAlready purchased."
	elif not _merchant_allows_item(item_id):
		description += "\n%s" % _purchase_block_reason(item_id)
	description_label.text = description

func _purchase_selected() -> void:
	if not _merchant or not _player or _shop_rows.is_empty():
		return
	var item: Dictionary = ITEMS[_shop_index]
	var item_id := StringName(item["id"])
	var cost := int(item["cost"])
	var one_time := String(item["type"]) in ["ONE TIME", "PATTERN", "LORE"]
	if _is_sold_out(item_id):
		_set_status("This thread has already been claimed.")
		return
	if not _merchant_allows_item(item_id):
		_set_status(_purchase_block_reason(item_id))
		return
	if not _can_afford(cost):
		_set_status("Not enough Thread Knots.")
		AudioManager.play_ui(&"ui_click")
		return
	var purchased: bool = bool(_merchant.try_purchase(item_id, _player, cost, one_time)) if _merchant.has_method("try_purchase") else false
	if purchased:
		AudioManager.play_ui(&"menu_select")
		_set_status("Purchased %s." % String(item["name"]).to_lower())
	else:
		_set_status(_purchase_block_reason(item_id))
	_refresh_currency()
	_refresh_shop_rows()

func _on_shop_row_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_shop(index, true)
		_purchase_selected()

func _merchant_allows_item(item_id: StringName) -> bool:
	return not _merchant or not _merchant.has_method("can_purchase_item") or _merchant.can_purchase_item(item_id, _player)

func _purchase_block_reason(item_id: StringName) -> String:
	if _merchant and _merchant.has_method("get_purchase_block_reason"):
		return String(_merchant.get_purchase_block_reason(item_id, _player))
	return "The Follower cannot offer this yet."

func _can_afford(cost: int) -> bool:
	if not _player:
		return false
	if _player.has_method("can_weave_stat_upgrade"):
		return _player.can_weave_stat_upgrade(cost)
	return int(_player.get("thread_knot_count")) >= cost

func _is_sold_out(item_id: StringName) -> bool:
	return _merchant and _merchant.has_method("has_purchased") and _merchant.has_purchased(item_id)

func _set_status(text: String) -> void:
	status_label.text = text

func _refresh_currency() -> void:
	var knots := int(_player.get("thread_knot_count")) if _player else 0
	thread_knot_label.text = str(knots)

func _make_label_settings(font_size: int, color: Color, use_sc_font: bool) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font = load("res://Assets/UI/Fonts/Almendra_SC/AlmendraSC-Regular.ttf") if use_sc_font else load("res://Assets/UI/Fonts/Almendra/Almendra-Regular.ttf")
	settings.font_size = font_size
	settings.font_color = color
	settings.outline_size = 3
	settings.outline_color = Color(0.02, 0.015, 0.01, 1.0)
	return settings

func _connect_binding_updates() -> void:
	var manager := get_node_or_null("/root/InputBindingManager")
	if manager and manager.has_signal("bindings_changed"):
		manager.bindings_changed.connect(_refresh_footer)

func _refresh_footer() -> void:
	if not footer_label:
		return
	var confirm := InputGlyphFormatter.get_action_display_bbcode(&"interact", "ENTER", _input_family, 30)
	var cancel := InputGlyphFormatter.get_action_display_bbcode(&"ui_cancel", "ESC", _input_family, 30)
	match _screen:
		Screen.HUB:
			footer_label.text = "%s SELECT     %s LEAVE" % [confirm, cancel]
		Screen.TALK:
			footer_label.text = "%s CONTINUE     %s BACK" % [confirm, cancel]
		Screen.SHOP:
			footer_label.text = "%s BUY     %s BACK" % [confirm, cancel]
		Screen.FAREWELL:
			footer_label.text = "%s CONTINUE" % confirm

func _set_player_flow_audio_suspended(is_suspended: bool) -> void:
	var player := _player if _player else get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_flow_state_audio_suspended"):
		player.set_flow_state_audio_suspended(is_suspended)

func _is_confirm_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_A
	return event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or event.is_action_pressed("Attack")

func _is_cancel_event(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_cancel")
