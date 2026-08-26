shader_type canvas_item;

uniform vec4 deep_color : source_color = vec4(0.045, 0.19, 0.34, 1.0);
uniform vec4 mid_color : source_color = vec4(0.09, 0.42, 0.61, 1.0);
uniform vec4 light_color : source_color = vec4(0.28, 0.61, 0.66, 1.0);
uniform vec4 glint_color : source_color = vec4(0.58, 0.81, 0.79, 1.0);
uniform float motion_speed = 0.22;
uniform float ripple_density = 32.0;
uniform float gust_frequency = 0.13;

float band(float value, float center, float width) {
	return 1.0 - smoothstep(width, width * 2.0, abs(value - center));
}

void fragment() {
	vec2 uv = UV;
	float time = TIME * motion_speed;
	float gust = pow(max(sin(TIME * gust_frequency), 0.0), 8.0);
	float bend = sin(uv.x * 11.0 + time * 3.0) * 0.012;
	bend += sin(uv.x * 27.0 - time * 1.7) * 0.006;
	bend *= 1.0 + gust * 1.8;

	vec3 water = mix(mid_color.rgb, deep_color.rgb, smoothstep(0.05, 1.0, uv.y));
	water = mix(light_color.rgb, water, smoothstep(0.0, 0.2, uv.y));

	float fine_wave = sin(uv.x * ripple_density + uv.y * 19.0 + time * 5.0);
	float broken = sin(uv.x * 7.0 - time * 1.5) * 0.025;
	float ripple_a = band(fract((uv.y + bend + broken) * 13.0), 0.16, 0.025);
	float ripple_b = band(fract((uv.y - bend * 0.6) * 21.0), 0.72, 0.018);
	float breakup = smoothstep(0.1, 0.72, fine_wave);
	float ripples = ripple_a * breakup * 0.34 + ripple_b * (1.0 - breakup) * 0.15;

	float reflection = sin(uv.x * 5.0 + time) * sin(uv.x * 13.0 - time * 0.7);
	reflection = smoothstep(0.55, 0.95, reflection) * (1.0 - uv.y) * 0.13;
	water = mix(water, glint_color.rgb, clamp(ripples + reflection, 0.0, 0.62));

	float surface = 1.0 - smoothstep(0.018, 0.055, uv.y + bend * 0.7);
	water = mix(water, glint_color.rgb, surface * 0.58);
	COLOR = vec4(water, 1.0);
}
