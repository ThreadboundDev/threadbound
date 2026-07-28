shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 tint_color : source_color = vec4(1.0, 0.84, 0.48, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.82;
uniform float energy : hint_range(0.0, 3.0) = 1.0;
uniform float opacity : hint_range(0.0, 1.0) = 0.62;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float value = max(source.r, max(source.g, source.b));
	vec3 source_neutral = mix(vec3(value), source.rgb, 0.28);
	vec3 tinted = mix(source_neutral, tint_color.rgb * value, tint_strength);
	float alpha = source.a * COLOR.a * tint_color.a * opacity;
	COLOR = vec4(tinted * COLOR.rgb * energy * opacity, alpha);
}
