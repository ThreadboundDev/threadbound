extends Node3D
## Blade-driven trails, soft woven wavefronts and restrained impact flecks.
const TRAIL = preload("res://scripts/study_blade_trail.gd")
var pieces: Array[Dictionary] = []
var trails: Array[MeshInstance3D] = []

func glow(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = color*0.25
	return mat

func watch_blade(owner_node, blade: MeshInstance3D) -> void:
	var trail = TRAIL.new()
	trail.owner_actor = owner_node
	trail.blade = blade
	add_child(trail)
	trails.append(trail)

func strand(a: Vector3, b: Vector3, color: Color, radius := 0.02) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = maxf(0.01,a.distance_to(b))
	mesh.radial_segments = 5
	node.mesh = mesh
	node.material_override = glow(color)
	add_child(node)
	node.position = (a+b)*0.5
	if a.distance_to(b)>0.001: node.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	return node

func ring(center: Vector3, radius: float, color: Color, life := 0.35, arc := TAU, yaw := 0.0) -> Node3D:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
uniform vec4 tint:source_color=vec4(1.0);
uniform float fade=1.0;
void fragment(){
 float edge=pow(max(0.0,sin(UV.y*3.14159)),1.4);
 float weave=0.65+0.35*sin(UV.x*301.59+UV.y*12.56);
 ALBEDO=tint.rgb; EMISSION=tint.rgb*0.2;
 ALPHA=edge*weave*fade*0.48;
}"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("tint",color)
	var root := MeshInstance3D.new()
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var width := clampf(radius*0.08,0.05,0.22)
	for i in range(72):
		var a := yaw-arc/2+arc*i/72
		var b := yaw-arc/2+arc*(i+1)/72
		for item in [[a,radius,0.0],[a,radius+width,1.0],[b,radius+width,1.0],[a,radius,0.0],[b,radius+width,1.0],[b,radius,0.0]]:
			tool.set_uv(Vector2((item[0]-yaw)/TAU,item[2]))
			tool.add_vertex(Vector3(sin(item[0])*item[1],0,cos(item[0])*item[1]))
	root.mesh = tool.commit()
	root.material_override = mat
	root.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(root)
	root.position = center
	pieces.append({"node":root,"time":life,"life":life,"kind":"ring","material":mat})
	return root

func burst(center: Vector3, color: Color, strong := false) -> void:
	var node := CPUParticles3D.new()
	node.amount = 14 if strong else 7
	node.lifetime = 0.42 if strong else 0.24
	node.one_shot = true
	node.explosiveness = 1
	node.spread = 160
	node.direction = Vector3.UP
	node.gravity = Vector3(0,-1.2,0)
	node.initial_velocity_min = 0.4
	node.initial_velocity_max = 1.7 if strong else 1.0
	node.scale_amount_min = 0.015
	node.scale_amount_max = 0.045
	var quad := QuadMesh.new()
	quad.size = Vector2(1,0.6)
	node.mesh = quad
	var mat := glow(color)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	node.material_override = mat
	var gradient := Gradient.new()
	gradient.set_color(0,Color(1,1,1,0.85))
	gradient.set_color(1,Color(1,1,1,0))
	node.color_ramp = gradient
	add_child(node)
	node.global_position = center
	node.emitting = true
	pieces.append({"node":node,"time":0.6,"life":0.6,"kind":"particles"})

func neutral(center: Vector3, radius: float) -> void:
	for height in [0.08,0.22]: ring(center+Vector3.UP*height,radius,Color("d3c091"),0.5)
	var node := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1
	sphere.height = 2
	node.mesh = sphere
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
uniform float fade=1.0;
void fragment(){
 float rim=pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),3.0);
 float seam=pow(abs(sin(UV.y*75.4+UV.x*12.56)),18.0);
 ALBEDO=mix(vec3(0.34,0.57,0.61),vec3(0.95,0.87,0.65),seam);
 EMISSION=ALBEDO*0.25; ALPHA=fade*(rim*0.27+seam*rim*0.28);
}"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	node.position = center+Vector3.UP*0.8
	pieces.append({"node":node,"time":0.5,"life":0.5,"kind":"sphere","radius":radius,"material":mat})
	burst(center+Vector3.UP,color_for_flow(),true)

func color_for_flow() -> Color:
	return Color("e8d8ac")

func number_at(point: Vector3, value: int, color: Color) -> void:
	var node := Label3D.new()
	node.text = str(value)
	node.font_size = 32
	node.pixel_size = 0.006
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.modulate = color
	add_child(node)
	node.position = point
	pieces.append({"node":node,"time":0.6,"life":0.6,"kind":"number"})

func clear() -> void:
	for item in pieces:
		if is_instance_valid(item.node): item.node.queue_free()
	pieces.clear()
	for trail in trails: trail.samples.clear()

func _process(delta: float) -> void:
	for index in range(pieces.size()-1,-1,-1):
		var item := pieces[index]
		item.time -= delta
		if not is_instance_valid(item.node) or item.time <= 0:
			if is_instance_valid(item.node): item.node.queue_free()
			pieces.remove_at(index)
			continue
		var remaining: float = item.time/item.life
		if item.has("material"): item.material.set_shader_parameter("fade",remaining)
		if item.kind == "sphere": item.node.scale = Vector3.ONE*item.radius*(0.25+0.75*sqrt(1-remaining))
		if item.kind == "number":
			item.node.position.y += delta*0.65
			item.node.modulate.a = remaining
		pieces[index] = item
