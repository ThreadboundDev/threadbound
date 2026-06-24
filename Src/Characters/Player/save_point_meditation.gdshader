shader_type canvas_item;

uniform float pulse_strength : hint_range(0.0, 0.25) = 0.045;
uniform float pulse_speed : hint_range(0.1, 4.0) = 1.15;
uniform vec4 warmth : source_color = vec4(1.0, 0.78, 0.48, 1.0);
uniform float warmth_strength : hint_range(0.0, 0.35) = 0.08;

void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	float pulse = (sin(TIME * TAU * pulse_speed) + 1.0) * 0.5;
	color.rgb = mix(color.rgb, color.rgb * (1.0 + pulse_strength * pulse), color.a);
	color.rgb = mix(color.rgb, warmth.rgb, warmth_strength * pulse * color.a);
	COLOR = color;
}
