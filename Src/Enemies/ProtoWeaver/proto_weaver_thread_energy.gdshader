shader_type canvas_item;
render_mode unshaded;

uniform sampler2D thread_noise : repeat_enable, filter_linear;
uniform vec4 shadow_color : source_color = vec4(0.12, 0.01, 0.018, 1.0);
uniform vec4 strand_color : source_color = vec4(0.92, 0.035, 0.018, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.93, 0.82, 1.0);
uniform float texture_strength : hint_range(0.0, 1.0) = 0.52;
uniform float pulse_speed : hint_range(0.0, 12.0) = 4.8;

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	if (source.a > 0.001) {
		vec2 woven_uv = SCREEN_UV * vec2(42.0, 68.0);
		float coarse = texture(thread_noise, woven_uv + vec2(TIME * 0.24, -TIME * 0.11)).r;
		float cross_thread = sin(
			(SCREEN_UV.x * 1550.0 + SCREEN_UV.y * 920.0)
			+ TIME * pulse_speed
		);
		float weave = smoothstep(0.34, 0.74, coarse * 0.72 + cross_thread * 0.18 + 0.18);
		float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
		vec3 palette = mix(shadow_color.rgb, strand_color.rgb, smoothstep(0.08, 0.68, luminance));
		palette = mix(palette, core_color.rgb, smoothstep(0.72, 1.0, luminance + weave * 0.16));
		float energized = texture_strength * (0.52 + weave * 0.48);
		source.rgb = mix(source.rgb, palette, energized);
		source.rgb += strand_color.rgb * weave * 0.14 * source.a;
	}
	COLOR = source;
}
