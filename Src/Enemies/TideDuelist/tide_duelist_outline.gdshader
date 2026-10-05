shader_type canvas_item;
render_mode unshaded;

uniform vec4 outline_color : source_color = vec4(0.015, 0.035, 0.055, 0.96);
uniform float outline_width : hint_range(0.0, 6.0, 0.5) = 3.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 pixel = TEXTURE_PIXEL_SIZE * outline_width;
	float nearby_alpha = 0.0;
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV + vec2(pixel.x, 0.0)).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV - vec2(pixel.x, 0.0)).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV + vec2(0.0, pixel.y)).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV - vec2(0.0, pixel.y)).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV + pixel).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV - pixel).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV + vec2(pixel.x, -pixel.y)).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV + vec2(-pixel.x, pixel.y)).a);
	float outline_alpha = max(0.0, nearby_alpha - source.a);
	COLOR = mix(outline_color * outline_alpha, source, source.a);
	COLOR.a = max(source.a, outline_alpha * outline_color.a);
}
