shader_type canvas_item;
render_mode unshaded;

uniform float water_y = 660.0;
uniform vec4 water_color : source_color = vec4(0.404, 0.725, 0.812, 1.0);
varying float world_y;

void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).y;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float excess = source.g - max(source.r, source.b) * 1.32;
	float key = smoothstep(0.54, 0.62, excess);
	source.g = min(source.g, max(source.r, source.b) * 1.08);
	float depth = max(0.0, world_y - water_y);
	// The lake occludes the feet; only a short submerged section stays visible.
	vec3 tint = mix(source.rgb, water_color.rgb, smoothstep(0.0, 30.0, depth) * 0.85);
	float submerged = 1.0 - smoothstep(8.0, 30.0, depth);
	COLOR = vec4(tint, source.a * (1.0-key) * submerged);
}
