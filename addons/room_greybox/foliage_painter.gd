@tool
extends MarginContainer
## Paints individually editable foliage nodes into the active room's foliage layers.

const STAMP_SCRIPT := preload("res://Src/Environment/BlueBiome/ArtPlaceables/Foliage/foliage_stamp_2d.gd")
const ART_PATH := "res://Assets/BlueBiome/Art/CaveMouthFoliage/"
const CATALOG := [
	["Fine Strands", "fine_strands.png", Vector2(93, 51)],
	["Tall Strands", "tall_strands.png", Vector2(81, 64)],
	["Soft Grass Patch", "soft_strands.png", Vector2(138, 52)],
	["Broadleaf Accent", "fan_tuft.png", Vector2(104, 42)],
]
const GREENS := [Color("73a858"), Color("86ad61"), Color("609655"), Color("78a46d")]
const DEFAULT_HELP := "Click or drag to stamp. Right-click to erase. Turn Paint off to move stamps with Godot's tools."

var _plugin: EditorPlugin
var _paint: CheckButton
var _palette: OptionButton
var _layer: OptionButton
var _size: SpinBox
var _spacing: SpinBox
var _variation: SpinBox
var _flip: CheckButton
var _tint: CheckButton
var _status: Label
var _rng := RandomNumberGenerator.new()
var _textures: Dictionary[String, Texture2D] = {}
var _stroke_root: Node2D
var _stroke_parent: Node2D
var _stroke: Array[Node2D] = []
var _last_cursor := Vector2.ZERO
var _distance_to_stamp := 0.0


func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin


func _ready() -> void:
	_rng.randomize()
	for side in ["left", "right", "top", "bottom"]:
		add_theme_constant_override("margin_" + side, 9)
	var rows := VBoxContainer.new()
	add_child(rows)
	var choices := HBoxContainer.new()
	rows.add_child(choices)
	_paint = _toggle(choices, "Paint", false)
	_paint.toggled.connect(_paint_toggled)
	_palette = OptionButton.new()
	_palette.add_item("Mixed Grass")
	for brush in CATALOG:
		_palette.add_item(brush[0])
	_palette.tooltip_text = "Mixed Grass varies the three strand masks. Broadleaf is an accent."
	choices.add_child(_palette)
	_layer = OptionButton.new()
	_layer.add_item("Front of Player")
	_layer.add_item("Behind Player")
	choices.add_child(_layer)
	var move := Button.new()
	move.text = "Send Selection to Layer"
	move.pressed.connect(_move_selection)
	choices.add_child(move)
	var settings := HBoxContainer.new()
	rows.add_child(settings)
	_size = _number(settings, "Size", 25, 300, 100, "%")
	_spacing = _number(settings, "Spacing", 8, 512, 48, "px")
	_variation = _number(settings, "Variation", 0, 75, 26, "%")
	_flip = _toggle(settings, "Random Flip", true)
	_tint = _toggle(settings, "Vary Tint", true)
	_status = Label.new()
	_status.text = DEFAULT_HELP
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(_status)
	visibility_changed.connect(_visibility_changed)


func _process(_delta: float) -> void:
	if not _stroke.is_empty() and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_finish_stroke()


func _toggle(parent: Control, caption: String, checked: bool) -> CheckButton:
	var control := CheckButton.new()
	control.text = caption
	control.button_pressed = checked
	parent.add_child(control)
	return control


func _number(parent: Control, label_text: String, minimum: float, maximum: float,
		initial: float, unit: String) -> SpinBox:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var control := SpinBox.new()
	control.min_value = minimum
	control.max_value = maximum
	control.value = initial
	control.suffix = unit
	parent.add_child(control)
	return control


func _active() -> bool:
	return is_visible_in_tree() and is_instance_valid(_paint) and _paint.button_pressed


func _layers(root: Node2D) -> Node2D:
	return root.find_child("FoliageStamps", true, true) as Node2D if root else null


func _target(layers: Node2D) -> Node2D:
	return layers.get_node_or_null("FrontFoliage" if _layer.selected == 0 else "BackFoliage") as Node2D if layers else null


