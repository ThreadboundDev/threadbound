extends CanvasLayer

@export var display_time := 4.0
@export var fade_time := 0.18

@onready var panel: Panel = $Panel as Panel
@onready var margin_container: MarginContainer = $Panel/MarginContainer as MarginContainer
@onready var message_label: Label = $Panel/MarginContainer/MessageLabel as Label

var _tween: Tween
var _base_label_settings: LabelSettings
var _rich_message_label: RichTextLabel

func _ready() -> void:
	add_to_group("demo_message_box")
	_base_label_settings = message_label.label_settings
	visible = false
	panel.modulate.a = 0.0

func configure_layout(settings: Dictionary) -> void:
	var panel_rect: Rect2 = settings.get("panel_rect", Rect2(panel.offset_left, panel.offset_top, panel.size.x, panel.size.y))
	panel.offset_left = panel_rect.position.x
	panel.offset_top = panel_rect.position.y
	panel.offset_right = panel_rect.position.x + panel_rect.size.x
	panel.offset_bottom = panel_rect.position.y + panel_rect.size.y

	var text_margins: Vector4 = settings.get("text_margins", Vector4(24.0, 18.0, 24.0, 18.0))
	margin_container.offset_left = text_margins.x
	margin_container.offset_top = text_margins.y
	margin_container.offset_right = -text_margins.z
	margin_container.offset_bottom = -text_margins.w

	display_time = float(settings.get("display_time", display_time))
	fade_time = float(settings.get("fade_time", fade_time))

	var label_settings = settings.get("label_settings")
	message_label.label_settings = label_settings if label_settings is LabelSettings else _base_label_settings

func show_message(message: String, use_bbcode := false) -> void:
	if _tween:
		_tween.kill()

	if use_bbcode:
		var rich_label := _ensure_rich_message_label()
		message_label.visible = false
		rich_label.visible = true
		rich_label.text = "[center]%s[/center]" % message
	else:
		message_label.visible = true
		message_label.text = message
		if _rich_message_label:
			_rich_message_label.visible = false
	visible = true
	panel.modulate.a = 0.0

	_tween = create_tween()
	_tween.tween_property(panel, "modulate:a", 1.0, fade_time)
	_tween.tween_interval(display_time)
	_tween.tween_property(panel, "modulate:a", 0.0, fade_time)
	_tween.tween_callback(func() -> void: visible = false)

func _ensure_rich_message_label() -> RichTextLabel:
	if _rich_message_label:
		return _rich_message_label

	_rich_message_label = RichTextLabel.new()
	_rich_message_label.name = "RichMessageLabel"
	_rich_message_label.bbcode_enabled = true
	_rich_message_label.fit_content = false
	_rich_message_label.scroll_active = false
	_rich_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rich_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rich_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_rich_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rich_message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _base_label_settings:
		if _base_label_settings.font:
			_rich_message_label.add_theme_font_override("normal_font", _base_label_settings.font)
			_rich_message_label.add_theme_font_override("bold_font", _base_label_settings.font)
		_rich_message_label.add_theme_font_size_override("normal_font_size", _base_label_settings.font_size)
		_rich_message_label.add_theme_font_size_override("bold_font_size", _base_label_settings.font_size)
		_rich_message_label.add_theme_color_override("default_color", _base_label_settings.font_color)
		_rich_message_label.add_theme_constant_override("outline_size", _base_label_settings.outline_size)
		_rich_message_label.add_theme_color_override("font_outline_color", _base_label_settings.outline_color)
	margin_container.add_child(_rich_message_label)
	return _rich_message_label
