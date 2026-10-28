extends Node3D
## Short-lived thread arcs, impact stitches and unravel strands. No generated art.
var pieces: Array[Dictionary] = []

func glow(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = color * 0.35
	return mat

func strand(a: Vector3, b: Vector3, color: Color, radius := 0.02) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = maxf(0.01, a.distance_to(b))
	mesh.radial_segments = 5
	node.mesh = mesh
	node.material_override = glow(color)
	add_child(node)
	node.position = (a+b) * 0.5
	var direction := (b-a).normalized()
	if direction.length() > 0.01:
		node.quaternion = Quaternion(Vector3.UP, direction)
	return node

func ring(center: Vector3, radius: float, color: Color, life := 0.35, arc := TAU, yaw := 0.0) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.position = center
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, glow(color))
	var count := 48
	for i in range(count):
		var a := yaw - arc/2 + arc * i/count
		var b := yaw - arc/2 + arc * (i+1)/count
		var p := Vector3(sin(a), 0, cos(a))
		var q := Vector3(sin(b), 0, cos(b))
		for v in [p*radius, p*(radius+0.065), q*radius, q*radius, p*(radius+0.065), q*(radius+0.065)]:
			mesh.surface_add_vertex(v)
	mesh.surface_end()
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	root.add_child(instance)
	pieces.append({"node": root, "time": life, "life": life, "kind": "ring"})
	return root

func burst(center: Vector3, color: Color, strong := false) -> void:
	for i in range(12 if strong else 6):
		var a := i * 2.39996
		var direction := Vector3(cos(a), 0.3 + (i%3) * 0.3, sin(a)).normalized()
		var node := strand(center, center + direction * (0.7 if strong else 0.3), color, 0.014)
		pieces.append({"node": node, "time": 0.5, "life": 0.5, "kind": "strand", "velocity": direction * 2.5})

func number_at(center: Vector3, amount: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = str(amount)
	label.font_size = 42
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	add_child(label)
	label.position = center
	pieces.append({"node": label, "time": 0.7, "life": 0.7, "kind": "number"})

func _process(delta: float) -> void:
	for i in range(pieces.size()-1, -1, -1):
		var item: Dictionary = pieces[i]
		if not is_instance_valid(item.node):
			pieces.remove_at(i)
			continue
		item.time -= delta
		if item.kind == "ring":
			item.node.scale *= 1 + delta * 0.6
		elif item.kind == "strand":
			item.node.position += item.velocity * delta
		else:
			item.node.position.y += delta * 0.7
			item.node.modulate.a = item.time / item.life
		if item.time <= 0:
			item.node.queue_free()
			pieces.remove_at(i)

func clear() -> void:
	for item in pieces:
		if is_instance_valid(item.node): item.node.queue_free()
	pieces.clear()
