shader_type canvas_item;

void fragment() {
	// The distant village has reflections baked into its source. Feather the
	// outer edges into the distant lake so those pixels don't form a rectangle.
	float sides = smoothstep(0.0, 0.11, UV.x) * (1.0 - smoothstep(0.89, 1.0, UV.x));
	float bottom = 1.0 - smoothstep(0.72, 1.0, UV.y);
	COLOR.a *= sides * bottom;
}
