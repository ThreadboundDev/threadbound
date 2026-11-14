extends RefCounted
## Presentation shared by the Demo 2.0 menus and their title-screen overlays.

const ButtonTheme := preload("res://Src/UI/menu_button_theme.gd")
const DEMO := "res://Src/Environment/World/Chamber Of The First Weave - Demo 2.0.tscn"
const TITLE := "res://Src/UI/MainMenu/main_menu.tscn"
const SURFACE := Color("#1a1b20")
const EDGE := Color("#454249")
const SCRIM := Color(0.045, 0.047, 0.06, 0.78)
const SELECTED := &"demo_menu_selected"

static var _buttons: Theme
static var _surface: StyleBoxFlat


static func enabled(node: Node) -> bool:
	var ancestor := node
	while ancestor:
		if ancestor.scene_file_path in [DEMO, TITLE]:
			return true
		ancestor = ancestor.get_parent()
	var scene := node.get_tree().current_scene
	return scene != null and scene.scene_file_path in [DEMO, TITLE]


static func button_theme() -> Theme:
	if not _buttons:
		_buttons = ButtonTheme.create(ButtonTheme.CHAMBER, 32)
	return _buttons


static func surface() -> StyleBoxFlat:
	if not _surface:
		_surface = StyleBoxFlat.new()
		_surface.bg_color = SURFACE
		_surface.border_color = EDGE
		_surface.set_border_width_all(1)
		_surface.set_corner_radius_all(10)
		_surface.content_margin_left = 14.0
		_surface.content_margin_top = 12.0
		_surface.content_margin_right = 14.0
		_surface.content_margin_bottom = 12.0
	return _surface


static func plate(control: Control, is_choice := false) -> void:
	if control is TextureRect:
		control.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		control.texture = null
	elif control is ColorRect:
		control.color = Color.TRANSPARENT
	elif control is Panel or control is PanelContainer:
		control.add_theme_stylebox_override(&"panel", surface())
		if not is_choice:
			return
	control.draw.connect(_draw_plate.bind(control, is_choice))
	control.resized.connect(control.queue_redraw)
	control.queue_redraw()


static func _draw_plate(control: Control, is_choice: bool) -> void:
	var rect := Rect2(Vector2.ZERO, control.size)
	if not is_choice:
		control.draw_style_box(surface(), rect)
		return
	var selected := bool(control.get_meta(SELECTED, false))
	var buttons := button_theme()
	control.draw_style_box(buttons.get_stylebox(&"hover" if selected else &"normal", &"Button"), rect)
	if selected:
		control.draw_style_box(buttons.get_stylebox(&"focus", &"Button"), rect)


static func select_plate(control: Control, selected: bool) -> void:
	control.set_meta(SELECTED, selected)
	control.modulate = Color.WHITE
	control.queue_redraw()


static func row(row_control: Control) -> void:
	var plaque := row_control.get_node("Plaque") as TextureRect
	plate(plaque, true)
	plaque.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var label := row_control.get_node("Label") as Label
	label.label_settings = null
	label.add_theme_font_override(&"font", ButtonTheme.FONT)
	label.add_theme_font_size_override(&"font_size", 32)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


static func select_row(row_control: Control, selected: bool) -> void:
	select_plate(row_control.get_node("Plaque"), selected)
	var label := row_control.get_node("Label") as Label
	label.modulate = ButtonTheme.ACTIVE_TEXT if selected else ButtonTheme.TEXT


static func tab(label: Label) -> void:
	var backing := Control.new()
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.show_behind_parent = true
	backing.name = "DemoTabPlate"
	label.add_child(backing)
	backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backing.offset_left = -12
	backing.offset_top = -4
	backing.offset_right = 12
	backing.offset_bottom = 4
	plate(backing, true)


static func select_tab(label: Label, selected: bool, hovered := false) -> void:
	var backing := label.get_node("DemoTabPlate") as Control
	select_plate(backing, selected)
	label.modulate = ButtonTheme.ACTIVE_TEXT if selected or hovered else ButtonTheme.TEXT


static func slider(control: Control) -> void:
	control.get_node("Shell").hide()
	var track := control.get_node("VolumeBar/Empty") as TextureRect
	var fill := control.get_node("VolumeBar/FilledClip/Filled") as TextureRect
	var knob := control.get_node("Knob") as TextureRect
	_slider_mark(track, 0.0, 12.0, EDGE)
	_slider_mark(fill, 0.0, 12.0, ButtonTheme.CHAMBER)
	_slider_mark(knob, 22.0, 28.0, ButtonTheme.ACTIVE_TEXT)


static func _slider_mark(mark: TextureRect, width: float, height: float, color: Color) -> void:
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.texture = null
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	mark.resized.connect(mark.queue_redraw)
	mark.draw.connect(func() -> void:
		var extent := Vector2(width if width > 0.0 else mark.size.x, height)
		mark.draw_style_box(style, Rect2((mark.size - extent) * 0.5, extent))
	)


static func native_buttons(root: Node) -> void:
	for child in root.find_children("*", "Button", true, false):
		var button := child as Button
		button.theme = button_theme()
		for style in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
			button.remove_theme_stylebox_override(style)
		for color in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_disabled_color"]:
			button.remove_theme_color_override(color)
		button.remove_theme_font_override(&"font")
