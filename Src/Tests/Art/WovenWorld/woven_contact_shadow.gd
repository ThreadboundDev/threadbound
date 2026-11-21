extends Node2D
## Soft surface-projected shadow for the static art-test caps. No player changes.

var target: CharacterBody2D
var receivers: Array[Dictionary] = []
var receiver: Dictionary = {}
var ground_distance := INF
var clipped_right := 0.0
var main: Sprite2D
var contacts: Array[Sprite2D] = []
var maximum_height := 640.0


func _ready() -> void:
	# Run after the live doll updates its animated skeleton and 2D composite.
	process_priority = 110
	z_index = 0
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.65, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.22), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.width = 192
	texture.height = 192
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	main = _sprite(texture)
	for foot in 2:
		contacts.append(_sprite(texture))


func _sprite(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_filter_clip_enabled = true
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sprite.material = unlit
	add_child(sprite)
	return sprite


func _receiver_below(point: Vector2) -> Dictionary:
	var nearest: Dictionary = {}
	var distance := maximum_height
	for surface in receivers:
		var height := float(surface.y) - point.y
		if point.x < float(surface.left) or point.x > float(surface.right):
			continue
		if height < -4.0 or height > distance:
			continue
		distance = maxf(height, 0)
		nearest = surface
	return nearest


func _paint(sprite: Sprite2D, center_x: float, surface: Dictionary, extent: Vector2, opacity: float) -> void:
	var left := maxf(center_x - extent.x * 0.5, float(surface.left))
	var right := minf(center_x + extent.x * 0.5, float(surface.right))
	if right - left < 1.0 or opacity <= 0.001:
		sprite.hide()
		return
	var texture_left := (left - (center_x - extent.x * 0.5)) / extent.x * 192.0
	sprite.region_rect = Rect2(texture_left, 0, (right - left) / extent.x * 192.0, 192)
	sprite.scale = extent / 192.0
	sprite.global_position = Vector2((left + right) * 0.5, float(surface.y) + 2.0)
	sprite.modulate = Color(0.09, 0.065, 0.045, opacity)
	sprite.show()
	if sprite == main:
		clipped_right = right


func _foot_points() -> PackedVector2Array:
	var result := PackedVector2Array()
	var visual: Node = target.get_node_or_null("Live3DVisual")
	if not visual:
		return result
	var skeleton := visual.get("_skeleton") as Skeleton3D
	var camera := visual.get("_camera") as Camera3D
	var display := visual.get("_display") as Sprite2D
	var viewport := visual.get("_viewport") as SubViewport
	var probes: Array = visual.get("_sole_probes")
	if not skeleton or not camera or not display or not viewport or probes.size() != 4:
		return result
	# Heel and toe probes already used by the player are ordered L heel/toe,
	# R heel/toe. Read their projection; never alter the pose or its renderer.
	for foot in 2:
		var center := Vector2.ZERO
		for index in 2:
			var probe: Dictionary = probes[foot * 2 + index]
			var point := skeleton.to_global(skeleton.get_bone_global_pose(probe.bone) * probe.point)
			var pixel := camera.unproject_position(point) - Vector2(viewport.size) * 0.5 + display.offset
			if display.flip_h:
				pixel.x = -pixel.x
			center += display.to_global(pixel)
		result.append(center * 0.5)
	return result


func _process(_delta: float) -> void:
	main.hide()
	for contact in contacts:
		contact.hide()
	receiver = {}
	ground_distance = INF
	if not is_instance_valid(target):
		return
	var collider := target.get_node("CollisionShape2D") as CollisionShape2D
	var feet := collider.to_global(Vector2(0, collider.shape.get_rect().end.y))
	var points := _foot_points()
	var center_x := feet.x
	var width := 144.0
	if points.size() == 2:
		center_x = (points[0].x + points[1].x) * 0.5
		width = clampf(absf(points[0].x - points[1].x) + 46.0, 86.0, 154.0)
	receiver = _receiver_below(feet)
	if not receiver.is_empty():
		ground_distance = maxf(float(receiver.y) - feet.y, 0.0)
		var height_ratio := clampf(ground_distance / maximum_height, 0, 1)
		var extent := Vector2(width * lerpf(1.0, 0.6, height_ratio), lerpf(18.0, 24.0, height_ratio))
		_paint(main, center_x, receiver, extent, 0.32 * pow(1.0 - height_ratio, 1.5))
	for index in points.size():
		var surface := _receiver_below(points[index])
		if surface.is_empty():
			continue
		var separation := absf(float(surface.y) - points[index].y)
		var opacity := 0.34 * clampf(1.0 - separation / 18.0, 0, 1)
		_paint(contacts[index], points[index].x, surface, Vector2(36, 9), opacity)
