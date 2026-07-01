shader_type canvas_item;

uniform vec4 edge_color : source_color = vec4(0.0, 0.0, 0.0, 0.88);
uniform vec4 inner_color : source_color = vec4(0.0, 0.0, 0.0, 0.18);
uniform vec2 focal_center = vec2(0.30, 0.52);
uniform float inner_radius : hint_range(0.0, 1.5) = 0.22;
uniform float outer_radius : hint_range(0.0, 1.5) = 0.78;

void fragment() {
	vec2 aspect = vec2(1.0, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);
	vec2 delta = (SCREEN_UV - focal_center) / aspect;
	float distance_from_focus = length(delta);
	float fade = smoothstep(inner_radius, outer_radius, distance_from_focus);
	COLOR = mix(inner_color, edge_color, fade);
}
