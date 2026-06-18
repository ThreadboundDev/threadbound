shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec4 tint_color : source_color = vec4(0.2, 0.3, 0.6, 0.3);  // Soft blue hue (low alpha)
uniform float tint_intensity : hint_range(0.0, 1.0) = 1;  // Overall strength
uniform vec4 top_light_color : source_color = vec4(1.0, 0.86, 0.58, 1.0);
uniform float top_light_strength : hint_range(0.0, 1.0) = 0.22;
uniform vec2 top_light_position = vec2(0.5, 0.0);
uniform float top_light_radius : hint_range(0.1, 1.5) = 0.62;
uniform float edge_shadow_strength : hint_range(0.0, 1.0) = 0.18;
uniform float cavern_falloff : hint_range(0.0, 1.0) = 0.28;
uniform float shaft_strength : hint_range(0.0, 1.0) = 0.12;
uniform float shaft_spread : hint_range(0.05, 1.0) = 0.32;
uniform float grain_strength : hint_range(0.0, 0.12) = 0.018;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec3 color = mix(screen.rgb, tint_color.rgb, tint_intensity * tint_color.a);

	float top_light_distance = distance(SCREEN_UV, top_light_position);
	float top_light = 1.0 - smoothstep(0.0, top_light_radius, top_light_distance);
	top_light *= 1.0 - smoothstep(0.05, 0.95, SCREEN_UV.y);
	color = mix(color, top_light_color.rgb, top_light * top_light_strength);

	float shaft_width = mix(shaft_spread, shaft_spread * 1.8, SCREEN_UV.y);
	float shaft_center = abs(SCREEN_UV.x - top_light_position.x);
	float shaft_mask = 1.0 - smoothstep(0.0, shaft_width, shaft_center);
	shaft_mask *= 1.0 - smoothstep(0.0, 1.0, SCREEN_UV.y);
	color += top_light_color.rgb * shaft_mask * shaft_strength;

	vec2 centered = abs(SCREEN_UV - vec2(0.5));
	float vignette = smoothstep(0.35, 0.82, length(centered));
	color *= 1.0 - vignette * edge_shadow_strength;

	float lower_cave = smoothstep(0.16, 1.0, SCREEN_UV.y);
	color *= 1.0 - lower_cave * cavern_falloff;

	float grain = hash(FRAGCOORD.xy + TIME * 17.0) - 0.5;
	color += grain * grain_strength;

	COLOR = vec4(color, screen.a);
}
