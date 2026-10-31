shader_type canvas_item;
// Parallax is decorative; the waterline stays fixed in world space.
varying float world_y;
uniform float water_surface_y = 411.0;
void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).y;
}
void fragment() {
	COLOR.a *= smoothstep(water_surface_y-3.0,water_surface_y+3.0,world_y);
}