func forward_canvas_input(event: InputEvent) -> bool:
	if not _active():
		return false
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_stroke()
		_paint.button_pressed = false
		return true
	var mouse := event as InputEventMouse
	if mouse == null or Input.is_key_pressed(KEY_SPACE) or mouse.ctrl_pressed or mouse.alt_pressed:
		return false
	var viewport := EditorInterface.get_editor_viewport_2d()
	var point := viewport.get_canvas_transform().affine_inverse() * mouse.position
	_plugin.update_overlays()
	if event is InputEventMouseMotion and not _stroke.is_empty():
		_extend_stroke(point)
		return true
	if not event is InputEventMouseButton:
		return false
	if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and not _stroke.is_empty():
		_extend_stroke(point)
		_finish_stroke()
		return true
	if not event.pressed or event.button_index not in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		return false
	var root := EditorInterface.get_edited_scene_root() as Node2D
	var layer := _target(_layers(root))
	if layer == null:
		_status.text = "Open Blue Blockout or a room with FrontFoliage and BackFoliage layers."
		return false
	if event.button_index == MOUSE_BUTTON_RIGHT:
		_erase_at(root, layer, point)
	else:
		_begin_stroke(root, layer, point)
	return true


func draw_canvas_overlay(overlay: Control) -> void:
	if not _active() or Input.is_key_pressed(KEY_SPACE):
		return
	var root := EditorInterface.get_edited_scene_root() as Node2D
	if _target(_layers(root)) == null:
		return
	var cursor := overlay.get_local_mouse_position()
	if not Rect2(Vector2.ZERO, overlay.size).has_point(cursor):
		return
	var index := get_catalog_index_for_preview()
	var brush_texture := _brush_texture(index)
	if brush_texture == null:
		return
	var zoom := EditorInterface.get_editor_viewport_2d().get_canvas_transform().get_scale().abs()
	var brush_size := Vector2(CATALOG[index][2]) * zoom * _size.value / 100.0
	var bounds := Rect2(cursor - Vector2(brush_size.x * 0.5, brush_size.y), brush_size)
	var tint := Color(1, 1, 1, .55) if index == 3 else Color(GREENS[0], .63)
	overlay.draw_texture_rect(brush_texture, bounds, false, tint)
	overlay.draw_circle(cursor, 3.0, Color("ddeced"))


func get_catalog_index_for_preview() -> int:
	return maxi(0, _palette.selected - 1)


func _brush_texture(index: int) -> Texture2D:
	var path := ART_PATH + str(CATALOG[index][1])
	if not _textures.has(path) and ResourceLoader.exists(path):
		_textures[path] = load(path) as Texture2D
	return _textures.get(path)


func _begin_stroke(root: Node2D, target: Node2D, point: Vector2) -> void:
	_finish_stroke()
	_stroke_root = root
	_stroke_parent = target
	_last_cursor = point
	_distance_to_stamp = _spacing.value
	_place_stamp(point)


func _extend_stroke(point: Vector2) -> void:
	if not is_instance_valid(_stroke_parent):
		cancel_stroke()
		return
	var start := _last_cursor
	var remaining := start.distance_to(point)
	while remaining >= _distance_to_stamp:
		start = start.move_toward(point, _distance_to_stamp)
		_place_stamp(start)
		remaining = start.distance_to(point)
		_distance_to_stamp = _spacing.value
	_distance_to_stamp -= remaining
	_last_cursor = point


func _place_stamp(point: Vector2) -> void:
	var index := _rng.randi_range(0, 2) if _palette.selected == 0 else _palette.selected - 1
	var brush_texture := _brush_texture(index)
	if brush_texture == null:
		return
	var brush: Array = CATALOG[index]
	var stamp := MeshInstance2D.new()
	stamp.set_script(STAMP_SCRIPT)
	stamp.name = str(brush[0]).replace(" ", "")
	stamp.texture = brush_texture
	stamp.set("stamp_size", brush[2])
	stamp.set("flip_horizontal", _flip.button_pressed and _rng.randf() < 0.5)
	var jitter := _variation.value / 100.0
	stamp.scale = Vector2.ONE * (_size.value / 100.0) * _rng.randf_range(1.0 - jitter, 1.0 + jitter)
	if index < 3:
		stamp.modulate = GREENS[_rng.randi_range(0, GREENS.size() - 1)] if _tint.button_pressed else GREENS[0]
	stamp.position = _stroke_parent.to_local(point)
	_stroke_parent.add_child(stamp, true)
	_stroke.append(stamp)


