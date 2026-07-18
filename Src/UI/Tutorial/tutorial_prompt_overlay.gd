class_name TutorialPromptOverlay
extends CanvasLayer

@export var prompt_position := Vector2(96.0, 720.0)
@export var prompt_size := Vector2(620.0, 150.0)
@export var pointer_start := Vector2(350.0, 180.0)
@export var pointer_end := Vector2(226.0, 126.0)
@export var pointer_color := Color(1.0, 0.78, 0.34, 0.92)
@export var panel_color := Color(0.02, 0.018, 0.014, 0.82)
@export var border_color := Color(0.95, 0.68, 0.28, 0.78)
@export var text_color := Color(1.0, 0.9, 0.68, 1.0)
@export var dim_color := Color(0.18, 0.18, 0.18, 0.72)

var _root: Control
var _panel: PanelContainer
var _label: RichTextLabel
var _pointer: Line2D
var _end_point: ColorRect
var _dim_rects: Array[ColorRect] = []
var _tween: Tween

func _ready() -> void:
	layer = 110
	_build_ui()
	hide_prompt(true)

func show_prompt(text: String, show_pointer := false, instant := false) -> void:
	if not _label:
		return

	_label.clear()
	_label.append_text(text)
	_panel.position = prompt_position
	_apply_prompt_size(prompt_size)
	_pointer.visible = show_pointer
	_end_point.visible = show_pointer
	_update_pointer()

	_panel.visible = true
	_panel.modulate.a = 1.0 if instant else 0.0
	if _tween:
		_tween.kill()
	if instant:
		return
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.18)

func hide_prompt(instant := false) -> void:
	if not _panel:
		return

	if _tween:
		_tween.kill()
	if instant:
		_panel.visible = false
		_panel.modulate.a = 0.0
		_pointer.visible = false
		_end_point.visible = false
		set_spotlight(false)
		return

	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.14)
	_tween.tween_callback(func() -> void:
		if _panel:
			_panel.visible = false
		if _pointer:
			_pointer.visible = false
		if _end_point:
			_end_point.visible = false
		set_spotlight(false)
	)

func set_prompt_layout(position: Vector2, size: Vector2) -> void:
	prompt_position = position
	prompt_size = size
	if _panel:
		_panel.position = prompt_position
		_apply_prompt_size(prompt_size)

func set_pointer(start: Vector2, end: Vector2) -> void:
	pointer_start = start
	pointer_end = end
	_update_pointer()

func set_spotlight(enabled: bool, focus_rect := Rect2()) -> void:
	if _dim_rects.is_empty():
		return
	for rect in _dim_rects:
		rect.visible = enabled
	if not enabled:
		return
	_update_spotlight_rects(focus_rect)

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "TutorialPromptRoot"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_build_dim_overlay()

	_pointer = Line2D.new()
	_pointer.name = "MomentumPointer"
	_pointer.width = 3.0
	_pointer.default_color = pointer_color
	_pointer.visible = false
	_root.add_child(_pointer)

	_end_point = ColorRect.new()
	_end_point.name = "PointerEndpoint"
	_end_point.color = pointer_color
	_end_point.size = Vector2(12.0, 12.0)
	_end_point.pivot_offset = _end_point.size * 0.5
	_end_point.visible = false
	_root.add_child(_end_point)

	_panel = PanelContainer.new()
	_panel.name = "PromptPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.position = prompt_position
	_panel.size = prompt_size
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	_root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.name = "PromptMargin"
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_panel.add_child(margin)

	_label = RichTextLabel.new()
	_label.name = "PromptLabel"
	_label.bbcode_enabled = true
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.fit_content = true
	_label.scroll_active = false
	_label.scroll_following = false
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_color_override("font_color", text_color)
	_label.add_theme_font_size_override("font_size", 30)
	margin.add_child(_label)

func _apply_prompt_size(size: Vector2) -> void:
	if not _panel:
		return
	_panel.custom_minimum_size = size
	_panel.size = size
	if _label:
		_label.custom_minimum_size = Vector2(maxf(0.0, size.x - 48.0), maxf(0.0, size.y - 36.0))
		_label.size = _label.custom_minimum_size

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = panel_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _build_dim_overlay() -> void:
	for rect_name in ["DimTop", "DimLeft", "DimRight", "DimBottom"]:
		var rect := ColorRect.new()
		rect.name = rect_name
		rect.color = dim_color
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.visible = false
		_root.add_child(rect)
		_dim_rects.append(rect)

func _update_spotlight_rects(focus_rect: Rect2) -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var clamped: Rect2 = focus_rect.intersection(Rect2(Vector2.ZERO, viewport_size))
	if clamped.size == Vector2.ZERO:
		clamped = Rect2(Vector2.ZERO, viewport_size)

	_dim_rects[0].position = Vector2.ZERO
	_dim_rects[0].size = Vector2(viewport_size.x, clamped.position.y)

	_dim_rects[1].position = Vector2(0.0, clamped.position.y)
	_dim_rects[1].size = Vector2(clamped.position.x, clamped.size.y)

	_dim_rects[2].position = Vector2(clamped.end.x, clamped.position.y)
	_dim_rects[2].size = Vector2(maxf(0.0, viewport_size.x - clamped.end.x), clamped.size.y)

	_dim_rects[3].position = Vector2(0.0, clamped.end.y)
	_dim_rects[3].size = Vector2(viewport_size.x, maxf(0.0, viewport_size.y - clamped.end.y))

func _update_pointer() -> void:
	if _pointer:
		_pointer.points = PackedVector2Array([pointer_start, pointer_end])
		_pointer.default_color = pointer_color
	if _end_point:
		_end_point.position = pointer_end - _end_point.size * 0.5
		_end_point.color = pointer_color
