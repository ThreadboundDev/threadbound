shader_type canvas_item;

uniform float reveal_progress : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.001, 0.2) = 0.045;
uniform vec4 stitch_glow : source_color = vec4(1.0, 0.68, 0.22, 1.0);

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 local = fract(point);
	local = local * local * (3.0 - 2.0 * local);
	return mix(
		mix(hash(cell), hash(cell + vec2(1.0, 0.0)), local.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), local.x),
		local.y
	);
}

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float coarse_thread = value_noise(UV * vec2(24.0, 14.0));
	float fine_thread = value_noise(UV * vec2(73.0, 41.0));
	float stagger = (coarse_thread - 0.5) * 0.11 + (fine_thread - 0.5) * 0.035;
	float stitch_order = UV.x * 0.78 + UV.y * 0.16 + stagger;
	float travel = reveal_progress * 1.22 - 0.15;
	float revealed = smoothstep(stitch_order - edge_width, stitch_order + edge_width, travel);
	float leading_edge = smoothstep(travel - edge_width * 1.8, travel, stitch_order)
		* (1.0 - smoothstep(travel, travel + edge_width * 1.8, stitch_order));
	leading_edge *= step(0.001, source.a);

	vec3 highlighted = mix(source.rgb, stitch_glow.rgb, leading_edge * 0.48);
	float alpha = source.a * revealed;
	COLOR = vec4(highlighted, alpha);
}
