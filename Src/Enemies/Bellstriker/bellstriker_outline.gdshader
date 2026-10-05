shader_type canvas_item;
render_mode unshaded;
uniform vec4 outline_color : source_color = vec4(0.015, 0.035, 0.055, 0.96);
uniform float outline_width : hint_range(0.0, 6.0, 0.5) = 3.0;
varying vec4 item_tint;
void vertex() {
	item_tint = COLOR;
}
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 pixel = TEXTURE_PIXEL_SIZE * outline_width;
	float nearby_alpha = 0.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV + vec2(float(x), float(y)) * pixel).a);
		}
	}
	float edge = max(0.0, nearby_alpha - source.a);
	COLOR = mix(outline_color * edge, source, source.a);
	COLOR.a = max(source.a, edge * outline_color.a);
	// Preserve shared hit flash, death fade, and other CanvasItem modulation.
	COLOR *= item_tint;
}
