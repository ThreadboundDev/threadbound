shader_type canvas_item;

// Only non-solid rear wood uses this material. Preserve alpha and sharp contours.
uniform float saturation : hint_range(0.0, 1.0) = 0.45;
uniform float contrast : hint_range(0.0, 1.0) = 0.65;
uniform float haze_amount : hint_range(0.0, 1.0) = 0.28;
uniform vec4 haze_color : source_color = vec4(0.10, 0.19, 0.26, 1.0);

void fragment() {
	// Canvas fragment COLOR already includes the texture and node modulation.
	vec4 source = COLOR;
	float value = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 quiet = mix(vec3(value), source.rgb, saturation);
	quiet = (quiet - vec3(0.5)) * contrast + vec3(0.5);
	COLOR = vec4(mix(quiet, haze_color.rgb, haze_amount), source.a);
}
