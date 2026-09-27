shader_type canvas_item;

uniform vec4 fill_color : source_color = vec4(0.027, 0.082, 0.133, 1.0);

void fragment() {
	float source_alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(fill_color.rgb, fill_color.a * source_alpha);
}
