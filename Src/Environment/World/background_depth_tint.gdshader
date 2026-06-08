shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(0.55, 0.68, 0.9, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.25;
uniform float saturation : hint_range(0.0, 1.5) = 0.8;
uniform float contrast : hint_range(0.5, 1.5) = 0.9;
uniform float alpha_multiplier : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desaturated = mix(vec3(luma), tex.rgb, saturation);
	vec3 contrasted = (desaturated - vec3(0.5)) * contrast + vec3(0.5);
	vec3 tinted = mix(contrasted, tint_color.rgb, tint_strength);
	COLOR = vec4(tinted, tex.a * alpha_multiplier);
}
