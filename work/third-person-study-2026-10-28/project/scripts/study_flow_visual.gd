extends MeshInstance3D
## Continuous, ivory-and-flax weave for the base game's earned Flow state.
var actor
var strength := 0.0
var clock := 0.0

func _ready() -> void:
	actor = get_parent()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
uniform float strength=0.0;
void fragment(){
 float edge=max(0.0,sin(UV.x*3.14159));
 ALBEDO=mix(COLOR.rgb,vec3(1.0,0.94,0.76),edge);
 EMISSION=ALBEDO*0.45;
 ALPHA=edge*strength*0.5;
}"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	material_override = mat

func point(t: float, phase: float, side: float) -> Vector3:
	var angle := t*TAU*1.5+phase+clock*1.6
	var radius := 0.35+sin(t*PI)*0.13+side*0.012
	return Vector3(cos(angle)*radius,0.1+t*1.75,sin(angle)*radius)

func _process(delta: float) -> void:
	clock += delta
	strength = move_toward(strength,1.0 if actor.momentum.flow else 0.0,delta*3)
	visible = strength>0.01
	if not visible: return
	material_override.set_shader_parameter("strength",strength)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var colors: Array[Color]=[Color("b58b40")]
	if actor.get_parent().has_method("flow_colors"):
		var channels: Array[Color]=actor.get_parent().flow_colors()
		if not channels.is_empty(): colors=channels
	for strand in range(3):
		for segment in range(32):
			var a := segment/32.0
			var b := (segment+1)/32.0
			var phase := strand*TAU/3
			for item in [[a,-1.0],[a,1.0],[b,1.0],[a,-1.0],[b,1.0],[b,-1.0]]:
				tool.set_color(colors[strand%colors.size()])
				tool.set_uv(Vector2((item[1]+1)/2,item[0]))
				tool.add_vertex(point(item[0],phase,item[1]))
	mesh = tool.commit()
