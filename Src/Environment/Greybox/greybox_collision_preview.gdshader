shader_type canvas_item;
render_mode unshaded;

uniform vec4 fill_color : source_color = vec4(0.16, 0.18, 0.22, 1.0);
uniform vec4 border_color : source_color = vec4(0.34, 0.38, 0.44, 1.0);
uniform vec2 atlas_grid = vec2(4.0, 4.0);
uniform float border_width : hint_range(0.0, 0.15) = 0.035;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 tile_uv = fract(UV * atlas_grid);
	float nearest_edge = min(
		min(tile_uv.x, 1.0 - tile_uv.x),
		min(tile_uv.y, 1.0 - tile_uv.y)
	);
	float border = 1.0 - smoothstep(border_width, border_width + 0.012, nearest_edge);
	vec3 greybox_color = mix(fill_color.rgb, border_color.rgb, border);
	COLOR = vec4(greybox_color, source.a * fill_color.a);
}