func _finish_stroke() -> void:
	if _stroke.is_empty():
		return
	if not is_instance_valid(_stroke_root) or not is_instance_valid(_stroke_parent):
		cancel_stroke()
		return
	var undo := _plugin.get_undo_redo()
	undo.create_action("Paint Foliage", UndoRedo.MERGE_DISABLE, _stroke_root)
	for stamp in _stroke:
		stamp.owner = _stroke_root
		undo.add_do_method(_stroke_parent, "add_child", stamp, true)
		undo.add_do_property(stamp, "owner", _stroke_root)
		undo.add_do_reference(stamp)
		undo.add_undo_method(_stroke_parent, "remove_child", stamp)
	undo.commit_action(false)
	_status.text = "Placed %d foliage stamp%s. %s" % [_stroke.size(), "" if _stroke.size() == 1 else "s", DEFAULT_HELP]
	_stroke.clear()


func cancel_stroke() -> void:
	for stamp in _stroke:
		if is_instance_valid(stamp):
			stamp.queue_free()
	_stroke.clear()


func _erase_at(root: Node2D, layer: Node2D, point: Vector2) -> void:
	var closest: Node2D
	var best := maxf(22.0, _spacing.value * 0.65)
	for stamp in layer.get_children():
		if stamp.get_script() != STAMP_SCRIPT:
			continue
		var center: Vector2 = stamp.to_global(Vector2(0.0, -stamp.stamp_size.y * 0.35))
		var distance := center.distance_to(point)
		if distance < best:
			closest = stamp
			best = distance
	if closest == null:
		return
	var undo := _plugin.get_undo_redo()
	undo.create_action("Erase Foliage", UndoRedo.MERGE_DISABLE, root)
	undo.add_do_method(layer, "remove_child", closest)
	undo.add_undo_method(layer, "add_child", closest, true)
	undo.add_undo_method(layer, "move_child", closest, closest.get_index())
	undo.add_undo_property(closest, "owner", root)
	undo.add_undo_reference(closest)
	undo.commit_action()


func _move_selection() -> void:
	var root := EditorInterface.get_edited_scene_root() as Node2D
	var layers := _layers(root)
	var target := _target(layers)
	if target == null:
		return
	var selection := EditorInterface.get_selection().get_selected_nodes()
	var stamps := selection.filter(func(node: Node) -> bool:
		return node.get_script() == STAMP_SCRIPT and node.get_parent().get_parent() == layers and node.get_parent() != target)
	if stamps.is_empty():
		_status.text = "Select foliage stamps in the other layer, then send them here."
		return
	stamps.sort_custom(func(a: Node, b: Node) -> bool: return a.get_index() < b.get_index())
	var undo := _plugin.get_undo_redo()
	undo.create_action("Change Foliage Layer", UndoRedo.MERGE_DISABLE, root)
	for stamp in stamps:
		var source: Node = stamp.get_parent()
		undo.add_undo_method(stamp, "reparent", source, true)
		undo.add_undo_method(source, "move_child", stamp, stamp.get_index())
		undo.add_do_method(stamp, "reparent", target, true)
	undo.commit_action()
	_status.text = "Moved %d selected stamps to %s." % [stamps.size(), _layer.get_item_text(_layer.selected)]


func _paint_toggled(active: bool) -> void:
	if active:
		var layers := _layers(EditorInterface.get_edited_scene_root() as Node2D)
		if layers:
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(layers)
			EditorInterface.edit_node(layers)
	else:
		_finish_stroke()
	_plugin.update_overlays()


func _visibility_changed() -> void:
	if not is_visible_in_tree():
		_finish_stroke()
		if is_instance_valid(_plugin):
			_plugin.update_overlays()
