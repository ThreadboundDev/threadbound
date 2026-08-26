shader_type canvas_item;

uniform float blend_width : hint_range(0.01, 0.3) = 0.09;

void fragment() {
	vec4 painted = texture(TEXTURE, UV) * COLOR;
	float left_fade = smoothstep(0.0, blend_width, UV.x);
	float right_fade = smoothstep(0.0, blend_width, 1.0 - UV.x);
	painted.a *= left_fade * right_fade;
	COLOR = painted;
}
