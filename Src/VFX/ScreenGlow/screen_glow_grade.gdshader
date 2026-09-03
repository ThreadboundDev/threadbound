shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.62;
uniform float glow_threshold : hint_range(0.0, 2.0) = 0.72;
uniform float glow_soft_knee : hint_range(0.01, 1.0) = 0.32;
uniform float glow_spread : hint_range(1.0, 6.0) = 3.2;
uniform float exposure : hint_range(-1.0, 1.0) = 0.0;
uniform float contrast : hint_range(0.5, 1.5) = 1.02;
uniform float saturation : hint_range(0.0, 1.5) = 1.04;
uniform vec3 color_balance = vec3(1.01, 1.015, 1.035);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.08;
uniform float vignette_radius : hint_range(0.1, 1.5) = 0.92;

float luminance(vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec3 threshold_color(vec3 color) {
	float brightness = luminance(color);
	float knee = max(glow_soft_knee, 0.001);
	float contribution = smoothstep(glow_threshold - knee, glow_threshold + knee, brightness);
	return color * contribution;
}

void fragment() {
	vec3 source = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	vec3 small_a = textureLod(screen_texture, SCREEN_UV, glow_spread).rgb;
	vec3 small_b = textureLod(screen_texture, SCREEN_UV, glow_spread + 1.5).rgb;
	vec3 bloom = threshold_color(mix(small_a, small_b, 0.42));
	vec3 graded = source + bloom * glow_strength;

	graded *= exp2(exposure);
	graded = (graded - 0.5) * contrast + 0.5;
	float gray = luminance(graded);
	graded = mix(vec3(gray), graded, saturation) * color_balance;

	vec2 centered = SCREEN_UV * 2.0 - 1.0;
	float vignette = smoothstep(vignette_radius, vignette_radius + 0.72, length(centered));
	graded *= 1.0 - vignette * vignette_strength;
	COLOR = vec4(max(graded, vec3(0.0)), 1.0);
}
