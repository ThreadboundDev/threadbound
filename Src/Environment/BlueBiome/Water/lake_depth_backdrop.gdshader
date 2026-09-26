shader_type canvas_item;
render_mode unshaded;
varying float world_y;
uniform float water_surface_y = 450.0;
void vertex() { world_y=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).y; }
void fragment() {
	if (world_y < water_surface_y) { discard; }
	float depth = world_y - water_surface_y;
	vec3 tint=mix(vec3(.404,.725,.812),vec3(.035,.12,.19),smoothstep(0.0,2150.0,depth));
	COLOR=vec4(tint,1.0);
}
