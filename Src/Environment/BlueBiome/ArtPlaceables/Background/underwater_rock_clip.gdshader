shader_type canvas_item;
render_mode unshaded;
// Parallax is decorative; the waterline stays fixed in world space.
varying float world_y;
uniform float water_surface_y = 411.0;
uniform vec4 distance_color : source_color = vec4(0.10,0.25,0.31,1.0);
void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).y;
}
void fragment() {
	// The art is placed deeper, then emerges gradually through shallow haze.
	// No hard slice of rock coincides with the visible surface.
	float value = dot(COLOR.rgb,vec3(0.2126,0.7152,0.0722));
	vec3 quiet = mix(vec3(value),COLOR.rgb,0.60)*0.72;
	COLOR.rgb = mix(quiet,distance_color.rgb,0.38);
	COLOR.a *= smoothstep(water_surface_y+70.0,water_surface_y+250.0,world_y);
}
