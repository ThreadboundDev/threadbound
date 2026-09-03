shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float noise_seed = 0.0;
uniform float erosion_softness : hint_range(0.01, 0.5) = 0.16;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32 + noise_seed);
	return fract(p.x * p.y);
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float coarse = hash21(floor(UV * vec2(30.0, 42.0)));
	float fine = hash21(floor(UV * vec2(71.0, 89.0)) + 13.7);
	float noise = mix(coarse, fine, 0.34);
	float erosion_edge = progress * 0.88 - 0.08;
	float remains = smoothstep(
		erosion_edge - erosion_softness,
		erosion_edge + erosion_softness,
		noise
	);
	float edge_energy = smoothstep(0.05, 0.55, source.a);
	vec3 identity = COLOR.rgb;
	vec3 bright_center = mix(identity, vec3(1.0, 0.965, 0.84), edge_energy * (1.0 - progress) * 0.32);
	COLOR = vec4(bright_center, source.a * COLOR.a * remains);
}
