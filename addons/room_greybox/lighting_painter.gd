@tool
extends MarginContainer

const PRESETS := [
	["Warm lamp", Color("ffb064"), 240.0, 0.8],
	["Cool fill", Color("91bdff"), 360.0, 0.5],
	["Neutral glow", Color("fff0d6"), 320.0, 0.6],
]
const TEXTURE_SIZE := 512
const LIGHT_MARKER := &"painted_light"

var _plugin: EditorPlugin
var _paint: CheckButton
var _radius: SpinBox
var _energy: SpinBox
var _color: ColorPickerButton
var _shadows: CheckButton
var _texture: GradientTexture2D


func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin


func _ready() -> void:
	for side in ["left", "right", "top", "bottom"]:
		add_theme_constant_override("margin_" + side, 9)
	var rows := VBoxContainer.new()
	add_child(rows)
	var settings := HBoxContainer.new()
	rows.add_child(settings)
	_paint = CheckButton.new()
	_paint.text = "Paint"
	_paint.toggled.connect(_paint_toggled)
	settings.add_child(_paint)
	var presets := OptionButton.new()
	for preset in PRESETS:
		presets.add_item(preset[0])
	presets.item_selected.connect(_apply_preset)
	settings.add_child(presets)
	_radius = _number(settings, "Radius", 24.0, 1600.0, 8.0, "px")
	_energy = _number(settings, "Energy", 0.05, 3.0, 0.05, "")
	_color = ColorPickerButton.new()
	_color.edit_alpha = false
	_color.custom_minimum_size.x = 54
	_color.tooltip_text = "Light color and eyedropper"
	_color.get_picker().sampler_visible = true
	_color.color_changed.connect(_refresh_overlay)
	settings.add_child(_color)
	_shadows = CheckButton.new()
	_shadows.text = "Cast Shadows"
	_shadows.button_pressed = true
	settings.add_child(_shadows)
	var help := Label.new()
	help.text = "Click to place. Right-click a painted light to erase it. [ / ] change radius."
	rows.add_child(help)
	visibility_changed.connect(_refresh_overlay)

	var falloff := Gradient.new()
	falloff.colors = PackedColorArray([Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
	_texture = GradientTexture2D.new()
	_texture.width = TEXTURE_SIZE
	_texture.height = TEXTURE_SIZE
	_texture.fill = GradientTexture2D.FILL_RADIAL
	_texture.fill_from = Vector2(0.5, 0.5)
	_texture.fill_to = Vector2(1.0, 0.5)
	_texture.gradient = falloff
	_apply_preset(0)


func _number(parent: Control, caption: String, minimum: float, maximum: float, step: float, unit: String) -> SpinBox:
	var label := Label.new()
	label.text = caption
	parent.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = step
	spin.suffix = unit
	spin.value_changed.connect(_refresh_overlay)
	parent.add_child(spin)
	return spin


func _apply_preset(index: int) -> void:
	var preset: Array = PRESETS[index]
	_color.color = preset[1]
	_radius.value = preset[2]
	_energy.value = preset[3]
	_refresh_overlay()


func cancel_paint() -> void:
	if is_instance_valid(_paint):
		_paint.button_pressed = false


func _paint_toggled(enabled: bool) -> void:
	if enabled:
		var root := EditorInterface.get_edited_scene_root() as Node2D
		if root:
			var parent := _target(root)
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(parent)
			EditorInterface.edit_node(parent)
	_refresh_overlay()


func _refresh_overlay(_value: Variant = null) -> void:
	_plugin.update_overlays()


func _active() -> bool:
	return is_visible_in_tree() and is_instance_valid(_paint) and _paint.button_pressed


func _target(root: Node2D) -> Node2D:
	var geometry := root.get_node_or_null("Geometry") as Node2D
	return geometry if geometry and geometry.owner == root else root


func _world_to_canvas() -> Transform2D:
	return EditorInterface.get_editor_viewport_2d().global_canvas_transform


func forward_canvas_input(event: InputEvent) -> bool:
	if not _active():
		return false
	if event is InputEventKey and event.pressed and not (event.ctrl_pressed or event.alt_pressed or event.meta_pressed):
		match event.keycode:
			KEY_ESCAPE:
				cancel_paint()
			KEY_BRACKETLEFT:
				_radius.value -= 32.0
			KEY_BRACKETRIGHT:
				_radius.value += 32.0
			_:
				return false
		return true
	var mouse := event as InputEventMouse
	if mouse == null or mouse.ctrl_pressed or mouse.alt_pressed or Input.is_key_pressed(KEY_SPACE):
		return false
	_refresh_overlay()
	if not (mouse is InputEventMouseButton and mouse.pressed):
		return false
	var root := EditorInterface.get_edited_scene_root() as Node2D
	if root == null:
		return false
	var view := _world_to_canvas()
	if mouse.button_index == MOUSE_BUTTON_LEFT:
		_place(root, view.affine_inverse() * mouse.position)
	elif mouse.button_index == MOUSE_BUTTON_RIGHT:
		_erase(root, view, mouse.position)
	else:
		return false
	return true


func draw_canvas_overlay(overlay: Control) -> void:
	if not _active() or Input.is_key_pressed(KEY_SPACE):
		return
	var root := EditorInterface.get_edited_scene_root() as Node2D
	var cursor := overlay.get_local_mouse_position()
	if root == null or not Rect2(Vector2.ZERO, overlay.size).has_point(cursor):
		return
	var transform := _world_to_canvas() * _target(root).global_transform
	var center := transform.affine_inverse() * cursor
	var radius := Vector2.ONE * _radius.value
	var tint := _color.color
	var bounds := Rect2(center - radius, radius * 2.0)
	overlay.draw_set_transform_matrix(transform)
	overlay.draw_texture_rect(_texture, bounds, false, Color(tint, minf(0.65, 0.28 + _energy.value * 0.20)))
	overlay.draw_arc(center, _radius.value, 0.0, TAU, 48, Color(tint, 0.76), -1.0, true)
	overlay.draw_set_transform_matrix(Transform2D.IDENTITY)
	overlay.draw_circle(cursor, 3.0, tint)


func _place(root: Node2D, point: Vector2) -> void:
	var parent := _target(root)
	var light := PointLight2D.new()
	light.name = _plugin.call("_unique_child_name", parent, "PaintedLight")
	light.position = parent.to_local(point)
	light.texture = _texture
	light.texture_scale = _radius.value * 2.0 / TEXTURE_SIZE
	light.color = _color.color
	light.energy = _energy.value
	light.range_item_cull_mask = 3
	light.shadow_item_cull_mask = 3
	light.shadow_enabled = _shadows.button_pressed
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	light.set_meta(LIGHT_MARKER, true)
	_plugin.call("_add_owned_node", parent, light, root)


func _erase(root: Node2D, view: Transform2D, cursor: Vector2) -> void:
	var closest: PointLight2D
	var radius_squared := 22.0 * 22.0
	for node in root.find_children("*", "PointLight2D", true, false):
		var light := node as PointLight2D
		if light.owner != root or not light.has_meta(LIGHT_MARKER):
			continue
		var distance := (view * light.global_position).distance_squared_to(cursor)
		if distance <= radius_squared:
			closest = light
			radius_squared = distance
	if closest == null:
		return
	var parent := closest.get_parent()
	var undo := _plugin.get_undo_redo()
	undo.create_action("Erase Painted Light")
	undo.add_do_method(parent, "remove_child", closest)
	undo.add_undo_method(parent, "add_child", closest)
	undo.add_undo_method(parent, "move_child", closest, closest.get_index())
	undo.add_undo_property(closest, "owner", root)
	undo.add_undo_reference(closest)
	undo.commit_action()
