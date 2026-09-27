shader_type canvas_item;

uniform float green_threshold : hint_range(0.3, 1.0) = 0.62;
uniform float dominance : hint_range(1.0, 3.0) = 1.32;
uniform float edge_softness : hint_range(0.0, 0.3) = 0.08;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float green_excess = source.g - max(source.r, source.b) * dominance;
	float key = smoothstep(green_threshold - edge_softness, green_threshold, green_excess);
	// Suppress residual spill at keyed edges without affecting the blue-slate
	// artwork, whose green channel never dominates both red and blue this way.
	vec3 cleaned = source.rgb;
	cleaned.g = min(cleaned.g, max(cleaned.r, cleaned.b) * 1.08);
	COLOR = vec4(cleaned, source.a * (1.0 - key));
}
