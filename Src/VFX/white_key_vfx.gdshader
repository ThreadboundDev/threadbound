shader_type canvas_item;

uniform float key_threshold : hint_range(0.0, 1.0) = 0.92;
uniform float key_softness : hint_range(0.001, 0.3) = 0.08;

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	float white_amount = min(tex.r, min(tex.g, tex.b));
	float keyed_alpha = 1.0 - smoothstep(key_threshold - key_softness, key_threshold, white_amount);
	tex.a *= keyed_alpha;
	COLOR = tex;
}
