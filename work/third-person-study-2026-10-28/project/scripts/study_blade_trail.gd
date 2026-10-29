extends MeshInstance3D
## A short surface swept by the actual blade, rather than an approximate swing arc.
var blade: MeshInstance3D
var owner_actor
var samples: Array[Dictionary] = []
var clock := 0.0
var life := 0.14
var references: Array[Dictionary] = []
var rig: Skeleton3D

func _ready() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
void fragment(){
 float edge=pow(UV.x,0.6);
 float fade=pow(1.0-UV.y,1.8);
 ALBEDO=mix(vec3(0.36,0.64,0.67),vec3(1.0,0.91,0.69),edge);
 EMISSION=ALBEDO*0.3;
 ALPHA=fade*edge*0.62;
}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material_override = material
	top_level = true
	global_transform = Transform3D.IDENTITY
	if blade.skin != null:
		rig = blade.get_node_or_null(blade.skeleton) as Skeleton3D
	var bound := blade.mesh.get_aabb()
	var axis := bound.size.max_axis_index()
	var root := bound.get_center()
	var tip := bound.get_center()
	if owner_actor.has_method("facing"):
		root[axis] = bound.end[axis]-bound.size[axis]*0.28
		tip[axis] = bound.position[axis]
	else:
		root[axis] = bound.position[axis]+bound.size[axis]*0.25
		tip[axis] = bound.end[axis]
	if blade.has_meta("blade_base_gltf") and blade.has_meta("blade_tip_gltf"):
		var a: Array = blade.get_meta("blade_base_gltf")
		var b: Array = blade.get_meta("blade_tip_gltf")
		root = Vector3(a[0],a[1],a[2])
		tip = Vector3(b[0],b[1],b[2])
	references = [reference(root),reference(tip)]

func _process(delta: float) -> void:
	if not is_instance_valid(owner_actor) or not is_instance_valid(blade): return
	clock += delta
	var emitting := false
	if owner_actor.has_method("facing"):
		var combat = owner_actor.combat
		emitting = combat.action in ["light", "air", "water", "spin"] and combat.elapsed >= combat.active_start-0.025 and combat.elapsed < combat.active_end+0.025
	else: emitting = owner_actor.state == "active"
	if emitting and blade.is_visible_in_tree():
		samples.append({"a":posed_reference(references[0]),"b":posed_reference(references[1]),"time":clock})
	while not samples.is_empty() and clock-samples[0].time > life: samples.pop_front()
	if samples.size() < 2:
		visible = false
		return
	visible = true
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(samples.size()-1):
		var a: Dictionary = samples[i]
		var b: Dictionary = samples[i+1]
		if Vector3(a.b).distance_to(b.b) > 2.5: continue
		for item in [[a.a,0.0,a.time],[a.b,1.0,a.time],[b.b,1.0,b.time],[a.a,0.0,a.time],[b.b,1.0,b.time],[b.a,0.0,b.time]]:
			tool.set_uv(Vector2(item[1], clampf((clock-item[2])/life,0,1)))
			tool.add_vertex(item[0])
	mesh = tool.commit()

func reference(point: Vector3) -> Dictionary:
	var result := {"point":point,"bones":[],"weights":[]}
	if rig == null or blade.skin == null: return result
	var distance := INF
	for surface in range(blade.mesh.get_surface_count()):
		var arrays := blade.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones = arrays[Mesh.ARRAY_BONES]
		var weights = arrays[Mesh.ARRAY_WEIGHTS]
		if bones == null or weights == null or vertices.is_empty(): continue
		var count: int = bones.size()/vertices.size()
		for i in range(vertices.size()):
			var d := vertices[i].distance_squared_to(point)
			if d<distance:
				distance = d
				result = {"point":vertices[i],"bones":[],"weights":[]}
				for j in range(count):
					result.bones.append(bones[i*count+j])
					result.weights.append(weights[i*count+j])
	return result

func posed_reference(data: Dictionary) -> Vector3:
	if rig == null or data.bones.is_empty(): return blade.to_global(data.point)
	var result := Vector3.ZERO
	for i in range(data.bones.size()):
		var weight: float = data.weights[i]
		if weight<=0: continue
		var bind: int = data.bones[i]
		var bone: int = blade.skin.get_bind_bone(bind)
		if bone<0: bone = rig.find_bone(blade.skin.get_bind_name(bind))
		if bone<0: continue
		result += (rig.global_transform*rig.get_bone_global_pose(bone)*blade.skin.get_bind_pose(bind)*Vector3(data.point))*weight
	return result
