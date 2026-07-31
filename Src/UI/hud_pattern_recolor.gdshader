shader_type canvas_item;
render_mode unshaded;

uniform vec4 pattern_black : source_color = vec4(0.035, 0.026, 0.018, 1.0);
uniform vec4 pattern_gold : source_color = vec4(0.69, 0.48, 0.19, 1.0);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	float gold_amount = smoothstep(0.08, 0.72, luminance);
	COLOR = vec4(mix(pattern_black.rgb, pattern_gold.rgb, gold_amount), source.a);
}
